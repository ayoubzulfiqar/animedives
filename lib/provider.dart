import 'models/site_config.dart';

/// Raw provider URLs contributed for this build. Kept as plain constants so they
/// are easy to edit; the [defaultSites] list below turns them into fully
/// configured [AnimeSiteConfig] objects.
const String animeXUrl = "https://animex.one/home";
const String animeParadiseMoeUrl = "https://www.animeparadise.moe/";
const String aniHQUrl = "https://anihq.cc/home/";
const String animeyaUrl = "https://animeya.cc/home";
const String animeKizzUrl = "https://animekizz.live/";
const String animeWaveUrl = "https://aniwaves.ru/";
const String animePahe = "https://animepahe.pw/";
const String reanime = "https://reanime.to/home";

const String animeSalt = "https://animesalt.link/";
const String aniChi = "https://anichi.to/";
const String aniKage = "https://anikage.cc/";
const String aniSuge = "https://animesuge.cz/";
const String animeXin = "https://animexin.dev/";
const String aniZone = "https://anizone.to/";
const String aniDB = "https://anidb.app/home";
const String aniKoto = "https://anikoto.cz/home";
const String animeNoSub = "https://animenosub.to/";

// ----------

const String rule34Video = "https://rule34video.com/";
const String hentaiTV = "https://hentai.tv/";
const String hentaiCity = "https://www.hentaicity.com/";
const String underHentai = "https://www.underhentai.net/";
const String oppaiStream = "https://oppai.stream/";
const String hentaiMoon = "https://hentai-moon.com/discover/";

// --------

