import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Utilities for calculating color contrast ratios according to WCAG 2.1.
class ColorContrastUtils {
  const ColorContrastUtils._();

  /// WCAG AA minimum contrast ratio for normal text.
  static const double wcagAA = 4.5;

  /// WCAG AA minimum contrast ratio for large text (18pt+ or 14pt+ bold) and
  /// for non-text content such as icons (WCAG 1.4.11).
  static const double wcagAALarge = 3.0;

  /// WCAG AAA contrast ratio for normal text.
  static const double wcagAAA = 7.0;

  /// WCAG AAA contrast ratio for large text.
  static const double wcagAAALarge = 4.5;

  static const Color _black = Color(0xFF000000);
  static const Color _white = Color(0xFFFFFFFF);

  /// Calculates the contrast ratio between two opaque colors.
  ///
  /// Returns a value between 1.0 (no contrast) and 21.0 (maximum contrast).
  /// Alpha is ignored; use [composite] first for translucent colors.
  static double calculateContrastRatio(Color color1, Color color2) {
    final luminance1 = relativeLuminance(color1);
    final luminance2 = relativeLuminance(color2);

    final lighter = math.max(luminance1, luminance2);
    final darker = math.min(luminance1, luminance2);

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// The relative luminance of [color] according to the WCAG formula, from
  /// 0.0 (black) to 1.0 (white).
  static double relativeLuminance(Color color) {
    final r = _linearize(color.r);
    final g = _linearize(color.g);
    final b = _linearize(color.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _linearize(double component) {
    if (component <= 0.03928) {
      return component / 12.92;
    }
    return math.pow((component + 0.055) / 1.055, 2.4).toDouble();
  }

  /// Paints [foreground] over [background] and returns the visible color.
  ///
  /// Use this before measuring contrast when the text color is translucent.
  static Color composite(Color foreground, Color background) =>
      Color.alphaBlend(foreground, background);

  /// Checks if the contrast ratio meets WCAG AA standards.
  static bool meetsWCAGAA(double contrastRatio, {bool isLargeText = false}) {
    return contrastRatio >= (isLargeText ? wcagAALarge : wcagAA);
  }

  /// Checks if the contrast ratio meets WCAG AAA standards.
  static bool meetsWCAGAAA(double contrastRatio, {bool isLargeText = false}) {
    return contrastRatio >= (isLargeText ? wcagAAALarge : wcagAAA);
  }

  /// Returns the highest WCAG conformance level a [contrastRatio] reaches:
  /// `AAA`, `AA`, or `Fail`.
  static String wcagLevel(double contrastRatio, {bool isLargeText = false}) {
    if (meetsWCAGAAA(contrastRatio, isLargeText: isLargeText)) return 'AAA';
    if (meetsWCAGAA(contrastRatio, isLargeText: isLargeText)) return 'AA';
    return 'Fail';
  }

  /// Formats [color] as a `#RRGGBB` hex string.
  static String toHex(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  /// Suggests the closest color to [foreground] that meets the WCAG AA ratio
  /// against [background].
  ///
  /// The foreground is moved towards black on light backgrounds and towards
  /// white on dark ones (falling back to the other direction if needed), using
  /// the smallest change that passes. Returns [foreground] unchanged when it
  /// already passes.
  static Color suggestBetterColor(
    Color foreground,
    Color background, {
    bool isLargeText = false,
  }) {
    final targetRatio = isLargeText ? wcagAALarge : wcagAA;
    if (calculateContrastRatio(foreground, background) >= targetRatio) {
      return foreground;
    }

    // Aim slightly above the threshold so rounding never lands us below it.
    final searchTarget = targetRatio + 0.05;
    final lightBackground = relativeLuminance(background) > 0.5;
    final first = lightBackground ? _black : _white;
    final second = lightBackground ? _white : _black;

    return _towards(foreground, background, first, searchTarget) ??
        _towards(foreground, background, second, searchTarget) ??
        (calculateContrastRatio(_black, background) >=
                calculateContrastRatio(_white, background)
            ? _black
            : _white);
  }

  static Color? _towards(
    Color foreground,
    Color background,
    Color extreme,
    double target,
  ) {
    if (calculateContrastRatio(extreme, background) < target) return null;
    var low = 0.0;
    var high = 1.0;
    for (var i = 0; i < 24; i++) {
      final mid = (low + high) / 2;
      final candidate = Color.lerp(foreground, extreme, mid)!;
      if (calculateContrastRatio(candidate, background) >= target) {
        high = mid;
      } else {
        low = mid;
      }
    }
    return Color.lerp(foreground, extreme, high)!.withValues(alpha: 1);
  }
}
