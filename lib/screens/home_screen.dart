import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/history_controller.dart';
import '../models/site_config.dart';
import '../provider.dart';
import '../themes.dart';
import 'history_screen.dart';
import 'webview_screen.dart';

/// Convenience accessors for the theme tokens defined in [themes.dart].
ColorScheme _scheme(BuildContext c) => Theme.of(c).colorScheme;
AnimedivesColors _animedives(BuildContext c) =>
    Theme.of(c).extension<AnimedivesColors>()!;

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

class _HomeScreenState extends State<HomeScreen> {
  final List<AnimeSiteConfig> _sites = [];
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _isInitialized = false;
  // Three-state category filter: null = All (anime + hentai), false = Anime only,
  // true = Hentai only. Replaces the previous single _showMature boolean.
  bool? _showMature;

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
    return _sites
        .where(
          (s) =>
              (_showMature == null || s.mature == _showMature!) &&
              (q.isEmpty ||
                  s.name.toLowerCase().contains(q) ||
                  s.domain.toLowerCase().contains(q)),
        )
        .toList();
  }

  Future<void> _openSite(AnimeSiteConfig site) async {
    // Opening a provider always starts at its homepage; per-anime resume points
    // are listed on the dedicated Continue Watching screen.
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WebviewScreen(site: site)),
    );
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
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
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
      child: _GradientBorder(
        radius: 10,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _scheme(context).surfaceContainerHighest,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ad-Shielded Streaming',
                style: TextStyle(
                  color: _scheme(context).onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A secure, full-screen WebView wrapper. Redirect ads are '
                'blocked, clutter is hidden and video goes native landscape.',
                style: TextStyle(
                  color: _animedives(context).mutedForeground,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  /// Category filter chips (All / Anime / Hentai) rendered above the search bar.
  Widget _filterBar() => SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        sliver: SliverToBoxAdapter(
          child: Row(
            children: [
              _categoryChip('All', _showMature == null, () {
                setState(() => _showMature = null);
              }, isMature: false),
              const SizedBox(width: 12),
              _categoryChip('Anime', _showMature == false, () {
                setState(() => _showMature = false);
              }, isMature: false),
              const SizedBox(width: 12),
              _categoryChip('Hentai', _showMature == true, () {
                setState(() => _showMature = true);
              }, isMature: true),
              const Spacer(),
              if (_showMature == true)
                Icon(Icons.warning_amber_rounded,
                    color: _animedives(context).mutedForeground, size: 16),
            ],
          ),
        ),
      );

  Widget _categoryChip(
      String label, bool selected, VoidCallback onTap,
      {required bool isMature}) {
    final Color color = selected
        ? (isMature
            ? _animedives(context).destructive
            : _scheme(context).primary)
        : _animedives(context).border;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? (isMature
                  ? _animedives(context).destructive.withValues(alpha: 0.15)
                  : _scheme(context).primary.withValues(alpha: 0.15))
              : _scheme(context).surfaceContainerHighest,
          border: Border.all(color: color, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _searchBar() => SliverPadding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
    sliver: SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          color: _scheme(context).surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _animedives(context).border),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _query = v),
          style: TextStyle(color: _scheme(context).onSurface),
          decoration: InputDecoration(
            hintText: 'Search providers...',
            hintStyle: TextStyle(color: _animedives(context).mutedForeground),
            prefixIcon: Icon(Icons.search, color: _scheme(context).onSurface),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _grid() => SliverPadding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
    sliver: SliverLayoutBuilder(
      builder: (context, constraints) {
        final cross = constraints.crossAxisExtent > 600 ? 3 : 2;
        final sites = _filteredSites;
        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.82,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final site = sites[index];
            final isCustom = !defaultSites.contains(site);
            return ProviderCard(
              site: site,
              onTap: () => _openSite(site),
              onRemove: isCustom
                  ? () {
                      setState(() => _sites.remove(site));
                      final custom =
                          _sites.where((s) => !defaultSites.contains(s)).toList();
                      Get.find<HistoryController>().saveCustomSites(custom);
                    }
                  : null,
            );
          }, childCount: sites.length),
        );
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
        child: _GradientBorder(
          radius: 10,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _logo(initial),
                    const Spacer(),
                    if (widget.onRemove != null)
                      Icon(
                        Icons.more_vert,
                        color: animedives.mutedForeground,
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  widget.site.name,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
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
                    Icon(Icons.play_circle_outline, color: scheme.onSurface),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _logo(String initial) {
    if (widget.site.logoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          widget.site.logoUrl,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _gradientLogo(initial),
        ),
      );
    }
    return _gradientLogo(initial);
  }

  Widget _gradientLogo(String initial) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      gradient: animedivesBorderGradient(context),
      borderRadius: BorderRadius.circular(10),
    ),
    alignment: Alignment.center,
    child: Text(
      initial,
      style: TextStyle(
        color: _scheme(context).surface,
        fontSize: 20,
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

class _GradientBorder extends StatelessWidget {
  final Widget child;
  final double radius;

  const _GradientBorder({required this.child, this.radius = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: animedivesBorderGradient(context),
        borderRadius: BorderRadius.circular(radius),
      ),
      padding: const EdgeInsets.all(1.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1.0),
        child: child,
      ),
    );
  }
}
