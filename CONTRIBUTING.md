# Contributing to AnimeDives

Thank you for your interest in contributing to AnimeDives! This document outlines
how to set up the project and the workflow we follow.

## Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (stable channel, 3.13+)
- Android SDK (for Android builds)
- Java JDK 17+

## Getting Started

```bash
git clone https://github.com/ayoubzulfiqar/animedives.git
cd animedives
flutter pub get
flutter run
```

## Project Structure

```
lib/
├── controllers/       # GetX controllers (history persistence)
├── models/            # Data models (site config, watch history)
├── screens/           # UI screens (home, webview, history)
├── themes.dart        # Light/dark themes and extensions
├── provider.dart      # Anime site configurations
└── main.dart          # App entry point
```

## Adding a New Provider

1. Add the provider's URL constant in `lib/provider.dart`
2. Create an `AnimeSiteConfig` entry with:
   - Appropriate `hideSelectors` for headers, footers, ads, popups
   - `safeCdnDomains` for the site's video/image CDNs
   - A `logoUrl` for the favicon/apple-touch-icon
3. Add the provider to the README's supported providers list

## Running Tests

```bash
flutter test
flutter analyze
```

## Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/my-feature`)
3. Make your changes
4. Run `flutter analyze` and `flutter test`
5. Commit with a clear message
6. Push and open a PR

## License

By contributing, you agree that your contributions will be licensed under the
MIT License. See [LICENSE](LICENSE) for details.
