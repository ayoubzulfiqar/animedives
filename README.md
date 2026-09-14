# 🌊 AnimeDives

[![Website](https://img.shields.io/badge/Website-animedives.com-00E5FF?style=for-the-badge&logo=googlechrome&logoColor=white)](https://animedives.com/)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)
[![CI](https://github.com/ayoubzulfiqar/animedives/actions/workflows/flutter.yml/badge.svg)](https://github.com/ayoubzulfiqar/animedives/actions/workflows/flutter.yml)

> **An Anime Watching App That Just Works.**  
> Install the app, select a provider, and start watching. No hassle, no bloat.

AnimeDives is a sleek, high-performance media aggregation app designed to provide
a seamless anime streaming experience. By wrapping carefully vetted third-party
providers with a custom, ad-shielded WebView engine, AnimeDives delivers a
native-like experience with smart history tracking, immersive fullscreen
playback, and robust anti-bot bypass capabilities.

---

## ✨ Key Features

- 🛡️ **Built-in Ad & Pop-up Shield**: Aggressively blocks redirect ads, tracking
  domains, and intrusive pop-unders via a custom navigation delegate and DOM
  injection.
- 📜 **Smart Watch History**: Automatically saves your deepest resume point per
  series. Intelligently ignores generic homepage navigations to keep your
  history clean. Episodes of the same series are grouped together.
- 📱 **Seamless Native Fullscreen**: Detects HTML5 fullscreen events and
  instantly triggers native landscape rotation and immersive system UI hiding.
- ⚡ **Optimized Performance**: Utilizes Hybrid Composition, throttled state
  updates, and `RepaintBoundary` isolation for buttery-smooth scrolling and fast
  load times.
- 🤖 **Cloudflare & Challenge Ready**: Features smart mobile User-Agent
  spoofing and deferred CSS injection, ensuring human-verification widgets
  (Turnstile/reCAPTCHA) render perfectly without being hidden by ad-blockers.
- 🎨 **Premium UI/UX**: Built with a modern glassmorphism design, custom brand
  gradients, AMOLED-ready dark mode, and smooth animated overlays.
- 💾 **Persistent Custom Sites**: Add your own providers and they persist across
  app restarts.
- 🏗️ **CI/CD**: Automated APK and App Bundle builds on every release via
  GitHub Actions.

---

## 🌐 Supported Providers (95+ sites)

AnimeDives supports a wide range of streaming providers. _(Note: Provider
availability is subject to change based on third-party domain rotations)._

### 🎌 General Anime

**Pre-configured (with tuned ad-shield selectors):**
- animex.one, animeparadise.moe, anihq.cc, animeya.cc, animekizz.live,
  aniwaves.ru, animepahe.pw, reanime.to, animesalt.link, anichi.to,
  anikage.cc, animesuge.cz, animexin.dev, anizone.to, anidb.app, anikoto.cz,
  animenosub.to

**Auto-configured (using global selectors):**
- anikototv.to, miruro.to, mkissa.to, senshi.to, anime.uniquestream.net,
  kaa.lt, anime.nexus, bilibili.tv, youtube.com, anineko.to, anibd.app,
  animeonsen.xyz, anify.to, anisnatch.to, animeheaven.me, lunarx.to, ani.pm,
  anidap.lol, just4anime.online, anistream.one, animegg.org, xanime.me,
  2dhive.com, aniworld.to, anichan.net, animotvslash.org, hidive.com,
  anikuro.ru, bettermelon.ru, kisskh.co, hianimes.se, animekai.ro, fireani.me,
  anime-loads.org, wcostream.tv, kimoitv.com, otaku-streamers.com,
  av1please.com, kuroanime.lol, 4animo.xyz, anilight.live, meguanime.com,
  otakutsu.cc, justanime.to, luna-stream.me, anixo.online, animeyubi.com,
  kazora.cc, yumezone.live, itachi.tv, kaorii.app, luffytv.live, kyren.moe,
  animelok.live, pimpanime.nl, zenkai.to, aniwatchtv.com.ro, oceanveil.net,
  retrocrush.tv, yomi.to, animesilo.cc, nekowatch.xyz, watchanimez.me,
  aniclipse.com, anikura.club, animetvplus.xyz, onianime.eu, animegers.com,
  animedex.fun, last1234.fun, kawaii-anime.com, streamex.sh, sankanime.web.id,
  aniwave.com.se, ramenflix.com, hulu.com, enma.lol, anime-dunya.com,
  animixplay.fun, watchanimeworld.one, animedekho.app

### 🔞 Mature / 18+ Content

_⚠️ The following providers contain adult content. Viewer discretion is advised._

- rule34video.com, hentai.tv, hentaicity.com, underhentai.net, oppai.stream,
  hentai-moon.com

---

## 🚀 Getting Started

### For Users

1. Visit our official website: [animedives.com](https://animedives.com/)
2. Download the latest release for your platform (Android / iOS).
3. Install the application and grant necessary permissions (e.g., screen
   rotation, storage for caching).
4. Select your preferred provider from the dashboard and start watching!

### For Developers

```bash
git clone https://github.com/ayoubzulfiqar/animedives.git
cd animedives
flutter pub get
flutter run
```

### Requirements

- [Flutter](https://docs.flutter.dev/get-started/install) 3.13+ (stable channel)
- Android SDK 34+ (for Android builds)
- Java JDK 17+

### Testing

```bash
flutter analyze
flutter test
```

### Adding a New Provider

1. Add the provider's URL to the `_allSites` table in [`lib/provider.dart`](lib/provider.dart)
2. Each entry uses the `_SiteRow` record: name, homepageUrl, logoUrl,
   safeCdnDomains, optional hideSelectors, and `mature` flag
3. Pre-configured sites with custom selectors can include a `hideSelectors` list;
   otherwise the global selectors in [`lib/models/site_config.dart`](lib/models/site_config.dart)
   are used
4. Update the README's supported providers list

---

## 📦 Builds

GitHub Actions automatically builds APK and App Bundle binaries on every
release. See the [releases
page](https://github.com/ayoubzulfiqar/animedives/releases) for the latest
binaries.

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for more
information.

Copyright (c) 2026 **Ayoub Zulfiqar** — [ayoubzulfiqar.com](https://ayoubzulfiqar.com)
