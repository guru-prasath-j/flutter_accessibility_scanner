import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_accessibility_scanner/flutter_accessibility_scanner.dart';
import 'package:flutter_test/flutter_test.dart';

// A 1x1 transparent PNG.
final Uint8List _pixel = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

Future<AccessibilityReport> _scan(
  WidgetTester tester,
  Widget body, {
  AccessibilityScanner? scanner,
}) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: body)));
  await tester.pumpAndSettle();
  return (scanner ?? AccessibilityScanner())
      .scan(tester.element(find.byType(Scaffold)));
}

void main() {
  group('Compilation', () {
    test('all classes can be instantiated', () {
      expect(AccessibilityScanner.new, returnsNormally);
      expect(
        () => AccessibilityReport(
          timestamp: DateTime.now(),
          totalIssues: 0,
          issues: const [],
        ),
        returnsNormally,
      );
      expect(
        () => const AccessibilityIssue(
          type: AccessibilityIssueType.missingSemanticsLabel,
          description: 'Test',
          severity: AccessibilityIssueSeverity.low,
        ),
        returnsNormally,
      );
    });

    test('default scanner is shared, custom scanners are not', () {
      expect(identical(AccessibilityScanner(), AccessibilityScanner()), isTrue);
      final custom = AccessibilityScanner(detectors: const [TapTargetDetector()]);
      expect(identical(custom, AccessibilityScanner()), isFalse);
      expect(custom.detectors, hasLength(1));
    });
  });

  group('SemanticsDetector', () {
    testWidgets('flags an unlabeled GestureDetector', (tester) async {
      final report = await _scan(
        tester,
        GestureDetector(
          onTap: () {},
          child: Container(width: 100, height: 100, color: Colors.blue),
        ),
      );
      expect(
        report.issuesOfType(AccessibilityIssueType.missingSemanticsLabel),
        isNotEmpty,
      );
    });

    testWidgets('flags an InkWell that only contains an unlabeled icon',
        (tester) async {
      final report = await _scan(
        tester,
        Center(
          child: InkWell(
            onTap: () {},
            child: const SizedBox(
              width: 20,
              height: 20,
              child: Icon(Icons.star, size: 16),
            ),
          ),
        ),
      );
      expect(
        report.issuesOfType(AccessibilityIssueType.missingSemanticsLabel),
        isNotEmpty,
      );
    });

    testWidgets('accepts buttons with text, tooltips or icon labels',
        (tester) async {
      final report = await _scan(
        tester,
        Column(
          children: [
            ElevatedButton(onPressed: () {}, child: const Text('Save')),
            IconButton(
              onPressed: () {},
              tooltip: 'Delete',
              icon: const Icon(Icons.delete),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.share, semanticLabel: 'Share'),
            ),
            Semantics(
              label: 'Favorite',
              button: true,
              child: InkWell(
                onTap: () {},
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.star),
                ),
              ),
            ),
            CheckboxListTile(
              value: true,
              onChanged: (_) {},
              title: const Text('Accept terms'),
            ),
          ],
        ),
      );
      expect(
        report.issuesOfType(AccessibilityIssueType.missingSemanticsLabel),
        isEmpty,
        reason: report.issues.join('\n'),
      );
    });
  });

  group('ImageLabelDetector', () {
    testWidgets('flags images without a semantic label', (tester) async {
      final report = await _scan(
        tester,
        Image.memory(_pixel, width: 50, height: 50),
      );
      final images = report.issues
          .where((i) => i.metadata?['element'] == 'image')
          .toList();
      expect(images, hasLength(1));
      expect(images.single.wcagCriterion, startsWith('1.1.1'));
    });

    testWidgets('ignores labeled and decorative images', (tester) async {
      final report = await _scan(
        tester,
        Column(
          children: [
            Image.memory(_pixel, width: 50, height: 50, semanticLabel: 'Logo'),
            Image.memory(
              _pixel,
              width: 50,
              height: 50,
              excludeFromSemantics: true,
            ),
          ],
        ),
      );
      expect(
        report.issues.where((i) => i.metadata?['element'] == 'image'),
        isEmpty,
      );
    });
  });

  group('TapTargetDetector', () {
    testWidgets('flags small tap targets', (tester) async {
      final report = await _scan(
        tester,
        Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(width: 20, height: 20, color: Colors.blue),
          ),
        ),
      );
      final small = report.issuesOfType(AccessibilityIssueType.smallTapTarget);
      expect(small, hasLength(1));
      expect(small.single.severity, AccessibilityIssueSeverity.critical);
    });

    testWidgets('respects Material tap target padding', (tester) async {
      final report = await _scan(
        tester,
        Center(
          child: IconButton(
            onPressed: () {},
            tooltip: 'Menu',
            icon: const Icon(Icons.menu),
          ),
        ),
      );
      expect(report.issuesOfType(AccessibilityIssueType.smallTapTarget), isEmpty);
    });

    testWidgets('minimumSize is configurable', (tester) async {
      final report = await _scan(
        tester,
        Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(width: 30, height: 30, color: Colors.blue),
          ),
        ),
        scanner: AccessibilityScanner(
          detectors: const [TapTargetDetector(minimumSize: 24)],
        ),
      );
      expect(report.issues, isEmpty);
    });
  });

  group('FocusDetector', () {
    testWidgets('flags GestureDetector but not InkWell', (tester) async {
      final report = await _scan(
        tester,
        Column(
          children: [
            GestureDetector(
              onTap: () {},
              child: const SizedBox(width: 60, height: 60, child: Text('A')),
            ),
            InkWell(
              onTap: () {},
              child: const SizedBox(width: 60, height: 60, child: Text('B')),
            ),
          ],
        ),
        scanner: AccessibilityScanner(detectors: const [FocusDetector()]),
      );
      expect(report.issues, hasLength(1));
      expect(report.issues.single.type,
          AccessibilityIssueType.missingFocusSupport);
    });
  });

  group('ContrastDetector', () {
    testWidgets('flags low-contrast text and suggests a passing color',
        (tester) async {
      final report = await _scan(
        tester,
        Container(
          color: Colors.white,
          child: Text('Hard to read', style: TextStyle(color: Colors.grey[300])),
        ),
      );
      final contrast =
          report.issuesOfType(AccessibilityIssueType.poorColorContrast);
      expect(contrast, hasLength(1));
      expect(contrast.single.metadata!['backgroundColor'], '#FFFFFF');
      expect(contrast.single.wcagCriterion, startsWith('1.4.3'));
    });

    testWidgets('reads ColoredBox, DecoratedBox and Material backgrounds',
        (tester) async {
      final report = await _scan(
        tester,
        Column(
          children: [
            const ColoredBox(
              color: Colors.black,
              child: Text('ok', style: TextStyle(color: Colors.white)),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFF0D47A1)),
              child: Text('ok', style: TextStyle(color: Colors.white)),
            ),
            Material(
              color: Colors.black,
              child: Text('bad', style: TextStyle(color: Colors.grey[900])),
            ),
          ],
        ),
      );
      final contrast =
          report.issuesOfType(AccessibilityIssueType.poorColorContrast);
      expect(contrast, hasLength(1));
      expect(contrast.single.metadata!['text'], 'bad');
    });

    testWidgets('uses the 3:1 threshold for large text', (tester) async {
      // #949494 on white is about 3.0:1: fails for body text, passes large.
      final report = await _scan(
        tester,
        const ColoredBox(
          color: Colors.white,
          child: Column(
            children: [
              Text('small', style: TextStyle(color: Color(0xFF949494))),
              Text(
                'large',
                style: TextStyle(color: Color(0xFF949494), fontSize: 28),
              ),
            ],
          ),
        ),
      );
      final contrast =
          report.issuesOfType(AccessibilityIssueType.poorColorContrast);
      expect(contrast, hasLength(1));
      expect(contrast.single.metadata!['text'], 'small');
    });
  });

  group('AccessibilityScanner', () {
    testWidgets('filters by minimumSeverity and sorts by severity',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                GestureDetector(
                  onTap: () {},
                  child: Container(width: 20, height: 20, color: Colors.blue),
                ),
                Image.memory(_pixel, width: 50, height: 50),
              ],
            ),
          ),
        ),
      );
      final context = tester.element(find.byType(Scaffold));

      final all = await AccessibilityScanner().scan(context);
      expect(all.hasIssues, isTrue);
      for (var i = 1; i < all.issues.length; i++) {
        expect(
          all.issues[i - 1].severity.index,
          greaterThanOrEqualTo(all.issues[i].severity.index),
        );
      }

      final severe = await AccessibilityScanner().scan(
        context,
        minimumSeverity: AccessibilityIssueSeverity.high,
      );
      expect(
        severe.issues
            .every((i) => i.severity.isAtLeast(AccessibilityIssueSeverity.high)),
        isTrue,
      );
      expect(severe.totalIssues, lessThan(all.totalIssues));
      expect(all.scannedElements, greaterThan(0));
    });

    testWidgets('generates a JSON report', (tester) async {
      final report = await _scan(
        tester,
        Text('Test', style: TextStyle(color: Colors.grey[300])),
      );
      final json = report.toJson();
      expect(json, contains('timestamp'));
      expect(json, contains('totalIssues'));
      expect(json, contains('wcagCriterion'));
      expect(report.toMap()['issuesBySeverity'], isA<Map<String, int>>());
    });

    testWidgets('supports custom detectors', (tester) async {
      final report = await _scan(
        tester,
        const Text('TODO: remove'),
        scanner: AccessibilityScanner(detectors: [_TodoDetector()]),
      );
      expect(report.issues, hasLength(1));
    });

    testWidgets('reports issue bounds in global coordinates', (tester) async {
      final report = await _scan(
        tester,
        Padding(
          padding: const EdgeInsets.only(left: 100, top: 200),
          child: GestureDetector(
            onTap: () {},
            child: Container(width: 20, height: 20, color: Colors.blue),
          ),
        ),
      );
      final issue =
          report.issuesOfType(AccessibilityIssueType.smallTapTarget).single;
      expect(issue.bounds!.left, closeTo(100, 0.01));
      expect(issue.bounds!.top, closeTo(200, 0.01));
    });
  });

  group('ColorContrastUtils', () {
    test('calculates contrast ratio correctly', () {
      final ratio =
          ColorContrastUtils.calculateContrastRatio(Colors.black, Colors.white);
      expect(ratio, closeTo(21.0, 0.1));
    });

    test('detects WCAG AA compliance', () {
      expect(ColorContrastUtils.meetsWCAGAA(4.5), isTrue);
      expect(ColorContrastUtils.meetsWCAGAA(4.0), isFalse);
      expect(ColorContrastUtils.wcagLevel(8), 'AAA');
      expect(ColorContrastUtils.wcagLevel(5), 'AA');
      expect(ColorContrastUtils.wcagLevel(2), 'Fail');
    });

    test('suggests better colors for poor contrast', () {
      for (final pair in [
        (Colors.grey[400]!, Colors.grey[300]!),
        (Colors.grey[600]!, Colors.grey[800]!),
        (const Color(0xFF777777), const Color(0xFF777777)),
      ]) {
        final suggested =
            ColorContrastUtils.suggestBetterColor(pair.$1, pair.$2);
        expect(
          ColorContrastUtils.calculateContrastRatio(suggested, pair.$2),
          greaterThan(4.5),
        );
      }
    });

    test('formats hex colors', () {
      expect(ColorContrastUtils.toHex(const Color(0xFF0A0B0C)), '#0A0B0C');
    });
  });

  group('AccessibilityFixerButton', () {
    testWidgets('meets minimum tap target size', (tester) async {
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
      final size = tester.getSize(find.byType(AccessibilityFixerButton));
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('has proper semantics and passes the scanner',
        (tester) async {
      final report = await _scan(
        tester,
        AccessibilityFixerButton(
          onPressed: () {},
          semanticsLabel: 'Test Button',
          semanticsHint: 'Tap to test',
          child: const Icon(Icons.star),
        ),
      );
      expect(find.bySemanticsLabel('Test Button'), findsOneWidget);
      expect(report.issues, isEmpty, reason: report.issues.join('\n'));
    });
  });

  group('AccessibilityFixerText', () {
    testWidgets('adjusts color to meet contrast', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibilityFixerText(
              text: 'Readable',
              style: TextStyle(color: Color(0xFFBBBBBB)),
              backgroundColor: Colors.white,
            ),
          ),
        ),
      );
      final text = tester.widget<Text>(find.text('Readable'));
      final ratio = ColorContrastUtils.calculateContrastRatio(
        text.style!.color!,
        Colors.white,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });
  });

  group('AccessibilityReport', () {
    const issues = [
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
        severity: AccessibilityIssueSeverity.medium,
      ),
    ];
    final report = AccessibilityReport(
      timestamp: DateTime(2026),
      totalIssues: issues.length,
      issues: issues,
    );

    test('groups issues', () {
      expect(report.issuesBySeverity[AccessibilityIssueSeverity.critical],
          hasLength(1));
      expect(report.issuesByType.keys, hasLength(3));
      expect(report.issuesAtLeast(AccessibilityIssueSeverity.high),
          hasLength(2));
    });

    test('generates readable summary', () {
      final summary = report.summary;
      expect(summary, contains('Total Issues: 3'));
      expect(summary, contains('high: 1'));
      expect(summary, contains('medium: 1'));
    });
  });
}

class _TodoDetector extends AccessibilityDetector {
  @override
  Future<List<AccessibilityIssue>> detect(RenderObject renderObject) async {
    if (renderObject is RenderParagraph &&
        renderObject.text.toPlainText().contains('TODO')) {
      return const [
        AccessibilityIssue(
          type: AccessibilityIssueType.missingScreenReaderHint,
          description: 'Placeholder text shipped',
          severity: AccessibilityIssueSeverity.low,
        ),
      ];
    }
    return const [];
  }
}
