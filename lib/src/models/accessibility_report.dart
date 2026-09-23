import 'dart:convert';

import 'accessibility_issue.dart';

/// Contains the results of an accessibility scan.
class AccessibilityReport {
  /// Creates a report.
  const AccessibilityReport({
    required this.timestamp,
    required this.totalIssues,
    required this.issues,
    this.scannedElements,
    this.scanDuration,
  });

  /// When the scan finished.
  final DateTime timestamp;

  /// The number of issues in [issues].
  final int totalIssues;

  /// Every issue found, most severe first when produced by the scanner.
  final List<AccessibilityIssue> issues;

  /// How many render objects were inspected, if known.
  final int? scannedElements;

  /// How long the scan took, if known.
  final Duration? scanDuration;

  /// Whether the scan found at least one issue.
  bool get hasIssues => issues.isNotEmpty;

  /// Groups issues by severity level.
  Map<AccessibilityIssueSeverity, List<AccessibilityIssue>>
      get issuesBySeverity {
    final grouped = <AccessibilityIssueSeverity, List<AccessibilityIssue>>{};
    for (final issue in issues) {
      grouped.putIfAbsent(issue.severity, () => []).add(issue);
    }
    return grouped;
  }

  /// Groups issues by type.
  Map<AccessibilityIssueType, List<AccessibilityIssue>> get issuesByType {
    final grouped = <AccessibilityIssueType, List<AccessibilityIssue>>{};
    for (final issue in issues) {
      grouped.putIfAbsent(issue.type, () => []).add(issue);
    }
    return grouped;
  }

  /// Returns the issues whose severity is at least [severity].
  List<AccessibilityIssue> issuesAtLeast(AccessibilityIssueSeverity severity) =>
      issues.where((i) => i.severity.isAtLeast(severity)).toList();

  /// Returns the issues of the given [type].
  List<AccessibilityIssue> issuesOfType(AccessibilityIssueType type) =>
      issues.where((i) => i.type == type).toList();

  /// Converts the report to a JSON-compatible map.
  Map<String, dynamic> toMap() {
    final bySeverity = issuesBySeverity;
    return {
      'timestamp': timestamp.toIso8601String(),
      'totalIssues': totalIssues,
      if (scannedElements != null) 'scannedElements': scannedElements,
      if (scanDuration != null)
        'scanDurationMs': scanDuration!.inMilliseconds,
      'issuesBySeverity': {
        for (final s in AccessibilityIssueSeverity.values.reversed)
          s.name: bySeverity[s]?.length ?? 0,
      },
      'issues': issues.map((issue) => issue.toJson()).toList(),
    };
  }

  /// Converts the report to a JSON string.
  String toJson() => jsonEncode(toMap());

  /// Creates a human-readable summary of the report.
  String get summary {
    final buffer = StringBuffer()
      ..writeln('Accessibility Scan Report')
      ..writeln('Generated: $timestamp')
      ..writeln('Total Issues: $totalIssues');

    if (totalIssues > 0) {
      buffer.writeln('\nIssues by Severity:');
      final bySeverity = issuesBySeverity;
      for (final severity in AccessibilityIssueSeverity.values) {
        final count = bySeverity[severity]?.length ?? 0;
        if (count > 0) {
          buffer.writeln('  ${severity.name}: $count');
        }
      }
    }

    return buffer.toString();
  }
}
