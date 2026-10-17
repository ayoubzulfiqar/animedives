import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animedives/controllers/history_controller.dart';
import 'package:animedives/main.dart';
import 'package:animedives/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel =
      MethodChannel('plugins.flutter.io/shared_preferences');

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

  testWidgets('Searching providers updates count and clear button resets query', (WidgetTester tester) async {
    final history = Get.put(HistoryController(), permanent: true);
    await history.loadAll();

    await tester.pumpWidget(const AnimedivesApp());
    await tester.pumpAndSettle();

    // Initially clear button should not be present
    expect(find.byIcon(Icons.clear_rounded), findsNothing);

    // Enter search text for AniHQ
    await tester.enterText(find.byType(TextField), 'AniHQ');
    await tester.pumpAndSettle();

    // Clear button should now be visible
    expect(find.byIcon(Icons.clear_rounded), findsOneWidget);
    expect(find.text('AniHQ'), findsWidgets);

    // Tap clear button
    await tester.tap(find.byIcon(Icons.clear_rounded));
    await tester.pumpAndSettle();

    // Query is cleared and clear button disappears
    expect(find.byIcon(Icons.clear_rounded), findsNothing);
  });

  testWidgets('Provider card displays favorite toggle and toggling pins provider', (WidgetTester tester) async {
    final history = Get.put(HistoryController(), permanent: true);
    await history.loadAll();

    await tester.pumpWidget(const AnimedivesApp());
    await tester.pumpAndSettle();

    // Find star icon on cards
    final starFinder = find.byIcon(Icons.star_border_rounded);
    expect(starFinder, findsWidgets);

    // Tap first star icon to favorite the site
    await tester.tap(starFinder.first);
    await tester.pumpAndSettle();

    // At least one star should now be filled
    expect(find.byIcon(Icons.star_rounded), findsWidgets);
  });
}
