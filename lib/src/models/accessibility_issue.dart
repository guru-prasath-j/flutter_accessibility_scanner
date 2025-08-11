import 'package:flutter/material.dart';

/// Represents an accessibility issue found during scanning.
class AccessibilityIssue {
  final AccessibilityIssueType type;
  final String description;
  final AccessibilityIssueSeverity severity;
  final String? suggestion;
  final Map<String, dynamic>? metadata;
  final Rect? bounds;

  const AccessibilityIssue({
    required this.type,
    required this.description,
    required this.severity,
    this.suggestion,
    this.metadata,
    this.bounds,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'description': description,
      'severity': severity.toString(),
      'suggestion': suggestion,
      'metadata': metadata,
      'bounds': bounds != null
          ? {
              'left': bounds!.left,
              'top': bounds!.top,
              'right': bounds!.right,
              'bottom': bounds!.bottom,
            }
          : null,
    };
  }
}

enum AccessibilityIssueType {
  missingSemanticsLabel,
  poorColorContrast,
  smallTapTarget,
  missingFocusSupport,
  missingScreenReaderHint,
}

enum AccessibilityIssueSeverity {
  low,
  medium,
  high,
  critical,
}
