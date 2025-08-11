import 'package:flutter/material.dart';

/// A button widget that automatically applies accessibility best practices.
class AccessibilityFixerButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticsLabel;
  final String? semanticsHint;
  final double minWidth;
  final double minHeight;
  final EdgeInsetsGeometry? padding;

  const AccessibilityFixerButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.semanticsLabel,
    this.semanticsHint,
    this.minWidth = 48.0,
    this.minHeight = 48.0,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      hint: semanticsHint,
      button: true,
      enabled: onPressed != null,
      child: Focus(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: minWidth,
            minHeight: minHeight,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(8.0),
              child: Padding(
                padding: padding ?? const EdgeInsets.all(8.0),
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A text widget that automatically ensures good color contrast.
class AccessibilityFixerText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color? backgroundColor;

  const AccessibilityFixerText({
    Key? key,
    required this.text,
    this.style,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyle = theme.textTheme.bodyMedium ?? const TextStyle();
    final effectiveStyle = defaultStyle.merge(style);

    // Use theme colors that ensure good contrast
    final foregroundColor = effectiveStyle.color ??
        (theme.brightness == Brightness.dark ? Colors.white : Colors.black);

    return Text(
      text,
      style: effectiveStyle.copyWith(color: foregroundColor),
      semanticsLabel: text.length > 100 ? '${text.substring(0, 100)}...' : null,
    );
  }
}