/// The default set of streaming providers shipped with the app. Each entry is an
/// [AnimeSiteConfig] so the WebView knows the domain to shield against, the CSS
/// selectors to strip and any extra CDN hosts the player needs.
final List<AnimeSiteConfig> defaultSites = [
  AnimeSiteConfig(
    name: 'AnimeX',
    homepageUrl: animeXUrl,
    domain: AnimeSiteConfig.domainFromUrl(animeXUrl),
    logoUrl: 'https://animex.one/_app/immutable/assets/favicon.CdbYna26.png',
    hideSelectors: [
      'header',
      '.site-header',
      '#header',
      'footer',
      '.site-footer',
      '#footer',
      '.home-popup',
      '.promo-banner',
      '[class*="chat" i]',
    ],
    safeCdnDomains: ['cdn.animex.one', 'img.animex.one'],
  ),
  AnimeSiteConfig(
    name: 'AnimeParadise',
    homepageUrl: animeParadiseMoeUrl,
    domain: AnimeSiteConfig.domainFromUrl(animeParadiseMoeUrl),
    logoUrl: 'https://www.animeparadise.moe/icon/apple-touch-icon.png',
    hideSelectors: [
      'nav',
      '.navbar',
      '.site-footer',
      '.ads-section',
      '.newsletter-modal',
      '.popup-overlay',
    ],
    safeCdnDomains: ['cdn.animeparadise.moe', 'static.animeparadise.moe'],
  ),
  AnimeSiteConfig(
    name: 'AniHQ',
    homepageUrl: aniHQUrl,
    domain: AnimeSiteConfig.domainFromUrl(aniHQUrl),
    logoUrl: 'https://anihq.cc/apple-touch-icon.png',
    hideSelectors: [
      '.top-bar',
      '.header-wrap',
      '.footer-wrap',
      '.sidebar-ads',
      '#live-chat',
      '.interstitial',
    ],
    safeCdnDomains: ['vid.anihq.cc', 'cdn.anihq.cc'],
  ),
  AnimeSiteConfig(
    name: 'Animeya',
    homepageUrl: animeyaUrl,
    domain: AnimeSiteConfig.domainFromUrl(animeyaUrl),
    logoUrl: 'https://animeya.cc/apple-icon.png',
    hideSelectors: [
      'header',
      '.main-header',
      'footer',
      '.main-footer',
      '.ad-container',
      '.cookie-notice',
      '.chat-dock',
    ],
    safeCdnDomains: ['media.animeya.cc', 'edge.animeya.cc'],
  ),
  AnimeSiteConfig(
    name: 'AnimeKizz',
    homepageUrl: animeKizzUrl,
    domain: AnimeSiteConfig.domainFromUrl(animeKizzUrl),
    logoUrl: 'https://animekizz.live/logo.ico',
    hideSelectors: [
      '.site-nav',
      '.site-foot',
      '.popunder',
      '.banner-ad',
      '.age-gate',
      '.modal',
    ],
    safeCdnDomains: ['stream.animekizz.live', 'cdn.animekizz.live'],
  ),
  AnimeSiteConfig(
    name: 'AniWave',
    homepageUrl: animeWaveUrl,
    domain: AnimeSiteConfig.domainFromUrl(animeWaveUrl),
    logoUrl: 'https://aniwaves.ru/assets/images/favicons/apple-touch-icon.png',
    hideSelectors: [
      'header',
      '.header',
      'footer',
      '.footer',
      '.ad-banner',
      '.popup',
      '.chat-box',
    ],
    safeCdnDomains: ['video.aniwave.com.se', 'cdn.aniwave.com.se'],
  ),
  AnimeSiteConfig(
    name: 'AnimePahe',
    homepageUrl: animePahe,
    domain: AnimeSiteConfig.domainFromUrl(animePahe),
    logoUrl: 'https://animepahe.ch/wp-content/uploads/2026/04/favicon.png',
    hideSelectors: [
      '.header',
      '#header',
      '.footer',
      '#footer',
      '.navbar',
      '.ads',
      '.popup',
      '.modal',
    ],
    safeCdnDomains: ['cdn.animepahe.pw', 'img.animepahe.pw', 's4.animepahe.pw'],
  ),
  AnimeSiteConfig(
    name: 'ReAnime',
    homepageUrl: reanime,
    domain: AnimeSiteConfig.domainFromUrl(reanime),
    logoUrl: 'https://reanime.to/apple-touch-icon.png',
    hideSelectors: [
      'header',
      '.site-header',
      'footer',
      '.site-footer',
      '.promo-banner',
      '.popup',
      '.chat-dock',
    ],
    safeCdnDomains: ['cdn.reanime.to', 'img.reanime.to', 'stream.reanime.to'],
  ),

  AnimeSiteConfig(
    name: 'AnimeSalt',
    homepageUrl: animeSalt,
    domain: AnimeSiteConfig.domainFromUrl(animeSalt),
    logoUrl: 'https://animesalt.link/favicon.ico',
    hideSelectors: [
      'header',
      '.site-header',
      'footer',
      '.site-footer',
      '.popup',
      '.modal',
      '[class*="chat" i]',
    ],
    safeCdnDomains: ['cdn.animesalt.link', 'static.animesalt.link'],
  ),
  AnimeSiteConfig(
    name: 'AniChi',
    homepageUrl: aniChi,
    domain: AnimeSiteConfig.domainFromUrl(aniChi),
    logoUrl: 'https://anichi.to/anichi/images/favicon.png?v=1',
    hideSelectors: [
      'header',
      '.header',
      'footer',
      '.footer',
      '.popup-overlay',
      '.modal',
      '[class*="chat" i]',
    ],
    safeCdnDomains: ['cdn.anichi.to', 'static.anichi.to'],
  ),
  AnimeSiteConfig(
    name: 'AniKage',
    homepageUrl: aniKage,
    domain: AnimeSiteConfig.domainFromUrl(aniKage),
    logoUrl: 'https://anikage.cc/favicon.ico',
    hideSelectors: [
      '.site-nav',
      '.site-foot',
      '.popunder',
      '.banner-ad',
      '.modal',
      '[class*="chat" i]',
    ],
    safeCdnDomains: ['cdn.anikage.cc', 'stream.anikage.cc'],
  ),
  AnimeSiteConfig(
    name: 'AniSuge',
    homepageUrl: aniSuge,
    domain: AnimeSiteConfig.domainFromUrl(aniSuge),
    logoUrl: 'https://animesuge.cz/favicon.ico',
    hideSelectors: [
      'header',
      '.site-header',
      'footer',
      '.site-footer',
      '.popup',
      '.modal',
      '[class*="chat" i]',
    ],
    safeCdnDomains: ['cdn.animesuge.cz', 'static.animesuge.cz'],
  ),
  AnimeSiteConfig(
    name: 'AnimeXin',
    homepageUrl: animeXin,
    domain: AnimeSiteConfig.domainFromUrl(animeXin),
    logoUrl:
        'https://animexin.dev/wp-content/uploads/2026/01/cropped-New-Logo-e1768365053967-192x192.png',
    hideSelectors: [
      '.site-header',
      '#header',
      '.site-footer',
      '#footer',
      '.popup',
      '.modal',
      '[class*="chat" i]',
    ],
    safeCdnDomains: ['cdn.animexin.dev', 'static.animexin.dev'],
  ),
  AnimeSiteConfig(
    name: 'AniZone',
    homepageUrl: aniZone,
    domain: AnimeSiteConfig.domainFromUrl(aniZone),
    logoUrl: 'https://anizone.to/apple-touch-icon.png',
    hideSelectors: [
      'header',
      '.header',
      'footer',
      '.footer',
      '.popup-overlay',
      '.modal',
      '[class*="chat" i]',
    ],
    safeCdnDomains: ['cdn.anizone.to', 'static.anizone.to'],
  ),
  AnimeSiteConfig(
    name: 'AniDB',
    homepageUrl: aniDB,
    domain: AnimeSiteConfig.domainFromUrl(aniDB),
    logoUrl: 'https://anidb.app/favicon.ico',
    hideSelectors: [
      '.site-header',
      '#header',
      '.site-footer',
      '#footer',
      '.popup',
      '.modal',
      '[class*="chat" i]',
    ],
    safeCdnDomains: ['cdn.anidb.app', 'static.anidb.app'],
  ),
  AnimeSiteConfig(
    name: 'AniKoto',
    homepageUrl: aniKoto,
    domain: AnimeSiteConfig.domainFromUrl(aniKoto),
    logoUrl: 'https://anikoto.cz/favicon.ico',
    hideSelectors: [
      'header',
      '.site-header',
      'footer',
      '.site-footer',
      '.popup',
      '.modal',
      '[class*="chat" i]',
    ],
    safeCdnDomains: ['cdn.anikoto.cz', 'static.anikoto.cz'],
  ),
  AnimeSiteConfig(
    name: 'AnimeNoSub',
    homepageUrl: animeNoSub,
    domain: AnimeSiteConfig.domainFromUrl(animeNoSub),
    logoUrl:
        'https://i3.wp.com/animenosub.to/wp-content/uploads/2024/04/cropped-favicon-192x192.png',
    hideSelectors: [
      'header',
      '.header',
      'footer',
      '.footer',
      '.popup-overlay',
      '.modal',
      '[class*="chat" i]',
    ],
    safeCdnDomains: ['cdn.animenosub.to', 'static.animenosub.to'],
  ),
  AnimeSiteConfig(
    name: 'Rule34Video',
    homepageUrl: rule34Video,
    domain: AnimeSiteConfig.domainFromUrl(rule34Video),
    logoUrl: 'https://rule34video.com/apple-touch-icon.png',
    hideSelectors: [
      '.site-header',
      '#header',
      '.site-footer',
      '#footer',
      '.banner',
      '.popup',
      '.modal',
    ],
    safeCdnDomains: ['cdn.rule34video.com', 'img.rule34video.com'],
  ),
  AnimeSiteConfig(
    name: 'HentaiTV',
    homepageUrl: hentaiTV,
    domain: AnimeSiteConfig.domainFromUrl(hentaiTV),
    logoUrl: 'https://hentai.tv/apple-icon.png?apple-icon.0c08tjjgl86o0.png',
    hideSelectors: [
      'header',
      '.header',
      'footer',
      '.footer',
      '.nav',
      '.ad-placeholder',
      '.popup',
    ],
    safeCdnDomains: ['cdn.hentai.tv', 'img.hentai.tv', 'stream.hentai.tv'],
  ),
  AnimeSiteConfig(
    name: 'HentaiCity',
    homepageUrl: hentaiCity,
    domain: AnimeSiteConfig.domainFromUrl(hentaiCity),
    logoUrl: 'https://www.hentaicity.com/apple-touch-icon.png',
    hideSelectors: [
      '.header',
      '#header',
      '.footer',
      '#footer',
      '.navbar',
      '.ads',
      '.popup-overlay',
    ],
    safeCdnDomains: ['cdn.hentaicity.com', 'static.hentaicity.com'],
  ),
  AnimeSiteConfig(
    name: 'UnderHentai',
    homepageUrl: underHentai,
    domain: AnimeSiteConfig.domainFromUrl(underHentai),
    logoUrl:
        'https://static.underhentai.net/themes/undernet-bs3/icons/xapple-touch-icon.png.pagespeed.ic.EqN0jX-NzE.webp',
    hideSelectors: [
      '.site-header',
      '#header',
      '.site-footer',
      '#footer',
      '.top-bar',
      '.popup',
      '.modal',
    ],
    safeCdnDomains: ['cdn.underhentai.net', 'img.underhentai.net'],
  ),
  AnimeSiteConfig(
    name: 'OppaiStream',
    homepageUrl: oppaiStream,
    domain: AnimeSiteConfig.domainFromUrl(oppaiStream),
    logoUrl: 'https://oppai.stream/assets/logo/apple-touch-icon.png',
    hideSelectors: [
      'header',
      '.header',
      'footer',
      '.footer',
      '.nav-wrap',
      '.banner-ad',
      '.popup',
    ],
    safeCdnDomains: ['cdn.oppai.stream', 'media.oppai.stream'],
  ),
  AnimeSiteConfig(
    name: 'HentaiMoon',
    homepageUrl: hentaiMoon,
    domain: AnimeSiteConfig.domainFromUrl(hentaiMoon),
    logoUrl: 'https://hentai-moon.com/favicon.ico',
    hideSelectors: [
      '.site-header',
      '#header',
      '.site-footer',
      '#footer',
      '.discover-ad',
      '.popup',
      '.modal',
    ],
    safeCdnDomains: ['cdn.hentai-moon.com', 'img.hentai-moon.com'],
  ),
];

