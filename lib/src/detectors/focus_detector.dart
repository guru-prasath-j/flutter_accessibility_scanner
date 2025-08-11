import 'package:flutter/rendering.dart';

import '../accessibility_scanner.dart';
import '../models/accessibility_issue.dart';

/// Detects interactive elements that lack proper focus support.
class FocusDetector extends AccessibilityDetector {
  @override
  Future<List<AccessibilityIssue>> detect(RenderObject renderObject) async {
    final List<AccessibilityIssue> issues = [];

    if (_isInteractiveElement(renderObject) &&
        !_hasFocusSupport(renderObject)) {
      issues.add(AccessibilityIssue(
        type: AccessibilityIssueType.missingFocusSupport,
        description: 'Interactive element lacks keyboard focus support',
        severity: AccessibilityIssueSeverity.medium,
        suggestion:
            'Wrap the widget with Focus or ensure it properly handles keyboard navigation',
        bounds: renderObject.paintBounds,
        metadata: {
          'widgetType': renderObject.runtimeType.toString(),
          'canRequestFocus': _canRequestFocus(renderObject),
        },
      ));
    }

    return issues;
  }

  bool _isInteractiveElement(RenderObject renderObject) {
    // More comprehensive detection of interactive elements
    final String typeName = renderObject.runtimeType.toString().toLowerCase();

    return renderObject is RenderPointerListener ||
        typeName.contains('button') ||
        typeName.contains('gesture') ||
        typeName.contains('inkwell') ||
        typeName.contains('tap') ||
        typeName.contains('pointer') ||
        _hasClickableSemantics(renderObject);
  }

  bool _hasClickableSemantics(RenderObject renderObject) {
    final semantics = renderObject.debugSemantics;
    if (semantics == null) return false;

    // Check if has tap action or is marked as button
    return semantics.hasFlag(SemanticsFlag.isButton) ||
        semantics.hasFlag(SemanticsFlag.isLink);
  }

  bool _hasFocusSupport(RenderObject renderObject) {
    // Check if the render object or its semantic node supports focus
    final semantics = renderObject.debugSemantics;

    // If no semantics at all, consider it lacking focus support
    if (semantics == null) return false;

    return semantics.hasFlag(SemanticsFlag.isFocusable) ||
        semantics.hasFlag(SemanticsFlag.isFocused) ||
        _canRequestFocus(renderObject);
  }

  bool _canRequestFocus(RenderObject renderObject) {
    // This is a simplified check - in a real implementation, you'd want to
    // traverse up the widget tree to find Focus widgets
    return renderObject.runtimeType.toString().toLowerCase().contains('focus');
  }
}
