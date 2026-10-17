import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'controllers/history_controller.dart';
import 'screens/home_screen.dart';
import 'themes.dart';

void main() async {
  // Ensure plugins/services are ready before touching SystemChrome.
  WidgetsFlutterBinding.ensureInitialized();

  // Register app-wide controllers before the first frame so the home screen
  // can read watch history and persistent settings immediately.
  Get.put(HistoryController(), permanent: true);

  // Modern edge-to-edge look on Android (draw behind status/nav bars).
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Allow both portrait and landscape. We enforce portrait by default here and
  // the WebView screen temporarily flips to landscape when a video goes native
  // fullscreen, then restores portrait on exit.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const AnimedivesApp());
}

/// Root application widget. Listens reactively to [HistoryController.themeMode]
/// so the user's light/dark/system preference is persisted across sessions and
/// system UI bar icon contrast adjusts dynamically.
class AnimedivesApp extends StatelessWidget {
  const AnimedivesApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure HistoryController is registered even when running standalone tests
    final history = Get.isRegistered<HistoryController>()
        ? Get.find<HistoryController>()
        : Get.put(HistoryController(), permanent: true);

    return Obx(() {
      final mode = history.themeMode.value;
      // Evaluate effective brightness to guarantee high-contrast system icons
      final platformBrightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      final isDark = mode == ThemeMode.dark ||
          (mode == ThemeMode.system && platformBrightness == Brightness.dark);

      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        ),
      );

      return GetMaterialApp(
        title: 'Animedives',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: mode,
        home: HomeScreen(
          themeMode: mode,
          onCycleTheme: history.cycleThemeMode,
        ),
      );
    });
  }
}
