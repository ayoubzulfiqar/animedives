# AnimeDives Enterprise UI/UX & Architecture Design Specification

**Date:** 2026-10-17  
**Author:** Antigravity (Senior Flutter Engineer, System Architect, UI/UX Expert)  
**Status:** Approved  
**Scope:** Architectural Overhaul, UI/UX Elevation, Engine Hardening, and Bug Fixes  

---

## 1. Executive Summary & Vision

AnimeDives is an ad-shielded anime streaming aggregator for Flutter. This specification formalizes the transformation of AnimeDives into an enterprise-grade, visually stunning media application with an **Electric Cyber Glassmorphism** design system, persistent preferences, hardened WebView security shield, interactive in-app navigation controls, and seamless multi-device responsiveness.

---

## 2. Issues & Root Causes Addressed

1. **Theme Preference Resets on App Restart**:
   * *Root Cause*: `_themeMode` was stored as ephemeral widget state in `_AnimedivesAppState` in `lib/main.dart` without disk persistence.
   * *Resolution*: Persist theme mode in `SharedPreferences` via `HistoryController` (or unified app preferences) and sync on boot.
2. **System Status/Nav Bar Contrast in Dark Mode**:
   * *Root Cause*: `SystemChrome.setSystemUIOverlayStyle` statically set dark icons regardless of active theme brightness.
   * *Resolution*: Dynamically update system overlay style whenever theme toggles.
3. **Domain Matching & Subdomain Allowance Bug**:
   * *Root Cause*: `AnimeSiteConfig.domainFromUrl` retained `www.` while subdomains and redirects drop it, causing `_isHostAllowed` to block navigation and legitimate player CDN assets.
   * *Resolution*: Normalize domains by stripping `www.` and verify both exact host match and `.domain` suffix match.
4. **Custom Sites Discarded on Resume**:
   * *Root Cause*: `_siteFor` in `HistoryScreen` only searched `defaultSites`, causing custom sites to lose their tailored shield configurations.
   * *Resolution*: Unify custom and default sites in `HistoryController` so resumption always loads the full config.
5. **History Deletion Race Condition**:
   * *Root Cause*: Swiping to delete used `Future.delayed(Duration.zero, ...)` causing potential "Dismissible still in tree" widget errors.
   * *Resolution*: Synchronously remove item in `onDismissed` while keeping a memory reference for "Undo".
6. **Accidental Deletion of Custom Sites**:
   * *Root Cause*: Long-press immediately removed custom sites with no confirmation.
   * *Resolution*: Provide an explicit confirmation bottom sheet/dialog before deletion.
7. **Input Field Freeze in WebView Injected CSS**:
   * *Root Cause*: Aggressive `user-select: none !important;` on `*` broke form fields, search bars, and challenge inputs.
   * *Resolution*: Scope out `input`, `textarea`, and `[contenteditable]` elements.
8. **Stranded User in In-App WebView**:
   * *Root Cause*: No browser controls existed in `WebviewScreen`.
   * *Resolution*: Floating, frosted glass control bar with Back, Forward, Reload, Desktop Mode toggle, Shield stats, and Exit.
9. **Lack of Quick Resume on Home Screen**:
   * *Root Cause*: Users had to open a separate screen to access watch history.
   * *Resolution*: Inline "Continue Watching" hero rail directly on the Home Screen.
10. **Provider Discovery & Organization**:
    * *Root Cause*: 95+ providers without favoriting or clear counter metrics.
    * *Resolution*: Favorites pinning system, real-time search clear button, and result counts.

---

## 3. Architecture & Data Layer

### 3.1 Preferences & State Management (`HistoryController`)
* **Theme Persistence**:
  * Key: `animedives.theme_mode.v1` (`system`, `light`, `dark`).
  * Observable `Rx<ThemeMode> themeMode` exposed to root `GetMaterialApp`.
* **Favorites Persistence**:
  * Key: `animedives.favorite_sites.v1` (`List<String>` of normalized domain names).
  * Observable `RxSet<String> favoriteDomains`.
  * Methods: `toggleFavorite(String domain)`, `bool isFavorite(String domain)`.
