import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/history_controller.dart';
import '../models/site_config.dart';
import '../models/watch_history.dart';
import '../provider.dart';
import '../themes.dart';
import 'webview_screen.dart';

/// Convenience accessors for the theme tokens defined in [themes.dart].
ColorScheme _scheme(BuildContext c) => Theme.of(c).colorScheme;
AnimedivesColors _animedives(BuildContext c) =>
    Theme.of(c).extension<AnimedivesColors>()!;

/// Human-friendly "last watched" label, e.g. "just now", "2h ago".
///
/// Defensive against corrupted clocks: a zero/negative [ts] (uninitialized)
/// or a future timestamp (system clock ahead) is clamped to "just now" rather
/// than producing a negative or absurd value. Intervals are truncated (floor)
/// so an episode watched 1h35m ago shows "1h ago" until a full second hour
/// elapses, which matches natural human expectation.
String _relativeTime(int ts) {
  if (ts <= 0) return 'just now';
  final diff = DateTime.now().millisecondsSinceEpoch - ts;
  if (diff <= 0) return 'just now';
  if (diff < 60000) return 'just now';
  if (diff < 3600000) return '${(diff / 60000).floor()}m ago';
  if (diff < 86400000) return '${(diff / 3600000).floor()}h ago';
  if (diff < 604800000) return '${(diff / 86400000).floor()}d ago';
  return '${(diff / 604800000).floor()}w ago';
}

/// Safely extracts the first user-perceived character (grapheme cluster) of
/// [text] for the avatar initial, handling emoji flags, combining diacritics
/// and surrogate pairs correctly via the [characters] package.
String _initialChar(String text) {
  if (text.isEmpty) return '?';
  return text.characters.first.toUpperCase();
}

/// Dedicated "Continue Watching" screen listing every anime the user has
/// watched, newest first. Each row resumes the exact episode URL; rows can be
/// swiped to delete (with an Undo snackbar) and the whole list can be cleared.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  /// Resolves the [AnimeSiteConfig] for a history entry so we can reopen the
  /// WebView with the correct shield config. Matching is normalized (trim + case
  /// + leading "www.") against [defaultSites] using the controller's single
  /// source of truth; if the provider is no longer present we synthesize a
  /// minimal config from the entry itself.
  AnimeSiteConfig _siteFor(WatchHistoryEntry entry) {
    final target = normalizeDomain(entry.domain);
    final match = defaultSites.where(
      (s) => normalizeDomain(s.domain) == target,
    );
    if (match.isNotEmpty) return match.first;
    // Build a safe fallback homepage URL: if the stored domain already carries
    // a scheme (e.g. "http://192.168.1.50:8080") use it as-is, otherwise prefix
    // https://. This avoids producing a broken "https://http://..." address.
    final fallbackUrl = Uri.tryParse(entry.domain)?.hasScheme == true
        ? entry.domain
        : 'https://${entry.domain}';
    return AnimeSiteConfig.auto(
      name: entry.providerName,
      homepageUrl: fallbackUrl,
    );
  }

  Future<void> _resume(BuildContext context, WatchHistoryEntry entry) async {
    final site = _siteFor(entry);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WebviewScreen(site: site, initialUrl: entry.url),
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    // Snapshot the theme tokens AND the ScaffoldMessenger BEFORE any async gap
    // so we never dereference a potentially-unmounted BuildContext after
    // awaiting the dialog/controller.
    final scheme = _scheme(context);
    final animedives = _animedives(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(
          'Clear watch history?',
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This removes every saved resume point and cannot be undone.',
          style: TextStyle(color: animedives.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: animedives.mutedForeground),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      // Clear any lingering "Undo" snackbar so its action can't resurrect a
      // single item into the now-empty list.
      messenger.hideCurrentSnackBar();
      await Get.find<HistoryController>().clearAll();
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: scheme.inverseSurface,
            content: Text(
              'Watch history cleared',
              style: TextStyle(color: scheme.inversePrimary),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Deletes a single entry immediately and offers an Undo action so the fast
  /// swipe-to-delete gesture isn't interrupted by a confirmation dialog.
  void _deleteWithUndo(BuildContext context, WatchHistoryEntry entry) {
    final history = Get.find<HistoryController>();
    final scheme = _scheme(context);
    // Snapshot the entry so Undo can re-insert the exact same record.
    final removed = entry;

    // Show the snackbar immediately for snappy feedback. The actual removal is
    // deferred one frame (Duration.zero) so Flutter finishes tearing down the
    // Dismissible's slide-out animation and frees its list slot BEFORE the
    // Obx-driven SliverList rebuilds with a smaller childCount. Mutating the
    // reactive list synchronously inside onDismissed would yank the item out
    // mid-animation and throw "A Dismissible widget still resides in the tree".
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: scheme.inverseSurface,
            content: Text(
              'Removed "${removed.title}"',
              style: TextStyle(color: scheme.inversePrimary),
            ),
            action: SnackBarAction(
              label: 'Undo',
              textColor: scheme.inversePrimary,
              // Preserve the original timestamp so the item returns to its
              // previous position instead of jumping to the top.
              onPressed: () => history.record(removed, preserveTimestamp: true),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
    }

    // Deferred removal (see note above). The disk write inside removeById runs
    // concurrently in the background thereafter.
    Future.delayed(Duration.zero, () => history.removeById(removed.id));
  }

  @override
  Widget build(BuildContext context) {
    final history = Get.find<HistoryController>();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.arrow_back,
                        color: _scheme(context).onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'CONTINUE WATCHING',
                      style: TextStyle(
                        color: _scheme(context).onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    Obx(() {
                      if (history.entries.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return IconButton(
                        tooltip: 'Clear all',
                        onPressed: () => _confirmClearAll(context),
                        icon: Icon(
                          Icons.delete_sweep_outlined,
                          color: _scheme(context).onSurface,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            Obx(() {
              if (!history.isReady.value) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (history.entries.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_toggle_off_outlined,
                            size: 56,
                            color: _animedives(context).mutedForeground,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No watch history yet',
                            style: TextStyle(
                              color: _scheme(context).onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Anime you watch will show up here so you can '
                            'pick up right where you left off.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _animedives(context).mutedForeground,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((ctx, index) {
                    // Guard against the list shrinking during a layout sweep
                    // (reactive removal): never build an out-of-range index.
                    if (index < 0 || index >= history.entries.length) {
                      return const SizedBox.shrink();
                    }
                    final entry = history.entries[index];
                  return _HistoryRow(
                    key: ValueKey('row_${entry.id}'),
                    entry: entry,
                    // Use the scoped builder context 'ctx' so Navigator/scaffold
                    // lookups resolve from the precise list element.
                    onTap: () => _resume(ctx, entry),
                    onDelete: () => _deleteWithUndo(ctx, entry),
                  );
                  }, childCount: history.entries.length),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final WatchHistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryRow({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = _scheme(context);
    final animedives = _animedives(context);
    final initial = _initialChar(entry.title);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key('dismiss_${entry.id}'),
        direction: DismissDirection.endToStart,
        // No confirmDismiss: a swipe deletes immediately for a fast gesture,
        // with an Undo offered via SnackBar (see _deleteWithUndo).
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: scheme.error,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.delete_outline, color: scheme.onError),
        ),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border.all(color: animedives.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: animedivesBorderGradient(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: scheme.surface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${entry.providerName} · ${_relativeTime(entry.lastWatchedAt)}',
                        style: TextStyle(
                          color: animedives.mutedForeground,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.play_circle_fill, color: scheme.onSurface),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
