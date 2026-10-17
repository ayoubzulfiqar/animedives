# Implementation Plan: Pure Monochrome Minimalist Design & Core Bug Fixes

**Date:** 2026-10-17  
**Goal:** Deliver a pure monochrome, ultra-sleek AMOLED design with zero elevation/shadows, fix the star favorite re-ordering bug, fix provider favicon rendering, fix navigation button/text contrast, and polish all UI/UX bugs across the app.

---

## 1. Problem Statements & Root Causes

### 1.1 Star Favorite Icon Bug ("Click one and it changes the other")
* **Root Cause:** In `home_screen.dart`, `_filteredSites` dynamically sorted by `bFav.compareTo(aFav)`. When the user tapped the star icon on any card, `history.toggleFavorite` immediately changed favorite state, which caused the list to re-order instantly on the next frame. The favorited item teleported to the top (index 0), sliding whatever card was at index + 1 right under the user's touch. Tapping again toggled that adjacent card.
* **Fix:**
  1. Keep the provider grid order stable while browsing (never abruptly re-order cards while the user is actively viewing/clicking in the grid).
  2. Add a dedicated **"Favorites"** category filter chip `[All, Favorites, Anime, Hentai]`. Selecting "Favorites" filters directly to favorited providers.
  3. Ensure `ProviderCard` updates its own star state reactively and isolated via `Obx` without shifting positions.

### 1.2 Provider Favicon Rendering Failures ("some of thier fav ico is not correctly rendering on homepage")
* **Root Cause:** 88 default providers in `provider.dart` specify `.ico` URLs (Windows Icon format), and 38 have empty `logoUrl`. Flutter's native image codec does not reliably decode `.ico` binary multi-icon bundles on Android/Linux, causing decoding errors and falling back to initial letter placeholders.
* **Fix:**
  1. Build a robust `siteLogoUrl(AnimeSiteConfig site)` helper that returns a crisp PNG favicon.
  2. If `logoUrl` is empty or ends with `.ico`, automatically resolve using Google's high-res Favicon API: `https://www.google.com/s2/favicons?domain=${site.domain}&sz=128`.
  3. In `ProviderCard._logo`, chain fallback: `site.logoUrl` (if not .ico) -> Google Favicon PNG -> initial letter placeholder with monochrome styling.

### 1.3 Navigation Buttons & Text Color Contrast
* **Root Cause:**
  1. In `_categoryChip`, unselected chips had `TextStyle(color: _animedives(context).border)`. In dark theme, `border` is dark `#22222E` on background `#161620`, which is nearly unreadable black-on-black. In light theme, `border` is `#E5E7EB` on `#F1F5F9`, which is washed out gray-on-gray.
  2. In `webview_screen.dart`, the floating glass bar had hardcoded neon cyan/blue (`kBrandBlue`), `Colors.white38`, and no theme adaptation.
  3. In `home_screen.dart`, continue watching "See all" and history buttons used neon cyan instead of clean monochrome tokens.
* **Fix:**
  1. In `_categoryChip`: Unselected chips use `animedives.mutedForeground` (`#999999` in dark, `#666666` in light) for crisp readable text, with a subtle border and transparent/subtle background. Selected chips use high-contrast solid monochrome pill (`#FFFFFF` background with `#000000` text in dark; `#000000` background with `#FFFFFF` text in light).
  2. All navigation icons and text use `colorScheme.onSurface` and `animedives.mutedForeground`.

### 1.4 Monochrome Minimalist Design System & Zero Elevation
* **User Requirement:** "The Coloring and glassmorphic is not correct. Change it not to monochrome elegent and stunning no elevation" -> Confirmed: Pure Monochrome & Minimalist (Deep AMOLED black, pure white text, clean grayscale borders, zero elevation/shadows).
* **Fix:**
  1. In `themes.dart`:
     - Base Dark: True AMOLED `#000000`, card surfaces `#121214`, borders `#26262B`, text `#FFFFFF`, muted text `#9E9EA8`, zero elevation (`elevation: 0`).
     - Base Light: Crisp `#FFFFFF` / `#FAFAFA`, card surfaces `#FFFFFF`, borders `#E4E4E7`, text `#09090B`, muted text `#71717A`, zero elevation (`elevation: 0`).
     - Eliminate all neon cyan (`#00E5FF`) and violet (`#B388FF`) gradients and glowing borders.
     - Replace `animedivesCyberGradient` and `animedivesBorderGradient` with sleek monochrome gradient / subtle solid border tokens.
  2. In `home_screen.dart`, `webview_screen.dart`, `history_screen.dart`:
     - Remove all `BoxShadow` drops (zero elevation).
     - Flat, ultra-clean borders (`Border.all(color: animedives.cardBorder, width: 1)`).
     - Crisp, stunning typography using Bricolage Grotesque.

