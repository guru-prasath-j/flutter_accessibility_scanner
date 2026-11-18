import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_accessibility_scanner/flutter_accessibility_scanner.dart';

import 'scanner_page.dart';
import 'settings_page.dart';
import 'theme.dart';

void main() {
  runApp(const MyApp());
}

/// Options the Settings tab changes; passed straight to
/// [AccessibilityScannerWidget] and the manual scan.
@immutable
class ScannerSettings {
  /// Creates scanner settings.
  const ScannerSettings({
    this.overlayEnabled = kDebugMode,
    this.showHighlights = true,
    this.minimumSeverity = AccessibilityIssueSeverity.low,
    this.overlayDuration = const Duration(seconds: 5),
  });

  /// Whether the floating scan button is shown.
  final bool overlayEnabled;

  /// Whether issues are outlined on screen after a scan.
  final bool showHighlights;

  /// Issues below this severity are ignored.
  final AccessibilityIssueSeverity minimumSeverity;

  /// How long overlay results stay visible; zero keeps them until closed.
  final Duration overlayDuration;

  /// Returns a copy with the given fields replaced.
  ScannerSettings copyWith({
    bool? overlayEnabled,
    bool? showHighlights,
    AccessibilityIssueSeverity? minimumSeverity,
    Duration? overlayDuration,
  }) =>
      ScannerSettings(
        overlayEnabled: overlayEnabled ?? this.overlayEnabled,
        showHighlights: showHighlights ?? this.showHighlights,
        minimumSeverity: minimumSeverity ?? this.minimumSeverity,
        overlayDuration: overlayDuration ?? this.overlayDuration,
      );
}

/// Demo app. The floating accessibility button (debug builds) scans the
/// current screen and outlines every issue it finds.
class MyApp extends StatefulWidget {
  /// Creates the demo app.
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  ScannerSettings _settings = const ScannerSettings();
  AccessibilityReport? _lastReport;

  void _onReport(AccessibilityReport report) {
    debugPrint(report.summary);
    setState(() => _lastReport = report);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Accessibility Scanner Demo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      builder: (context, child) => AccessibilityScannerWidget(
        enabled: _settings.overlayEnabled,
        showHighlights: _settings.showHighlights,
        minimumSeverity: _settings.minimumSeverity,
        overlayDuration: _settings.overlayDuration,
        onReport: _onReport,
        child: child!,
      ),
      home: HomeShell(
        themeMode: _themeMode,
        onThemeModeChanged: (mode) => setState(() => _themeMode = mode),
        settings: _settings,
        onSettingsChanged: (s) => setState(() => _settings = s),
        lastReport: _lastReport,
        onReport: _onReport,
      ),
    );
  }
}

/// Scanner / Settings tabs with a bottom navigation bar.
class HomeShell extends StatefulWidget {
  /// Creates the shell.
  const HomeShell({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.settings,
    required this.onSettingsChanged,
    required this.lastReport,
    required this.onReport,
  });

  /// The app's current theme mode.
  final ThemeMode themeMode;

  /// Called when the user picks another theme mode.
  final ValueChanged<ThemeMode> onThemeModeChanged;

  /// Current scanner settings.
  final ScannerSettings settings;

  /// Called when a setting changes.
  final ValueChanged<ScannerSettings> onSettingsChanged;

  /// The most recent scan, from either the manual or the floating button.
  final AccessibilityReport? lastReport;

  /// Called with each manual scan's report.
  final ValueChanged<AccessibilityReport> onReport;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // Only the visible tab is built, so a scan never picks up the other one.
    final page = switch (_index) {
      0 => ScannerPage(
          key: const ValueKey('scanner'),
          themeMode: widget.themeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
          settings: widget.settings,
          report: widget.lastReport,
          onReport: widget.onReport,
        ),
      _ => SettingsPage(
          key: const ValueKey('settings'),
          themeMode: widget.themeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
          settings: widget.settings,
          onSettingsChanged: widget.onSettingsChanged,
          lastReport: widget.lastReport,
          onOpenScanner: () => setState(() => _index = 0),
        ),
    };

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _index = 0);
      },
      child: Scaffold(
        body: AmbientBackground(
          child: SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: page,
            ),
          ),
        ),
        bottomNavigationBar: _BottomNav(
          index: _index,
          onSelected: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onSelected});

  final int index;
  final ValueChanged<int> onSelected;

  static const _items = [
    (Icons.manage_search_rounded, Icons.search_rounded, 'Scanner'),
    (Icons.settings_rounded, Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.backgroundDeep,
        border: Border(top: BorderSide(color: context.colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SizedBox(
              height: 72,
              child: Row(
                children: [
                  for (var i = 0; i < _items.length; i++)
                    Expanded(
                      child: _NavItem(
                        selectedIcon: _items[i].$1,
                        icon: _items[i].$2,
                        label: _items[i].$3,
                        selected: i == index,
                        onTap: () => onSelected(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? context.colors.accent : context.colors.textSecondary;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              height: 3,
              width: selected ? 56 : 0,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(3)),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(
                              alpha: 0.7 * context.colors.glowStrength),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
            ),
            const Spacer(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                selected ? selectedIcon : icon,
                key: ValueKey(selected),
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
