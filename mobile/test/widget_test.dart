import 'package:flutter_test/flutter_test.dart';
import 'package:pesavault/main.dart';

void main() {
  testWidgets('App launches with splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PesaVaultApp());
    expect(find.text('PesaVault'), findsOneWidget);
  });
}
