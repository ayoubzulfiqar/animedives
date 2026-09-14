import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../controllers/history_controller.dart';
import '../models/site_config.dart';
import '../models/watch_history.dart';
import '../themes.dart';

/// Core brand color tokens used across dashboards, custom loaders,
/// and glassmorphism interface panels.
const Color kBrandBlue = Color(0xFF00E5FF); // Electric Cyan
const Color kBrandAmber = Color(
  0xFFB388FF,
); // Vibrant Cyber Purple / Amber Accent

/// Premium linear gradient applied to grid cards, borders,
/// and programmatic text placeholders.
const LinearGradient kBrandGradient = LinearGradient(
  colors: [kBrandBlue, kBrandAmber],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Name of the JavaScript channel used to notify Dart when the page enters or
/// exits HTML5 fullscreen.
const String _fullscreenChannel = 'animedivesFullscreen';

/// Minimum gap between watch-history persistence writes, so rapid in-page
/// navigations don't spam SharedPreferences.
const Duration _kHistoryWriteInterval = Duration(seconds: 3);

/// A secure, ad-shielded WebView wrapper for a single [AnimeSiteConfig].
///
/// Responsibilities:
///  * Block redirect ads via [NavigationDelegate.onNavigationRequest] (allow
///    only the site domain + safe CDN hosts).
///  * Strip headers/footers/pop-ups/chat by injecting site-specific CSS once
///    the page has finished loading.
///  * Go native landscape + immersive when the page enters HTML5 fullscreen.
///    [webview_flutter] has no built-in fullscreen callbacks, so we detect the
///    fullscreen change with a JS listener that posts to a [JavascriptChannel].
///  * Show a fade-out loading overlay and an error/retry screen.
class WebviewScreen extends StatefulWidget {
  final AnimeSiteConfig site;

  /// Optional deep-link to open instead of [AnimeSiteConfig.homepageUrl].
  /// Used by "continue watching" so the user resumes on the exact episode page
  /// they left, rather than the provider's homepage.
  final String? initialUrl;

  const WebviewScreen({super.key, required this.site, this.initialUrl});

  @override
  State<WebviewScreen> createState() => _WebviewScreenState();
}

class _WebviewScreenState extends State<WebviewScreen>
    with WidgetsBindingObserver {
  late final WebViewController _controller;

  bool _isLoading = true;
  bool _hasError = false;
  bool _pageLoaded = false;
  bool _isFullscreen = false;
  bool _isTransitioningFullscreen = false;
  int _progress = 0;

  /// The deepest URL the user has reached on this provider. Persisted to the
  /// watch-history store so the session can be resumed after the app closes.
  String _currentUrl = '';

  /// Best-known title for the current anime. Starts as a humanized URL slug and
  /// is upgraded to the real document title once the page finishes loading.
  String _currentTitle = '';

  /// Guards the history write so rapid in-page navigations don't spam
  /// SharedPreferences on every script-triggered URL change.
  DateTime? _lastHistoryWrite;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = WebViewController()
      // Unrestricted JS is required for the fullscreen listener + CSS injection.
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // A real mobile Chrome UA makes Cloudflare / Turnstile / reCAPTCHA treat
      // the WebView like a normal phone browser instead of a desktop automation
      // client. A desktop UA (or a missing UA) heavily increases the chance
      // that "verify you are human" challenges re-issue after passing.
      ..setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
      )
      ..addJavaScriptChannel(
        _fullscreenChannel,
        onMessageReceived: _onFullscreenMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          // Ad-blocking navigation shield (see [_onNavigationRequest]).
          onNavigationRequest: _onNavigationRequest,
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
              _pageLoaded = false;
            });
            // Track the deepest URL reached so we can resume here later.
            _currentUrl = url;
            // Only pre-hide clutter once we are past any "verify you are human"
            // challenge. Injecting our header/footer/modal/popup CSS on a
            // Cloudflare Turnstile / reCAPTCHA page hides the very widget the
            // user must interact with, so the challenge silently reloads forever.
            // We therefore let challenge/verification hosts render untouched.
            if (_isOnSiteDomain(url)) {
              _injectScripts();
            }
          },
          onPageFinished: (url) => _onPageFinished(url),
          onProgress: (progress) {
            if ((progress - _progress).abs() >= 5) {
              setState(() => _progress = progress);
            }
          },
          // Only a failure of the MAIN document, before it has ever rendered, is
          // fatal. Sub-resource errors (a CDN thumbnail, an ad tracker, a
          // preloaded font/image, an SSL/connection reset) are extremely common
          // and must NOT pop the Retry overlay over a working page. We also
          // ignore `ERR_ABORTED` (-3) which the WebView raises for cancelled /
          // intentionally-unused preloads.
          onWebResourceError: (error) {
            if (error.isForMainFrame != true) return;
            if (error.errorCode == -3) return; // ERR_ABORTED (benign)
            if (_pageLoaded) return; // page is already interactive
            setState(() => _hasError = true);
          },
          // Server (5xx) errors are only fatal during the initial load, never
          // for transient sub-resource failures on an already-loaded page.
          onHttpError: (error) {
            if (_pageLoaded) return;
            final code = error.response?.statusCode;
            if (code != null && code >= 500) {
              setState(() => _hasError = true);
            }
          },
        ),
      );
    // Seed the resume point with the homepage (or the saved deep-link when
    // resuming) so even an immediate exit keeps a valid URL; subsequent
    // navigations overwrite it.
    _currentUrl = widget.initialUrl ?? widget.site.homepageUrl;
    _currentTitle = humanizeSlug(
      Uri.tryParse(_currentUrl)?.pathSegments.isNotEmpty == true
          ? Uri.parse(_currentUrl).pathSegments.last
          : widget.site.name,
    );
    _controller.loadRequest(Uri.parse(_currentUrl));

    // Streaming sites often request images/avatars over plain HTTP while the
    // page itself is HTTPS. By default the Android WebView blocks that
    // "mixed content" and the assets silently fail to load. Compatibility mode
    // allows safe mixed content while maintaining better security than
    // alwaysAllow.
    if (_controller.platform is AndroidWebViewController) {
      final androidController =
          _controller.platform as AndroidWebViewController;
      androidController.setMixedContentMode(MixedContentMode.compatibilityMode);
    }
  }

  @override
  void dispose() {
    // Prevent orientation/wakelock leak if disposed while in fullscreen
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      WakelockPlus.disable().catchError((_) {});
    }
    // Always disable wakelock on dispose to prevent battery drain
    WakelockPlus.disable().catchError((_) {});
    // Final persistence on exit so the resume point reflects the last page even
    // if the throttle suppressed the most recent in-session write.
    _recordHistory(force: true);
    WidgetsBinding.instance.removeObserver(this);
    // Unbind the channel interface explicitly to prevent native callback drift
    // when backing out of a player that is spamming fullscreen toggles.
    _controller.removeJavaScriptChannel(_fullscreenChannel).catchError((_) {});
    // Scrub cached video/data. Guarded so a mid-unmount engine drop can't throw
    // an unhandled error on slow hardware.
    // _controller.clearCache().catchError((_) {});
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause any playing media when the app is backgrounded so audio does not
    // keep streaming from behind (the controller has no native pause API).
    if (state == AppLifecycleState.paused) {
      // Persist the resume point when backgrounded (e.g. user hits home / locks
      // the screen) so it survives process death.
      _recordHistory();
      _controller.runJavaScript(
        'document.querySelectorAll("video,audio").forEach(function(e){'
        'try{e.pause();}catch(_){}});',
      );
    }
  }

  /// ---------------------------------------------------------------------------
  /// Ad-blocking navigation shield.
  ///
  /// [onNavigationRequest] fires for every top-level (main-frame) navigation
  /// attempt. We block the request unless its host belongs to the site's own
  /// [AnimeSiteConfig.domain] or one of the safe CDN / asset hosts. Redirect ad
  /// networks, tracking domains and pop-unders are therefore prevented from
  /// ever loading.
  /// ---------------------------------------------------------------------------
  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    if (uri == null || uri.host.isEmpty) return NavigationDecision.prevent;
    return _isHostAllowed(uri.host)
        ? NavigationDecision.navigate
        : NavigationDecision.prevent;
  }

  /// True when [url] is on the site's own domain (or its safe CDN subdomains).
  /// Used to decide whether it is safe to inject our clutter-hiding / sandbox
  /// CSS. On third-party "verify you are human" hosts (Cloudflare Turnstile,
  /// reCAPTCHA, hCaptcha, etc.) we must NOT inject that CSS, otherwise we hide
  /// the challenge widget and the verification can never complete.
  bool _isOnSiteDomain(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return false;
    return _isHostAllowed(uri.host);
  }

  /// Returns true when [url] is just the provider's own homepage / a generic
  /// landing path (no specific anime). We deliberately skip logging these so
  /// the history list reflects the actual anime being watched, not every tap
  /// on a provider card.
  bool _isGenericPage(String id, String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return true;
    final slug = id.split('::').last;
    const generic = {
      'home',
      'homepage',
      'index',
      'watch',
      'anime',
      'tv',
      'movies',
      'series',
      'browse',
      'latest',
      'popular',
      'trending',
    };
    if (generic.contains(slug.toLowerCase())) return true;
    // No path beyond the root (e.g. "https://anihq.cc/") is the bare homepage.
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return true;
    return false;
  }

  /// Returns true when [host] is the site itself or a known-good CDN host.
  bool _isHostAllowed(String host) {
    final h = host.toLowerCase();

    final domain = widget.site.domain.toLowerCase();
    if (domain.isNotEmpty && (h == domain || h.endsWith('.$domain'))) {
      return true;
    }

    for (final safe in widget.site.safeCdnDomains) {
      final s = safe.toLowerCase();
      if (h == s || h.endsWith('.$s')) return true;
    }
    for (final safe in globalSafeCdnDomains) {
      final s = safe.toLowerCase();
      if (h == s || h.endsWith('.$s')) return true;
    }
    return false;
  }

  /// Persists the current page as a resume point for the specific anime being
  /// watched (keyed by URL slug, so multiple animes on one site stay separate).
  ///
  /// Writes are throttled to once per [_kHistoryWriteInterval] so that a burst
  /// of SPA navigations / redirects doesn't hammer SharedPreferences. The very
  /// first call (no previous write) is always honored so an immediate exit
  /// still saves the page.
  ///
  /// When [force] is true, the throttle is bypassed. This is used during
  /// lifecycle events (dispose, backgrounding) to ensure the final state is
  /// never lost.
  void _recordHistory({bool force = false}) {
    if (_currentUrl.isEmpty) return;
    if (!_isOnSiteDomain(_currentUrl)) return;

    // 1. Parse the URL safely
    final uri = Uri.tryParse(_currentUrl);
    if (uri == null) return;

    // 2. Extract a clean Anime identifier (Slug)
    // Instead of just taking the absolute last path segment (which shifts from episode-1 to episode-2),
    // identify the base folder or clean the string to bind it to the series name.
    String baseSlug = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : widget.site.name;

    // Normalize out common episode designations so "naruto-episode-1" and "naruto-ep-2"
    // map to the same base show history record id.
    // Safer: Only strip if explicitly marked as an episode
    final episodeRegex = RegExp(
      r'[-_](?:ep|episode|ch|chapter)[-_]?\d+$',
      caseSensitive: false,
    );
    String showIdSlug = baseSlug.replaceAll(episodeRegex, '');
    if (showIdSlug.isEmpty) showIdSlug = baseSlug;

    // 3. Generate the stable key for HistoryController
    final id = animeHistoryId(widget.site.domain, showIdSlug);

    if (_isGenericPage(id, _currentUrl)) return;

    final now = DateTime.now();
    if (!force &&
        _lastHistoryWrite != null &&
        now.difference(_lastHistoryWrite!) < _kHistoryWriteInterval) {
      return;
    }
    _lastHistoryWrite = now;

    // 4. Resolve titles and write (The rest of your method remains unchanged)
    final existing = Get.find<HistoryController>().byId(id);
    final fallback = humanizeSlug(baseSlug);
    final title = _currentTitle.isNotEmpty
        ? _currentTitle
        : (existing?.title.isNotEmpty == true
              ? existing!.title
              : (fallback.isNotEmpty ? fallback : widget.site.name));

    // Capture everything needed so we can persist even after dispose.
    final entry = WatchHistoryEntry(
      id: id,
      domain: widget.site.domain,
      providerName: widget.site.name,
      title: title,
      url: _currentUrl,
      lastWatchedAt: DateTime.now().millisecondsSinceEpoch,
    );

    // While the widget is mounted we schedule a microtask so we never mutate the
    // history list (and trigger Obx rebuilds) while the framework's build/layout
    // phase is locked. Once disposed (back navigation / exit) we persist
    // synchronously - there is no build in progress, so it is safe and the final
    // state is not lost.
    if (mounted) {
      Future.microtask(() {
        Get.find<HistoryController>().record(entry);
      });
    } else {
      Get.find<HistoryController>().record(entry);
    }
  }

  /// ---------------------------------------------------------------------------
  /// CSS clutter-busting + "sandbox" hardening.
  ///
  /// The combined stylesheet hides every per-site + global clutter selector and
  /// also disables long-press text selection and tap callouts - the invisible
  /// overlays ad scripts use to capture the first tap anywhere on the viewport
  /// and spawn pop-ups. It is injected as early as possible (see [_injectScripts])
  /// so headers/ads are gone before first paint.
  /// ---------------------------------------------------------------------------
  Future<void> _onPageFinished(String url) async {
    // Keep the resume point in sync with the committed URL (e.g. after a
    // post-challenge redirect lands on the real episode page).
    _currentUrl = url;
    // On the site's own domain, grab the real page title for a nicer history
    // label (skip challenge/verification hosts). The title often contains the
    // anime + episode, e.g. "Naruto - Episode 3". Best-effort; failures are
    // ignored and the humanized URL slug remains the fallback.
    if (_isOnSiteDomain(url)) {
      // Capture the most descriptive title we can: prefer <title>, then the
      // first <h1>, then the document title. This gives us the anime name +
      // episode for the history label.
      try {
        final result = await _controller.runJavaScriptReturningResult(
          '(document.querySelector("title")?.textContent '
          '|| document.querySelector("h1")?.textContent '
          '|| document.title || "").toString()',
        );
        final raw = result.toString().trim();
        // Strip surrounding quotes some webviews wrap the returned string in.
        final trimmed = raw
            .replaceAll('"', '')
            .replaceAll("'", '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (trimmed.isNotEmpty) {
          _currentTitle = trimmed;
          _recordHistory();
        } else {
          _recordHistory();
        }
      } catch (_) {
        // If JS title fetch fails, fall back to URL slug with forced persist
        _recordHistory();
      }
    } else {
      // Not on site domain (challenge host, etc.) – persist without title
      _recordHistory();
    }
    // Same rule as onPageStarted: keep challenge/verification pages untouched
    // so the human-verification widget can complete. Once we are on the site's
    // own domain we hide the clutter and harden the sandbox.
    if (_isOnSiteDomain(url)) {
      try {
        await _injectScripts();
      } catch (_) {
        // Injection failure is non-fatal; page still works without clutter hiding
      }
    }
    // The document committed successfully: clear any transient error (so a
    // preload/resource hiccup never leaves the page stuck behind Retry) and
    // mark the page as loaded so later resource errors are ignored.
    setState(() {
      _isLoading = false;
      _hasError = false;
      _pageLoaded = true;
    });
  }

  /// Per-site + global clutter selectors combined with the sandbox-hardening
  /// rules, returned as a single stylesheet string.
  String get _clutterCss {
    final selectors = [...globalHideSelectors, ...widget.site.hideSelectors];
    final rules = selectors
        .map((s) => '$s{display:none !important;}')
        .join('\n');
    const sandbox = '''
*,*::before,*::after{
  -webkit-touch-callout:none !important;
  -webkit-user-select:none !important;
  user-select:none !important;
  -webkit-tap-highlight-color:transparent !important;
}''';
    return '$rules\n$sandbox';
  }

  /// Injects the clutter-busting CSS, the fullscreen listener and a viewport
  /// reset as early as the DOM allows. The style is applied the instant
  /// `document.documentElement` exists (before first paint), and a
  /// MutationObserver re-applies it if the site's own scripts try to remove it.
  /// This removes the flash of unstyled content (FOUC) where ads/headers blink
  /// onto screen for a moment before being hidden.
  Future<void> _injectScripts() async {
    final css = jsonEncode(_clutterCss);
    try {
      await _controller.runJavaScript('''
      (function(){
        if(window.__adCleanerActive) return;
        window.__adCleanerActive = true;
        
        function apply(){
          var id='animedives-cleaner-style';
          var style=document.getElementById(id);
          if(!style){
            style=document.createElement('style');
            style.id=id;
            (document.head||document.documentElement).appendChild(style);
          }
          style.innerHTML=$css;
          var meta=document.querySelector('meta[name="viewport"]');
          if(!meta){meta=document.createElement('meta');meta.name='viewport';document.head.appendChild(meta);}
          meta.content='width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=no';
        }
        
        function boot(){
          if(!document.documentElement){requestAnimationFrame(boot);return;}
          apply();
          new MutationObserver(function(m){
            for(var i=0;i<m.length;i++){
              var r=m[i].removedNodes;
              for(var j=0;j<r.length;j++){
                if(r[j]&&r[j].id==='animedives-cleaner-style'){apply();return;}
              }
            }
          }).observe(document.head,{childList:true});
          
          document.addEventListener('contextmenu',function(e){e.preventDefault();},true);
        }
        boot();
      })();
    ''');
    } catch (_) {
      // Injection failure is non-fatal; page still works without clutter hiding
    }
    try {
      await _injectFullscreenListener();
    } catch (_) {
      // Fullscreen listener injection failure is non-fatal
    }
  }

  /// Installs a listener that posts 'enter'/'exit' to the Dart side whenever the
  /// page toggles HTML5 fullscreen. This is how we drive native rotation since
  /// [webview_flutter] does not expose fullscreen callbacks of its own.
  Future<void> _injectFullscreenListener() async {
    await _controller.runJavaScript('''
(function() {
  if (window.__animedivesFsBound) return;
  window.__animedivesFsBound = true;
  function notify() {
    var fs = !!(document.fullscreenElement || document.webkitFullscreenElement);
    $_fullscreenChannel.postMessage(fs ? 'enter' : 'exit');
  }
  document.addEventListener('fullscreenchange', notify);
  document.addEventListener('webkitfullscreenchange', notify);
})();
''');
  }

  /// ---------------------------------------------------------------------------
  /// Native fullscreen handling.
  ///
  /// When the page requests HTML5 fullscreen (the video player goes fullscreen)
  /// the JS listener above posts 'enter', so we rotate to landscape and hide the
  /// system bars so the video truly fills the screen. When the player exits and
  /// posts 'exit', we restore portrait + the system UI.
  /// ---------------------------------------------------------------------------
  void _onFullscreenMessage(JavaScriptMessage message) {
    final entering = message.message == 'enter';
    // Ignore duplicate signals, and never start a new orientation/UI transition
    // while one is still in flight - overlapping SystemChrome calls on a slow
    // device can lock the app in landscape with hidden system bars.
    if (entering == _isFullscreen || _isTransitioningFullscreen) return;

    _isTransitioningFullscreen = true;
    if (mounted) setState(() => _isFullscreen = entering);
    final transition = entering ? _enterFullscreen() : _exitFullscreen();
    // Guard against the view being disposed mid-transition (e.g. user pops the
    // screen while the player crashes/exits). The flag must always reset.
    transition.whenComplete(() {
      if (mounted) setState(() => _isTransitioningFullscreen = false);
    });
  }

  Future<void> _enterFullscreen() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Keep the screen awake during long episodes (best-effort).
    await WakelockPlus.enable().catchError((_) {});
  }

  Future<void> _exitFullscreen() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await WakelockPlus.disable().catchError((_) {});
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _pageLoaded = false;
      _isLoading = true;
    });
    _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    // Intercept the system/gesture back button so it navigates the WebView's
    // own history (inner pages -> listing -> site home) instead of immediately
    // closing the whole screen. Only pop the Flutter route when the WebView has
    // no more history to go back to.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;

        // While in native fullscreen, an edge-swipe is a media-controller
        // gesture, not a navigation request. Tell the page to exit fullscreen
        // first; do NOT navigate the hidden web history (that would break
        // playback mid-stream).
        if (_isFullscreen) {
          await _controller.runJavaScript(
            'if(document.exitFullscreen){document.exitFullscreen();}'
            'else if(document.webkitExitFullscreen){document.webkitExitFullscreen();}',
          );
          return;
        }

        if (await _controller.canGoBack()) {
          await _controller.goBack();
        } else if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        // Keep one consistent widget-tree architecture in both modes. We never
        // swap the SafeArea parent in/out (that would change the element path
        // and let Flutter dispose/recreate the WebView, dumping the stream).
        // Instead we disable individual insets while in native fullscreen so the
        // notch/cutout doesn't push the video inward.
        body: SafeArea(
          left: !_isFullscreen,
          right: !_isFullscreen,
          top: !_isFullscreen,
          bottom: !_isFullscreen,
          child: _webViewStack(),
        ),
      ),
    );
  }

  /// The shared WebView + overlays stack. An explicit [ValueKey] anchors the
  /// native WebView identity across rebuilds (including fullscreen toggles) so
  /// the engine never recreates the view and resets the video stream.
  Widget _webViewStack() => Stack(
    key: const ValueKey('animedives_webview_stack'),
    children: [
      RepaintBoundary(
        child: WebViewWidget(controller: _controller),
      ),
      _loadingOverlay(),
      if (_hasError) _errorOverlay(),
    ],
  );

  /// Custom overlay spinner that fades out only when the page is fully loaded
  /// AND the cleaner CSS has been injected.
  Widget _loadingOverlay() {
    final scheme = Theme.of(context).colorScheme;
    final animedives = Theme.of(context).extension<AnimedivesColors>()!;
    return AnimatedOpacity(
      opacity: _isLoading ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: IgnorePointer(
        ignoring: !_isLoading,
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: kBrandBlue, strokeWidth: 3),
              const SizedBox(height: 18),
              Text(
                'Loading ${widget.site.name}...',
                style: TextStyle(
                  color: animedives.mutedForeground,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 160,
                child: LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress / 100,
                  color: kBrandAmber,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Error overlay shown on top of the (still-mounted) WebView when the network
  /// drops or the server returns an error. Rendered as an overlay rather than a
  /// replacement so the native WebView is never disposed (which would look like
  /// a disconnect).
  Widget _errorOverlay() {
    final scheme = Theme.of(context).colorScheme;
    final animedives = Theme.of(context).extension<AnimedivesColors>()!;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, color: kBrandAmber, size: 56),
              const SizedBox(height: 18),
              Text(
                'Connection failed',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Could not reach ${widget.site.domain}. Check your connection '
                'and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: animedives.mutedForeground,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrandAmber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
