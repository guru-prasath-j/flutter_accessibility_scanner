import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_accessibility_scanner/flutter_accessibility_scanner.dart';

import 'main.dart' show ScannerSettings;
import 'theme.dart';

/// Settings: appearance, scanner options, the checks that run, the last
/// scan and package info.
class SettingsPage extends StatelessWidget {
  /// Creates the page.
  const SettingsPage({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.settings,
    required this.onSettingsChanged,
    required this.lastReport,
    required this.onOpenScanner,
  });

  /// The app's current theme mode.
  final ThemeMode themeMode;

  /// Called when the user picks another theme mode.
  final ValueChanged<ThemeMode> onThemeModeChanged;

  /// Current scanner settings.
  final ScannerSettings settings;

  /// Called when a setting changes.
  final ValueChanged<ScannerSettings> onSettingsChanged;

  /// The most recent scan, if any.
  final AccessibilityReport? lastReport;

  /// Switches to the Scanner tab.
  final VoidCallback onOpenScanner;

  static const _durations = [
    (Duration(seconds: 3), '3 s'),
    (Duration(seconds: 5), '5 s'),
    (Duration(seconds: 10), '10 s'),
    (Duration.zero, 'Until closed'),
  ];

  static const _checks = [
    (
      Icons.label_outline_rounded,
      'Semantic labels',
      'Interactive widgets need a name screen readers can announce.',
      '4.1.2 · 1.3.1',
    ),
    (
      Icons.image_outlined,
      'Image descriptions',
      'Meaningful images need a label; decorative ones are skipped.',
      '1.1.1',
    ),
    (
      Icons.contrast_rounded,
      'Colour contrast',
      'Text 4.5:1 (3:1 large), icons 3:1 — with a suggested fix colour.',
      '1.4.3 · 1.4.11',
    ),
    (
      Icons.touch_app_outlined,
      'Tap target size',
      'Touch targets should be at least 48 × 48 logical pixels.',
      '2.5.5',
    ),
    (
      Icons.keyboard_outlined,
      'Keyboard focus',
      'Tappable widgets must be reachable without a pointer.',
      '2.1.1',
    ),
  ];