* **Unified Site Resolution**:
  * Getter `List<AnimeSiteConfig> get allSites`: Combines `defaultSites` and loaded `customSites`.
  * `AnimeSiteConfig? findSiteByDomain(String domain)`: Resolves any site regardless of origin.

---

## 4. WebView Engine & Security Shield

### 4.1 Domain Shield Logic
```dart
bool isHostAllowed(String host, AnimeSiteConfig site) {
  final cleanHost = normalizeDomain(host);
  final cleanDomain = normalizeDomain(site.domain);
  if (cleanHost == cleanDomain || cleanHost.endsWith('.$cleanDomain')) return true;

  for (final safe in site.safeCdnDomains) {
    final cleanSafe = normalizeDomain(safe);
    if (cleanHost == cleanSafe || cleanHost.endsWith('.$cleanSafe')) return true;
  }
  for (final safe in globalSafeCdnDomains) {
    final cleanSafe = normalizeDomain(safe);
    if (cleanHost == cleanSafe || cleanHost.endsWith('.$cleanSafe')) return true;
  }
  return false;
}
```

### 4.2 Injected CSS Sandbox
```css
*:not(input):not(textarea):not([contenteditable="true"]) {
  -webkit-touch-callout: none !important;
  -webkit-user-select: none !important;
  user-select: none !important;
}
input, textarea, [contenteditable="true"] {
  -webkit-user-select: auto !important;
  user-select: auto !important;
}
```

### 4.3 Floating Glass Navigation Bar
* Positioned at bottom center with `SafeArea` padding.
* Controls:
  * Back (with canGoBack status)
  * Forward (with canGoForward status)
  * Reload (with refresh indicator)
  * Desktop / Mobile UA switcher
  * Shield details sheet (domain, blocked selectors, CDNs)
  * Close / Exit button
* Behavior:
  * Automatically hidden when HTML5 fullscreen is active (`_isFullscreen == true`).
  * Auto-hides on downward scroll and appears on upward gesture or screen edge touch.

---

## 5. UI/UX & Design System

### 5.1 Electric Cyber Glassmorphism Palette
* **Obsidian OLED Background**: `#08080A` (Dark), `#F8F9FC` (Light).
* **Glass Card Surfaces**: `#121217` with 85% opacity, 1px border (`#1E1E28`).
* **Electric Cyan Accent**: `#00E5FF`
* **Cyber Purple Accent**: `#B388FF`
* **Neon Crimson Accent**: `#FF3366` (for 18+ Mature warnings and destructive actions)
* **Gradients**: `LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFFB388FF)])`

### 5.2 Home Dashboard Components
1. **Responsive Cyber App Bar**:
   * Brand title `ANIMEDIVES` with glowing cyan bolt.
   * Theme mode cycle toggle with tooltips.
   * Add custom provider dialog launcher.
   * Watch history icon with reactive badge counter.
2. **Continue Watching Hero Rail**:
   * Horizontal list of recent watch entries directly on the Home Screen.
   * Card shows: Episode title, provider badge, relative time ("35m ago"), play icon, and progress bar accent.
   * One-tap direct resumption.
3. **Filter & Search Bar**:
   * Search input with clear (`×`) icon and real-time provider match counter.
   * Category pills: "All", "Anime", "18+ Mature" (with neon glow and warning badge).
4. **Provider Card Grid**:
   * 2 columns on mobile, 3 on tablet, 4-5 on desktop.
   * Pinned favorites appear first with electric star badge.
   * Dual-tone monogram avatar fallback when remote image fails (403/network error).
   * Shield protection count chip.
   * Long-press custom site management sheet.

---

## 6. Testing & Quality Assurance Plan

* Unit tests for domain normalization and subdomain matching.
* Unit tests for `HistoryController` favorites toggle, theme persistence, and custom site lookup.
* Widget tests verifying home screen rendering, "Continue Watching" rail, search filtering, and provider card pinning.
* Verification that `flutter analyze` passes with 0 warnings/errors and `flutter test` passes all tests.
