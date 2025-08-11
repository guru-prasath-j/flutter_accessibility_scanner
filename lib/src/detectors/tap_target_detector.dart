import 'package:flutter/rendering.dart';

import '../accessibility_scanner.dart';
import '../models/accessibility_issue.dart';

/// Detects interactive elements with tap targets smaller than recommended size.
class TapTargetDetector extends AccessibilityDetector {
  static const double minimumTapTargetSize = 48.0; // WCAG recommended minimum

  @override
  Future<List<AccessibilityIssue>> detect(RenderObject renderObject) async {
    final List<AccessibilityIssue> issues = [];

    if (_isInteractiveElement(renderObject)) {
      final size = renderObject.paintBounds.size;

      //print(
      // 'Debug: Checking tap target size for ${renderObject.runtimeType}: ${size.width}x${size.height}');

      if (size.width < minimumTapTargetSize ||
          size.height < minimumTapTargetSize) {
        //print('Debug: Found small tap target: ${size.width}x${size.height}');
        final issue = AccessibilityIssue(
          type: AccessibilityIssueType.smallTapTarget,
          description:
              'Interactive element tap target is smaller than recommended ${minimumTapTargetSize}x${minimumTapTargetSize} pixels',
          severity: _calculateSeverity(size),
          suggestion:
              'Increase the tap target size to at least ${minimumTapTargetSize}x${minimumTapTargetSize} pixels using padding or minimum size constraints',
          bounds: renderObject.paintBounds,
          metadata: {
            'currentWidth': size.width,
            'currentHeight': size.height,
            'recommendedWidth': minimumTapTargetSize,
            'recommendedHeight': minimumTapTargetSize,
            'widgetType': renderObject.runtimeType.toString(),
          },
        );
        issues.add(issue);
        //print(
        // 'Debug: Added tap target issue to list. Total issues: ${issues.length}');
      }
    }

    return issues;
  }

  bool _isInteractiveElement(RenderObject renderObject) {
    final String typeName = renderObject.runtimeType.toString().toLowerCase();

    // Check for common interactive render objects
    if (renderObject is RenderPointerListener ||
        typeName.contains('button') ||
        typeName.contains('gesture') ||
        typeName.contains('inkwell') ||
        typeName.contains('ink') ||
        typeName.contains('tap') ||
        typeName.contains('pointer')) {
      return true;
    }

    // Check semantics for interactive behavior
    final semantics = renderObject.debugSemantics;
    final semanticsData = semantics?.getSemanticsData();
    if ((semanticsData?.hasAction(SemanticsAction.tap) == true) ||
        semantics?.hasFlag(SemanticsFlag.isButton) == true ||
        semantics?.hasFlag(SemanticsFlag.isLink) == true) {
      return true;
    }
    // If semantics is null or doesn't have actions, it's not interactive
    if (semantics == null) {
      return false;
    }
    // Fallback: check if any actions are available (for newer Flutter versions)
    if (semantics.getSemanticsData().hasAction(SemanticsAction.tap)) {
      return true;
    }
    return false;
  }

  AccessibilityIssueSeverity _calculateSeverity(Size size) {
    final minDimension = size.width < size.height ? size.width : size.height;

    if (minDimension < 24.0) {
      return AccessibilityIssueSeverity.critical;
    } else if (minDimension < 32.0) {
      return AccessibilityIssueSeverity.high;
    } else if (minDimension < 40.0) {
      return AccessibilityIssueSeverity.medium;
    } else {
      return AccessibilityIssueSeverity.low;
    }
  }
}
