// Smoke test: verifies the app boots and renders the dashboard.
import 'package:flutter_test/flutter_test.dart';

import 'package:animedives/main.dart';

void main() {
  testWidgets('Home screen renders the welcome banner', (WidgetTester tester) async {
    await tester.pumpWidget(const AnimedivesApp());
    await tester.pumpAndSettle();

    // The brand mark and welcome copy should be present.
    expect(find.text('ANIMEDIVES'), findsWidgets);
    expect(find.text('Ad-Shielded Streaming'), findsOneWidget);
  });
}
