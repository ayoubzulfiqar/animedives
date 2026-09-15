# 🌊 AnimeDives

[![Website](https://img.shields.io/badge/Website-animedives.com-00E5FF?style=for-the-badge&logo=googlechrome&logoColor=white)](https://animedives.com/)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)
[![CI](https://github.com/ayoubzulfiqar/animedives/actions/workflows/flutter.yml/badge.svg)](https://github.com/ayoubzulfiqar/animedives/actions/workflows/flutter.yml)
[![Release](https://img.shields.io/github/v/release/ayoubzulfiqar/animedives?style=for-the-badge&label=Release)](https://github.com/ayoubzulfiqar/animedives/releases)

> **An Anime Watching App That Just Works.**
> Install the app, select a provider, and start watching. No hassle, no bloat.

AnimeDives is a sleek, high-performance media aggregation app designed to provide a
seamless anime streaming experience. By wrapping carefully vetted third-party
providers with a custom, ad-shielded WebView engine, AnimeDives delivers a
native-like experience with smart history tracking, immersive fullscreen
playback, and robust anti-bot bypass capabilities.

---

## ✨ Key Features

| Icon | Feature | Description |
|------|---------|-------------|
| 🛡️ | **Ad & Pop-up Shield** | Aggressively blocks redirect ads, tracking domains, and intrusive pop-unders via a custom navigation delegate and DOM injection. |
| 📜 | **Smart Watch History** | Automatically saves your deepest resume point per series. Intelligently ignores generic homepage navigations. Episodes of the same series are grouped together. |
| 📱 | **Native Fullscreen** | Detects HTML5 fullscreen events and instantly triggers native landscape rotation and immersive system UI hiding. |
| ⚡ | **Optimized Performance** | Hybrid Composition, throttled state updates, and `RepaintBoundary` isolation for buttery-smooth scrolling. |
| 🤖 | **Cloudflare & Challenge Ready** | Smart mobile User-Agent spoofing and deferred CSS injection ensure human-verification widgets render correctly. |
| 🎨 | **Premium UI/UX** | Glassmorphism design, AMOLED-ready dark mode, smooth animated overlays. |
| 💾 | **Persistent Custom Sites** | Add your own providers and they persist across app restarts. |
| 🌐 | **95+ Providers** | Huge library of pre-configured and auto-configured anime streaming sites. |

---

## 🌐 Supported Providers

AnimeDives supports a wide range of streaming providers. _Provider availability is
subject to change based on third-party domain rotations._

### Pre-configured (tuned ad-shield selectors)

These sites have hand-tuned `hideSelectors` and `safeCdnDomains` for optimal ad
blocking and video playback.

| # | Name | Domain |
|---|------|--------|
| 1 | AnimeX | [animex.one](https://animex.one/home) |
| 2 | AnimeParadise | [animeparadise.moe](https://www.animeparadise.moe/) |
| 3 | AniHQ | [anihq.cc](https://anihq.cc/home/) |
| 4 | Animeya | [animeya.cc](https://animeya.cc/home) |
| 5 | AnimeKizz | [animekizz.live](https://animekizz.live/) |
| 6 | AniWave | [aniwaves.ru](https://aniwaves.ru/) |
| 7 | AnimePahe | [animepahe.pw](https://animepahe.pw/) |
| 8 | ReAnime | [reanime.to](https://reanime.to/home) |
| 9 | AnimeSalt | [animesalt.link](https://animesalt.link/) |
| 10 | AniChi | [anichi.to](https://anichi.to/) |
| 11 | AniKage | [anikage.cc](https://anikage.cc/) |
| 12 | AniSuge | [animesuge.cz](https://animesuge.cz/) |
| 13 | AnimeXin | [animexin.dev](https://animexin.dev/) |
| 14 | AniZone | [anizone.to](https://anizone.to/) |
| 15 | AniDB | [anidb.app](https://anidb.app/home) |
| 16 | AniKoto | [anikoto.cz](https://anikoto.cz/home) |
| 17 | AnimeNoSub | [animenosub.to](https://animenosub.to/) |

### Auto-configured (global selectors)

These sites use the built-in global ad-shield selectors. They are automatically
configured and ready to use.

| # | Name | Domain |
|---|------|--------|
| 1 | AniKotoTV | [anikototv.to](https://anikototv.to/home) |
| 2 | Miruro | [miruro.to](https://www.miruro.to/) |
| 3 | Mkissa | [mkissa.to](https://mkissa.to/anime) |
| 4 | Senshi | [senshi.to](https://senshi.to/) |
| 5 | AnimeUniqueStream | [anime.uniquestream.net](https://anime.uniquestream.net/) |
| 6 | KAA | [kaa.lt](https://kaa.lt/) |
| 7 | AnimeNexus | [anime.nexus](https://anime.nexus/) |
| 8 | Bilibili | [bilibili.tv](https://www.bilibili.tv/en/anime) |
| 9 | YouTube | [youtube.com](https://youtube.com/) |
| 10 | AniNeo | [anineko.to](https://anineko.to/) |
| 11 | AniBD | [anibd.app](https://anibd.app/) |
| 12 | AnimeOnsen | [animeonsen.xyz](https://www.animeonsen.xyz/) |
| 13 | AniFy | [anify.to](https://anify.to/) |
| 14 | AniSquawk | [anisnatch.to](https://anisnatch.to/home) |
| 15 | AnimeHeaven | [animeheaven.me](https://animeheaven.me/) |
| 16 | LunarX | [lunarx.to](https://lunarx.to/anime) |
| 17 | AniPM | [ani.pm](https://ani.pm/) |
| 18 | AniDap | [anidap.lol](https://anidap.lol/home) |
| 19 | Just4Ani | [just4anime.online](https://just4anime.online/) |
| 20 | AniStream | [anistream.one](https://anistream.one/home) |
| 21 | AnimeGG | [animegg.org](https://www.animegg.org/) |
| 22 | XAnime | [xanime.me](https://xanime.me/) |
| 23 | 2DHive | [2dhive.com](https://2dhive.com/) |
| 24 | AniWorld | [aniworld.to](https://aniworld.to/) |
| 25 | AniChan | [anichan.net](https://anichan.net/) |
| 26 | AnimeTVSlash | [animotvslash.org](https://www.animotvslash.org/) |
| 27 | HiDive | [hidive.com](https://www.hidive.com/) |
| 28 | AniKuro | [anikuro.ru](https://anikuro.ru/) |
| 29 | BetterMelon | [bettermelon.ru](https://bettermelon.ru/) |
| 30 | KissKH | [kisskh.co](https://kisskh.co/) |
| 31 | HiAnimes | [hianimes.se](https://hianimes.se/home) |
| 32 | AniKaio | [animekai.ro](https://animekai.ro/) |
| 33 | FireAni | [fireani.me](https://fireani.me/) |
| 34 | AnimeLoads | [anime-loads.org](https://www.anime-loads.org/) |
| 35 | WcoStream | [wcostream.tv](https://www.wcostream.tv/) |
| 36 | KimoITV | [kimoitv.com](https://kimoitv.com/) |
| 37 | OtakuStreamers | [otaku-streamers.com](https://otaku-streamers.com/) |
| 38 | AV1Please | [av1please.com](https://av1please.com/) |
| 39 | KuroAni | [kuroanime.lol](https://kuroanime.lol/) |
| 40 | 4AniMo | [4animo.xyz](https://4animo.xyz/home) |
| 41 | AniLight | [anilight.live](https://anilight.live/) |
| 42 | MegaAni | [meguanime.com](https://meguanime.com/) |
| 43 | Otakutsu | [otakutsu.cc](https://otakutsu.cc/) |
| 44 | JustAni | [justanime.to](https://www.justanime.to/) |
| 45 | LunaStream | [luna-stream.me](https://luna-stream.me/) |
| 46 | AniXo | [anixo.online](https://anixo.online/) |
| 47 | AniYubi | [animeyubi.com](https://animeyubi.com/) |
| 48 | Kazora | [kazora.cc](https://kazora.cc/) |
| 49 | YumeZone | [yumezone.live](https://yumezone.live/) |
| 50 | Itachi | [itachi.tv](https://itachi.tv/) |
| 51 | Kaorii | [kaorii.app](https://kaorii.app/) |
| 52 | LuffyTV | [luffytv.live](https://luffytv.live/) |
| 53 | Kyren | [kyren.moe](https://kyren.moe/) |
| 54 | AniTok | [animelok.live](https://animelok.live/) |
| 55 | PimpAni | [pimpanime.nl](https://pimpanime.nl/) |
| 56 | Zenkai | [zenkai.to](https://zenkai.to/home) |
| 57 | AniWatchTV | [aniwatchtv.com.ro](https://aniwatchtv.com.ro/) |
| 58 | OceanVeil | [oceanveil.net](https://oceanveil.net/) |
| 59 | RetroCrush | [retrocrush.tv](https://www.retrocrush.tv/) |
| 60 | Yomi | [yomi.to](https://yomi.to/) |
| 61 | AniSil | [animesilo.cc](https://animesilo.cc/anime) |
| 62 | NekoWatch | [nekowatch.xyz](https://nekowatch.xyz/) |
| 63 | WatchAniZ | [watchanimez.me](https://watchanimez.me/) |
| 64 | AniClipse | [aniclipse.com](https://aniclipse.com/) |
| 65 | AniKura | [anikura.club](https://anikura.club/) |
| 66 | AniTVPlus | [animetvplus.xyz](https://animetvplus.xyz/) |
| 67 | OniAni | [onianime.eu](https://onianime.eu/home) |
| 68 | AniGers | [animegers.com](https://animegers.com/) |
| 69 | AniDex | [animedex.fun](https://animedex.fun/) |
| 70 | Last1234 | [last1234.fun](https://last1234.fun/) |
| 71 | KawaiiAni | [kawaii-anime.com](https://kawaii-anime.com/) |
| 72 | StreamEx | [streamex.sh](https://streamex.sh/anime) |
| 73 | SanAni | [sankanime.web.id](https://sankanime.web.id/) |
| 74 | AniWaveSE | [aniwave.com.se](https://aniwave.com.se/) |
| 75 | RamenFlix | [ramenflix.com](https://ramenflix.com/home) |
| 76 | Hulu | [hulu.com](https://www.hulu.com/hub/anime) |
| 77 | Enma | [enma.lol](https://www.enma.lol/) |
| 78 | AnimeDunya | [anime-dunya.com](https://anime-dunya.com/) |
| 79 | AniMixPlay | [animixplay.fun](https://animixplay.fun/) |
| 80 | WatchAniWorld | [watchanimeworld.one](https://watchanimeworld.one/) |
| 81 | AniDekho | [animedekho.app](https://animedekho.app/home) |

---

## 🚀 Getting Started

### For Users

1. Visit our official website: [animedives.com](https://animedives.com/)
2. Download the latest release for your platform:
   - **Android**: APK + AAB available via GitHub Actions artifacts
3. Install the APK or AAB and grant necessary permissions (e.g., screen rotation, storage for caching).
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

1. Add the provider's details to the `_allSites` table in [`lib/provider.dart`](lib/provider.dart)
2. Each entry uses the `_SiteRow` record: name, homepageUrl, logoUrl, safeCdnDomains, hideSelectors, and category flags
3. Pre-configured sites with custom selectors can include a `hideSelectors` list; otherwise the global selectors in [`lib/models/site_config.dart`](lib/models/site_config.dart) are used
4. Update the supported providers table in the README

---

## 📦 Builds

GitHub Actions automatically builds APK and App Bundle binaries on every push
and release. See the [releases page](https://github.com/ayoubzulfiqar/animedives/releases)
for the latest binaries.

---

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for more
information.

Copyright (c) 2026 **Ayoub Zulfiqar** — [ayoubzulfiqar.com](https://ayoubzulfiqar.com)
