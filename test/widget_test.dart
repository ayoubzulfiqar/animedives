// Smoke test: verifies the app boots and renders the dashboard.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:animedives/controllers/history_controller.dart';
import 'package:animedives/main.dart';

void main() {
  const MethodChannel channel =
      MethodChannel('plugins.flutter.io/shared_preferences');

  setUp(() {
    // Mock the shared_preferences platform channel so
    // SharedPreferences.getInstance() resolves instantly instead of
    // hanging on a missing platform handler in tests.
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getAll') return <String, dynamic>{};
      if (call.method == 'setString' ||
          call.method == 'setStringList') {
        return true;
      }
      return null;
    });
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('Home screen renders the welcome banner', (WidgetTester tester) async {
    // Register the HistoryController that HomeScreen depends on via Get.find().
    Get.put(HistoryController(), permanent: true);

    await tester.pumpWidget(const AnimedivesApp());
    await tester.pumpAndSettle();

    // The brand mark and welcome copy should be present.
    expect(find.text('ANIMEDIVES'), findsWidgets);
    expect(find.text('Ad-Shielded Streaming'), findsOneWidget);
  });
}