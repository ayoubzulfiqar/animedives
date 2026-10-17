import 'dart:convert';

/// Data model describing a single streaming/anime website that the app can wrap
/// in an ad-shielded, full-screen capable WebView.
///
/// Everything the WebView needs to know about a site lives here so the UI and
/// controller logic stay decoupled from the data.
class AnimeSiteConfig {
  /// Human friendly label shown on the dashboard card.
  final String name;

  /// The page the WebView should open first (the site's real homepage).
  final String homepageUrl;

  /// Root domain used for the navigation shield. Any main-frame navigation to a
  /// host that is not this domain (or one of the safe CDN domains) is blocked.
  final String domain;

  /// Optional logo URL. When empty the UI renders a gradient placeholder.
  final String logoUrl;

  /// CSS selectors that should be forced to `display: none !important;` once the
  /// page finishes loading. Used to strip headers, footers, pop-ups and chats.
  final List<String> hideSelectors;

  /// Extra hosts (besides [domain]) that are always allowed to load. These are
  /// typically video CDNs / asset hosts the player depends on.
  final List<String> safeCdnDomains;

  /// Whether this provider targets adult / 18+ content. Drives the Anime/Hentai
  /// category filter in the home screen.
  final bool mature;

  const AnimeSiteConfig({
    required this.name,
    required this.homepageUrl,
    required this.domain,
    this.logoUrl = '',
    this.hideSelectors = const [],
    this.safeCdnDomains = const [],
    this.mature = false,
  });

  /// Extracts the bare host (domain) from a URL, e.g.
  /// `"https://www.animeparadise.moe/"` -> `"animeparadise.moe"`.
  static String domainFromUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri?.host ?? '';
  }

  /// Returns a reliable image URL for this provider's icon.
  /// If [logoUrl] is specified and is a standard web image (not a legacy .ico),
  /// [logoUrl] is used directly. If [logoUrl] is empty or is a Windows .ico
  /// format that native codecs cannot decode reliably, it resolves a crisp 128px
  /// PNG icon via Google's Favicon service.
  String get effectiveFaviconUrl {
    final trimmed = logoUrl.trim();
    final lower = trimmed.toLowerCase();
    if (trimmed.isNotEmpty &&
        !lower.endsWith('.ico') &&
        !lower.contains('.ico?')) {
      return trimmed;
    }
    final targetDomain = domain.isNotEmpty
        ? domain
        : domainFromUrl(homepageUrl);
    return 'https://www.google.com/s2/favicons?domain=$targetDomain&sz=128';
  }

  /// Builds the full stylesheet that hides every [hideSelectors] entry.
  /// Returns an empty string when there is nothing to hide.
  String get injectedCss {
    if (hideSelectors.isEmpty) return '';
    final buffer = StringBuffer();
    for (final selector in hideSelectors) {
      buffer.writeln('$selector{display:none !important;}');
    }
    return buffer.toString();
  }

  /// Convenience factory that derives [domain] automatically from the homepage.
  factory AnimeSiteConfig.auto({
    required String name,
    required String homepageUrl,
    String logoUrl = '',
    List<String> hideSelectors = const [],
    List<String> safeCdnDomains = const [],
    bool mature = false,
  }) {
    return AnimeSiteConfig(
      name: name,
      homepageUrl: homepageUrl,
      domain: domainFromUrl(homepageUrl),
      logoUrl: logoUrl,
      hideSelectors: hideSelectors,
      safeCdnDomains: safeCdnDomains,
      mature: mature,
    );
  }

  /// Serializes the config to JSON (used to persist custom user entries).
  Map<String, dynamic> toJson() => {
    'name': name,
    'homepageUrl': homepageUrl,
    'domain': domain,
    'logoUrl': logoUrl,
    'hideSelectors': hideSelectors,
    'safeCdnDomains': safeCdnDomains,
    'mature': mature,
  };

  /// De-serializes a config created with [toJson].
  factory AnimeSiteConfig.fromJson(
    Map<String, dynamic> json,
  ) => AnimeSiteConfig(
    name: json['name'] as String,
    homepageUrl: json['homepageUrl'] as String,
    domain: json['domain'] as String,
    logoUrl: json['logoUrl'] as String? ?? '',
    hideSelectors:
        (json['hideSelectors'] as List?)?.map((e) => e as String).toList() ??
        const [],
    safeCdnDomains:
        (json['safeCdnDomains'] as List?)?.map((e) => e as String).toList() ??
        const [],
    mature: json['mature'] as bool? ?? false,
  );

  /// Convenience: JSON string for SharedPreferences persistence.
  String toJsonString() => jsonEncode(toJson());

  /// Convenience: parse from a JSON string stored by [toJsonString].
  factory AnimeSiteConfig.fromJsonString(String raw) =>
      AnimeSiteConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  /// Safely embeds the injected CSS into a JavaScript source string.
  String get injectedCssJs => jsonEncode(injectedCss);
}

