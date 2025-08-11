import 'dart:convert';

import 'accessibility_issue.dart';

/// Contains the results of an accessibility scan.
class AccessibilityReport {
  final DateTime timestamp;
  final int totalIssues;
  final List<AccessibilityIssue> issues;

  const AccessibilityReport({
    required this.timestamp,
    required this.totalIssues,
    required this.issues,
  });

  /// Groups issues by severity level.
  Map<AccessibilityIssueSeverity, List<AccessibilityIssue>>
      get issuesBySeverity {
    final Map<AccessibilityIssueSeverity, List<AccessibilityIssue>> grouped =
        {};
    for (final issue in issues) {
      grouped.putIfAbsent(issue.severity, () => []).add(issue);
    }
    return grouped;
  }

  /// Converts the report to JSON format.
  String toJson() {
    return jsonEncode({
      'timestamp': timestamp.toIso8601String(),
      'totalIssues': totalIssues,
      'issuesBySeverity': {
        'critical':
            issuesBySeverity[AccessibilityIssueSeverity.critical]?.length ?? 0,
        'high': issuesBySeverity[AccessibilityIssueSeverity.high]?.length ?? 0,
        'medium':
            issuesBySeverity[AccessibilityIssueSeverity.medium]?.length ?? 0,
        'low': issuesBySeverity[AccessibilityIssueSeverity.low]?.length ?? 0,
      },
      'issues': issues.map((issue) => issue.toJson()).toList(),
    });
  }

  /// Creates a human-readable summary of the report.
  String get summary {
    final buffer = StringBuffer();
    buffer.writeln('Accessibility Scan Report');
    buffer.writeln('Generated: ${timestamp.toString()}');
    buffer.writeln('Total Issues: $totalIssues');

    if (totalIssues > 0) {
      buffer.writeln('\nIssues by Severity:');
      for (final severity in AccessibilityIssueSeverity.values) {
        final count = issuesBySeverity[severity]?.length ?? 0;
        if (count > 0) {
          buffer.writeln('  ${severity.name}: $count');
        }
      }
    }

    return buffer.toString();
  }
}
