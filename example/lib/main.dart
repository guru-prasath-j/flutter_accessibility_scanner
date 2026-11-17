import 'package:flutter/material.dart';
import 'package:flutter_accessibility_scanner/flutter_accessibility_scanner.dart';

void main() {
  runApp(const MyApp());
}

/// Demo app. The floating accessibility button (debug builds) scans the
/// current screen and outlines every issue it finds.
class MyApp extends StatelessWidget {
  /// Creates the demo app.
  const MyApp({super.key});

  static ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3949AB),
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surfaceContainerLowest,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme:
          const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Accessibility Scanner Demo',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      builder: (context, child) => AccessibilityScannerWidget(
        onReport: (report) => debugPrint(report.summary),
        child: child!,
      ),
      home: const MyHomePage(),
    );
  }
}

/// A page with deliberately good and bad examples side by side.
class MyHomePage extends StatefulWidget {
  /// Creates the page.
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  AccessibilityReport? _report;
  bool _scanning = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Icon(Icons.accessibility_new, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Accessibility Scanner Demo'),
          ],
        ),
      ),
      // A non-lazy scroll view so every example is built (and scanned), not
      // just the ones currently on screen.
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _HeroCard(),
                const SizedBox(height: 32),
                const _SectionHeader(
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
                      child: Icon(Icons.star, color: theme.colorScheme.primary),
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
                    body: 'Same colour, darkened just enough to pass.',
                    preview: AccessibilityFixerText(
                      text: 'This text is darkened just enough to pass WCAG AA',
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                      backgroundColor: theme.colorScheme.surfaceContainerLow,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const _SectionHeader(
                  title: 'Scan this screen',
                  subtitle: 'Runs every detector against the widgets above.',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _scanning ? null : _performManualScan,
                  icon: _scanning
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.manage_search),
                  label: const Text('Run manual accessibility scan'),
                ),
                if (_report != null) ...[
                  const SizedBox(height: 24),
                  _ReportView(report: _report!),
                ],
              ],
            ),
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
    final report = await AccessibilityScanner().scan(context);
    if (!mounted) return;
    setState(() {
      _report = report;
      _scanning = false;
    });
    _showSnackBar('Scan complete: ${report.totalIssues} issues found');
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Catch accessibility issues before your users do',
            style: text.headlineSmall?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'WCAG 2.1 checks for missing labels, low contrast, small tap '
            'targets and focus support — with a fix hint for every issue.',
            style: text.bodyLarge?.copyWith(color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (icon, label) in const [
                (Icons.label_outline, 'Labels'),
                (Icons.contrast, 'Contrast'),
                (Icons.touch_app_outlined, 'Tap targets'),
                (Icons.keyboard_outlined, 'Focus'),
              ])
                Chip(
                  avatar: Icon(icon, size: 18, color: scheme.primary),
                  label: Text(label),
                  labelStyle: TextStyle(color: scheme.onSurface),
                  backgroundColor: scheme.surface,
                  side: BorderSide.none,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final badgeBg = good ? const Color(0xFFDCF5E3) : scheme.errorContainer;
    final badgeFg = good ? const Color(0xFF0F5323) : scheme.onErrorContainer;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    good ? Icons.check_circle : Icons.error,
                    size: 16,
                    color: badgeFg,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    good ? 'Accessible' : 'Problem',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: badgeFg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 88),
              padding: const EdgeInsets.all(16),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: good ? scheme.surfaceContainerLow : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: preview,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportView extends StatelessWidget {
  const _ReportView({required this.report});

  final AccessibilityReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final counts = {
      for (final s in AccessibilityIssueSeverity.values.reversed)
        s: report.issues.where((i) => i.severity == s).length,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Found ${report.totalIssues} issues',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (report.scannedElements != null ||
                    report.scanDuration != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (report.scannedElements != null)
                        '${report.scannedElements} elements scanned',
                      if (report.scanDuration != null)
                        'in ${report.scanDuration!.inMilliseconds} ms',
                    ].join(' '),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in counts.entries)
                      _SeverityPill(severity: e.key, count: e.value),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (report.issues.isEmpty)
          Card(
            child: ListTile(
              leading: Icon(Icons.verified, color: scheme.primary),
              title: const Text('No issues — this screen looks accessible.'),
            ),
          )
        else
          for (final issue in report.issues) ...[
            _IssueCard(issue: issue),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

(Color, Color) _severityColors(
  AccessibilityIssueSeverity severity,
  ColorScheme scheme,
) =>
    switch (severity) {
      AccessibilityIssueSeverity.critical ||
      AccessibilityIssueSeverity.high =>
        (scheme.errorContainer, scheme.onErrorContainer),
      AccessibilityIssueSeverity.medium => (
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer
        ),
      AccessibilityIssueSeverity.low => (
          scheme.secondaryContainer,
          scheme.onSecondaryContainer
        ),
    };

String _capitalize(String s) => '${s[0].toUpperCase()}${s.substring(1)}';

class _SeverityPill extends StatelessWidget {
  const _SeverityPill({required this.severity, required this.count});

  final AccessibilityIssueSeverity severity;
  final int count;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _severityColors(severity, Theme.of(context).colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${_capitalize(severity.name)}  $count',
        style: TextStyle(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.issue});

  final AccessibilityIssue issue;

  static IconData _iconFor(AccessibilityIssueType type) => switch (type) {
        AccessibilityIssueType.missingSemanticsLabel =>
          Icons.label_off_outlined,
        AccessibilityIssueType.poorColorContrast => Icons.contrast,
        AccessibilityIssueType.smallTapTarget => Icons.touch_app_outlined,
        AccessibilityIssueType.missingFocusSupport => Icons.keyboard_outlined,
        AccessibilityIssueType.missingScreenReaderHint =>
          Icons.record_voice_over_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (bg, fg) = _severityColors(issue.severity, scheme);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
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
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (issue.suggestion != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      issue.suggestion!,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    '${_capitalize(issue.severity.name)} · '
                    'WCAG ${issue.wcagCriterion ?? '-'}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
