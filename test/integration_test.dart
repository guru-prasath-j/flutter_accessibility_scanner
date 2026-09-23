import 'package:flutter/material.dart';
import 'package:flutter_accessibility_scanner/flutter_accessibility_scanner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Integration', () {
    testWidgets('complete accessibility scan workflow', (tester) async {
      await tester.pumpWidget(const TestAppWithIssues());
      await tester.pumpAndSettle();

      final report = await AccessibilityScanner()
          .scan(tester.element(find.byType(MaterialApp)));

      expect(report.totalIssues, greaterThan(0));
      expect(
        report.issuesOfType(AccessibilityIssueType.missingSemanticsLabel),
        isNotEmpty,
        reason: 'Should detect missing semantics labels',
      );
      expect(
        report.issuesOfType(AccessibilityIssueType.smallTapTarget),
        isNotEmpty,
        reason: 'Should detect small tap targets',
      );
      expect(
        report.issuesOfType(AccessibilityIssueType.poorColorContrast),
        isNotEmpty,
        reason: 'Should detect color contrast issues',
      );

      // The accessible button must not be reported.
      final goodButton = tester.getRect(find.byType(AccessibilityFixerButton));
      expect(
        report.issues.where(
          (i) => i.bounds != null && goodButton.contains(i.bounds!.center),
        ),
        isEmpty,
      );
    });

    testWidgets('AccessibilityFixerButton works', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibilityFixerButton(
              onPressed: () => pressed = true,
              semanticsLabel: 'Test Button',
              child: const Text('Click Me'),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(AccessibilityFixerButton));
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));
      expect(find.bySemanticsLabel('Test Button'), findsOneWidget);

      await tester.tap(find.byType(AccessibilityFixerButton));
      expect(pressed, isTrue);
    });

    testWidgets('scanner overlay scans, reports and highlights',
        (tester) async {
      AccessibilityReport? received;
      await tester.pumpWidget(
        MaterialApp(
          home: AccessibilityScannerWidget(
            enabled: true,
            onReport: (report) => received = report,
            child: Scaffold(
              body: Center(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(width: 20, height: 20, color: Colors.blue),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.accessibility), findsOneWidget);
      await tester.tap(find.byIcon(Icons.accessibility));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(received, isNotNull);
      expect(received!.hasIssues, isTrue);
      expect(find.text('Accessibility Report'), findsOneWidget);
      // The scanner never reports its own floating button.
      final fab = tester.getRect(find.byType(FloatingActionButton));
      expect(
        received!.issues.where(
          (i) => i.bounds != null && fab.overlaps(i.bounds!),
        ),
        isEmpty,
      );

      await tester.pump(const Duration(seconds: 6));
      expect(find.text('Accessibility Report'), findsNothing);
    });

    testWidgets('scanner overlay can wrap MaterialApp', (tester) async {
      await tester.pumpWidget(
        const AccessibilityScannerWidget(
          enabled: true,
          child: MaterialApp(home: Scaffold(body: Text('Hello'))),
        ),
      );
      await tester.tap(find.byIcon(Icons.accessibility));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Accessibility Report'), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('disabled overlay renders only the child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AccessibilityScannerWidget(
            enabled: false,
            child: Scaffold(body: Text('Hello')),
          ),
        ),
      );
      expect(find.byIcon(Icons.accessibility), findsNothing);
      expect(find.text('Hello'), findsOneWidget);
    });
  });
}

/// A small app with known accessibility problems.
class TestAppWithIssues extends StatelessWidget {
  /// Creates the app.
  const TestAppWithIssues({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Test App')),
        body: Column(
          children: [
            // Small tap target without a label.
            GestureDetector(
              onTap: () {},
              child: Container(
                width: 20,
                height: 20,
                color: Colors.blue,
                child: const Icon(Icons.star, size: 12),
              ),
            ),
            // Poor contrast text.
            Container(
              color: Colors.grey[200],
              child: Text(
                'Hard to read text',
                style: TextStyle(color: Colors.grey[300]),
              ),
            ),
            // Interactive element that is too short.
            InkWell(
              onTap: () {},
              child: Container(
                width: 100,
                height: 40,
                color: Colors.red.shade900,
                child: const Center(
                  child: Text('Button', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
            // Good example for comparison.
            AccessibilityFixerButton(
              onPressed: () {},
              semanticsLabel: 'Good button',
              child: const Text('Accessible Button'),
            ),
          ],
        ),
      ),
    );
  }
}
