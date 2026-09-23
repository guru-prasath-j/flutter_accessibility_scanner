import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../accessibility_scanner.dart';
import '../models/accessibility_issue.dart';
import '../utils/render_tree_utils.dart';

/// Detects interactive widgets that screen readers cannot name.
///
/// A tappable element is considered named when it contains visible text, or
/// when it or an ancestor carries a `Semantics` label, a `Tooltip`, or an
/// `Icon.semanticLabel`.
class SemanticsDetector extends AccessibilityDetector {
  /// Creates the detector. Set [flagLongText] to also report long paragraphs
  /// (over [longTextThreshold] characters) with a low-severity hint.
  const SemanticsDetector({
    this.flagLongText = false,
    this.longTextThreshold = 200,
  });

  /// Whether to report long text blocks as [AccessibilityIssueType.missingScreenReaderHint].
  final bool flagLongText;

  /// Character count above which [flagLongText] reports a paragraph.
  final int longTextThreshold;

  @override
  Future<List<AccessibilityIssue>> detect(RenderObject renderObject) async {
    final issues = <AccessibilityIssue>[];

    if (RenderTreeUtils.isTapHandler(renderObject) &&
        !RenderTreeUtils.hasAccessibleName(renderObject)) {
      issues.add(AccessibilityIssue(
        type: AccessibilityIssueType.missingSemanticsLabel,
        description: 'Interactive element has no accessible name',
        severity: AccessibilityIssueSeverity.high,
        suggestion: 'Give it visible text, a Tooltip, an Icon.semanticLabel, '
            'or wrap it in Semantics(label: ..., button: true)',
        bounds: RenderTreeUtils.globalBounds(renderObject),
        wcagCriterion: '4.1.2 Name, Role, Value',
        metadata: {'widgetType': renderObject.runtimeType.toString()},
      ));
    }

    if (flagLongText && renderObject is RenderParagraph) {
      final text = renderObject.text.toPlainText();
      if (text.length > longTextThreshold) {
        issues.add(AccessibilityIssue(
          type: AccessibilityIssueType.missingScreenReaderHint,
          description: 'Long text block without semantic structure',
          severity: AccessibilityIssueSeverity.low,
          suggestion: 'Split it up with headings (Semantics(header: true)) '
              'so screen reader users can navigate it',
          bounds: RenderTreeUtils.globalBounds(renderObject),
          wcagCriterion: '1.3.1 Info and Relationships',
          metadata: {
            'widgetType': renderObject.runtimeType.toString(),
            'textLength': text.length,
            'textPreview': text.substring(0, math.min(50, text.length)),
          },
        ));
      }
    }

    return issues;
  }
}
