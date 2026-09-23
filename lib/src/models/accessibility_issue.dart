import 'dart:ui' show Rect;

/// Represents an accessibility issue found during scanning.
class AccessibilityIssue {
  /// Creates an issue.
  const AccessibilityIssue({
    required this.type,
    required this.description,
    required this.severity,
    this.suggestion,
    this.metadata,
    this.bounds,
    this.wcagCriterion,
  });

  /// The category of the problem.
  final AccessibilityIssueType type;

  /// A human-readable description of the problem.
  final String description;

  /// How badly the problem affects users.
  final AccessibilityIssueSeverity severity;

  /// An actionable suggestion for fixing the problem, if available.
  final String? suggestion;

  /// Extra machine-readable details (sizes, colors, widget type, ...).
  final Map<String, dynamic>? metadata;

  /// Where the offending element is drawn, in global (screen) coordinates
  /// when the render object was attached at scan time.
  final Rect? bounds;

  /// The WCAG 2.1 success criterion this issue relates to, for example
  /// `1.4.3 Contrast (Minimum)`.
  final String? wcagCriterion;

  /// The runtime type of the render object that produced the issue, if known.
  String? get widgetType => metadata?['widgetType'] as String?;

  /// Converts the issue to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    final rect = bounds;
    return {
      'type': type.toString(),
      'description': description,
      'severity': severity.toString(),
      'suggestion': suggestion,
      'wcagCriterion': wcagCriterion,
      'metadata': metadata,
      'bounds': rect != null
          ? {
              'left': rect.left,
              'top': rect.top,
              'right': rect.right,
              'bottom': rect.bottom,
            }
          : null,
    };
  }

  @override
  String toString() =>
      'AccessibilityIssue(${type.name}, ${severity.name}: $description)';
}

/// The categories of accessibility problems the scanner can report.
enum AccessibilityIssueType {
  /// An interactive element or image has no accessible name.
  missingSemanticsLabel,

  /// Text (or an icon) does not have enough contrast with its background.
  poorColorContrast,

  /// An interactive element is smaller than the recommended touch size.
  smallTapTarget,

  /// An interactive element cannot be reached with a keyboard or switch.
  missingFocusSupport,

  /// Content that would benefit from an extra screen reader hint.
  missingScreenReaderHint,
}

/// How severely an issue affects users, from least to most severe.
enum AccessibilityIssueSeverity {
  /// Minor polish.
  low,

  /// Noticeable friction for some users.
  medium,

  /// Blocks or seriously hinders some users.
  high,

  /// Makes content unusable for some users.
  critical;

  /// Whether this severity is at least as severe as [other].
  bool isAtLeast(AccessibilityIssueSeverity other) => index >= other.index;
}
