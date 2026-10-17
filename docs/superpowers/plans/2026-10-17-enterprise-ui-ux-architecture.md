# AnimeDives Enterprise UI/UX & Architecture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform AnimeDives into a stunning, enterprise-grade, ad-shielded streaming application with an Electric Cyber Glassmorphism design system, persistent themes and favorites, hardened WebView security shield, in-app floating navigation controls, and an inline Continue Watching hero rail.

**Architecture:** Build upon the existing Flutter + GetX reactive state layer while decoupling theme, favorites, and custom site persistence into `HistoryController` (persisting to `SharedPreferences`). Harden domain matching and CSS sandboxing in the WebView engine, and elevate the UI layer with glassmorphic surfaces, tactile cards, responsive grids, and an inline resume rail.

**Tech Stack:** Flutter 3.12+ (Dart 3), GetX, SharedPreferences, webview_flutter, wakelock_plus, google_fonts (Bricolage Grotesque).

**Spec:** `docs/superpowers/specs/2026-10-17-enterprise-ui-ux-architecture-design.md`

## Global Constraints

- Never break existing `SharedPreferences` schema (`animedives.watch_history.v2` must remain backward compatible).
- Maintain 100% safety against Cloudflare Turnstile / reCAPTCHA challenge loops by never injecting clutter-hiding CSS on verification hosts.
- Respect Edge-to-Edge display policies and ensure status/navigation bar icons maintain high contrast across themes.
- Follow Effective Dart and keep `flutter analyze` completely clean (0 errors, 0 warnings).

## Review Focus

1. Host allowance check on subdomain redirects (e.g. `www.anihq.cc` -> `anihq.cc` or `edge.stream.site.com`): must not be blocked by the navigation shield.
2. Form fields and search inputs inside WebView: must allow text selection and cursor placement.
3. Rapid swipe-to-delete in `HistoryScreen`: must synchronously update data to avoid "Dismissible widget still resides in the tree" error while preserving "Undo".
4. Long-press on custom provider cards: must display an explicit confirmation dialog before deletion.
5. In-app floating control bar: must instantly hide when entering HTML5 fullscreen mode so video playback has 0 obstructions.

---

### Task 1: Electric Cyber Glassmorphism Theme & Tokens

**Files:**
- Modify: `lib/themes.dart`
- Test: `test/themes_test.dart`

**Interfaces:**
- Produces: `AnimedivesColors` with `cyanAccent`, `purpleAccent`, `cardBorder`, `glassSurface`.
- Produces: `animedivesCyberGradient`, updated `lightTheme` and `darkTheme` with AMOLED deep obsidian (`#08080A`), frosted card styling, and dynamic status bar brightness.

- [ ] **Step 1: Write failing unit test in `test/themes_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:animedives/themes.dart';

void main() {
  test('Electric Cyber Glassmorphism theme provides brand tokens and extensions', () {
    expect(kBrandCyan, const Color(0xFF00E5FF));
    expect(kBrandPurple, const Color(0xFFB388FF));
    
    final dark = darkTheme;
    expect(dark.scaffoldBackgroundColor, const Color(0xFF08080A));
    final ext = dark.extension<AnimedivesColors>();
    expect(ext, isNotNull);
    expect(ext!.cyanAccent, kBrandCyan);
    expect(ext.purpleAccent, kBrandPurple);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/themes_test.dart`  
Expected: FAIL (unresolved identifiers `kBrandCyan`, `kBrandPurple`, `cyanAccent`).

- [ ] **Step 3: Implement updated design system in `lib/themes.dart`**

Define `kBrandCyan = Color(0xFF00E5FF)`, `kBrandPurple = Color(0xFFB388FF)`, `kBrandGradient`, enhance `AnimedivesColors` with `cyanAccent`, `purpleAccent`, `cardSurface`, `cardBorder`, and configure `lightTheme` / `darkTheme` with deep obsidian background and refined typography.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/themes_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/themes.dart test/themes_test.dart
git commit -m "feat(theme): implement electric cyber glassmorphism design tokens"
```

---

### Task 2: State Persistence, Favorites & Theme Sync in HistoryController

**Files:**
- Modify: `lib/controllers/history_controller.dart`
- Modify: `lib/main.dart`
- Test: `test/history_controller_test.dart`

**Interfaces:**
- Consumes: `SharedPreferences`, `AnimeSiteConfig`, `WatchHistoryEntry`.
- Produces: `Rx<ThemeMode> themeMode`, `cycleThemeMode()`, `RxSet<String> favoriteDomains`, `toggleFavorite(String domain)`, `bool isFavorite(String domain)`, `List<AnimeSiteConfig> get allSites`, `AnimeSiteConfig? findSiteByDomain(String domain)`.

- [ ] **Step 1: Write failing unit test in `test/history_controller_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:animedives/controllers/history_controller.dart';
import 'package:animedives/models/site_config.dart';

