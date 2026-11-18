import 'package:flutter/material.dart';
import 'package:flutter_accessibility_scanner/flutter_accessibility_scanner.dart';

import 'main.dart' show ScannerSettings;
import 'theme.dart';

/// The demo page: deliberately good and bad examples side by side, plus a
/// manual scan and its report.
class ScannerPage extends StatefulWidget {
  /// Creates the page.
  const ScannerPage({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.settings,
    required this.report,
    required this.onReport,
  });

  /// The app's current theme mode, shown by the theme toggle.
  final ThemeMode themeMode;

  /// Called when the user picks another theme mode.
  final ValueChanged<ThemeMode> onThemeModeChanged;

  /// Scanner options (minimum severity is applied to the manual scan).
  final ScannerSettings settings;

  /// The latest report, shown below the scan button.
  final AccessibilityReport? report;

  /// Called with each manual scan's report.
  final ValueChanged<AccessibilityReport> onReport;

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool _scanning = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // A non-lazy scroll view so every example is built (and scanned), not
    // just the ones currently on screen.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                themeMode: widget.themeMode,
                onThemeModeChanged: widget.onThemeModeChanged,
                // Leave room for the floating scan button (top-right).
                reserveRight: widget.settings.overlayEnabled,
              ),
              const SizedBox(height: 28),
              const _HeroCard(),
              const SizedBox(height: 36),
              const SectionHeader(
                title: 'Live examples',
                subtitle: 'Each problem is shown next to its fixed version.',
              ),
              const SizedBox(height: 16),
              _ComparisonRow(
                bad: _ExampleCard(
                  good: false,
                  title: 'Tiny, unlabeled button',
                  body: '30×30 px with no label — too small to tap and '
                      'silent to screen readers.',
                  preview: GestureDetector(
                    onTap: () => _showSnackBar('Tapped bad button'),
                    child: Container(
                      width: 30,
                      height: 30,
                      color: Colors.grey[300],
                      child: Icon(Icons.star, color: Colors.grey[400]),
                    ),
                  ),
                ),
                good: _ExampleCard(
                  good: true,
                  title: 'AccessibilityFixerButton',
                  body: '48×48 px minimum, with a semantic label and hint.',
                  preview: AccessibilityFixerButton(
                    onPressed: () => _showSnackBar('Tapped good button'),
                    semanticsLabel: 'Add to favorites',
                    semanticsHint: 'Adds this item to your favorites list',
                    child: Icon(Icons.star_rounded, color: colors.accent),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _ComparisonRow(
                bad: _ExampleCard(
                  good: false,
                  title: 'Low-contrast text',
                  body: 'Light grey on white falls below the WCAG AA '
                      'ratio of 4.5:1.',
                  preview: Text(
                    'This text has poor contrast and is hard to read',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ),
                good: _ExampleCard(
                  good: true,
                  title: 'AccessibilityFixerText',
                  body: 'Same colour, adjusted just enough to pass.',
                  preview: AccessibilityFixerText(
                    text: 'This text is darkened just enough to pass WCAG AA',
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    backgroundColor: colors.surfaceHigh,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              const SectionHeader(
                title: 'Scan this screen',
                subtitle: 'Runs every detector against the widgets above.',
              ),
              const SizedBox(height: 20),
              Center(
                child: GradientButton(
                  label: 'Run manual accessibility scan',
                  icon: Icons.manage_search_rounded,
                  loading: _scanning,
                  onPressed: _scanning ? null : _performManualScan,
                ),
              ),
              if (widget.report != null) ...[
                const SizedBox(height: 28),
                _ReportView(report: widget.report!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _performManualScan() async {
    setState(() => _scanning = true);
    final report = await AccessibilityScanner().scan(
      context,
      minimumSeverity: widget.settings.minimumSeverity,
    );
    if (!mounted) return;
    setState(() => _scanning = false);
    widget.onReport(report);
    _showSnackBar('Scan complete: ${report.totalIssues} issues found');
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.reserveRight,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final bool reserveRight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(right: reserveRight ? 56 : 0),
      child: Row(
        children: [
          const AppLogo(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Accessibility Scanner Demo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  'flutter_accessibility_scanner · v${AppInfo.version}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _ThemeToggle(mode: themeMode, onChanged: onThemeModeChanged),
        ],
      ),
    );
  }
}

/// Cycles System → Light → Dark. Each option has an icon and a tooltip, so
/// the button is labelled for screen readers too.
class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({required this.mode, required this.onChanged});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final (icon, label, next) = switch (mode) {
      ThemeMode.system => (
          Icons.brightness_auto_rounded,
          'System',
          ThemeMode.light
        ),
      ThemeMode.light => (Icons.light_mode_rounded, 'Light', ThemeMode.dark),
      ThemeMode.dark => (Icons.dark_mode_rounded, 'Dark', ThemeMode.system),
    };
    return CircleIconButton(
      icon: icon,
      tooltip: 'Theme: $label (tap to change)',
      onPressed: () => onChanged(next),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final headline = TextStyle(
      fontSize: 30,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
      color: colors.textPrimary,
    );
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.surfaceHigh, colors.surface],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDeep
                .withValues(alpha: 0.25 * colors.glowStrength),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TintPill(
            label: 'WCAG 2.1 · AA',
            icon: Icons.auto_awesome,
            color: AppColors.primary,
            textColor: colors.accent,
          ),
          const SizedBox(height: 18),
          Semantics(
            header: true,
            label: 'Catch accessibility issues before your users do',
            excludeSemantics: true,
            child: Wrap(
              children: [
                Text('Catch accessibility issues ', style: headline),
                GradientText('before your users do', style: headline),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Checks for missing labels, low contrast, small tap targets and '
            'focus support — with a fix hint for every issue.',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (icon, label) in const [
                (Icons.label_outline_rounded, 'Labels'),
                (Icons.contrast_rounded, 'Contrast'),
                (Icons.touch_app_outlined, 'Tap targets'),
                (Icons.keyboard_outlined, 'Focus'),
              ])
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.surfaceHigh,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: colors.accent),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Side by side on wide screens, stacked on narrow ones.
class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.bad, required this.good});

  final Widget bad;
  final Widget good;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          return Column(children: [bad, const SizedBox(height: 12), good]);
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: bad),
              const SizedBox(width: 16),
              Expanded(child: good),
            ],
          ),
        );
      },
    );
  }
}

