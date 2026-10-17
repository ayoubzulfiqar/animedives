import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animedives/controllers/history_controller.dart';
import 'package:animedives/main.dart';
import 'package:animedives/models/watch_history.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel(
    'plugins.flutter.io/shared_preferences',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getAll') return <String, dynamic>{};
          return true;
        });
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets(
    'Home screen renders Continue Watching rail when history entries exist',
    (WidgetTester tester) async {
      final history = Get.put(HistoryController(), permanent: true);
      await history.loadAll();

      history.entries.assignAll([
        WatchHistoryEntry(
          id: 'anihq.cc::naruto',
          domain: 'anihq.cc',
          providerName: 'AniHQ',
          title: 'Naruto Shippuden',
          url: 'https://anihq.cc/anime/naruto/episode-1',
          lastWatchedAt: DateTime.now().millisecondsSinceEpoch - 60000,
        ),
      ]);

      await tester.pumpWidget(const AnimedivesApp());
      await tester.pumpAndSettle();

      expect(find.text('CONTINUE WATCHING'), findsOneWidget);
      expect(find.text('Naruto Shippuden'), findsOneWidget);
    },
  );
}
