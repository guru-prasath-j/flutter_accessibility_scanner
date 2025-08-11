import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../accessibility_scanner.dart';
import '../models/accessibility_issue.dart';
import '../utils/color_contrast_utils.dart';

/// Detects text with poor color contrast against backgrounds.
class ContrastDetector extends AccessibilityDetector {
  @override
  Future<List<AccessibilityIssue>> detect(RenderObject renderObject) async {
    final List<AccessibilityIssue> issues = [];

    if (renderObject is RenderParagraph) {
      final textStyle = renderObject.text.style;
      if (textStyle?.color != null) {
        final backgroundColor = _estimateBackgroundColor(renderObject);
        if (backgroundColor != null) {
          final contrastRatio = ColorContrastUtils.calculateContrastRatio(
            textStyle!.color!,
            backgroundColor,
          );

          final isLargeText = _isLargeText(textStyle);
          final meetsStandard = ColorContrastUtils.meetsWCAGAA(contrastRatio,
              isLargeText: isLargeText);

          if (!meetsStandard) {
            final suggestedColor = ColorContrastUtils.suggestBetterColor(
              textStyle.color!,
              backgroundColor,
              isLargeText: isLargeText,
            );

            issues.add(AccessibilityIssue(
              type: AccessibilityIssueType.poorColorContrast,
              description:
                  'Text color contrast ratio ${contrastRatio.toStringAsFixed(1)} does not meet WCAG AA standards',
              severity: contrastRatio < 3.0
                  ? AccessibilityIssueSeverity.critical
                  : AccessibilityIssueSeverity.high,
              suggestion:
                  'Use a color with better contrast. Suggested: ${_colorToHex(suggestedColor)}',
              bounds: renderObject.paintBounds,
              metadata: {
                'contrastRatio': contrastRatio,
                'foregroundColor': _colorToHex(textStyle.color!),
                'backgroundColor': _colorToHex(backgroundColor),
                'suggestedColor': _colorToHex(suggestedColor),
                'isLargeText': isLargeText,
                'requiredRatio': isLargeText
                    ? ColorContrastUtils.wcagAALarge
                    : ColorContrastUtils.wcagAA,
              },
            ));
          }
        }
      }
    }

    return issues;
  }

  Color? _estimateBackgroundColor(RenderObject renderObject) {
    // Try to find background color from parent containers
    RenderObject? parent = renderObject.parent as RenderObject?;
    while (parent != null) {
      if (parent is RenderDecoratedBox) {
        final decoration = parent.decoration;
        if (decoration is BoxDecoration && decoration.color != null) {
          return decoration.color;
        }
      }
      parent = parent.parent as RenderObject?;
    }

    // Default to white background if we can't determine
    return Colors.white;
  }

  bool _isLargeText(TextStyle textStyle) {
    final fontSize = textStyle.fontSize ?? 14.0;
    final fontWeight = textStyle.fontWeight ?? FontWeight.normal;

    // WCAG considers text large if it's 18pt+ or 14pt+ bold
    return fontSize >= 18.0 ||
        (fontSize >= 14.0 && fontWeight.index >= FontWeight.bold.index);
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}
