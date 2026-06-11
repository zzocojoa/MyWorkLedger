import 'package:flutter_test/flutter_test.dart';

import 'package:workledger/main.dart';

void main() {
  testWidgets('shows app names', (WidgetTester tester) async {
    await tester.pumpWidget(const WorkLedgerApp());

    expect(find.text('내근무장부'), findsWidgets);
    expect(find.text('WorkLedger'), findsOneWidget);
  });
}
