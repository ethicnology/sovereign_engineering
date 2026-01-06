import 'package:flutter_test/flutter_test.dart';

import 'package:sovereign_engineering/main.dart';

void main() {
  testWidgets('LUD16 Hunter app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const Lud16HunterApp());
    expect(find.text('LUD16 HUNTER'), findsOneWidget);
    expect(find.text('START HUNT'), findsOneWidget);
  });
}
