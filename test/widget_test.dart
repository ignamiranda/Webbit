import 'package:flutter_test/flutter_test.dart';
import 'package:webbit/app.dart';

void main() {
  testWidgets('App loads browser screen', (WidgetTester tester) async {
    await tester.pumpWidget(const WebbitApp());
    expect(find.text('Webbit'), findsOneWidget);
  });
}
