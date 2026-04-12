import 'package:flutter_test/flutter_test.dart';

import 'package:hext/app/app.dart';

void main() {
  testWidgets('HEXT loads dashboard shell', (WidgetTester tester) async {
    await tester.pumpWidget(const HextApp());
    await tester.pumpAndSettle();

    expect(find.text('Dashboard PAD'), findsAtLeastNWidgets(1));
    expect(find.text('Seguimiento asistencial'), findsNothing);
  });
}
