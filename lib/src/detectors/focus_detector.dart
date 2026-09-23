import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../accessibility_scanner.dart';
import '../models/accessibility_issue.dart';
import '../utils/render_tree_utils.dart';

/// Detects interactive elements that keyboard and switch users cannot reach.
///
/// `InkWell`, Material buttons and other focus-aware widgets pass. A bare
/// `GestureDetector` is reported, because it never takes keyboard focus.
class FocusDetector extends AccessibilityDetector {
  /// Creates the detector.
  const FocusDetector();

  @override
  Future<List<AccessibilityIssue>> detect(RenderObject renderObject) async {
    if (!RenderTreeUtils.isTapHandler(renderObject) ||
        _hasFocusSupport(renderObject)) {
      return const [];
    }

    return [
      AccessibilityIssue(
        type: AccessibilityIssueType.missingFocusSupport,
        description: 'Interactive element cannot receive keyboard focus',
        severity: AccessibilityIssueSeverity.medium,
        suggestion: 'Use InkWell or a Material button instead of '
            'GestureDetector, or wrap it in FocusableActionDetector',
        bounds: RenderTreeUtils.globalBounds(renderObject),
        wcagCriterion: '2.1.1 Keyboard',
        metadata: {'widgetType': renderObject.runtimeType.toString()},
      ),
    ];
  }

  bool _hasFocusSupport(RenderObject handler) {
    // Focus widgets annotate semantics with their `focused` state, which is
    // only set on focusable nodes.
    for (final ancestor in RenderTreeUtils.ancestors(handler, maxDepth: 12)) {
      if (ancestor is RenderSemanticsAnnotations &&
          ancestor.properties.focused != null) {
        return true;
      }
    }
    if (RenderTreeUtils.anyInSemanticsSubtree(
      handler,
      (node) =>
          node is RenderEditable ||
          (node is RenderSemanticsAnnotations &&
              node.properties.focused != null),
      maxDepth: 8,
    )) {
      return true;
    }

    // In debug builds we can also look for a Focus widget directly.
    final element = RenderTreeUtils.creatorElement(handler);
    if (element == null) return false;
    var found = false;
    var steps = 0;
    element.visitAncestorElements((ancestor) {
      final widget = ancestor.widget;
      if (widget is Focus && widget is! FocusScope) {
        found = widget.canRequestFocus != false;
        return false;
      }
      return ++steps < 30;
    });
    return found;
  }
}
