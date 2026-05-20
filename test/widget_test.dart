import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webbit/app.dart';

void main() {
  testWidgets('App shows loading indicator while adblock initializes', (WidgetTester tester) async {
    await tester.pumpWidget(const WebbitApp());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