  void _copy(BuildContext context, String text, String what) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final report = lastReport;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  // Leave room for the floating scan button (top-right).
                  padding: EdgeInsets.only(
                    right: settings.overlayEnabled ? 56 : 0,
                  ),
                  child: SizedBox(
                    height: 48,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Semantics(
                        header: true,
                        child: Text(
                          'Settings',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontSize: 28),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const _InfoBanner(),

                // ── Appearance ──────────────────────────────────────────
                const _Section('Appearance'),
                _ThemeSelector(mode: themeMode, onChanged: onThemeModeChanged),

                // ── Scanner ────────────────────────────────────────────
                const _Section('Scanner'),
                _Card(children: [
                  _SwitchRow(
                    icon: Icons.accessibility_new_rounded,
                    label: 'Floating scan button',
                    detail: 'Scan any screen from a button in the corner.',
                    value: settings.overlayEnabled,
                    onChanged: (v) =>
                        onSettingsChanged(settings.copyWith(overlayEnabled: v)),
                  ),
                  _SwitchRow(
                    icon: Icons.highlight_alt_rounded,
                    label: 'Highlight issues',
                    detail: 'Outline each issue on screen after a scan.',
                    value: settings.showHighlights,
                    onChanged: (v) =>
                        onSettingsChanged(settings.copyWith(showHighlights: v)),
                  ),
                  _ChoiceRow<AccessibilityIssueSeverity>(
                    icon: Icons.filter_alt_outlined,
                    label: 'Minimum severity',
                    detail: 'Issues below this level are not reported.',
                    value: settings.minimumSeverity,
                    options: [
                      for (final s in AccessibilityIssueSeverity.values)
                        (s, capitalize(s.name)),
                    ],
                    onChanged: (v) => onSettingsChanged(
                        settings.copyWith(minimumSeverity: v)),
                  ),
                  _ChoiceRow<Duration>(
                    icon: Icons.timer_outlined,
                    label: 'Keep results visible',
                    detail: 'How long the overlay report stays on screen.',
                    value: settings.overlayDuration,
                    options: _durations,
                    onChanged: (v) => onSettingsChanged(
                        settings.copyWith(overlayDuration: v)),
                  ),
                ]),

                // ── Checks ─────────────────────────────────────────────
                const _Section('Checks · WCAG 2.1'),
                _Card(children: [
                  for (final (icon, name, detail, wcag) in _checks)
                    _CheckRow(
                      icon: icon,
                      name: name,
                      detail: detail,
                      wcag: wcag,
                    ),
                ]),

                // ── Last scan ──────────────────────────────────────────
                const _Section('Last scan'),
                if (report == null)
                  _Card(children: [
                    _ActionRow(
                      icon: Icons.manage_search_rounded,
                      label: 'No scans yet — run one on the Scanner tab',
                      onTap: onOpenScanner,
                    ),
                  ])
                else
                  _Card(children: [
                    _InfoRow(
                      Icons.report_gmailerrorred_rounded,
                      'Issues found',
                      '${report.totalIssues}',
                      valueColor: report.hasIssues
                          ? colors.dangerText
                          : colors.successText,
                    ),
                    if (report.scannedElements != null)
                      _InfoRow(Icons.account_tree_outlined, 'Elements scanned',
                          '${report.scannedElements}'),
                    if (report.scanDuration != null)
                      _InfoRow(Icons.speed_rounded, 'Duration',
                          '${report.scanDuration!.inMilliseconds} ms'),
                    _InfoRow(Icons.schedule_rounded, 'Scanned at',
                        _time(report.timestamp)),
                    _ActionRow(
                      icon: Icons.data_object_rounded,
                      label: 'Copy report as JSON',
                      onTap: () => _copy(
                          context, report.toJson(pretty: true), 'JSON report'),
                    ),
                    _ActionRow(
                      icon: Icons.notes_rounded,
                      label: 'Copy report as Markdown',
                      onTap: () => _copy(
                          context, report.toMarkdown(), 'Markdown report'),
                    ),
                  ]),

                // ── About ──────────────────────────────────────────────
                const _Section('About'),
                _Card(children: [
                  const _InfoRow(Icons.inventory_2_outlined, 'Package',
                      AppInfo.packageName),
                  const _InfoRow(
                      Icons.info_outline_rounded, 'Version', AppInfo.version),
                  const _InfoRow(
                      Icons.gavel_rounded, 'License', AppInfo.license),
                  const _InfoRow(Icons.flutter_dash, 'Requires',
                      'Flutter 3.27+ · Dart 3.6+'),
                  _ActionRow(
                    icon: Icons.code_rounded,
                    label: 'Copy repository link',
                    onTap: () =>
                        _copy(context, AppInfo.repository, 'Repository link'),
                  ),
                  _ActionRow(
                    icon: Icons.description_outlined,
                    label: 'Open-source licenses',
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: 'Accessibility Scanner',
                      applicationVersion: AppInfo.version,
                      applicationIcon: const Padding(
                        padding: EdgeInsets.all(12),
                        child: AppLogo(size: 56),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Made with Flutter · ${AppInfo.license} licensed',
                    style: TextStyle(color: colors.textMuted, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _time(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    final l = t.toLocal();
    return '${two(l.hour)}:${two(l.minute)}:${two(l.second)}';
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.28),
            AppColors.primaryDeep.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const AppLogo(size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scans run inside your app',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  'The live widget tree is checked on-device — no network, '
                  'no data leaves the app.',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 13.5,
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

/// Three-way System / Light / Dark switch with a sliding highlight.
class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.mode, required this.onChanged});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  static const _options = [
    (ThemeMode.system, Icons.brightness_auto_rounded, 'System'),
    (ThemeMode.light, Icons.light_mode_rounded, 'Light'),
    (ThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final selected = _options.indexWhere((o) => o.$1 == mode);
    return Container(
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: c.border),
      ),
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth / _options.length;
        return Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              left: w * selected,
              top: 0,
              bottom: 0,
              width: w,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.lavenderLight, AppColors.lavender],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary
                          .withValues(alpha: 0.35 * c.glowStrength),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                for (final (value, icon, label) in _options)
                  Expanded(
                    child: Semantics(
                      selected: value == mode,
                      button: true,
                      label: '$label theme',
                      excludeSemantics: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        onTap: () => onChanged(value),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  icon,
                                  size: 18,
                                  color: value == mode
                                      ? AppColors.onLavender
                                      : c.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: value == mode
                                        ? AppColors.onLavender
                                        : c.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 28, 4, 10),
      child: Semantics(
        header: true,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: context.colors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(indent: 52),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value, {this.valueColor});

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.colors.accent),
          const SizedBox(width: 16),
          Text(label),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor ?? context.colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: context.colors.accent),
            const SizedBox(width: 16),
            Expanded(child: Text(label)),
            Icon(Icons.chevron_right_rounded, color: context.colors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.detail,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: context.colors.accent),
              const SizedBox(width: 16),
              Expanded(child: _LabelDetail(label: label, detail: detail)),
              const SizedBox(width: 12),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.icon,
    required this.label,
    required this.detail,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String detail;
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: c.accent),
              const SizedBox(width: 16),
              Expanded(child: _LabelDetail(label: label, detail: detail)),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (v, text) in options)
                  _ChoiceChip(
                    label: text,
                    selected: v == value,
                    onTap: () => onChanged(v),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 40, minWidth: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? AppColors.brandGradient : null,
            color: selected ? null : c.surfaceHigh,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? Colors.transparent : c.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : c.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.icon,
    required this.name,
    required this.detail,
    required this.wcag,
  });

  final IconData icon;
  final String name;
  final String detail;
  final String wcag;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: c.accent),
          const SizedBox(width: 16),
          Expanded(child: _LabelDetail(label: name, detail: detail)),
          const SizedBox(width: 12),
          TintPill(
            label: wcag,
            color: AppColors.primary,
            textColor: c.accent,
          ),
        ],
      ),
    );
  }
}

class _LabelDetail extends StatelessWidget {
  const _LabelDetail({required this.label, required this.detail});

  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(
          detail,
          style: TextStyle(color: context.colors.textSecondary, fontSize: 13.5),
        ),
      ],
    );
  }
}
