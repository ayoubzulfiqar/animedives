import 'dart:async';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/watch_history.dart';

/// Storage key under which the list of [WatchHistoryEntry] rows is persisted.
const String _kHistoryPrefsKey = 'animedives.watch_history.v2';

/// Maximum number of history entries kept. Older entries beyond this are
/// dropped on write so the persisted JSON array cannot grow without bound.
const int _kMaxHistoryEntries = 200;

/// Normalizes a domain for comparison: trims, lowercases, and strips a leading
/// "www." so "WWW.AniHQ.cc" and "anihq.cc" group together everywhere (lookup,
/// restore, and clear). This is the single source of truth for domain
/// normalization - the UI layer imports and reuses it rather than duplicating.
String normalizeDomain(String domain) =>
    domain.trim().toLowerCase().replaceFirst(RegExp(r'^www\.'), '');

/// App-wide watch-history store, exposed through GetX so any widget can read or
/// update "continue watching" state reactively.
///
/// Persistence model:
///  * One entry per *anime* (not per site). The key is
///    [WatchHistoryEntry.id] = "$domain::$slug", derived from the anime's URL,
///    so watching multiple animes on the same provider keeps a separate resume
///    point for each, and re-opening the same anime updates the existing entry
///    instead of duplicating it.
///  * The full list is serialized as a JSON array inside a single
///    `SharedPreferences` string for an atomic, cheap read/write.
///  * The in-memory list is kept sorted by [WatchHistoryEntry.lastWatchedAt]
///    descending so the most recently watched anime is always first.
class HistoryController extends GetxController {
  /// Reactive list of history entries, newest first.
  final RxList<WatchHistoryEntry> entries = <WatchHistoryEntry>[].obs;

  /// True once the initial load from disk has completed. UI can use this to
  /// avoid a flash of empty state before preferences are read.
  final RxBool isReady = false.obs;

  SharedPreferences? _prefs;

  /// Serializes concurrent disk writes into a single linear queue so that a
  /// slower, older write can never land after a newer one (write-skew that
  /// would silently revert history). Callers `await` the returned future, so
  /// they only proceed once their specific modification is safely on disk -
  /// no early-return that could be killed before the deferred write lands.
  Future<void>? _pendingSaveTask;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  /// Reads the persisted list.
  ///
  /// Each stored entry is parsed defensively: a single malformed/corrupt row
  /// (rare disk failure, schema change, missing field) is discarded on its own
  /// rather than throwing and wiping the user's entire history.
  Future<void> _load() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final raw = _prefs?.getStringList(_kHistoryPrefsKey) ?? [];
      final parsed = <WatchHistoryEntry>[];
      for (final row in raw) {
        try {
          parsed.add(WatchHistoryEntry.fromJsonString(row));
        } catch (_) {
          // Skip just this corrupt entry; keep the rest.
        }
      }
      parsed.sort((a, b) => b.lastWatchedAt.compareTo(a.lastWatchedAt));
      entries.assignAll(parsed);
    } catch (_) {
      // Only a catastrophic failure (e.g. prefs itself unavailable) clears.
      entries.clear();
    } finally {
      isReady.value = true;
    }
  }

  /// Persists the current [entries] to disk. Returns false if persistence is
  /// unavailable so callers can ignore transient failures.
  ///
  /// Writes are fully serialized through an awaitable completer queue: if a
  /// save is already running, the caller awaits that in-flight task and then
  /// runs its own save. This guarantees (a) no write-skew from interleaved
  /// writes, and (b) callers only return once THEIR modification is on disk -
  /// there is no early `false` return that could be killed by process death
  /// before the deferred write lands.
  Future<bool> _save() async {
    // Chain onto any save currently in flight so writes stay strictly ordered.
    if (_pendingSaveTask != null) {
      await _pendingSaveTask;
    }

    final completer = Completer<void>();
    _pendingSaveTask = completer.future;

    try {
      _prefs ??= await SharedPreferences.getInstance();
      if (_prefs == null) return false;
      final raw = entries.map((e) => e.toJsonString()).toList();
      return await _prefs!.setStringList(_kHistoryPrefsKey, raw);
    } catch (_) {
      return false;
    } finally {
      completer.complete();
      _pendingSaveTask = null;
    }
  }

  /// All history entries, newest first.
  List<WatchHistoryEntry> get all => entries;

  /// All history entries for a given provider [domain] (newest first). Domain
  /// comparison is normalized (trim + case + leading "www.") so variants group.
  List<WatchHistoryEntry> forDomain(String domain) {
    if (domain.isEmpty) return const [];
    final cleanTarget = normalizeDomain(domain);
    return entries
        .where((e) => normalizeDomain(e.domain) == cleanTarget)
        .toList();
  }

  /// Returns the saved entry matching [id], or null.
  WatchHistoryEntry? byId(String id) {
    if (id.isEmpty) return null;
    return entries.where((e) => e.id == id).firstOrNull;
  }

  /// Records (or updates) the resume point for a specific anime.
  ///
  /// Calling this repeatedly as the user navigates within the same anime simply
  /// bumps [lastWatchedAt] and updates [url]/[title]; it never creates
  /// duplicates. The list is re-sorted and persisted after the write.
  ///
  /// Pass [preserveTimestamp] = true (e.g. when undoing a deletion) to keep the
  /// entry's original [lastWatchedAt] so it returns to its previous position
  /// instead of jumping to the top of the list.
  Future<void> record(
    WatchHistoryEntry entry, {
    bool preserveTimestamp = false,
  }) async {
    if (entry.id.isEmpty || entry.url.isEmpty) return;
    final idx = entries.indexWhere((e) => e.id == entry.id);
    final now = preserveTimestamp
        ? entry.lastWatchedAt
        : DateTime.now().millisecondsSinceEpoch;

    if (idx == -1) {
      entries.add(entry.copyWith(lastWatchedAt: now));
    } else {
      entries[idx] = entry.copyWith(lastWatchedAt: now);
    }
    entries.sort((a, b) => b.lastWatchedAt.compareTo(a.lastWatchedAt));
    // Cap the list so unbounded growth can't make the SharedPreferences JSON
    // array grow forever (which would cause disk/UI jank over months of use).
    // Only the 200 most-recently-watched animes are kept.
    if (entries.length > _kMaxHistoryEntries) {
      entries.removeRange(_kMaxHistoryEntries, entries.length);
    }
    // Keep the reactive list identity fresh for observers.
    entries.refresh();
    await _save();
  }

  /// Removes a single anime's history by [id].
  Future<void> removeById(String id) async {
    if (id.isEmpty) return;
    entries.removeWhere((e) => e.id == id);
    entries.refresh();
    await _save();
  }

  /// Removes every history entry for a provider [domain]. Domain comparison is
  /// normalized (trim + case + leading "www.").
  Future<void> clearDomain(String domain) async {
    if (domain.isEmpty) return;
    final cleanTarget = normalizeDomain(domain);
    entries.removeWhere((e) => normalizeDomain(e.domain) == cleanTarget);
    entries.refresh();
    await _save();
  }

  /// Clears all watch history.
  Future<void> clearAll() async {
    entries.clear();
    await _save();
  }
}
