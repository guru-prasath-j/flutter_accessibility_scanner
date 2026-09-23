import 'package:flutter/rendering.dart';

import '../accessibility_scanner.dart';
import '../models/accessibility_issue.dart';
import '../utils/render_tree_utils.dart';

/// Detects interactive elements whose touch area is smaller than recommended.
///
/// The default of 48x48 logical pixels follows the Material and Android
/// guidelines; iOS recommends 44x44 and WCAG 2.2 (2.5.8) requires at least
/// 24x24. Pass [minimumSize] to match your platform target.
class TapTargetDetector extends AccessibilityDetector {
  /// Creates the detector.
  const TapTargetDetector({this.minimumSize = minimumTapTargetSize});

  /// The default minimum tap target edge, in logical pixels.
  static const double minimumTapTargetSize = 48.0;

  /// The minimum tap target edge this detector enforces.
  final double minimumSize;

  @override
  Future<List<AccessibilityIssue>> detect(RenderObject renderObject) async {
    if (!RenderTreeUtils.isTapHandler(renderObject) ||
        renderObject is! RenderBox ||
        !renderObject.hasSize) {
      return const [];
    }

    final size = RenderTreeUtils.effectiveTapSize(renderObject);
    if (size.width >= minimumSize && size.height >= minimumSize) {
      return const [];
    }

    final min = minimumSize.toStringAsFixed(0);
    return [
      AccessibilityIssue(
        type: AccessibilityIssueType.smallTapTarget,
        description: 'Tap target is ${size.width.toStringAsFixed(0)}x'
            '${size.height.toStringAsFixed(0)}, smaller than the recommended '
            '${min}x$min',
        severity: _severityFor(size),
        suggestion: 'Increase the tap target to at least ${min}x$min using '
            'padding or ConstrainedBox(constraints: BoxConstraints(minWidth: '
            '$min, minHeight: $min))',
        bounds: RenderTreeUtils.globalBounds(renderObject),
        wcagCriterion: '2.5.5 Target Size',
        metadata: {
          'currentWidth': size.width,
          'currentHeight': size.height,
          'recommendedWidth': minimumSize,
          'recommendedHeight': minimumSize,
          'widgetType': renderObject.runtimeType.toString(),
        },
      ),
    ];
  }

  AccessibilityIssueSeverity _severityFor(Size size) {
    final smallest = size.shortestSide;
    if (smallest < 24.0) return AccessibilityIssueSeverity.critical;
    if (smallest < 32.0) return AccessibilityIssueSeverity.high;
    if (smallest < 40.0) return AccessibilityIssueSeverity.medium;
    return AccessibilityIssueSeverity.low;
  }
}
