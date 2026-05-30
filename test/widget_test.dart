import 'package:flutter_test/flutter_test.dart';
import 'package:shared_expense_app/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const SharedExpenseApp());
    expect(find.byType(SharedExpenseApp), findsOneWidget);
  });
}
