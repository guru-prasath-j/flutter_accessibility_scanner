import 'package:flutter/material.dart';

import '../utils/color_contrast_utils.dart';

/// A button that applies accessibility best practices by default: a minimum
/// 48x48 tap target, button semantics with a label and hint, keyboard focus,
/// and an optional tooltip.
class AccessibilityFixerButton extends StatelessWidget {
  /// Creates an accessible button.
  const AccessibilityFixerButton({
    super.key,
    required this.child,
    this.onPressed,
    this.semanticsLabel,
    this.semanticsHint,
    this.tooltip,
    this.minWidth = 48.0,
    this.minHeight = 48.0,
    this.padding,
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    this.focusNode,
    this.autofocus = false,
  });

  /// The button content.
  final Widget child;

  /// Called when the button is activated. The button is disabled when null.
  final VoidCallback? onPressed;

  /// What screen readers announce for the button.
  final String? semanticsLabel;

  /// Extra screen reader guidance about what activating the button does.
  final String? semanticsHint;

  /// Optional tooltip, shown on long press and hover and read by screen
  /// readers.
  final String? tooltip;

  /// Minimum width of the tap target.
  final double minWidth;

  /// Minimum height of the tap target.
  final double minHeight;

  /// Padding around [child]. Defaults to 8 on every side.
  final EdgeInsetsGeometry? padding;

  /// Shape of the ink splash and focus highlight.
  final BorderRadius borderRadius;

  /// Optional focus node for the button.
  final FocusNode? focusNode;

  /// Whether the button should request focus when first built.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    Widget result = Semantics(
      label: semanticsLabel,
      hint: semanticsHint,
      button: true,
      enabled: onPressed != null,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth, minHeight: minHeight),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            focusNode: focusNode,
            autofocus: autofocus,
            borderRadius: borderRadius,
            child: Padding(
              padding: padding ?? const EdgeInsets.all(8.0),
              child: Center(widthFactor: 1, heightFactor: 1, child: child),
            ),
          ),
        ),
      ),
    );
    if (tooltip != null) {
      result = Tooltip(message: tooltip, child: result);
    }
    return result;
  }
}

/// A text widget that guarantees WCAG AA contrast.
///
/// When [backgroundColor] is given, the text color is adjusted (as little as
/// possible) until it meets the AA ratio against it. Otherwise the theme's
/// high-contrast on-surface color is used when [style] has no color.
class AccessibilityFixerText extends StatelessWidget {
  /// Creates accessible text.
  const AccessibilityFixerText({
    super.key,
    required this.text,
    this.style,
    this.backgroundColor,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  /// The text to display.
  final String text;

  /// Optional style, merged over the theme's `bodyMedium`.
  final TextStyle? style;

  /// The color the text is drawn on, used to enforce contrast.
  final Color? backgroundColor;

  /// How the text is aligned.
  final TextAlign? textAlign;

  /// Maximum number of lines.
  final int? maxLines;

  /// How visual overflow is handled.
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveStyle =
        (theme.textTheme.bodyMedium ?? const TextStyle()).merge(style);

    var foreground = style?.color ??
        (theme.brightness == Brightness.dark ? Colors.white : Colors.black);
    final background = backgroundColor;
    if (background != null) {
      final fontSize = effectiveStyle.fontSize ?? 14.0;
      final isLarge = fontSize >= 24.0;
      foreground = ColorContrastUtils.suggestBetterColor(
        ColorContrastUtils.composite(foreground, background),
        background,
        isLargeText: isLarge,
      );
    }

    return Text(
      text,
      style: effectiveStyle.copyWith(color: foreground),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
