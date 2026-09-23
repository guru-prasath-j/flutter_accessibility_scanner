import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'detectors/contrast_detector.dart';
import 'detectors/focus_detector.dart';
import 'detectors/image_label_detector.dart';
import 'detectors/semantics_detector.dart';
import 'detectors/tap_target_detector.dart';
import 'models/accessibility_issue.dart';
import 'models/accessibility_report.dart';

/// Analyzes a Flutter render tree for accessibility issues.
///
/// ```dart
/// final report = await AccessibilityScanner().scan(context);
/// debugPrint(report.summary);
/// ```
///
/// Calling `AccessibilityScanner()` with no arguments returns a shared
/// instance using [defaultDetectors]. Pass [detectors] to run your own set,
/// including custom [AccessibilityDetector] subclasses.
class AccessibilityScanner {
  /// Returns a scanner. Without [detectors] the shared default scanner is
  /// returned; otherwise a new scanner running exactly [detectors].
  factory AccessibilityScanner({List<AccessibilityDetector>? detectors}) {
    if (detectors == null) return _instance;
    return AccessibilityScanner._(List.unmodifiable(detectors));
  }

  AccessibilityScanner._(this.detectors);

  static final AccessibilityScanner _instance =
      AccessibilityScanner._(List.unmodifiable(defaultDetectors()));

  /// The detectors run against every inspected render object.
  final List<AccessibilityDetector> detectors;

  /// A fresh list of the built-in detectors.
  static List<AccessibilityDetector> defaultDetectors() => [
        const SemanticsDetector(),
        const ImageLabelDetector(),
        const ContrastDetector(),
        const TapTargetDetector(),
        const FocusDetector(),
      ];

  /// Scans the widget subtree below [context] for accessibility issues.
  ///
  /// Only issues at least as severe as [minimumSeverity] are reported. Issues
  /// are returned most severe first.
  Future<AccessibilityReport> scan(
    BuildContext context, {
    AccessibilityIssueSeverity minimumSeverity = AccessibilityIssueSeverity.low,
  }) async {
    final renderObject = context.findRenderObject();
    if (renderObject == null) {
      return AccessibilityReport(
        timestamp: DateTime.now(),
        totalIssues: 0,
        issues: const [],
        scannedElements: 0,
        scanDuration: Duration.zero,
      );
    }
    return scanRenderObject(renderObject, minimumSeverity: minimumSeverity);
  }

  /// Scans the render tree rooted at [root].
  ///
  /// Offstage content (for example routes hidden behind the current one) is
  /// skipped, matching what assistive technologies can reach.
  Future<AccessibilityReport> scanRenderObject(
    RenderObject root, {
    AccessibilityIssueSeverity minimumSeverity = AccessibilityIssueSeverity.low,
  }) async {
    final stopwatch = Stopwatch()..start();
    final nodes = <RenderObject>[];
    _collect(root, nodes);

    final issues = <AccessibilityIssue>[];
    for (final node in nodes) {
      if (node is RenderBox && !node.hasSize) continue;
      for (final detector in detectors) {
        try {
          final found = await detector.detect(node);
          for (final issue in found) {
            if (issue.severity.isAtLeast(minimumSeverity)) issues.add(issue);
          }
        } catch (error, stack) {
          assert(() {
            debugPrint(
              'flutter_accessibility_scanner: ${detector.runtimeType} '
              'failed on ${node.runtimeType}: $error\n$stack',
            );
            return true;
          }());
        }
      }
    }

    // Most severe first, keeping tree order within the same severity.
    final ordered = List.generate(issues.length, (i) => i)
      ..sort((a, b) {
        final bySeverity =
            issues[b].severity.index.compareTo(issues[a].severity.index);
        return bySeverity != 0 ? bySeverity : a.compareTo(b);
      });
    final sorted = [for (final i in ordered) issues[i]];

    stopwatch.stop();
    return AccessibilityReport(
      timestamp: DateTime.now(),
      totalIssues: sorted.length,
      issues: sorted,
      scannedElements: nodes.length,
      scanDuration: stopwatch.elapsed,
    );
  }

  void _collect(RenderObject node, List<RenderObject> out) {
    out.add(node);
    // Excluded-from-semantics subtrees are still visited so that, for
    // example, icon glyphs get contrast-checked; offstage content is not.
    if (node is RenderExcludeSemantics && node.excluding) {
      node.visitChildren((child) => _collect(child, out));
    } else {
      node.visitChildrenForSemantics((child) => _collect(child, out));
    }
  }
}

/// Base class for accessibility issue detectors.
///
/// Subclass this to add project-specific rules and pass an instance to
/// `AccessibilityScanner(detectors: [...])`.
abstract class AccessibilityDetector {
  /// Const base constructor for subclasses.
  const AccessibilityDetector();

  /// Returns the issues [renderObject] itself has (children are visited
  /// separately by the scanner).
  Future<List<AccessibilityIssue>> detect(RenderObject renderObject);
}
