## 1.1.0

Accuracy, API and tooling overhaul. Source compatible with 1.0; scan
results are more precise, so issue counts will change.

### Detection
* Interactive elements are now found precisely from their gesture handlers
  (`GestureDetector`, `InkWell`, every Material button) instead of guessing
  from render-object type names, which removes most false positives from
  scroll views, pointer listeners and plain containers.
* **Missing labels**: a control counts as named when it contains visible text
  or has a `Semantics` label, `Tooltip`, or `Icon.semanticLabel`, including
  through `MergeSemantics` (e.g. `CheckboxListTile`). Icon glyphs no longer
  count as a label.
* **New `ImageLabelDetector`**: reports images without `semanticLabel` that
  are not marked `excludeFromSemantics` (WCAG 1.1.1).
* **Contrast**: reads backgrounds from `Container`/`ColoredBox`,
  `DecoratedBox`, `Material`, `Card` and `Scaffold`, blends translucent
  layers and text colors, honours the text scale factor, uses the correct
  WCAG "large text" size (24 px, or 18.66 px bold), and checks icon glyphs
  against the 3:1 non-text threshold (WCAG 1.4.11).
* **Tap targets**: accounts for the invisible 48x48 padding Material adds
  around small buttons; minimum size is configurable
  (`TapTargetDetector(minimumSize: 44)`).
* **Focus**: only reports controls that genuinely cannot take keyboard focus
  (e.g. a bare `GestureDetector`); `InkWell` and buttons pass.
* Offstage content (such as routes behind the current page) is skipped.

### API
* `AccessibilityScanner(detectors: [...])` runs a custom set of detectors,
  including your own `AccessibilityDetector` subclasses.
* `scan(context, minimumSeverity: ...)` and `scanRenderObject(root)`.
* Issues are sorted most severe first and carry `wcagCriterion` and global
  screen `bounds`.
* `AccessibilityReport`: `hasIssues`, `issuesByType`, `issuesAtLeast`,
  `issuesOfType`, `toMap`, `scannedElements`, `scanDuration`.
* `ColorContrastUtils`: `relativeLuminance`, `composite`, `wcagLevel`,
  `toHex`; `suggestBetterColor` now always returns a passing color with the
  smallest change.
* `AccessibilityScannerWidget`: outlines each issue on screen, lists issues
  with their WCAG criterion, adds `onReport`, `scanner`, `minimumSeverity`,
  `showHighlights` and `overlayDuration`, and no longer scans its own button.
* `AccessibilityFixerButton`: adds `tooltip`, `focusNode`, `autofocus` and
  `borderRadius`; no longer inserts a redundant focus stop or stretches to
  fill its parent.
* `AccessibilityFixerText`: `backgroundColor` now actually enforces AA
  contrast; long text is no longer truncated for screen readers. Adds
  `textAlign`, `maxLines` and `overflow`.
* All detectors have `const` constructors.

### Maintenance
* Removed debug `print` output from scans.
* Migrated off deprecated `Color` APIs; requires Flutter 3.27+ / Dart 3.6+.
* Fixed pubspec URLs, shortened the description and added topics.
* Clean static analysis, full API docs, new tests, CI and automated
  publishing.

## 1.0.0

### Initial Release

* ✨ **Core Features**
  - Automatic widget tree scanning for accessibility issues
  - WCAG 2.1 AA compliance checking
  - Real-time development scanning with visual feedback
  - JSON report generation with detailed issue metadata

* 🔍 **Issue Detection**
  - Missing semantic labels and descriptions
  - Poor color contrast ratios (below 4.5:1 WCAG standard)
  - Tap targets smaller than 48x48 logical pixels
  - Missing keyboard focus support

* 🛠️ **Developer Tools**
  - `AccessibilityScanner` - Main scanning engine
  - `AccessibilityScannerWidget` - Real-time development overlay
  - `AccessibilityFixerButton` - Helper widget for accessible buttons
  - `AccessibilityFixerText` - Helper widget for accessible text
  - `ColorContrastUtils` - WCAG color contrast calculations

* 📊 **Reporting**
  - Detailed accessibility reports with severity levels
  - JSON export functionality
  - Issue grouping by severity (Critical, High, Medium, Low)
  - Actionable suggestions for each detected issue

* 🧪 **Testing Integration**
  - Widget test compatibility
  - Comprehensive test suite with 16 passing tests
  - Integration test examples

* 📚 **Documentation**
  - Complete API documentation
  - Beginner-friendly examples
  - WCAG 2.1 guidelines mapping
  - Best practices guide
