import 'package:flutter_test/flutter_test.dart';

import 'package:fintrack/main.dart';

void main() {
  testWidgets('FinTrack app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FinTrackApp());

    expect(find.text('FinTrack'), findsOneWidget);
    expect(
      find.text('Керуйте своїми фінансами легко'),
      findsOneWidget,
    );
  });
}