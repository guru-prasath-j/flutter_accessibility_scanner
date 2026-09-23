import 'package:flutter/rendering.dart';

import '../accessibility_scanner.dart';
import '../models/accessibility_issue.dart';
import '../utils/render_tree_utils.dart';

/// Detects images that are exposed to screen readers without a description.
///
/// Images built with `excludeFromSemantics: true` are treated as decorative
/// and are not reported.
class ImageLabelDetector extends AccessibilityDetector {
  /// Creates the detector.
  const ImageLabelDetector();

  @override
  Future<List<AccessibilityIssue>> detect(RenderObject renderObject) async {
    if (renderObject is! RenderImage) return const [];

    RenderSemanticsAnnotations? imageSemantics;
    for (final ancestor
        in RenderTreeUtils.ancestors(renderObject, maxDepth: 6)) {
      if (ancestor is RenderSemanticsAnnotations &&
          ancestor.properties.image == true) {
        imageSemantics = ancestor;
        break;
      }
    }
    if (imageSemantics == null) return const [];
    if (RenderTreeUtils.hasName(imageSemantics.properties)) return const [];

    // An unlabeled image inside a labeled button is fine.
    for (final ancestor
        in RenderTreeUtils.ancestors(imageSemantics, maxDepth: 12)) {
      if (ancestor is RenderSemanticsAnnotations &&
          RenderTreeUtils.hasName(ancestor.properties)) {
        return const [];
      }
    }

    return [
      AccessibilityIssue(
        type: AccessibilityIssueType.missingSemanticsLabel,
        description: 'Image has no description for screen readers',
        severity: AccessibilityIssueSeverity.medium,
        suggestion: 'Set Image.semanticLabel, or excludeFromSemantics: true '
            'if the image is purely decorative',
        bounds: RenderTreeUtils.globalBounds(renderObject),
        wcagCriterion: '1.1.1 Non-text Content',
        metadata: {
          'widgetType': renderObject.runtimeType.toString(),
          'element': 'image',
        },
      ),
    ];
  }
}
