import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../accessibility_scanner.dart';
import '../models/accessibility_issue.dart';
import '../models/accessibility_report.dart';

// Ensure AccessibilityIssueSeverity is imported or defined
// If it's defined in accessibility_issue.dart, this import is correct.
// Otherwise, define the enum below or correct the import path.

/// A development widget that displays accessibility scan results in real-time.
class AccessibilityScannerWidget extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final VoidCallback? onReportGenerated;

  const AccessibilityScannerWidget({
    Key? key,
    required this.child,
    this.enabled = kDebugMode,
    this.onReportGenerated,
  }) : super(key: key);

  @override
  State<AccessibilityScannerWidget> createState() =>
      _AccessibilityScannerWidgetState();
}

class _AccessibilityScannerWidgetState
    extends State<AccessibilityScannerWidget> {
  AccessibilityReport? _lastReport;
  bool _isScanning = false;
  bool _showOverlay = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          Positioned(
            top: 50,
            right: 16,
            child: _buildScannerButton(),
          ),
          if (_showOverlay && _lastReport != null) _buildReportOverlay(),
        ],
      ),
    );
  }

  Widget _buildScannerButton() {
    return FloatingActionButton.small(
      heroTag: "accessibility_scanner",
      onPressed: _isScanning ? null : _performScan,
      backgroundColor: _getButtonColor(),
      child: _isScanning
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.accessibility, color: Colors.white),
    );
  }

  Color _getButtonColor() {
    if (_lastReport == null) return Colors.blue;

    final criticalIssues = _lastReport!
            .issuesBySeverity[AccessibilityIssueSeverity.critical]?.length ??
        0;
    final highIssues = _lastReport!
            .issuesBySeverity[AccessibilityIssueSeverity.high]?.length ??
        0;

    if (criticalIssues > 0) return Colors.red;
    if (highIssues > 0) return Colors.orange;
    if (_lastReport!.totalIssues > 0) return Colors.yellow[700]!;
    return Colors.green;
  }

  Future<void> _performScan() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final scanner = AccessibilityScanner();
      final report = await scanner.scan(context);

      setState(() {
        _lastReport = report;
        _showOverlay = true;
      });

      widget.onReportGenerated?.call();

      // Auto-hide overlay after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _showOverlay = false;
          });
        }
      });
    } catch (e) {
      // debug//print('Accessibility scan failed: $e');
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Widget _buildReportOverlay() {
    return Positioned(
      top: 100,
      right: 16,
      left: 16,
      child: Card(
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxHeight: 300),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Accessibility Report',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _showOverlay = false),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Total Issues: ${_lastReport!.totalIssues}'),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final severity in AccessibilityIssueSeverity.values)
                        if ((_lastReport!.issuesBySeverity[severity]?.length ??
                                0) >
                            0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '${severity.name}: ${_lastReport!.issuesBySeverity[severity]!.length}',
                              style: TextStyle(
                                color: _getSeverityColor(severity),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor(AccessibilityIssueSeverity severity) {
    switch (severity) {
      case AccessibilityIssueSeverity.critical:
        return Colors.red;
      case AccessibilityIssueSeverity.high:
        return Colors.orange;
      case AccessibilityIssueSeverity.medium:
        return Colors.yellow[700]!;
      case AccessibilityIssueSeverity.low:
        return Colors.blue;
    }
  }
}
