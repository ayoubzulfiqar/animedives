import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/history_controller.dart';
import '../models/site_config.dart';
import '../models/watch_history.dart';
import '../provider.dart';
import '../themes.dart';
import 'history_screen.dart';
import 'webview_screen.dart';

/// Convenience accessors for the theme tokens defined in [themes.dart].
ColorScheme _scheme(BuildContext c) => Theme.of(c).colorScheme;
AnimedivesColors _animedives(BuildContext c) =>
    Theme.of(c).extension<AnimedivesColors>() ??
    (Theme.of(c).brightness == Brightness.dark
        ? darkAnimedivesColors
        : lightAnimedivesColors);

/// The application's landing screen.
class HomeScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onCycleTheme;

  const HomeScreen({
    super.key,
    required this.themeMode,
    required this.onCycleTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum ProviderCategory { all, favorites, anime, mature }

class _HomeScreenState extends State<HomeScreen> {
  final List<AnimeSiteConfig> _sites = [];
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _isInitialized = false;
  ProviderCategory _filter = ProviderCategory.all;

  @override
  void initState() {
    super.initState();
    // Pre-load custom sites saved from a previous session alongside the
    // default providers. Done in initState so the list is ready before the
    // first build.
    _sites.addAll(defaultSites);
    _loadCustomSites();
  }

  Future<void> _loadCustomSites() async {
    try {
      final custom = await Get.find<HistoryController>().loadCustomSites();
      if (mounted && custom.isNotEmpty) {
        setState(() {
          _sites.addAll(custom);
        });
      }
    } catch (_) {
      // SharedPreferences may be unavailable (e.g. in unit tests); the
      // default sites are already loaded so the UI can still render.
    } finally {
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AnimeSiteConfig> get _filteredSites {
    final q = _query.trim().toLowerCase();
    final history = Get.find<HistoryController>();
    return _sites.where((s) {
      if (_filter == ProviderCategory.favorites &&
          !history.isFavorite(s.domain)) {
        return false;
      }
      if (_filter == ProviderCategory.anime && s.mature) {
        return false;
      }
      if (_filter == ProviderCategory.mature && !s.mature) {
        return false;
      }
      return q.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.domain.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _openSite(AnimeSiteConfig site) async {
    // Opening a provider always starts at its homepage; per-anime resume points
    // are listed on the dedicated Continue Watching screen.
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => WebviewScreen(site: site)));
  }

  Future<void> _resumeHistory(WatchHistoryEntry entry) async {
    final site =
        Get.find<HistoryController>().findSiteByDomain(entry.domain) ??
        AnimeSiteConfig.auto(
          name: entry.providerName,
          homepageUrl: Uri.tryParse(entry.domain)?.hasScheme == true
              ? entry.domain
              : 'https://${entry.domain}',
        );
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WebviewScreen(site: site, initialUrl: entry.url),
      ),
    );
  }

  Future<void> _confirmRemoveCustomSite(AnimeSiteConfig site) async {
    final scheme = _scheme(context);
    final animedives = _animedives(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Remove "${site.name}"?',
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to remove this custom provider from your list?',
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
              backgroundColor: animedives.destructive,
              foregroundColor: scheme.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _sites.remove(site));
      final custom = _sites.where((s) => !defaultSites.contains(s)).toList();
      Get.find<HistoryController>().saveCustomSites(custom);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: scheme.inverseSurface,
            content: Text(
              'Removed custom site "${site.name}"',
              style: TextStyle(color: scheme.inversePrimary),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Opens a form dialog to append a provider configuration safely.
  Future<void> _showAddDialog() async {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final selectorsCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<AnimeSiteConfig>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _scheme(ctx).surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(
          'Add Custom Site',
          style: TextStyle(
            color: _scheme(ctx).onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(nameCtrl, 'Site name', 'AnimeX'),
                const SizedBox(height: 12),
                _field(
                  urlCtrl,
                  'Homepage URL',
                  'https://example.com',
                  validator: (v) {
                    final uri = Uri.tryParse(v ?? '');
                    if (uri == null || uri.host.isEmpty) {
                      return 'Enter a valid URL';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _field(
                  selectorsCtrl,
                  'Hide selectors (comma separated, optional)',
                  'header, footer, .ads',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: _animedives(ctx).mutedForeground),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _scheme(ctx).inverseSurface,
              foregroundColor: _scheme(ctx).inversePrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                final url = urlCtrl.text.trim();
                final selectors = selectorsCtrl.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
                Navigator.of(ctx).pop(
                  AnimeSiteConfig.auto(
                    name: nameCtrl.text.trim(),
                    homepageUrl: url,
                    hideSelectors: selectors,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    // Context mounting check enforces frame safety across structural pops
    if (result != null && mounted) {
      setState(() => _sites.add(result));
      final custom = _sites.where((s) => !defaultSites.contains(s)).toList();
      Get.find<HistoryController>().saveCustomSites(custom);
    }
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    String hint, {
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: ctrl,
    validator: validator,
    style: TextStyle(color: _scheme(context).onSurface),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: _animedives(context).mutedForeground),
      labelStyle: TextStyle(color: _animedives(context).mutedForeground),
      filled: true,
      fillColor: _scheme(context).surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _scheme(context).onSurface, width: 1.5),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _appBar(),
              _welcomeBanner(),
              _continueWatchingRail(),
              _searchBar(),
              _filterBar(),
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _appBar(),
            _welcomeBanner(),
            _continueWatchingRail(),
            _searchBar(),
            _filterBar(),
            _grid(),
          ],
        ),
      ),
    );
  }

  Widget _appBar() => SliverPadding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
    sliver: SliverToBoxAdapter(
      child: Row(
        children: [
          Icon(Icons.bolt, color: _scheme(context).onSurface, size: 26),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'ANIMEDIVES',
              style: TextStyle(
                color: _scheme(context).onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          _historyButton(),
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: widget.onCycleTheme,
            icon: Icon(
              widget.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : widget.themeMode == ThemeMode.light
                  ? Icons.dark_mode
                  : Icons.brightness_auto,
              color: _scheme(context).onSurface,
            ),
          ),
          IconButton(
            tooltip: 'Add custom site',
            onPressed: _showAddDialog,
            icon: Icon(
              Icons.add_circle_outline,
              color: _scheme(context).onSurface,
            ),
          ),
          // IconButton(
          //   tooltip: 'Settings',
          //   onPressed: () {
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       SnackBar(
          //         backgroundColor: _scheme(context).inverseSurface,
          //         content: Text(
          //           'Long-press a card to remove a custom site.',
          //           style: TextStyle(color: _scheme(context).inversePrimary),
          //         ),
          //         duration: const Duration(seconds: 2),
          //       ),
          //     );
          //   },
          //   icon: Icon(
          //     Icons.settings_outlined,
          //     color: _scheme(context).onSurface,
          //   ),
          // ),
        ],
      ),
    ),
  );

  Widget _historyButton() {
    final history = Get.find<HistoryController>();
    return Obx(() {
      final count = history.entries.length;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            tooltip: 'Continue watching',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
            icon: Icon(
              Icons.history_rounded,
              color: _scheme(context).onSurface,
            ),
          ),
          if (count > 0)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _scheme(context).inverseSurface,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: TextStyle(
                    color: _scheme(context).inversePrimary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _welcomeBanner() => SliverPadding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
    sliver: SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _animedives(context).cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _animedives(context).cardBorder,
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ad-Shielded Streaming',
              style: TextStyle(
                color: _scheme(context).onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'A secure, full-screen WebView wrapper. Redirect ads are '
              'blocked, clutter is hidden and video goes native landscape.',
              style: TextStyle(
                color: _animedives(context).mutedForeground,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _continueWatchingRail() {
    final history = Get.find<HistoryController>();
    return Obx(() {
      final entries = history.entries;
      if (entries.isEmpty) {
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      }
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.play_circle_filled_rounded,
                    color: _scheme(context).onSurface,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CONTINUE WATCHING',
                    style: TextStyle(
                      color: _scheme(context).onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'See all (${entries.length})',
                          style: TextStyle(
                            color: _scheme(context).onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: _scheme(context).onSurface,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: entries.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (ctx, i) {
                    final entry = entries[i];
                    return _ContinueWatchingCard(
                      entry: entry,
                      onTap: () => _resumeHistory(entry),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Category filter chips (All / Favorites / Anime / Hentai) rendered above the search bar.
  Widget _filterBar() {
    final history = Get.find<HistoryController>();
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      sliver: SliverToBoxAdapter(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _categoryChip('All', _filter == ProviderCategory.all, () {
                setState(() => _filter = ProviderCategory.all);
              }),
              const SizedBox(width: 8),
              Obx(() {
                final favCount = history.favoriteDomains.length;
                return _categoryChip(
                  favCount > 0 ? 'Favorites ($favCount)' : 'Favorites',
                  _filter == ProviderCategory.favorites,
                  () {
                    setState(() => _filter = ProviderCategory.favorites);
                  },
                  icon: Icons.star_rounded,
                );
              }),
              const SizedBox(width: 8),
              _categoryChip('Anime', _filter == ProviderCategory.anime, () {
                setState(() => _filter = ProviderCategory.anime);
              }),
              const SizedBox(width: 8),
              _categoryChip(
                '18+ / Hentai',
                _filter == ProviderCategory.mature,
                () {
                  setState(() => _filter = ProviderCategory.mature);
                },
                isMature: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(
    String label,
    bool selected,
    VoidCallback onTap, {
    bool isMature = false,
    IconData? icon,
  }) {
    final scheme = _scheme(context);
    final animedives = _animedives(context);

    final Color bgColor;
    final Color textColor;
    final Color borderColor;

    if (selected) {
      if (isMature) {
        bgColor = animedives.destructive;
        textColor = Colors.white;
        borderColor = animedives.destructive;
      } else {
        bgColor = scheme.onSurface;
        textColor = scheme.surface;
        borderColor = scheme.onSurface;
      }
    } else {
      bgColor = scheme.surfaceContainerHighest;
      textColor = animedives.mutedForeground;
      borderColor = animedives.border;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 1.0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: textColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    final animedives = _animedives(context);
    final count = _filteredSites.length;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      sliver: SliverToBoxAdapter(
        child: Container(
          decoration: BoxDecoration(
            color: animedives.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: animedives.cardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  style: TextStyle(color: _scheme(context).onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search providers...',
                    hintStyle: TextStyle(color: animedives.mutedForeground),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: _scheme(context).onSurface,
                    ),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            tooltip: 'Clear search',
                            icon: Icon(
                              Icons.clear_rounded,
                              color: animedives.mutedForeground,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _scheme(context).surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: animedives.border),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: animedives.mutedForeground,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grid() => SliverPadding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
    sliver: SliverLayoutBuilder(
      builder: (context, constraints) {
        final scheme = _scheme(context);
        final animedives = _animedives(context);
        final width = constraints.crossAxisExtent;
        final int cross;
        if (width > 1200) {
          cross = 5;
        } else if (width > 900) {
          cross = 4;
        } else if (width > 600) {
          cross = 3;
        } else {
          cross = 2;
        }
        return Obx(() {
          // React to favorite state changes
          final _ = Get.find<HistoryController>().favoriteDomains.length;
          final sites = _filteredSites;
          if (sites.isEmpty) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 48,
                  horizontal: 24,
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        _filter == ProviderCategory.favorites
                            ? Icons.star_border_rounded
                            : Icons.search_off_rounded,
                        size: 48,
                        color: animedives.mutedForeground,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _filter == ProviderCategory.favorites
                            ? 'No favorite providers yet'
                            : 'No providers found',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _filter == ProviderCategory.favorites
                            ? 'Tap the star icon on any card to pin your favorite sites here.'
                            : 'Try adjusting your search query or category filter.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: animedives.mutedForeground,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cross,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.84,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final site = sites[index];
              final isCustom = !defaultSites.contains(site);
              return ProviderCard(
                key: ValueKey('provider_${site.domain}'),
                site: site,
                onTap: () => _openSite(site),
                onRemove: isCustom
                    ? () => _confirmRemoveCustomSite(site)
                    : null,
              );
            }, childCount: sites.length),
          );
        });
      },
    ),
  );
}

class ProviderCard extends StatefulWidget {
  final AnimeSiteConfig site;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const ProviderCard({
    super.key,
    required this.site,
    required this.onTap,
    this.onRemove,
  });

  @override
  State<ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<ProviderCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = _scheme(context);
    final animedives = _animedives(context);
    final history = Get.find<HistoryController>();
    final initial = widget.site.name.isNotEmpty
        ? widget.site.name[0].toUpperCase()
        : '?';

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      onLongPress: widget.onRemove,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: animedives.cardSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: animedives.cardBorder, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _logo(initial),
                  const Spacer(),
                  Obx(() {
                    final isFav = history.isFavorite(widget.site.domain);
                    return IconButton(
                      iconSize: 22,
                      splashRadius: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      tooltip: isFav
                          ? 'Unfavorite provider'
                          : 'Favorite provider',
                      icon: Icon(
                        isFav ? Icons.star_rounded : Icons.star_border_rounded,
                        color: isFav
                            ? scheme.onSurface
                            : animedives.mutedForeground,
                      ),
                      onPressed: () {
                        history.toggleFavorite(widget.site.domain);
                      },
                    );
                  }),
                  if (widget.onRemove != null)
                    IconButton(
                      iconSize: 20,
                      splashRadius: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      tooltip: 'Remove custom site',
                      icon: Icon(
                        Icons.more_vert,
                        color: animedives.mutedForeground,
                      ),
                      onPressed: widget.onRemove,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.site.name,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.site.mature) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: animedives.destructive.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: animedives.destructive,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        '18+',
                        style: TextStyle(
                          color: animedives.destructive,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                widget.site.domain,
                style: TextStyle(
                  color: animedives.mutedForeground,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  _stat(
                    Icons.shield_outlined,
                    '${widget.site.hideSelectors.length} blocked',
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.surfaceContainerHighest,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: scheme.onSurface,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logo(String initial) {
    final url = widget.site.effectiveFaviconUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _scheme(context).surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _animedives(context).border, width: 1.0),
        ),
        child: Image.network(
          url,
          width: 36,
          height: 36,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _gradientLogo(initial),
        ),
      ),
    );
  }

  Widget _gradientLogo(String initial) => Center(
    child: Text(
      initial,
      style: TextStyle(
        color: _scheme(context).onSurface,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _stat(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: _scheme(context).onSurface, size: 14),
      const SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(
          color: _animedives(context).mutedForeground,
          fontSize: 11,
        ),
      ),
    ],
  );
}

class _ContinueWatchingCard extends StatefulWidget {
  final WatchHistoryEntry entry;
  final VoidCallback onTap;

  const _ContinueWatchingCard({required this.entry, required this.onTap});

  @override
  State<_ContinueWatchingCard> createState() => _ContinueWatchingCardState();
}

class _ContinueWatchingCardState extends State<_ContinueWatchingCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = _scheme(context);
    final animedives = _animedives(context);
    final initial = widget.entry.title.isNotEmpty
        ? widget.entry.title.characters.first.toUpperCase()
        : '?';

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          width: 250,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: animedives.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: animedives.cardBorder, width: 1.0),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: animedives.border, width: 1.0),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.entry.title,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${widget.entry.providerName} · ${relativeTime(widget.entry.lastWatchedAt)}',
                      style: TextStyle(
                        color: animedives.mutedForeground,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.surfaceContainerHighest,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: scheme.onSurface,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
