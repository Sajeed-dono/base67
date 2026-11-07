// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:base67/main.dart';

void main() {
  testWidgets('the existing prologue entry point opens', (tester) async {
    await tester.pumpWidget(const Base67App());
    expect(find.textContaining('THE LAST YEAR'), findsOneWidget);
    expect(find.text('tap to continue'), findsOneWidget);
  });

  testWidgets('debug long-press opens the Data Check screen', (tester) async {
    await tester.pumpWidget(const Base67App());
    final entry = find.byKey(const ValueKey('base67-debug-data-check-entry'));
    expect(entry, findsOneWidget);

    await tester.longPress(entry);
    await tester.pumpAndSettle();

    expect(find.text('Data Check'), findsOneWidget);
  });
}
