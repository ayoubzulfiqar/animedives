# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Open-source release: MIT LICENSE, CODE_OF_CONDUCT.md, CONTRIBUTING.md
- Integrated 81 new anime streaming providers from sites.md
- Custom site persistence: user-added sites now survive app restarts
- Comprehensive unit tests for animeHistoryId, humanizeSlug, AnimeSiteConfig
- GitHub Actions CI/CD workflow for automated APK/AAB builds on releases
- General/mature site grouping via `generalSites`, `matureSites` exports
- Loading state in HomeScreen while custom sites restore from disk

### Fixed

- `.gitignore` no longer excludes source code (lib/, android/, ios/, test/,
  pubspec.yaml) — app is now properly open-source
- `animeHistoryId` now correctly groups episodes by series (filters generic
  keywords and episode markers, strips compound episode suffixes, normalizes
  www. prefix)
- `WebViewController.clearCache()` fire-and-forget removed from main.dart
- Watch history ID generation passes full URL instead of pre-extracted slug
- Test failure: HistoryController registration and SharedPreferences mock
- Android `local.properties` Windows paths replaced with Linux paths
- `.vscode/settings.json` CMake path corrected to Linux path
- Bare homepage slug now returns 'home' instead of '/'

### Security

- Navigation shield blocks all third-party domains except safe CDN and
  challenge-verification hosts (Cloudflare Turnstile, reCAPTCHA, hCaptcha)
- Mixed content mode set to compatibility for safe HTTP sub-resources
