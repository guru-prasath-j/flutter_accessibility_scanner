/// Scan Flutter widget trees for WCAG 2.1 accessibility issues.
///
/// Start with `AccessibilityScanner` for one-off or test-time scans, or wrap
/// your app in `AccessibilityScannerWidget` for an in-app, debug-only scanner
/// with on-screen highlights.
library;

export 'src/accessibility_scanner.dart';
export 'src/detectors/contrast_detector.dart';
export 'src/detectors/focus_detector.dart';
export 'src/detectors/image_label_detector.dart';
export 'src/detectors/semantics_detector.dart';
export 'src/detectors/tap_target_detector.dart';
export 'src/models/accessibility_issue.dart';
export 'src/models/accessibility_report.dart';
export 'src/utils/color_contrast_utils.dart';
export 'src/widgets/accessibility_fixer_button.dart';
export 'src/widgets/accessibility_scanner_widget.dart';