/// Generic clutter-busting selectors applied to *every* site on top of the
/// per-site [AnimeSiteConfig.hideSelectors]. These target the most common
/// header / footer / banner / chat containers found across anime streaming
/// layouts.
const List<String> globalHideSelectors = [
  'header',
  '#header',
  '.header',
  'footer',
  '#footer',
  '.footer',
  '[class*="banner" i]',
  '[id*="banner" i]',
  '[class*="popup" i]',
  '[id*="popup" i]',
  '[class*="modal" i]',
  '[class*="chat" i]',
  '[id*="chat" i]',
  '[class*="cookie" i]',
  '[id*="cookie" i]',
  '[class*="ads" i]',
  '[id*="ads" i]',
  '[class*="advert" i]',
];

/// Hosts that are globally considered safe to load (video CDNs, image hosts and
/// analytics endpoints that the players legitimately depend on). Sub-resources
/// served from these are never blocked by the navigation shield.
const List<String> globalSafeCdnDomains = [
  'googlevideo.com',
  'ytimg.com',
  'gstatic.com',
  'googleusercontent.com',
  'cloudfront.net',
  'akamaihd.net',
  'vimeocdn.com',
  'twimg.com',
  'jsdelivr.net',
  'unpkg.com',
  'fastly.net',
  // ---- Bot-protection / human-verification infrastructure ----
  // These MUST be reachable for Cloudflare Turnstile, reCAPTCHA and similar
  // "verify you are human" challenges to complete. If the navigation shield
  // blocks them the challenge silently reloads forever, so they are globally
  // allowed regardless of the current site.
  'cloudflare.com',
  'cloudflare.net',
  'cloudflareinsights.com',
  'cloudflarestream.com',
  'cf-assets.com',
  'turnstile.com',
  'recaptcha.net',
  'google.com',
  'gstatic.com',
  'hcaptcha.com',
  'arkoselabs.com',
  'funcaptcha.com',
  'perimeterx.net',
  'incapsula.com',
];

/// Three example template configs demonstrating how to target the most common
/// video-site layouts: a generic streaming portal, a header/footer heavy
/// layout and a chat/popup heavy layout. These show the expected shape and can
/// be copied when adding new providers.
const List<AnimeSiteConfig> templateSites = [
  // 1) Generic streaming portal - hides the standard header/footer/hero ad.
  AnimeSiteConfig(
    name: 'Template: Stream Portal',
    homepageUrl: 'https://example-stream.one/home',
    domain: 'example-stream.one',
    hideSelectors: ['.site-header', '.site-footer', '#top-ad', '.promo-banner'],
    safeCdnDomains: ['cdn.example-stream.one'],
  ),

  // 2) Header/footer heavy layout - big nav bar + sticky footer widget.
  AnimeSiteConfig(
    name: 'Template: Heavy Nav',
    homepageUrl: 'https://example-anime.cc/',
    domain: 'example-anime.cc',
    hideSelectors: [
      'nav.navbar',
      '.bottom-bar',
      '.sidebar-ads',
      '.newsletter-popup',
    ],
    safeCdnDomains: ['static.example-anime.cc'],
  ),

  // 3) Live-chat / popup heavy layout - kills the chat dock and modals.
  AnimeSiteConfig(
    name: 'Template: Chat Heavy',
    homepageUrl: 'https://example-watch.moe/',
    domain: 'example-watch.moe',
    hideSelectors: [
      '#live-chat',
      '.chat-dock',
      '.modal-overlay',
      '.age-gate',
      '.interstitial',
    ],
    safeCdnDomains: ['videos.example-watch.moe', 'cdn.example-watch.moe'],
  ),
];

/// Checks whether [host] is permitted by [site]'s domain, safe CDN domains, or global CDN domains.
/// Normalizes domains to handle both naked and www. domains as well as all subdomains.
bool isHostAllowed(String host, AnimeSiteConfig site) {
  if (host.isEmpty) return false;
  final h = host.trim().toLowerCase().replaceFirst(RegExp(r'^www\.'), '');

  final d = site.domain.trim().toLowerCase().replaceFirst(
    RegExp(r'^www\.'),
    '',
  );
  if (d.isNotEmpty && (h == d || h.endsWith('.$d'))) {
    return true;
  }

  for (final safe in site.safeCdnDomains) {
    final s = safe.trim().toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    if (s.isNotEmpty && (h == s || h.endsWith('.$s'))) {
      return true;
    }
  }

  for (final safe in globalSafeCdnDomains) {
    final s = safe.trim().toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    if (s.isNotEmpty && (h == s || h.endsWith('.$s'))) {
      return true;
    }
  }

  return false;
}

/// Builds the clutter-busting and sandbox-hardening stylesheet for [site].
/// Exempts form inputs, textareas, and contenteditable elements from the touch-callout
/// and selection freeze so users can type into search bars, episode boxes, and forms.
String buildClutterCss(AnimeSiteConfig site) {
  final selectors = [...globalHideSelectors, ...site.hideSelectors];
  final rules = selectors.map((s) => '$s{display:none !important;}').join('\n');
  const sandbox = '''
*:not(input):not(textarea):not([contenteditable="true"]) {
  -webkit-touch-callout: none !important;
  -webkit-user-select: none !important;
  user-select: none !important;
  -webkit-tap-highlight-color: transparent !important;
}
input, textarea, [contenteditable="true"] {
  -webkit-user-select: auto !important;
  user-select: auto !important;
}''';
  return '$rules\n$sandbox';
}