---

## 2. Implementation Tasks

### Task 1: Pure Monochrome Theme Tokens & Zero Elevation in `lib/themes.dart`
- Update `lib/themes.dart`:
  - Replace cyan/violet brand colors with pure monochrome tokens (`kMonochromeDark`, `kMonochromeLight`, etc.).
  - Set `cardSurface`, `cardBorder`, `border`, `mutedForeground` to sleek AMOLED / paper light tones.
  - Set all button themes and card themes to `elevation: 0`.
  - Update `animedivesBorderGradient` to clean subtle grayscale gradient.

### Task 2: Fix Star Fav Icon Re-ordering & Category Filter in `lib/screens/home_screen.dart`
- Change `_showMature` into an enum or clean filter state: `FilterCategory.all`, `FilterCategory.favorites`, `FilterCategory.anime`, `FilterCategory.mature`.
- Remove dynamic `list.sort` on every frame in `_filteredSites` that was swapping items on star toggle.
- When `FilterCategory.favorites` is active, filter `_filteredSites` to `history.isFavorite(s.domain)`.
- When in "All", "Anime", or "Hentai", keep stable catalog order.
- Tapping star toggles favorite smoothly in-place with immediate visual feedback, without jumping or moving items.

### Task 3: Robust Favicon & Logo Resolver in `lib/models/site_config.dart` & `lib/screens/home_screen.dart`
- Add a helper `String get effectiveFaviconUrl` on `AnimeSiteConfig` (or dedicated resolver function):
  - If `logoUrl` is non-empty and does NOT end with `.ico`, return `logoUrl`.
  - Otherwise, return `https://www.google.com/s2/favicons?domain=$domain&sz=128`.
- In `ProviderCard._logo`:
  - Load `effectiveFaviconUrl` via `Image.network` with smooth fade-in and caching.
  - If loading fails, gracefully fall back to initial letter placeholder styled with sleek monochrome dark/light container and zero elevation.

### Task 4: Fix Navigation Buttons, Category Chips & Text Colors
- In `home_screen.dart`:
  - `_categoryChip`: Redesign with high-contrast monochrome tokens. Selected = solid contrast pill (`#FFFFFF` on `#000000` in dark), Unselected = clean subtle border with `mutedForeground` text.
  - App bar icons, Continue watching "See all" link, History badge: Pure monochrome styling.
  - ProviderCard: Remove `BoxShadow` (zero elevation). Clean 1px border.
  - Welcome banner: Sleek monochrome banner with zero elevation.
- In `webview_screen.dart`:
  - Floating control bar: Remove `BoxShadow`. Use clean translucent AMOLED bar with 1px grayscale border.
  - Navigation icons: Go back, Go forward, Reload, Desktop/Mobile view, Shield status, Hide, Close styled with crisp monochrome contrast.
  - Shield modal: Pure monochrome design with zero elevation.
- In `history_screen.dart`:
  - History rows: Remove drop shadows. Pure monochrome styling.

### Task 5: Unit Tests & Regression Verification
- Write tests in `test/monochrome_and_favorites_test.dart`:
  - Test category filtering (`All`, `Favorites`, `Anime`, `Mature`).
  - Test that toggling a favorite does NOT change the order or indices of the remaining list under `All`.
  - Test favicon resolution for `.ico` and non-`.ico` domains.
  - Test unselected and selected chip text color contrast in both dark and light modes.
- Run all existing unit tests (41+ tests) to guarantee zero regressions.
- Verify with `flutter analyze`.

### Task 6: Release Build & Verification
- Compile release APK with `flutter build apk --release` on JDK 17.
- Confirm successful build and report output APK.
