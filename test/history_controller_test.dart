import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animedives/controllers/history_controller.dart';
import 'package:animedives/models/site_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('HistoryController toggles favorites and persists themeMode', () async {
    final controller = HistoryController();
    await controller.loadAll();

    expect(controller.isFavorite('anihq.cc'), isFalse);
    await controller.toggleFavorite('anihq.cc');
    expect(controller.isFavorite('anihq.cc'), isTrue);
    expect(controller.isFavorite('WWW.ANIHQ.CC'), isTrue); // Case & www normalized

    await controller.toggleFavorite('anihq.cc');
    expect(controller.isFavorite('anihq.cc'), isFalse);

    // Theme mode persistence
    expect(controller.themeMode.value, ThemeMode.system);
    await controller.setThemeMode(ThemeMode.dark);
    expect(controller.themeMode.value, ThemeMode.dark);

    // Re-verify from new controller instance loading from disk
    final reloadedController = HistoryController();
    await reloadedController.loadAll();
    expect(reloadedController.themeMode.value, ThemeMode.dark);

    // Cycle theme: dark -> system -> light -> dark
    await reloadedController.cycleThemeMode();
    expect(reloadedController.themeMode.value, ThemeMode.system);

    await reloadedController.cycleThemeMode();
    expect(reloadedController.themeMode.value, ThemeMode.light);

    await reloadedController.cycleThemeMode();
    expect(reloadedController.themeMode.value, ThemeMode.dark);
  });

  test('HistoryController findSiteByDomain finds default and custom sites', () async {
    final controller = HistoryController();
    await controller.loadAll();

    // Default site
    final defaultSite = controller.findSiteByDomain('anihq.cc');
    expect(defaultSite, isNotNull);
    expect(defaultSite!.name, 'AniHQ');

    // Custom site
    final customSite = AnimeSiteConfig(
      name: 'CustomStream',
      homepageUrl: 'https://custom.moe',
      domain: 'custom.moe',
    );
    await controller.saveCustomSites([customSite]);

    final resolved = controller.findSiteByDomain('custom.moe');
    expect(resolved, isNotNull);
    expect(resolved!.name, 'CustomStream');

    // Subdomain matching on normalized domain
    final resolvedWithWww = controller.findSiteByDomain('www.custom.moe');
    expect(resolvedWithWww, isNotNull);
    expect(resolvedWithWww!.name, 'CustomStream');
  });
}
