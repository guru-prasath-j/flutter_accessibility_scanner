import 'package:flutter/material.dart';
import 'package:flutter_accessibility_scanner/flutter_accessibility_scanner.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/main.dart';

void main() {
  testWidgets('Example app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(MyApp());

    // Verify that the app builds successfully
    expect(find.text('Accessibility Scanner Demo'), findsOneWidget);
    expect(find.text('❌ Bad: Button with issues'), findsOneWidget);
    expect(find.text('✅ Good: Accessibility-enhanced button'), findsOneWidget);

    // Test the manual scan button
    expect(find.text('Run Manual Accessibility Scan'), findsOneWidget);

    // Tap the scan button and verify it works
    await tester.tap(find.text('Run Manual Accessibility Scan'));
    await tester.pump();

    // Should show snackbar with scan results
    await tester.pump(Duration(milliseconds: 100));
  });

  testWidgets('Accessibility scanner widget is present',
      (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    // The AccessibilityScannerWidget should be present
    expect(find.byType(AccessibilityScannerWidget), findsOneWidget);

    // Should have the floating scan button
    expect(find.byIcon(Icons.accessibility), findsOneWidget);
  });

  testWidgets('Good and bad examples are present', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    // Should have examples of both good and bad accessibility
    expect(find.byType(GestureDetector), findsOneWidget);
    expect(find.byType(AccessibilityFixerButton), findsOneWidget);
    expect(find.byType(AccessibilityFixerText), findsOneWidget);
  });
}
