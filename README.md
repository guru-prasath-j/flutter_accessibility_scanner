# Flutter Accessibility Scanner

[![pub package](https://img.shields.io/pub/v/flutter_accessibility_scanner.svg)](https://pub.dev/packages/flutter_accessibility_scanner)
[![pub points](https://img.shields.io/pub/points/flutter_accessibility_scanner)](https://pub.dev/packages/flutter_accessibility_scanner/score)
[![CI](https://github.com/guru-prasath-j/flutter_accessibility_scanner/actions/workflows/ci.yml/badge.svg)](https://github.com/guru-prasath-j/flutter_accessibility_scanner/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Find accessibility problems in your Flutter UI before your users do. The
scanner walks the live render tree and reports issues against **WCAG 2.1**,
each with a severity, the WCAG success criterion, the on-screen location and
a concrete fix.

| Check | WCAG | Example finding |
|---|---|---|
| Missing accessible name | 4.1.2 | `GestureDetector` wrapping an unlabeled icon |
| Image without description | 1.1.1 | `Image` with no `semanticLabel` |
| Low text contrast | 1.4.3 | grey text on white, 2.1:1 (needs 4.5:1) |
| Low icon contrast | 1.4.11 | light icon on light surface, below 3:1 |
| Small tap target | 2.5.5 | 30x30 button (recommended 48x48) |
| No keyboard focus | 2.1.1 | tappable `GestureDetector` that can't be focused |

Use it three ways: an **in-app overlay** while you develop, a **one-line
check in widget tests**, or a **JSON report** for CI and audits.

## Install

```yaml
dev_dependencies:
  flutter_accessibility_scanner: ^1.1.0
```

Add it under `dependencies` instead if you ship the overlay in debug builds of
your app (it is disabled in release mode by default).

```dart
import 'package:flutter_accessibility_scanner/flutter_accessibility_scanner.dart';
```

## 1. In-app overlay

```dart
MaterialApp(
  builder: (context, child) => AccessibilityScannerWidget(
    onReport: (report) => debugPrint(report.summary),
    child: child!,
  ),
  home: const HomePage(),
);
```

A floating accessibility button appears in debug builds. Tap it to scan the
current screen: every issue is outlined in its severity color and listed with
its WCAG criterion.

## 2. In widget tests

```dart
testWidgets('checkout screen is accessible', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: CheckoutScreen()));
  await tester.pumpAndSettle();

  final report = await AccessibilityScanner().scan(
    tester.element(find.byType(CheckoutScreen)),
    minimumSeverity: AccessibilityIssueSeverity.high,
  );

  expect(report.issues, isEmpty, reason: report.issues.join('\n'));
});
```

## 3. Reports

```dart
final report = await AccessibilityScanner().scan(context);

report.totalIssues;                                   // 7
report.issuesAtLeast(AccessibilityIssueSeverity.high); // most urgent
report.issuesOfType(AccessibilityIssueType.poorColorContrast);
report.summary;                                       // human-readable
report.toJson();                                      // for CI artifacts

for (final issue in report.issues) {                  // most severe first
  print('${issue.severity.name}: ${issue.description}');
  print('  WCAG ${issue.wcagCriterion} at ${issue.bounds}');
  print('  Fix: ${issue.suggestion}');
}
```

## Configure

```dart
final scanner = AccessibilityScanner(detectors: [
  const SemanticsDetector(),
  const ImageLabelDetector(),
  const ContrastDetector(fallbackBackground: Color(0xFF121212)), // dark apps
  const TapTargetDetector(minimumSize: 44),                      // iOS HIG
  const FocusDetector(),
  MyTeamRulesDetector(),
]);
```

Write your own rule by extending `AccessibilityDetector`:

```dart
class MyTeamRulesDetector extends AccessibilityDetector {
  @override
  Future<List<AccessibilityIssue>> detect(RenderObject node) async {
    if (node is RenderParagraph && node.text.toPlainText().contains('TODO')) {
      return [
        const AccessibilityIssue(
          type: AccessibilityIssueType.missingScreenReaderHint,
          description: 'Placeholder text shipped',
          severity: AccessibilityIssueSeverity.low,
        ),
      ];
    }
    return const [];
  }
}
```

## Fixer widgets

```dart
// 48x48 minimum, button semantics, label, hint, keyboard focus, tooltip.
AccessibilityFixerButton(
  onPressed: addToFavorites,
  semanticsLabel: 'Add to favorites',
  tooltip: 'Add to favorites',
  child: const Icon(Icons.star),
);

// Darkens/lightens the color just enough to meet WCAG AA on the background.
AccessibilityFixerText(
  text: 'Fine print',
  style: TextStyle(color: Colors.grey[400]),
  backgroundColor: Colors.white,
);
```

`ColorContrastUtils` exposes the math: `calculateContrastRatio`,
`relativeLuminance`, `meetsWCAGAA`, `meetsWCAGAAA`, `wcagLevel`,
`suggestBetterColor`, `composite` and `toHex`.

## How detection works

* **Interactive elements** are the gesture handlers Flutter creates for
  `GestureDetector`, `InkWell` and all Material buttons with an `onTap` or
  `onLongPress`.
* **Names** come from visible text, `Semantics(label:)`, `Tooltip`,
  `Icon.semanticLabel`, or a surrounding `MergeSemantics`.
* **Backgrounds** are read from the nearest painted ancestor (`Container`,
  `ColoredBox`, `DecoratedBox`, `Material`, `Card`, `Scaffold`), blending
  translucent layers. Text over images or gradients can't be measured; those
  fall back to `fallbackBackground` and are marked `backgroundAssumed`.
* **Offstage** content is skipped, like a screen reader would.

An automated scan catches a large share of common problems but not all of
them. Also test with TalkBack/VoiceOver, keyboard navigation and large font
sizes.

## Contributing

Issues and pull requests are welcome on
[GitHub](https://github.com/guru-prasath-j/flutter_accessibility_scanner).

## License

MIT
