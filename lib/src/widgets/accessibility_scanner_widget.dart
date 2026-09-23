import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../accessibility_scanner.dart';
import '../models/accessibility_issue.dart';
import '../models/accessibility_report.dart';

/// A development overlay that scans [child] on demand and highlights every
/// issue on screen.
///
/// Wrap your app (or a single screen) with it. A floating accessibility
/// button appears in debug builds; tap it to scan. Issues are outlined in
/// their severity color and listed in a dismissible panel.
class AccessibilityScannerWidget extends StatefulWidget {
  /// Creates the scanner overlay.
  const AccessibilityScannerWidget({
    super.key,
    required this.child,
    this.enabled = kDebugMode,
    this.onReportGenerated,
    this.onReport,
    this.scanner,
    this.showHighlights = true,
    this.minimumSeverity = AccessibilityIssueSeverity.low,
    this.overlayDuration = const Duration(seconds: 5),
  });

  /// The app or screen to scan.
  final Widget child;

  /// Whether the overlay is active. Defaults to debug builds only.
  final bool enabled;

  /// Called after every scan.
  final VoidCallback? onReportGenerated;

  /// Called with the report after every scan, for logging or exporting it.
  final ValueChanged<AccessibilityReport>? onReport;

  /// The scanner to use. Defaults to `AccessibilityScanner()`.
  final AccessibilityScanner? scanner;

  /// Whether to outline each issue on screen.
  final bool showHighlights;

  /// Issues below this severity are ignored.
  final AccessibilityIssueSeverity minimumSeverity;

  /// How long results stay on screen. `Duration.zero` keeps them until the
  /// panel is closed.
  final Duration overlayDuration;

  @override
  State<AccessibilityScannerWidget> createState() =>
      _AccessibilityScannerWidgetState();
}

class _AccessibilityScannerWidgetState
    extends State<AccessibilityScannerWidget> {
  final GlobalKey _childKey = GlobalKey();
  AccessibilityReport? _lastReport;
  List<_Highlight> _highlights = const [];
  bool _isScanning = false;
  bool _showOverlay = false;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = KeyedSubtree(key: _childKey, child: widget.child);
    if (!widget.enabled) return child;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          child,
          if (_showOverlay && widget.showHighlights && _highlights.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _HighlightPainter(_highlights)),
              ),
            ),
          Positioned(top: 50, right: 16, child: _buildScannerButton()),
          if (_showOverlay && _lastReport != null) _buildReportPanel(),
        ],
      ),
    );
  }

  Widget _buildScannerButton() {
    return FloatingActionButton.small(
      heroTag: 'accessibility_scanner',
      onPressed: _isScanning ? null : _performScan,
      backgroundColor: _buttonColor(),
      child: _isScanning
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(
              Icons.accessibility,
              color: Colors.white,
              semanticLabel: 'Scan for accessibility issues',
            ),
    );
  }

  Color _buttonColor() {
    final report = _lastReport;
    if (report == null) return Colors.blue.shade700;
    final bySeverity = report.issuesBySeverity;
    if (bySeverity[AccessibilityIssueSeverity.critical]?.isNotEmpty ?? false) {
      return Colors.red.shade700;
    }
    if (bySeverity[AccessibilityIssueSeverity.high]?.isNotEmpty ?? false) {
      return Colors.deepOrange.shade700;
    }
    if (report.hasIssues) return Colors.brown.shade600;
    return Colors.green.shade700;
  }

  Future<void> _performScan() async {
    final target = _childKey.currentContext;
    if (target == null) return;
    setState(() => _isScanning = true);

    try {
      final report = await (widget.scanner ?? AccessibilityScanner()).scan(
        target,
        minimumSeverity: widget.minimumSeverity,
      );
      if (!mounted) return;

      final highlights = <_Highlight>[];
      final box = context.findRenderObject();
      if (box is RenderBox && box.hasSize) {
        for (final issue in report.issues) {
          final bounds = issue.bounds;
          if (bounds == null) continue;
          highlights.add(_Highlight(
            Rect.fromPoints(
              box.globalToLocal(bounds.topLeft),
              box.globalToLocal(bounds.bottomRight),
            ),
            _severityColor(issue.severity),
          ));
        }
      }

      setState(() {
        _lastReport = report;
        _highlights = highlights;
        _showOverlay = true;
      });

      widget.onReportGenerated?.call();
      widget.onReport?.call(report);

      _hideTimer?.cancel();
      if (widget.overlayDuration > Duration.zero) {
        _hideTimer = Timer(widget.overlayDuration, () {
          if (mounted) setState(() => _showOverlay = false);
        });
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Widget _buildReportPanel() {
    final report = _lastReport!;
    final bySeverity = report.issuesBySeverity;
    return Positioned(
      top: 100,
      right: 16,
      left: 16,
      child: Card(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Accessibility Report',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        semanticLabel: 'Close report',
                      ),
                      onPressed: () => setState(() => _showOverlay = false),
                    ),
                  ],
                ),
                Text('Total issues: ${report.totalIssues}'),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  children: [
                    for (final severity
                        in AccessibilityIssueSeverity.values.reversed)
                      if ((bySeverity[severity]?.length ?? 0) > 0)
                        Text(
                          '${severity.name}: ${bySeverity[severity]!.length}',
                          style: TextStyle(
                            color: _severityColor(severity),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final issue in report.issues)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '• ${issue.description}'
                            '${issue.wcagCriterion != null ? ' (WCAG ${issue.wcagCriterion})' : ''}',
                            style: TextStyle(
                              color: _severityColor(issue.severity),
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Color _severityColor(AccessibilityIssueSeverity severity) {
    switch (severity) {
      case AccessibilityIssueSeverity.critical:
        return Colors.red.shade700;
      case AccessibilityIssueSeverity.high:
        return Colors.deepOrange.shade800;
      case AccessibilityIssueSeverity.medium:
        return Colors.brown.shade600;
      case AccessibilityIssueSeverity.low:
        return Colors.blue.shade700;
    }
  }
}

class _Highlight {
  const _Highlight(this.rect, this.color);

  final Rect rect;
  final Color color;
}

class _HighlightPainter extends CustomPainter {
  _HighlightPainter(this.highlights);

  final List<_Highlight> highlights;

  @override
  void paint(Canvas canvas, Size size) {
    for (final h in highlights) {
      canvas.drawRect(
        h.rect.inflate(1),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = h.color,
      );
      canvas.drawRect(
        h.rect,
        Paint()..color = h.color.withValues(alpha: 0.12),
      );
    }
  }

  @override
  bool shouldRepaint(_HighlightPainter oldDelegate) =>
      oldDelegate.highlights != highlights;
}
