import 'package:flutter_accessibility_scanner/flutter_accessibility_scanner.dart';
import 'package:flutter_accessibility_scanner_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('example app builds and scans', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Accessibility Scanner Demo'), findsOneWidget);
    expect(find.byType(AccessibilityScannerWidget), findsOneWidget);
    expect(find.byType(AccessibilityFixerButton), findsOneWidget);
    expect(find.byType(AccessibilityFixerText), findsOneWidget);

    final scanButton = find.text('Run manual accessibility scan');
    await tester.ensureVisible(scanButton);
    await tester.pumpAndSettle();
    await tester.tap(scanButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('issues'), findsWidgets);
    await tester.pump(const Duration(seconds: 6));
  });
}
