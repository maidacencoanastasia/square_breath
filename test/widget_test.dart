import 'package:flutter_test/flutter_test.dart';

import 'package:square_breath/main.dart';

void main() {
  testWidgets('renders breathing session controls', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SquareBreathApp());

    expect(find.text('Square Breathing'), findsOneWidget);
    expect(find.text('Fixed Timer'), findsOneWidget);
    expect(find.text('Number of Rounds'), findsOneWidget);
    expect(find.text('Start Session'), findsOneWidget);
  });
}
