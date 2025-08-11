import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../accessibility_scanner.dart';
import '../models/accessibility_issue.dart';

/// Detects widgets that are missing semantic labels or descriptions.
class SemanticsDetector extends AccessibilityDetector {
  @override
  Future<List<AccessibilityIssue>> detect(RenderObject renderObject) async {
    final List<AccessibilityIssue> issues = [];

    // Check if this is an interactive widget without semantics
    if (_isInteractiveWidget(renderObject)) {
      if (!_hasSemantics(renderObject)) {
        issues.add(AccessibilityIssue(
          type: AccessibilityIssueType.missingSemanticsLabel,
          description: 'Interactive widget missing semantic label',
          severity: AccessibilityIssueSeverity.high,
          suggestion:
              'Add a Semantics widget or semanticsLabel property to provide screen reader support',
          bounds: renderObject.paintBounds,
          metadata: {
            'widgetType': renderObject.runtimeType.toString(),
          },
        ));
      }
    }

    // Check for text widgets without semantic meaning
    if (_isTextWidget(renderObject) && !_hasSemantics(renderObject)) {
      final textContent = _extractTextContent(renderObject);
      if (textContent != null && textContent.length > 50) {
        issues.add(AccessibilityIssue(
          type: AccessibilityIssueType.missingScreenReaderHint,
          description: 'Long text content without semantic structure',
          severity: AccessibilityIssueSeverity.medium,
          suggestion:
              'Consider adding semantic hints for better screen reader navigation',
          bounds: renderObject.paintBounds,
          metadata: {
            'textLength': textContent.length,
            'textPreview':
                textContent.substring(0, math.min(50, textContent.length)),
          },
        ));
      }
    }

    return issues;
  }

  bool _isInteractiveWidget(RenderObject renderObject) {
    return renderObject is RenderPointerListener ||
        renderObject.runtimeType.toString().toLowerCase().contains('button') ||
        renderObject.runtimeType.toString().toLowerCase().contains('gesture');
  }

  bool _isTextWidget(RenderObject renderObject) {
    return renderObject is RenderParagraph;
  }

  bool _hasSemantics(RenderObject renderObject) {
    // Check if the render object has semantic annotations
    final SemanticsNode? semantics = renderObject.debugSemantics;
    return semantics != null &&
        (semantics.label.isNotEmpty == true ||
            semantics.hint.isNotEmpty == true ||
            semantics.value.isNotEmpty == true);
  }

  String? _extractTextContent(RenderObject renderObject) {
    if (renderObject is RenderParagraph) {
      return renderObject.text.toPlainText();
    }
    return null;
  }
}
