import 'package:flutter/material.dart';
import 'package:flutter_accessibility_scanner/flutter_accessibility_scanner.dart';

/// Package facts shown in the UI.
abstract final class AppInfo {
  static const packageName = 'flutter_accessibility_scanner';
  static const version = '1.2.0';
  static const license = 'MIT';
  static const repository =
      'https://github.com/guru-prasath-j/flutter_accessibility_scanner';
}

String capitalize(String s) => '${s[0].toUpperCase()}${s.substring(1)}';

/// Brand colours shared by light and dark mode (PocketMind design language).
abstract final class AppColors {
  static const primary = Color(0xFF8B5CF6);
  static const primaryDeep = Color(0xFF6D28D9);
  static const lavender = Color(0xFFB9A5F8);
  static const lavenderLight = Color(0xFFD7CBFF);
  static const onLavender = Color(0xFF1A1438);
  static const danger = Color(0xFFEF4444);
  static const amber = Color(0xFFF59E0B);
  static const success = Color(0xFF22C55E);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9F7AFA), Color(0xFF6D28D9)],
  );
}

/// Theme-dependent colour tokens. Read with `context.colors`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.backgroundDeep,
    required this.surface,
    required this.surfaceHigh,
    required this.surfaceHighest,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.glowStrength,
    required this.textGradient,
    required this.dangerText,
    required this.amberText,
    required this.successText,
  });

  final Color background;
  final Color backgroundDeep;
  final Color surface;
  final Color surfaceHigh;
  final Color surfaceHighest;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final double glowStrength;
  final Gradient textGradient;

  /// Readable foregrounds for tinted status pills.
  final Color dangerText;
  final Color amberText;
  final Color successText;

  static const dark = AppPalette(
    background: Color(0xFF0B0A18),
    backgroundDeep: Color(0xFF07060F),
    surface: Color(0xFF15132A),
    surfaceHigh: Color(0xFF1D1A38),
    surfaceHighest: Color(0xFF262248),
    border: Color(0xFF2A2650),
    borderStrong: Color(0xFF3A3470),
    textPrimary: Color(0xFFF4F2FF),
    textSecondary: Color(0xFFB0AACF),
    textMuted: Color(0xFF7A7499),
    accent: AppColors.lavender,
    glowStrength: 1,
    textGradient: LinearGradient(
      colors: [Color(0xFFC4B1FF), Color(0xFF9B6BFA)],
    ),
    dangerText: Color(0xFFFCA5A5),
    amberText: Color(0xFFFCD34D),
    successText: Color(0xFF86EFAC),
  );

  static const light = AppPalette(
    background: Color(0xFFF7F5FF),
    backgroundDeep: Color(0xFFEEEAFB),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFF2EEFF),
    surfaceHighest: Color(0xFFE7E0FF),
    border: Color(0xFFE2DCF5),
    borderStrong: Color(0xFFCBC1EC),
    textPrimary: Color(0xFF15122B),
    textSecondary: Color(0xFF575173),
    textMuted: Color(0xFF8A84A6),
    accent: Color(0xFF6D28D9),
    glowStrength: 0.45,
    textGradient: LinearGradient(
      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    ),
    dangerText: Color(0xFFB91C1C),
    amberText: Color(0xFF92400E),
    successText: Color(0xFF15803D),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: c(background, other.background),
      backgroundDeep: c(backgroundDeep, other.backgroundDeep),
      surface: c(surface, other.surface),
      surfaceHigh: c(surfaceHigh, other.surfaceHigh),
      surfaceHighest: c(surfaceHighest, other.surfaceHighest),
      border: c(border, other.border),
      borderStrong: c(borderStrong, other.borderStrong),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textMuted: c(textMuted, other.textMuted),
      accent: c(accent, other.accent),
      glowStrength: glowStrength + (other.glowStrength - glowStrength) * t,
      textGradient: t < 0.5 ? textGradient : other.textGradient,
      dangerText: c(dangerText, other.dangerText),
      amberText: c(amberText, other.amberText),
      successText: c(successText, other.successText),
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// Current theme's colour tokens.
  AppPalette get colors => Theme.of(this).extension<AppPalette>()!;
}

abstract final class AppRadius {
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 24;
  static const double pill = 100;
}

abstract final class AppTheme {
  static ThemeData dark() => _build(Brightness.dark, AppPalette.dark);

  static ThemeData light() => _build(Brightness.light, AppPalette.light);

