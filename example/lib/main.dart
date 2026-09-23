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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Accessibility Scanner Demo',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Accessibility Scanner Demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Bad: tiny, unlabeled button',
              style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => _showSnackBar('Tapped bad button'),
              child: Container(
                width: 30,
                height: 30,
                color: Colors.grey[300],
                child: Icon(Icons.star, color: Colors.grey[400]),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Good: AccessibilityFixerButton',
              style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: AccessibilityFixerButton(
              onPressed: () => _showSnackBar('Tapped good button'),
              semanticsLabel: 'Add to favorites',
              semanticsHint: 'Adds this item to your favorites list',
              child: const Icon(Icons.star, color: Colors.indigo),
            ),
          ),
          const SizedBox(height: 20),
          Text('Bad: low-contrast text', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            'This text has poor contrast and is hard to read',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          Text('Good: AccessibilityFixerText',
              style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          AccessibilityFixerText(
            text: 'This text is darkened just enough to pass WCAG AA',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
            backgroundColor: theme.colorScheme.surface,
          ),
          const SizedBox(height: 30),
          FilledButton.icon(
            onPressed: _performManualScan,
            icon: const Icon(Icons.accessibility),
            label: const Text('Run manual accessibility scan'),
          ),
          if (_report != null) ...[
            const SizedBox(height: 20),
            Text(
              'Found ${_report!.totalIssues} issues',
              style: theme.textTheme.titleMedium,
            ),
            for (final issue in _report!.issues)
              ListTile(
                dense: true,
                title: Text(issue.description),
                subtitle: Text(
                  '${issue.severity.name} · WCAG ${issue.wcagCriterion ?? '-'}'
                  '\n${issue.suggestion ?? ''}',
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _performManualScan() async {
    final report = await AccessibilityScanner().scan(context);
    if (!mounted) return;
    setState(() => _report = report);
    _showSnackBar('Scan complete: ${report.totalIssues} issues found');
  }
}