class _ExampleCard extends StatelessWidget {
  const _ExampleCard({
    required this.good,
    required this.title,
    required this.body,
    required this.preview,
  });

  final bool good;
  final String title;
  final String body;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TintPill(
            label: good ? 'Accessible' : 'Problem',
            icon: good ? Icons.check_circle_rounded : Icons.error_rounded,
            color: good ? AppColors.success : AppColors.danger,
            textColor: good ? colors.successText : colors.dangerText,
          ),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(body, style: TextStyle(color: colors.textSecondary)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.all(16),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              // The "bad" preview stays white on purpose: it is the
              // low-contrast case the scanner should flag.
              color: good ? colors.surfaceHigh : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: colors.border),
            ),
            child: preview,
          ),
        ],
      ),
    );
  }
}

class _ReportView extends StatelessWidget {
  const _ReportView({required this.report});

  final AccessibilityReport report;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final counts = {
      for (final s in AccessibilityIssueSeverity.values.reversed)
        s: report.issues.where((i) => i.severity == s).length,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SurfaceCard(
          radius: AppRadius.lg,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.insights_rounded, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Found ${report.totalIssues} issues',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (report.scannedElements != null ||
                        report.scanDuration != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (report.scannedElements != null)
                            '${report.scannedElements} elements scanned',
                          if (report.scanDuration != null)
                            'in ${report.scanDuration!.inMilliseconds} ms',
                        ].join(' '),
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final e in counts.entries)
                          SeverityPill(
                            severity: e.key,
                            label: '${capitalize(e.key.name)}  ${e.value}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (report.issues.isEmpty)
          SurfaceCard(
            child: Row(
              children: [
                Icon(Icons.verified_rounded, color: colors.successText),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('No issues — this screen looks accessible.'),
                ),
              ],
            ),
          )
        else
          for (final issue in report.issues) ...[
            _IssueCard(issue: issue),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.issue});

  final AccessibilityIssue issue;

  static IconData _iconFor(AccessibilityIssueType type) => switch (type) {
        AccessibilityIssueType.missingSemanticsLabel =>
          Icons.label_off_outlined,
        AccessibilityIssueType.poorColorContrast => Icons.contrast_rounded,
        AccessibilityIssueType.smallTapTarget => Icons.touch_app_outlined,
        AccessibilityIssueType.missingFocusSupport => Icons.keyboard_outlined,
        AccessibilityIssueType.missingScreenReaderHint =>
          Icons.record_voice_over_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (tint, fg) = severityColors(context, issue.severity);
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: tint.withValues(alpha: 0.3)),
            ),
            child: Icon(_iconFor(issue.type), color: fg, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (issue.suggestion != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    issue.suggestion!,
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  '${capitalize(issue.severity.name)} · '
                  'WCAG ${issue.wcagCriterion ?? '-'}',
                  style: TextStyle(
                    color: fg,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
