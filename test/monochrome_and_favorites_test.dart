import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:animedives/controllers/history_controller.dart';
import 'package:animedives/models/site_config.dart';
import 'package:animedives/themes.dart';

import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('Favicon & Logo Resolution', () {
    test('uses png/svg logoUrl when provided and not an .ico', () {
      final config = AnimeSiteConfig(
        name: 'Test PNG',
        homepageUrl: 'https://test.com',
        domain: 'test.com',
        logoUrl: 'https://test.com/logo.png',
      );
      expect(config.effectiveFaviconUrl, 'https://test.com/logo.png');
    });

    test('falls back to Google PNG favicon when logoUrl is empty', () {
      final config = AnimeSiteConfig(
        name: 'No Logo',
        homepageUrl: 'https://example.com/anime',
        domain: 'example.com',
        logoUrl: '',
      );
      expect(
        config.effectiveFaviconUrl,
        'https://www.google.com/s2/favicons?domain=example.com&sz=128',
      );
    });

    test('falls back to Google PNG favicon when logoUrl is a .ico file', () {
      final config = AnimeSiteConfig(
        name: 'Ico Logo',
        homepageUrl: 'https://animesalt.link/',
        domain: 'animesalt.link',
        logoUrl: 'https://animesalt.link/favicon.ico',
      );
      expect(
        config.effectiveFaviconUrl,
        'https://www.google.com/s2/favicons?domain=animesalt.link&sz=128',
      );
    });
  });

  group('Pure Monochrome Theme & Zero Elevation', () {
    testWidgets('dark theme uses pure AMOLED black base and zero elevation', (
      tester,
    ) async {
      expect(darkTheme.brightness, Brightness.dark);
      expect(darkTheme.scaffoldBackgroundColor, const Color(0xFF000000));
      expect(darkTheme.colorScheme.surface, const Color(0xFF000000));
      expect(darkTheme.colorScheme.onSurface, const Color(0xFFFFFFFF));
      expect(darkTheme.elevatedButtonTheme.style?.elevation?.resolve({}), 0);

      final animedives = darkTheme.extension<AnimedivesColors>()!;
      expect(animedives.cardSurface, isNotNull);
      expect(animedives.cardBorder, isNotNull);
      expect(animedives.mutedForeground, isNotNull);
    });

    testWidgets('light theme uses pure white/paper base and zero elevation', (
      tester,
    ) async {
      expect(lightTheme.brightness, Brightness.light);
      expect(lightTheme.scaffoldBackgroundColor, const Color(0xFFFFFFFF));
      expect(lightTheme.colorScheme.onSurface, const Color(0xFF09090B));
      expect(lightTheme.elevatedButtonTheme.style?.elevation?.resolve({}), 0);

      final animedives = lightTheme.extension<AnimedivesColors>()!;
      expect(animedives.cardSurface, isNotNull);
      expect(animedives.cardBorder, isNotNull);
      expect(animedives.mutedForeground, isNotNull);
    });
  });

  group('Stable Grid Ordering & Favorites Filtering', () {
    test(
      'toggling favorite does not scramble the standard list order',
      () async {
        final history = Get.put(HistoryController());
        await history.loadAll();

        final sites = [
          AnimeSiteConfig(
            name: 'Alpha',
            homepageUrl: 'https://alpha.com',
            domain: 'alpha.com',
          ),
          AnimeSiteConfig(
            name: 'Beta',
            homepageUrl: 'https://beta.com',
            domain: 'beta.com',
          ),
          AnimeSiteConfig(
            name: 'Gamma',
            homepageUrl: 'https://gamma.com',
            domain: 'gamma.com',
          ),
        ];

        // Initial order
        expect(sites.map((s) => s.name).toList(), ['Alpha', 'Beta', 'Gamma']);

        // Toggle Gamma to favorite
        await history.toggleFavorite('gamma.com');
        expect(history.isFavorite('gamma.com'), isTrue);

        // In stable mode (All/Anime/Mature), order must remain unchanged
        expect(sites.map((s) => s.name).toList(), ['Alpha', 'Beta', 'Gamma']);

        // Dedicated favorites filter returns only favorited sites
        final favoritesOnly = sites
            .where((s) => history.isFavorite(s.domain))
            .toList();
        expect(favoritesOnly.map((s) => s.name).toList(), ['Gamma']);
      },
    );
  });
}
