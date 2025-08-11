import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Utilities for calculating color contrast ratios according to WCAG 2.1 guidelines.
class ColorContrastUtils {
  /// WCAG AA minimum contrast ratio for normal text.
  static const double wcagAA = 4.5;

  /// WCAG AA minimum contrast ratio for large text (18pt+ or 14pt+ bold).
  static const double wcagAALarge = 3.0;

  /// WCAG AAA contrast ratio for normal text.
  static const double wcagAAA = 7.0;

  /// WCAG AAA contrast ratio for large text.
  static const double wcagAAALarge = 4.5;

  /// Calculates the contrast ratio between two colors.
  /// Returns a value between 1.0 (no contrast) and 21.0 (maximum contrast).
  static double calculateContrastRatio(Color color1, Color color2) {
    final luminance1 = _calculateRelativeLuminance(color1);
    final luminance2 = _calculateRelativeLuminance(color2);

    final lighter = math.max(luminance1, luminance2);
    final darker = math.min(luminance1, luminance2);

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Calculates the relative luminance of a color according to WCAG formula.
  static double _calculateRelativeLuminance(Color color) {
    final r = _gammaCorrect(color.red / 255.0);
    final g = _gammaCorrect(color.green / 255.0);
    final b = _gammaCorrect(color.blue / 255.0);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Applies gamma correction to a color component.
  static double _gammaCorrect(double component) {
    if (component <= 0.03928) {
      return component / 12.92;
    } else {
      return math.pow((component + 0.055) / 1.055, 2.4).toDouble();
    }
  }

  /// Checks if the contrast ratio meets WCAG AA standards.
  static bool meetsWCAGAA(double contrastRatio, {bool isLargeText = false}) {
    return contrastRatio >= (isLargeText ? wcagAALarge : wcagAA);
  }

  /// Checks if the contrast ratio meets WCAG AAA standards.
  static bool meetsWCAGAAA(double contrastRatio, {bool isLargeText = false}) {
    return contrastRatio >= (isLargeText ? wcagAAALarge : wcagAAA);
  }

  /// Suggests a better color with improved contrast.
  static Color suggestBetterColor(Color foreground, Color background,
      {bool isLargeText = false}) {
    final currentRatio = calculateContrastRatio(foreground, background);
    final targetRatio = isLargeText ? wcagAALarge : wcagAA;

    if (currentRatio >= targetRatio) {
      return foreground; // Already meets standards
    }

    // Try darkening or lightening the foreground color
    final backgroundLuminance = _calculateRelativeLuminance(background);

    if (backgroundLuminance > 0.5) {
      // Light background, try darkening foreground
      return _adjustColorForContrast(foreground, background, targetRatio,
          darken: true);
    } else {
      // Dark background, try lightening foreground
      return _adjustColorForContrast(foreground, background, targetRatio,
          darken: false);
    }
  }

  static Color _adjustColorForContrast(
      Color foreground, Color background, double targetRatio,
      {required bool darken}) {
    Color adjusted = foreground;
    double currentRatio = calculateContrastRatio(adjusted, background);

    for (int i = 0; i < 10 && currentRatio < targetRatio; i++) {
      if (darken) {
        adjusted = Color.lerp(adjusted, Colors.black, 0.1) ?? adjusted;
      } else {
        adjusted = Color.lerp(adjusted, Colors.white, 0.1) ?? adjusted;
      }
      currentRatio = calculateContrastRatio(adjusted, background);
    }

    return adjusted;
  }
}
