import 'package:flutter_test/flutter_test.dart';

import 'package:wudget/design/token_demo_screen.dart';
import 'package:wudget/main.dart';

void main() {
  testWidgets('app boots to the token demo screen', (WidgetTester tester) async {
    await tester.pumpWidget(const WudgetApp());

    expect(find.byType(TokenDemoScreen), findsOneWidget);
  });
}
