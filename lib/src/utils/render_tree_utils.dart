import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Internal helpers for inspecting the render tree. Not exported.
class RenderTreeUtils {
  const RenderTreeUtils._();

  /// Whether [node] is a gesture handler that reacts to taps or long presses,
  /// which is what `GestureDetector`, `InkWell` and every Material button
  /// create under the hood.
  static bool isTapHandler(RenderObject node) =>
      node is RenderSemanticsGestureHandler &&
      (node.onTap != null || node.onLongPress != null);

  /// Walks up from [node] (exclusive), at most [maxDepth] levels.
  static Iterable<RenderObject> ancestors(
    RenderObject node, {
    int maxDepth = 12,
  }) sync* {
    var parent = node.parent;
    var depth = 0;
    while (parent != null && depth < maxDepth) {
      yield parent;
      parent = parent.parent;
      depth++;
    }
  }

  /// Whether [node] or anything below it (skipping subtrees excluded from
  /// semantics) satisfies [test]. Stops after [maxDepth] levels.
  static bool anyInSemanticsSubtree(
    RenderObject node,
    bool Function(RenderObject) test, {
    int maxDepth = 40,
  }) {
    if (test(node)) return true;
    if (maxDepth == 0) return false;
    if (node is RenderExcludeSemantics && node.excluding) return false;
    var found = false;
    node.visitChildrenForSemantics((child) {
      if (!found) {
        found = anyInSemanticsSubtree(child, test, maxDepth: maxDepth - 1);
      }
    });
    return found;
  }

  /// Whether [properties] give the element an accessible name.
  static bool hasName(SemanticsProperties properties) {
    bool notEmpty(String? s) => s != null && s.trim().isNotEmpty;
    return notEmpty(properties.label) ||
        notEmpty(properties.attributedLabel?.string) ||
        notEmpty(properties.tooltip) ||
        notEmpty(properties.value);
  }

  /// Whether [node] itself provides readable text or an explicit label.
  static bool providesName(RenderObject node) {
    if (node is RenderSemanticsAnnotations && hasName(node.properties)) {
      return true;
    }
    if (node is RenderParagraph) {
      return node.text
          .toPlainText(includeSemanticsLabels: true)
          .trim()
          .isNotEmpty;
    }
    if (node is RenderEditable) return true;
    return false;
  }

  /// Whether the interactive [handler] has an accessible name, either from
  /// its own content, a `Semantics`/`Tooltip` ancestor, or the subtree of an
  /// enclosing `MergeSemantics` (as used by `CheckboxListTile` and friends).
  static bool hasAccessibleName(RenderObject handler) {
    if (anyInSemanticsSubtree(handler, providesName)) return true;
    for (final ancestor in ancestors(handler, maxDepth: 30)) {
      if (ancestor is RenderSemanticsAnnotations &&
          hasName(ancestor.properties)) {
        return true;
      }
      if (ancestor is RenderMergeSemantics) {
        return anyInSemanticsSubtree(ancestor, providesName);
      }
    }
    return false;
  }

  /// The element (widget instance) that created [node], available in debug
  /// and profile-with-asserts builds only.
  static Element? creatorElement(RenderObject node) {
    final creator = node.debugCreator;
    return creator is DebugCreator ? creator.element : null;
  }

  /// [node]'s paint bounds in global coordinates when possible.
  static Rect globalBounds(RenderObject node) {
    try {
      if (node.attached) {
        return MatrixUtils.transformRect(
          node.getTransformTo(null),
          node.paintBounds,
        );
      }
    } catch (_) {
      // Fall through to local bounds.
    }
    return node.paintBounds;
  }

  /// The size a user can actually hit for [handler], accounting for the
  /// invisible padding Material adds around small buttons to reach 48x48.
  static Size effectiveTapSize(RenderBox handler) {
    var width = handler.size.width;
    var height = handler.size.height;
    for (final ancestor in ancestors(handler, maxDepth: 6)) {
      if (ancestor is RenderBox &&
          ancestor.hasSize &&
          ancestor.runtimeType.toString().contains('InputPadding')) {
        if (ancestor.size.width > width) width = ancestor.size.width;
        if (ancestor.size.height > height) height = ancestor.size.height;
      }
    }
    return Size(width, height);
  }
}
