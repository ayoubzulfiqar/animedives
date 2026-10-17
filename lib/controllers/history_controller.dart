import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/site_config.dart';
import '../models/watch_history.dart';
import '../provider.dart';

/// Storage keys for app data persistence.
const String _kHistoryPrefsKey = 'animedives.watch_history.v2';
const String _kThemePrefsKey = 'animedives.theme_mode.v1';
const String _kFavoritesPrefsKey = 'animedives.favorite_sites.v1';
const String _kCustomSitesPrefsKey = 'animedives.custom_sites.v1';

/// Maximum number of history entries kept. Older entries beyond this are
/// dropped on write so the persisted JSON array cannot grow without bound.
const int _kMaxHistoryEntries = 200;

/// Normalizes a domain for comparison: trims, lowercases, and strips a leading
/// "www." so "WWW.AniHQ.cc" and "anihq.cc" group together everywhere (lookup,
/// restore, and clear). This is the single source of truth for domain
/// normalization across the app.
String normalizeDomain(String domain) =>
    domain.trim().toLowerCase().replaceFirst(RegExp(r'^www\.'), '');

/// App-wide controller managing watch history, favorites, theme preference,
/// and custom providers.
class HistoryController extends GetxController {
  /// Reactive list of history entries, newest first.
  final RxList<WatchHistoryEntry> entries = <WatchHistoryEntry>[].obs;

  /// Reactive set of pinned / favorited provider domains.
  final RxSet<String> favoriteDomains = <String>{}.obs;

  /// Reactive list of user-created custom providers.
  final RxList<AnimeSiteConfig> customSites = <AnimeSiteConfig>[].obs;

  /// Active application theme mode (persisted to disk).
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  /// True once the initial load from disk has completed.
  final RxBool isReady = false.obs;

  SharedPreferences? _prefs;
  Future<void>? _pendingSaveTask;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  /// Loads all persisted states (history, theme, favorites, custom providers).
  Future<void> loadAll() async {
    _prefs ??= await SharedPreferences.getInstance();
    await Future.wait([
      _loadHistory(),
      _loadTheme(),
      _loadFavorites(),
      _loadCustomSitesInternal(),
    ]);
    isReady.value = true;
  }

  // ── Theme Mode Management ──────────────────────────────────────────

  Future<void> _loadTheme() async {
    try {
      final raw = _prefs?.getString(_kThemePrefsKey);
      if (raw == 'light') {
        themeMode.value = ThemeMode.light;
      } else if (raw == 'dark') {
        themeMode.value = ThemeMode.dark;
      } else {
        themeMode.value = ThemeMode.system;
      }
    } catch (_) {
      themeMode.value = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    _prefs ??= await SharedPreferences.getInstance();
    final val = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs?.setString(_kThemePrefsKey, val);
  }

  Future<void> cycleThemeMode() async {
    final next = switch (themeMode.value) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    await setThemeMode(next);
  }

  // ── Favorites Management ───────────────────────────────────────────

  Future<void> _loadFavorites() async {
    try {
      final list = _prefs?.getStringList(_kFavoritesPrefsKey) ?? [];
      favoriteDomains.assignAll(list.map(normalizeDomain));
    } catch (_) {
      favoriteDomains.clear();
    }
  }

  Future<void> _saveFavorites() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setStringList(_kFavoritesPrefsKey, favoriteDomains.toList());
  }

  bool isFavorite(String domain) {
    if (domain.isEmpty) return false;
    return favoriteDomains.contains(normalizeDomain(domain));
  }

  Future<void> toggleFavorite(String domain) async {
    if (domain.isEmpty) return;
    final norm = normalizeDomain(domain);
    if (favoriteDomains.contains(norm)) {
      favoriteDomains.remove(norm);
    } else {
      favoriteDomains.add(norm);
    }
    await _saveFavorites();
  }

  // ── Watch History Management ───────────────────────────────────────

  Future<void> _loadHistory() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final raw = _prefs?.getStringList(_kHistoryPrefsKey) ?? [];
      final parsed = <WatchHistoryEntry>[];
      for (final row in raw) {
        try {
          parsed.add(WatchHistoryEntry.fromJsonString(row));
        } catch (_) {
          // Skip corrupt rows defensively
        }
      }
      parsed.sort((a, b) => b.lastWatchedAt.compareTo(a.lastWatchedAt));
      entries.assignAll(parsed);
    } catch (_) {
      entries.clear();
    }
  }

  Future<bool> _save() async {
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

  List<WatchHistoryEntry> get all => entries;

  List<WatchHistoryEntry> forDomain(String domain) {
    if (domain.isEmpty) return const [];
    final cleanTarget = normalizeDomain(domain);
    return entries
        .where((e) => normalizeDomain(e.domain) == cleanTarget)
        .toList();
  }

  WatchHistoryEntry? byId(String id) {
    if (id.isEmpty) return null;
    return entries.where((e) => e.id == id).firstOrNull;
  }

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
    if (entries.length > _kMaxHistoryEntries) {
      entries.removeRange(_kMaxHistoryEntries, entries.length);
    }
    entries.refresh();
    await _save();
  }

  Future<void> removeById(String id) async {
    if (id.isEmpty) return;
    entries.removeWhere((e) => e.id == id);
    entries.refresh();
    await _save();
  }

  Future<void> clearDomain(String domain) async {
    if (domain.isEmpty) return;
    final cleanTarget = normalizeDomain(domain);
    entries.removeWhere((e) => normalizeDomain(e.domain) == cleanTarget);
    entries.refresh();
    await _save();
  }

  Future<void> clearAll() async {
    entries.clear();
    await _save();
  }

  // ── Custom Site & Unified Provider Resolution ───────────────────────

  Future<void> _loadCustomSitesInternal() async {
    final sites = await loadCustomSites();
    customSites.assignAll(sites);
  }

  Future<List<AnimeSiteConfig>> loadCustomSites() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getStringList(_kCustomSitesPrefsKey) ?? [];
    final result = <AnimeSiteConfig>[];
    for (final row in raw) {
      try {
        result.add(AnimeSiteConfig.fromJsonString(row));
      } catch (_) {
        // Skip corrupt entry
      }
    }
    return result;
  }

  Future<void> saveCustomSites(List<AnimeSiteConfig> sites) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = sites.map((e) => e.toJsonString()).toList();
    await _prefs!.setStringList(_kCustomSitesPrefsKey, raw);
    customSites.assignAll(sites);
  }

  /// Combines built-in default providers and custom user providers.
  List<AnimeSiteConfig> get allSites => [...defaultSites, ...customSites];

  /// Resolves any provider (built-in or custom) by matching its domain or root domain.
  AnimeSiteConfig? findSiteByDomain(String domain) {
    if (domain.isEmpty) return null;
    final target = normalizeDomain(domain);
    for (final site in allSites) {
      final siteDomain = normalizeDomain(site.domain);
      if (siteDomain == target ||
          target.endsWith('.$siteDomain') ||
          siteDomain.endsWith('.$target')) {
        return site;
      }
    }
    return null;
  }
}
