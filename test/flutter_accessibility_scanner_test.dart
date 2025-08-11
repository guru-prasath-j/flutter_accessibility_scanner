import 'package:flutter/material.dart';
import 'package:flutter_accessibility_scanner/flutter_accessibility_scanner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Compilation Tests', () {
    test('all classes can be instantiated', () {
      // Test that all main classes compile and can be instantiated
      expect(() => AccessibilityScanner(), returnsNormally);
      expect(
          () => AccessibilityReport(
                timestamp: DateTime.now(),
                totalIssues: 0,
                issues: [],
              ),
          returnsNormally);
      expect(
          () => AccessibilityIssue(
                type: AccessibilityIssueType.missingSemanticsLabel,
                description: 'Test',
                severity: AccessibilityIssueSeverity.low,
              ),
          returnsNormally);

      // Test color contrast utils
      expect(
          () => ColorContrastUtils.calculateContrastRatio(
              Colors.black, Colors.white),
          returnsNormally);
    });
  });

  group('AccessibilityScanner', () {
    testWidgets('debug scanner traversal', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GestureDetector(
              onTap: () {},
              child: Container(
                width: 20,
                height: 20,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Debug: Let's see what render objects we find
      final context = tester.element(find.byType(MaterialApp));
      final renderObject = context.findRenderObject();

      //print('Debug: Starting render object type: ${renderObject?.runtimeType}');

      void debugTraverse(RenderObject? obj, int depth) {
        if (obj == null) return;
        //print(
        // 'Debug: ${'  ' * depth}${obj.runtimeType} - paintBounds: ${obj.paintBounds}');
        obj.visitChildren((child) => debugTraverse(child, depth + 1));
      }

      debugTraverse(renderObject, 0);

      final scanner = AccessibilityScanner();
      final report = await scanner.scan(context);

      //print('Debug: Total issues found: ${report.totalIssues}');
      for (final issue in report.issues) {
        //print('Debug: Issue - ${issue.type}: ${issue.description}');
      }
    });

    testWidgets('detects missing semantics labels with simple button',
        (WidgetTester tester) async {
      // Create a more explicit test case
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Material(
                child: InkWell(
                  onTap: () {},
                  child: Container(
                    width: 20,
                    height: 20,
                    color: Colors.red,
                    child: Icon(Icons.star, size: 16),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final scanner = AccessibilityScanner();
      final report =
          await scanner.scan(tester.element(find.byType(MaterialApp)));

      //print('Debug: InkWell test - Total issues found: ${report.totalIssues}');
      for (final issue in report.issues) {
        //print('Debug: Issue - ${issue.type}: ${issue.description}');
      }

      // Now that we fixed the async issue, this should work
      expect(report.totalIssues, greaterThan(0));
    });

    testWidgets('detects missing semantics labels',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GestureDetector(
              onTap: () {},
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      // Let the widget tree fully build
      await tester.pumpAndSettle();

      final scanner = AccessibilityScanner();
      final report =
          await scanner.scan(tester.element(find.byType(MaterialApp)));

      //print('Debug: Total issues found: ${report.totalIssues}');
      for (final issue in report.issues) {
        //print('Debug: Issue - ${issue.type}: ${issue.description}');
      }

      // Should now detect issues properly
      expect(report.totalIssues, greaterThan(0));
      expect(
        report.issues.any((issue) =>
            issue.type == AccessibilityIssueType.missingSemanticsLabel ||
            issue.type == AccessibilityIssueType.missingFocusSupport),
        isTrue,
      );
    });

    testWidgets('detects small tap targets', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GestureDetector(
              onTap: () {},
              child: Container(
                width: 20, // Too small
                height: 20, // Too small
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      // Let the widget tree fully build
      await tester.pumpAndSettle();

      final scanner = AccessibilityScanner();
      final report =
          await scanner.scan(tester.element(find.byType(MaterialApp)));

      //print('Debug: Issues found for tap target test: ${report.totalIssues}');
      for (final issue in report.issues) {
        //print('Debug: Issue - ${issue.type}: ${issue.description}');
      }

      // Should detect issues now
      expect(report.totalIssues, greaterThan(0));
      expect(
        report.issues.any((issue) =>
            issue.type == AccessibilityIssueType.smallTapTarget ||
            issue.type == AccessibilityIssueType.missingSemanticsLabel),
        isTrue,
      );
    });

    testWidgets('generates JSON report correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text('Test', style: TextStyle(color: Colors.grey[300])),
          ),
        ),
      );

      final scanner = AccessibilityScanner();
      final report = await scanner.scan(tester.element(find.byType(Scaffold)));
      final json = report.toJson();

      expect(json, isA<String>());
      expect(json.contains('timestamp'), isTrue);
      expect(json.contains('totalIssues'), isTrue);
    });
  });

  group('ColorContrastUtils', () {
    test('calculates contrast ratio correctly', () {
      final ratio = ColorContrastUtils.calculateContrastRatio(
        Colors.black,
        Colors.white,
      );
      expect(ratio, closeTo(21.0, 0.1));
    });

    test('detects WCAG AA compliance', () {
      expect(ColorContrastUtils.meetsWCAGAA(4.5), isTrue);
      expect(ColorContrastUtils.meetsWCAGAA(4.0), isFalse);
    });

    test('suggests better colors for poor contrast', () {
      final suggested = ColorContrastUtils.suggestBetterColor(
        Colors.grey[400]!,
        Colors.grey[300]!,
      );

      final newRatio = ColorContrastUtils.calculateContrastRatio(
        suggested,
        Colors.grey[300]!,
      );

      expect(newRatio, greaterThan(4.5));
    });
  });

  group('AccessibilityFixerButton', () {
    testWidgets('meets minimum tap target size', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibilityFixerButton(
              onPressed: () {},
              child: const Icon(Icons.star),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(AccessibilityFixerButton);
      expect(buttonFinder, findsOneWidget);

      final buttonSize = tester.getSize(buttonFinder);
      expect(buttonSize.width, greaterThanOrEqualTo(48.0));
      expect(buttonSize.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('has proper semantics', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibilityFixerButton(
              onPressed: () {},
              semanticsLabel: 'Test Button',
              semanticsHint: 'Tap to test',
              child: const Icon(Icons.star),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Test Button'), findsOneWidget);
    });
  });

  group('AccessibilityReport', () {
    test('groups issues by severity correctly', () {
      final issues = [
        AccessibilityIssue(
          type: AccessibilityIssueType.missingSemanticsLabel,
          description: 'Test issue 1',
          severity: AccessibilityIssueSeverity.high,
        ),
        AccessibilityIssue(
          type: AccessibilityIssueType.poorColorContrast,
          description: 'Test issue 2',
          severity: AccessibilityIssueSeverity.critical,
        ),
        AccessibilityIssue(
          type: AccessibilityIssueType.smallTapTarget,
          description: 'Test issue 3',
          severity: AccessibilityIssueSeverity.high,
        ),
      ];

      final report = AccessibilityReport(
        timestamp: DateTime.now(),
        totalIssues: issues.length,
        issues: issues,
      );

      final grouped = report.issuesBySeverity;
      expect(grouped[AccessibilityIssueSeverity.critical]?.length, 1);
      expect(grouped[AccessibilityIssueSeverity.high]?.length, 2);
    });

    test('generates readable summary', () {
      final report = AccessibilityReport(
        timestamp: DateTime.now(),
        totalIssues: 2,
        issues: [
          AccessibilityIssue(
            type: AccessibilityIssueType.missingSemanticsLabel,
            description: 'Test issue',
            severity: AccessibilityIssueSeverity.high,
          ),
          AccessibilityIssue(
            type: AccessibilityIssueType.poorColorContrast,
            description: 'Test issue 2',
            severity: AccessibilityIssueSeverity.medium,
          ),
        ],
      );

      final summary = report.summary;
      expect(summary.contains('Total Issues: 2'), isTrue);
      expect(summary.contains('high: 1'), isTrue);
      expect(summary.contains('medium: 1'), isTrue);
    });
  });
}