  static ThemeData _build(Brightness brightness, AppPalette p) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: isDark ? AppColors.primaryDeep : p.surfaceHighest,
      onPrimaryContainer:
          isDark ? AppColors.lavenderLight : AppColors.primaryDeep,
      secondary: p.accent,
      onSecondary: isDark ? AppColors.onLavender : Colors.white,
      surface: p.background,
      onSurface: p.textPrimary,
      onSurfaceVariant: p.textSecondary,
      surfaceContainerLowest: p.backgroundDeep,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.surfaceHigh,
      surfaceContainerHighest: p.surfaceHighest,
      outline: p.borderStrong,
      outlineVariant: p.border,
      error: AppColors.danger,
      onError: Colors.white,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: [p],
    );
    final text = base.textTheme.apply(
      bodyColor: p.textPrimary,
      displayColor: p.textPrimary,
    );

    return base.copyWith(
      scaffoldBackgroundColor: p.background,
      textTheme: text.copyWith(
        headlineSmall: text.headlineSmall
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
        titleLarge: text.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        bodyLarge: text.bodyLarge?.copyWith(height: 1.5),
        bodyMedium: text.bodyMedium?.copyWith(height: 1.5),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      splashFactory: InkSparkle.splashFactory,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? p.surfaceHighest : p.textPrimary,
        contentTextStyle: TextStyle(color: isDark ? p.textPrimary : p.surface),
        actionTextColor: AppColors.lavender,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? p.surfaceHighest : p.textPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(color: isDark ? p.textPrimary : p.surface),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.surfaceHighest,
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : p.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary
              : p.surfaceHighest,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary
              : p.borderStrong,
        ),
      ),
    );
  }
}

/// Glowing violet tile with the accessibility mark + sparkle.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(size * 0.3),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary
                  .withValues(alpha: 0.5 * context.colors.glowStrength),
              blurRadius: size * 0.45,
              offset: Offset(0, size * 0.1),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.accessibility_new_rounded,
                color: Colors.white, size: size * 0.55),
            Positioned(
              top: size * 0.1,
              right: size * 0.1,
              child: Icon(Icons.auto_awesome,
                  color: Colors.white, size: size * 0.24),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints [text] with the theme's violet text gradient.
class GradientText extends StatelessWidget {
  const GradientText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: context.colors.textGradient.createShader,
      child: Text(text, style: style),
    );
  }
}

/// Soft violet glows behind the page. Purely visual.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [context.colors.background, context.colors.backgroundDeep],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: -160,
            bottom: -120,
            child: IgnorePointer(child: _Glow(size: 460, alpha: 0.16)),
          ),
          const Positioned(
            right: -140,
            top: -160,
            child: IgnorePointer(child: _Glow(size: 400, alpha: 0.12)),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.primary
                .withValues(alpha: alpha * context.colors.glowStrength),
            AppColors.primary.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

/// Round, softly filled icon button used in the header.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.size = 48,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: context.colors.surfaceHigh,
        shape: CircleBorder(side: BorderSide(color: context.colors.border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox.square(
            dimension: size,
            child: Icon(icon, size: 22, color: context.colors.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Pill-shaped primary action with the brand gradient and a soft glow.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled || loading ? 1 : 0.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary
                  .withValues(alpha: 0.45 * context.colors.glowStrength),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: enabled ? onPressed : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (loading)
                    const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  else if (icon != null)
                    Icon(icon, color: Colors.white, size: 22),
                  if (loading || icon != null) const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bordered surface card used throughout the page.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = AppRadius.md,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: context.colors.border),
      ),
      child: child,
    );
  }
}

/// Small tinted pill: icon + label.
class TintPill extends StatelessWidget {
  const TintPill({
    super.key,
    required this.label,
    required this.color,
    required this.textColor,
    this.icon,
  });

  final String label;
  final Color color;
  final Color textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section title with a gradient accent bar.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 44,
          margin: const EdgeInsets.only(right: 14),
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: colors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

/// (tint, readable text colour) for a severity.
(Color, Color) severityColors(
  BuildContext context,
  AccessibilityIssueSeverity severity,
) {
  final colors = context.colors;
  return switch (severity) {
    AccessibilityIssueSeverity.critical || AccessibilityIssueSeverity.high => (
        AppColors.danger,
        colors.dangerText
      ),
    AccessibilityIssueSeverity.medium => (AppColors.amber, colors.amberText),
    AccessibilityIssueSeverity.low => (AppColors.primary, colors.accent),
  };
}

/// Tinted pill in a severity's colour.
class SeverityPill extends StatelessWidget {
  const SeverityPill({super.key, required this.severity, required this.label});

  final AccessibilityIssueSeverity severity;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (tint, fg) = severityColors(context, severity);
    return TintPill(label: label, color: tint, textColor: fg);
  }
}
