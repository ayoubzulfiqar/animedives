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
  // can read watch history immediately. Get.put (not lazy) triggers onInit
  // -> the history is loaded from SharedPreferences up front. [permanent: true]
  // keeps the controller alive across route pushes/pops so the in-memory list
  // (and its disk read) is never re-initialized on every navigation.
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

  // Transparent system bar icons so the theme reads cleanly in either mode.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const AnimedivesApp());
}

/// Root application widget. Holds the active [ThemeMode] so the user can switch
/// between light, dark and system, and wires both [lightTheme] and [darkTheme].
class AnimedivesApp extends StatefulWidget {
  const AnimedivesApp({super.key});

  @override
  State<AnimedivesApp> createState() => _AnimedivesAppState();
}

class _AnimedivesAppState extends State<AnimedivesApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _cycleTheme() {
    setState(() {
      _themeMode = switch (_themeMode) {
        ThemeMode.system => ThemeMode.light,
        ThemeMode.light => ThemeMode.dark,
        ThemeMode.dark => ThemeMode.system,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Animedives',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: HomeScreen(themeMode: _themeMode, onCycleTheme: _cycleTheme),
    );
  }
}
