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

  /// Recreates a report from a map produced by [toMap], for example to compare
  /// a CI run against a saved baseline.
  factory AccessibilityReport.fromMap(Map<String, dynamic> map) {
    final rawIssues = map['issues'];
    final issues = <AccessibilityIssue>[
      if (rawIssues is List<dynamic>)
        for (final issue in rawIssues)
          AccessibilityIssue.fromJson(issue as Map<String, dynamic>),
    ];
    final ms = map['scanDurationMs'] as int?;
    return AccessibilityReport(
      timestamp: DateTime.parse(map['timestamp'] as String),
      totalIssues: map['totalIssues'] as int? ?? issues.length,
      issues: issues,
      scannedElements: map['scannedElements'] as int?,
      scanDuration: ms == null ? null : Duration(milliseconds: ms),
    );
  }

  /// Recreates a report from a string produced by [toJson].
  factory AccessibilityReport.fromJson(String source) {
    final map = jsonDecode(source) as Map<String, dynamic>;
    return AccessibilityReport.fromMap(map);
  }

  /// Version of the JSON layout written by [toMap]. Bumped when keys change
  /// meaning; new keys may be added without a bump.
  static const int jsonSchemaVersion = 2;

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

  /// Whether no issue reaches [failOn] severity.
  ///
  /// Use it as a CI gate: `expect(report.passes(), isTrue)` fails the test
  /// (and `flutter test` exits with a non-zero code) when a high or critical
  /// issue is found.
  bool passes({
    AccessibilityIssueSeverity failOn = AccessibilityIssueSeverity.high,
  }) {
    return issuesAtLeast(failOn).isEmpty;
  }

  /// Counts issues per WCAG success criterion, for example
  /// `{'1.4.3 Contrast (Minimum)': 2}`. Issues without a criterion are
  /// counted under `unspecified`.
  Map<String, int> get issueCountsByWcagCriterion {
    final counts = <String, int>{};
    for (final issue in issues) {
      final key = issue.wcagCriterion ?? 'unspecified';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  /// Converts the report to a JSON-compatible map.
  ///
  /// Keys: `schemaVersion`, `timestamp`, `totalIssues`, `scannedElements`,
  /// `scanDurationMs`, `issuesBySeverity`, `issuesByType`,
  /// `issuesByWcagCriterion` and `issues`.
  Map<String, dynamic> toMap() {
    final bySeverity = issuesBySeverity;
    final byType = issuesByType;
    return {
      'schemaVersion': jsonSchemaVersion,
      'timestamp': timestamp.toIso8601String(),
      'totalIssues': totalIssues,
      if (scannedElements != null) 'scannedElements': scannedElements,
      if (scanDuration != null) 'scanDurationMs': scanDuration!.inMilliseconds,
      'issuesBySeverity': {
        for (final s in AccessibilityIssueSeverity.values.reversed)
          s.name: bySeverity[s]?.length ?? 0,
      },
      'issuesByType': {
        for (final t in AccessibilityIssueType.values)
          t.name: byType[t]?.length ?? 0,
      },
      'issuesByWcagCriterion': issueCountsByWcagCriterion,
      'issues': issues.map((issue) => issue.toJson()).toList(),
    };
  }

  /// Converts the report to a JSON string. Set [pretty] for an indented,
  /// diff-friendly file (handy for CI artifacts and baselines).
  String toJson({bool pretty = false}) {
    if (!pretty) return jsonEncode(toMap());
    return const JsonEncoder.withIndent('  ').convert(toMap());
  }

  /// Renders the report as GitHub-flavoured Markdown, for example for a
  /// pull request comment or `$GITHUB_STEP_SUMMARY`.
  String toMarkdown({String title = 'Accessibility scan'}) {
    final buffer = StringBuffer()
      ..writeln('## $title')
      ..writeln()
      ..writeln('**$totalIssues issue${totalIssues == 1 ? '' : 's'}** found.');
    if (issues.isEmpty) return buffer.toString();
    buffer
      ..writeln()
      ..writeln('| Severity | Type | WCAG | Description | Suggested fix |')
      ..writeln('| --- | --- | --- | --- | --- |');
    for (final issue in issues) {
      final cells = [
        issue.severity.name,
        issue.type.name,
        issue.wcagCriterion ?? '',
        issue.description,
        issue.suggestion ?? '',
      ].map(_escapeCell);
      buffer.writeln('| ${cells.join(' | ')} |');
    }
    return buffer.toString();
  }

  static String _escapeCell(String text) =>
      text.replaceAll('|', r'\|').replaceAll('\n', ' ');

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
