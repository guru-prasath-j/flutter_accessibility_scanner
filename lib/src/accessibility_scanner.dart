import 'package:flutter/material.dart';

import 'detectors/contrast_detector.dart';
import 'detectors/focus_detector.dart';
import 'detectors/semantics_detector.dart';
import 'detectors/tap_target_detector.dart';
import 'models/accessibility_issue.dart';
import 'models/accessibility_report.dart';

/// Main accessibility scanner that analyzes Flutter widget trees for accessibility issues.
class AccessibilityScanner {
  static final AccessibilityScanner _instance =
      AccessibilityScanner._internal();
  factory AccessibilityScanner() => _instance;
  AccessibilityScanner._internal();

  final List<AccessibilityDetector> _detectors = [
    SemanticsDetector(),
    ContrastDetector(),
    TapTargetDetector(),
    FocusDetector(),
  ];

  /// Scans the widget tree starting from the given context for accessibility issues.
  /// Returns an [AccessibilityReport] containing all detected issues.
  Future<AccessibilityReport> scan(BuildContext context) async {
    final List<AccessibilityIssue> issues = [];
    final RenderObject? renderObject = context.findRenderObject();

    if (renderObject != null) {
      await _scanRenderObject(renderObject, issues);
    }

    return AccessibilityReport(
      timestamp: DateTime.now(),
      totalIssues: issues.length,
      issues: issues,
    );
  }

  Future<void> _scanRenderObject(
      RenderObject renderObject, List<AccessibilityIssue> issues) async {
    // Check current render object with all detectors
    for (final detector in _detectors) {
      try {
        final detectedIssues = await detector.detect(renderObject);
        if (detectedIssues.isNotEmpty) {
          //print(
          // 'Debug: ${detector.runtimeType} found ${detectedIssues.length} issues');
          for (final issue in detectedIssues) {
            print('Debug: Adding issue: ${issue.type} - ${issue.description}');
          }
        }
        issues.addAll(detectedIssues);
      } catch (e) {
        //print('Debug: Error in detector ${detector.runtimeType}: $e');
      }
    }

    // Recursively scan children using Future.wait to properly handle async
    final List<Future<void>> childFutures = [];
    renderObject.visitChildren((child) {
      childFutures.add(_scanRenderObject(child, issues));
    });

    // Wait for all child scans to complete
    await Future.wait(childFutures);
  }
}

/// Base class for accessibility issue detectors.
abstract class AccessibilityDetector {
  Future<List<AccessibilityIssue>> detect(RenderObject renderObject);
}
