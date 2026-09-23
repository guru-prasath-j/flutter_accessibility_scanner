import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../accessibility_scanner.dart';
import '../models/accessibility_issue.dart';
import '../utils/color_contrast_utils.dart';
import '../utils/render_tree_utils.dart';

/// Detects text and icons with poor color contrast against their background.
///
/// The background is estimated from the nearest painted ancestor: a
/// `Container`/`DecoratedBox` color, a `ColoredBox` (debug builds), or a
/// `Material`, `Card` or `Scaffold` surface. Translucent layers are blended.
/// Text uses the WCAG 1.4.3 thresholds (4.5:1, or 3:1 for large text); icon
/// glyphs use the 3:1 non-text threshold from WCAG 1.4.11.
class ContrastDetector extends AccessibilityDetector {
  /// Creates the detector. [fallbackBackground] is assumed when no painted
  /// ancestor can be found.
  const ContrastDetector({
    this.fallbackBackground = const Color(0xFFFFFFFF),
  });

  /// The background assumed when none can be determined.
  final Color fallbackBackground;

  @override
  Future<List<AccessibilityIssue>> detect(RenderObject renderObject) async {
    if (renderObject is! RenderParagraph) return const [];

    final style = renderObject.text.style;
    final textColor = style?.color;
    if (style == null || textColor == null || textColor.a == 0) {
      return const [];
    }
    final plain = renderObject.text.toPlainText();
    if (plain.trim().isEmpty) return const [];

    final (background, assumed) = _estimateBackground(renderObject);
    final foreground = ColorContrastUtils.composite(textColor, background);
    final ratio = ColorContrastUtils.calculateContrastRatio(
      foreground,
      background,
    );

    final isIcon = _isIconGlyph(plain);
    final isLargeText = isIcon || _isLargeText(style, renderObject.textScaler);
    if (ColorContrastUtils.meetsWCAGAA(ratio, isLargeText: isLargeText)) {
      return const [];
    }

    final suggested = ColorContrastUtils.suggestBetterColor(
      foreground,
      background,
      isLargeText: isLargeText,
    );
    final required = isLargeText
        ? ColorContrastUtils.wcagAALarge
        : ColorContrastUtils.wcagAA;
    final what = isIcon ? 'Icon' : 'Text';

    return [
      AccessibilityIssue(
        type: AccessibilityIssueType.poorColorContrast,
        description: '$what contrast ratio ${ratio.toStringAsFixed(2)}:1 is '
            'below the WCAG AA minimum of ${required.toStringAsFixed(1)}:1',
        severity: ratio < 3.0
            ? AccessibilityIssueSeverity.critical
            : AccessibilityIssueSeverity.high,
        suggestion: 'Use a color with more contrast, for example '
            '${ColorContrastUtils.toHex(suggested)}',
        bounds: RenderTreeUtils.globalBounds(renderObject),
        wcagCriterion:
            isIcon ? '1.4.11 Non-text Contrast' : '1.4.3 Contrast (Minimum)',
        metadata: {
          'widgetType': renderObject.runtimeType.toString(),
          'contrastRatio': ratio,
          'foregroundColor': ColorContrastUtils.toHex(foreground),
          'backgroundColor': ColorContrastUtils.toHex(background),
          'backgroundAssumed': assumed,
          'suggestedColor': ColorContrastUtils.toHex(suggested),
          'isLargeText': isLargeText,
          'isIcon': isIcon,
          'requiredRatio': required,
          if (!isIcon)
            'text': plain.length > 60 ? plain.substring(0, 60) : plain,
        },
      ),
    ];
  }

  /// Returns the estimated opaque background and whether it was assumed.
  (Color, bool) _estimateBackground(RenderObject node) {
    final layers = <Color>[];
    Color? base;
    for (final ancestor in RenderTreeUtils.ancestors(node, maxDepth: 1 << 30)) {
      final color = _paintedColor(ancestor);
      if (color == null || color.a == 0) continue;
      if (color.a >= 1) {
        base = color;
        break;
      }
      layers.add(color);
    }
    final assumed = base == null;
    var result = base ?? fallbackBackground;
    for (final layer in layers.reversed) {
      result = ColorContrastUtils.composite(layer, result);
    }
    return (result, assumed);
  }

  Color? _paintedColor(RenderObject node) {
    if (node is RenderDecoratedBox) {
      final decoration = node.decoration;
      if (decoration is BoxDecoration &&
          decoration.color != null &&
          node.position == DecorationPosition.background) {
        return decoration.color;
      }
      return null;
    }
    if (node is RenderPhysicalModel) return node.color;
    if (node is RenderPhysicalShape) return node.color;
    final widget = RenderTreeUtils.creatorElement(node)?.widget;
    if (widget is ColoredBox) return widget.color;
    return null;
  }

  bool _isLargeText(TextStyle style, TextScaler scaler) {
    final fontSize = scaler.scale(style.fontSize ?? 14.0);
    final weight = style.fontWeight ?? FontWeight.normal;
    final bold = FontWeight.values.indexOf(weight) >=
        FontWeight.values.indexOf(FontWeight.bold);
    // WCAG "large": 18pt (24 logical px) or 14pt (~18.66 px) bold.
    return fontSize >= 24.0 || (bold && fontSize >= 18.66);
  }

  bool _isIconGlyph(String text) {
    final runes = text.runes.toList();
    if (runes.length != 1) return false;
    final code = runes.single;
    // Icon fonts (Material Icons, Cupertino Icons) use Private Use Areas.
    return (code >= 0xE000 && code <= 0xF8FF) || code >= 0xF0000;
  }
}