void main() {
  const MethodChannel channel = MethodChannel('plugins.flutter.io/shared_preferences');
  final Map<String, dynamic> mockStorage = {};

  setUp(() {
    mockStorage.clear();
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getAll') return mockStorage;
      if (call.method == 'setString' || call.method == 'setStringList') {
        mockStorage[call.arguments['key']] = call.arguments['value'];
        return true;
      }
      return null;
    });
  });

  test('HistoryController toggles favorites and persists themeMode', () async {
    final controller = HistoryController();
    await controller.onInit();

    expect(controller.isFavorite('anihq.cc'), isFalse);
    await controller.toggleFavorite('anihq.cc');
    expect(controller.isFavorite('anihq.cc'), isTrue);
    expect(controller.isFavorite('WWW.ANIHQ.CC'), isTrue); // Normalized check

    expect(controller.themeMode.value, ThemeMode.system);
    await controller.setThemeMode(ThemeMode.dark);
    expect(controller.themeMode.value, ThemeMode.dark);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/history_controller_test.dart`  
Expected: FAIL (unresolved `toggleFavorite`, `isFavorite`, `setThemeMode`).

- [ ] **Step 3: Implement favorites and theme mode in `lib/controllers/history_controller.dart` and bind in `lib/main.dart`**

- Add `themeMode` and `favoriteDomains` properties and persistence methods to `HistoryController`.
- Wire `findSiteByDomain(String domain)` that inspects both `defaultSites` and `loadCustomSites()`.
- Update `main.dart` to read `themeMode` from `HistoryController` and dynamically adjust `SystemUiOverlayStyle`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/history_controller_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/controllers/history_controller.dart lib/main.dart test/history_controller_test.dart
git commit -m "feat(state): add favorites pinning, persistent theme mode, and dynamic overlay style"
```

---

### Task 3: Hardened WebView Security Shield & Domain Normalization

**Files:**
- Modify: `lib/models/site_config.dart`
- Modify: `lib/screens/webview_screen.dart`
- Test: `test/site_config_test.dart`

**Interfaces:**
- Consumes: `site.domain`, `site.safeCdnDomains`, `globalSafeCdnDomains`.
- Produces: `isHostAllowed(String host, AnimeSiteConfig site)`, sanitized CSS sandbox excluding input/textarea.

- [ ] **Step 1: Write failing test in `test/site_config_test.dart`**

```dart
test('isHostAllowed permits naked domain when site has www. domain', () {
  const config = AnimeSiteConfig(
    name: 'AnimeParadise',
    homepageUrl: 'https://www.animeparadise.moe/',
    domain: 'www.animeparadise.moe',
  );
  expect(isHostAllowed('animeparadise.moe', config), isTrue);
  expect(isHostAllowed('sub.animeparadise.moe', config), isTrue);
  expect(isHostAllowed('evil.com', config), isFalse);
});

test('clutter sandbox CSS does not disable user-select on form inputs', () {
  final css = buildClutterCss(const AnimeSiteConfig(name: 'Test', homepageUrl: 'https://test.com', domain: 'test.com'));
  expect(css, contains('input, textarea, [contenteditable="true"]'));
  expect(css, contains('user-select: auto !important;'));
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/site_config_test.dart`  
Expected: FAIL (`isHostAllowed` not defined or fails on naked domain).

- [ ] **Step 3: Implement domain normalization and updated CSS in `site_config.dart` & `webview_screen.dart`**

- Export top-level `isHostAllowed(String host, AnimeSiteConfig site)` using `normalizeDomain`.
- Update `_clutterCss` in `webview_screen.dart` to exempt input, textarea, and editable content.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/site_config_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/models/site_config.dart lib/screens/webview_screen.dart test/site_config_test.dart
git commit -m "fix(shield): support naked/subdomain navigation and protect web form inputs"
```

---

### Task 4: In-App WebView Floating Glass Control Bar

**Files:**
- Modify: `lib/screens/webview_screen.dart`
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: `WebViewController`, `_isFullscreen`, `AnimeSiteConfig`.
- Produces: `_FloatingControlBar` widget with Back, Forward, Reload, Desktop Mode, Shield Details, and Exit actions.

- [ ] **Step 1: Write widget test verifying floating bar presence in `test/widget_test.dart`**

```dart
testWidgets('WebViewScreen renders floating navigation control bar when loaded', (WidgetTester tester) async {
  // Mock HistoryController
  Get.put(HistoryController(), permanent: true);
  
  const site = AnimeSiteConfig(name: 'TestSite', homepageUrl: 'https://example.com', domain: 'example.com');
  await tester.pumpWidget(MaterialApp(home: WebviewScreen(site: site)));
  
  // Floating bar with navigation icons should be in tree
  expect(find.byKey(const ValueKey('webview_floating_controls')), findsOneWidget);
  expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
  expect(find.byIcon(Icons.shield_rounded), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`  
Expected: FAIL (key `webview_floating_controls` not found).

- [ ] **Step 3: Implement `_FloatingControlBar` and auto-hide behavior in `lib/screens/webview_screen.dart`**

- Build frosted glass container using `ClipRRect`, `BackdropFilter`, and translucent cyber background.
- Hook Back, Forward, Reload, Desktop UA toggle, Shield stats modal, and Exit actions.
- Automatically hide (`AnimatedSlide` / `AnimatedOpacity`) when `_isFullscreen` is true.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/webview_screen.dart test/widget_test.dart
git commit -m "feat(webview): add floating glass navigation control bar"
```

---

### Task 5: Continue Watching Hero Rail & History Screen Hardening

**Files:**
- Modify: `lib/screens/home_screen.dart`
- Modify: `lib/screens/history_screen.dart`
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: `HistoryController.entries`, `findSiteByDomain`.
- Produces: `_ContinueWatchingRail` on HomeScreen, hardened `_deleteWithUndo` in HistoryScreen, custom site removal confirmation modal.

- [ ] **Step 1: Write test for Continue Watching hero rail in `test/widget_test.dart`**

```dart
testWidgets('Home screen renders Continue Watching rail when history entries exist', (WidgetTester tester) async {
  final history = Get.put(HistoryController(), permanent: true);
  history.entries.assignAll([
    WatchHistoryEntry(
      id: 'anihq.cc::naruto',
      domain: 'anihq.cc',
      providerName: 'AniHQ',
      title: 'Naruto Shippuden',
      url: 'https://anihq.cc/anime/naruto/episode-1',
      lastWatchedAt: DateTime.now().millisecondsSinceEpoch,
    ),
  ]);

  await tester.pumpWidget(const AnimedivesApp());
  await tester.pumpAndSettle();

  expect(find.text('CONTINUE WATCHING'), findsOneWidget);
  expect(find.text('Naruto Shippuden'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`  
Expected: FAIL ('CONTINUE WATCHING' rail not found on Home screen).

- [ ] **Step 3: Implement Continue Watching rail in `home_screen.dart` and fix `HistoryScreen` dismissible synchronization**

- Add `_continueWatchingRail()` to `HomeScreen` above the provider grid.
- Update `HistoryScreen._siteFor` to use `HistoryController.findSiteByDomain`.
- In `_HistoryRow`, update `onDismissed` to synchronously remove the entry and offer an Undo snackbar.
- Add confirmation dialog before removing a custom site on long-press.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/home_screen.dart lib/screens/history_screen.dart test/widget_test.dart
git commit -m "feat(home): add inline Continue Watching rail and harden history deletion"
```

---

### Task 6: Redesigned Provider Cards, Search with Clear, and Responsive Grid

**Files:**
- Modify: `lib/screens/home_screen.dart`
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: `ProviderCard`, `AnimeSiteConfig`, `HistoryController.favoriteDomains`.
- Produces: Elevated `ProviderCard` with star favorite toggle, multi-tone gradient monogram avatar, clearable search bar with counter pill, and responsive grid calculations.

- [ ] **Step 1: Write test for search clear and favorite pinning in `test/widget_test.dart`**

```dart
testWidgets('Searching providers updates count and clear button resets query', (WidgetTester tester) async {
  Get.put(HistoryController(), permanent: true);
  await tester.pumpWidget(const AnimedivesApp());
  await tester.pumpAndSettle();

  // Enter search text
  await tester.enterText(find.byType(TextField), 'AnimeX');
  await tester.pumpAndSettle();

  expect(find.byIcon(Icons.clear_rounded), findsOneWidget);
  
  // Tap clear
  await tester.tap(find.byIcon(Icons.clear_rounded));
  await tester.pumpAndSettle();

  expect(find.text('AnimeX'), findsWidgets);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`  
Expected: FAIL (`Icons.clear_rounded` not found).

- [ ] **Step 3: Implement redesigned `ProviderCard`, search enhancements, and responsive layout**

- Add clear button (`Icons.clear_rounded`) to search bar with provider count chip.
- Sort pinned favorites to the top of the filtered site list.
- Update `ProviderCard` with Cyber Glassmorphic surface, electric star pinning toggle, dual-tone monogram fallback, and tactile scale feedback.
- Update grid layout builder for multi-column responsive breakpoints (2 on mobile, 3 on tablet, 4 on desktop).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/home_screen.dart test/widget_test.dart
git commit -m "feat(ui): elevate provider cards with favorite pinning, search clear, and responsive grid"
```

---

### Task 7: Final End-to-End Verification & Static Analysis

**Files:**
- All modified files

- [ ] **Step 1: Run static analysis**

Run: `flutter analyze`  
Expected: `No issues found!`.

- [ ] **Step 2: Run all tests**

Run: `flutter test`  
Expected: All tests pass.

- [ ] **Step 3: Verify clean git status and format code**

Run: `dart format lib/ test/`  
Expected: Code formatted, no syntax errors.

- [ ] **Step 4: Final commit and summary**

```bash
git commit -am "chore: format and finalize enterprise UI/UX overhaul"
```
