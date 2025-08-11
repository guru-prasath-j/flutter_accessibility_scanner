## Flutter Accessibility Scanner

A comprehensive Flutter package that automatically scans Flutter apps for accessibility issues and provides suggestions or automated fixes to improve app accessibility compliance with WCAG 2.1 guidelines.

## What is Accessibility?

Accessibility ensures that your Flutter app can be used by everyone, including people with disabilities who rely on screen readers, voice control, or other assistive technologies. This package helps you identify and fix common accessibility problems automatically.

## Features

- 🔍 **Automatic Widget Tree Scanning**: Scans your Flutter widget tree to detect accessibility issues
- 📊 **WCAG 2.1 Compliance**: Checks against Web Content Accessibility Guidelines 2.1 AA standards
- 🎯 **Multiple Issue Detection**:
  - Missing semantic labels and descriptions
  - Poor color contrast ratios (below WCAG standards)
  - Tap targets smaller than 48x48 logical pixels
  - Missing keyboard focus support
- 🛠️ **Automated Fix Suggestions**: Provides actionable suggestions for each detected issue
- 🧩 **Helper Widgets**: Pre-built widgets that automatically apply accessibility best practices
- 📋 **JSON Reports**: Generate detailed accessibility reports in JSON format
- 🐛 **Development Tools**: Real-time scanning during development with visual feedback

## Getting Started

### Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_accessibility_scanner: ^1.0.0

dev_dependencies:
  flutter_accessibility_scanner: ^1.0.0
```

Then run:

```bash
flutter pub get
```

### Import the Package

```dart
import 'package:flutter_accessibility_scanner/flutter_accessibility_scanner.dart';
```

## Basic Usage

### 1. Simple One-Time Scan

The easiest way to check your app for accessibility issues:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_accessibility_scanner/flutter_accessibility_scanner.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('My App')),
        body: Column(
          children: [
            // Your app content here
            ElevatedButton(
              onPressed: () async {
                // Scan for accessibility issues
                final scanner = AccessibilityScanner();
                final report = await scanner.scan(context);
                
                //print('Found ${report.totalIssues} accessibility issues');
                
                // Show issues
                for (final issue in report.issues) {
                  //print('${issue.type}: ${issue.description}');
                  //print('Suggestion: ${issue.suggestion}');
                }
              },
              child: Text('Check Accessibility'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 2. Real-Time Development Scanning

For continuous feedback while developing, wrap your app with `AccessibilityScannerWidget`:

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AccessibilityScannerWidget(
      enabled: true, // Only enabled in debug mode by default
      child: MaterialApp(
        home: MyHomePage(),
      ),
    );
  }
}
```

This adds a floating accessibility button that you can tap to scan your current screen and see results in an overlay.

### 3. Using Helper Widgets

Instead of fixing issues manually, use the provided helper widgets:

```dart
// ❌ Problematic button (too small, no semantics)
GestureDetector(
  onTap: () => doSomething(),
  child: Container(
    width: 30, // Too small!
    height: 30, // Too small!
    child: Icon(Icons.star),
  ),
)

// ✅ Accessible button using helper widget
AccessibilityFixerButton(
  onPressed: () => doSomething(),
  semanticsLabel: 'Add to favorites',
  semanticsHint: 'Double tap to add this item to your favorites',
  child: Icon(Icons.star),
)
```

## What Issues Does It Detect?

### 1. Missing Semantic Labels
**Problem**: Interactive elements without labels that screen readers can't understand.

```dart
// ❌ Bad: No label for screen reader
GestureDetector(
  onTap: () => save(),
  child: Icon(Icons.save),
)

// ✅ Good: Has semantic label
Semantics(
  label: 'Save document',
  child: GestureDetector(
    onTap: () => save(),
    child: Icon(Icons.save),
  ),
)
```

### 2. Poor Color Contrast
**Problem**: Text that's hard to read due to insufficient contrast with background.

```dart
// ❌ Bad: Poor contrast (will be detected)
Text(
  'Hard to read',
  style: TextStyle(color: Colors.grey[400]), // On white background
)

// ✅ Good: High contrast
Text(
  'Easy to read',
  style: TextStyle(color: Colors.black), // On white background
)
```

### 3. Small Tap Targets
**Problem**: Buttons or interactive areas smaller than 48x48 pixels are hard to tap.

```dart
// ❌ Bad: Too small to tap easily
Container(
  width: 20, // Too small!
  height: 20, // Too small!
  child: GestureDetector(
    onTap: () => action(),
    child: Icon(Icons.close, size: 16),
  ),
)

// ✅ Good: Proper tap target size
Container(
  width: 48, // Minimum recommended size
  height: 48,
  child: GestureDetector(
    onTap: () => action(),
    child: Icon(Icons.close),
  ),
)
```

### 4. Missing Focus Support
**Problem**: Interactive elements that can't be navigated with keyboard or assistive devices.

## Understanding the Report

When you run a scan, you get an `AccessibilityReport` object:

```dart
final report = await scanner.scan(context);

// Basic information
//print('Total issues: ${report.totalIssues}');
//print('Scan time: ${report.timestamp}');

// Issues by severity
final critical = report.issuesBySeverity[AccessibilityIssueSeverity.critical];
//print('Critical issues: ${critical.length ?? 0}');

// Detailed JSON report
String jsonReport = report.toJson();
//print(jsonReport); // Save this for detailed analysis

// Human-readable summary
//print(report.summary);
```

### Issue Severity Levels

- **Critical**: Major barriers (contrast ratio < 3.0, very small tap targets)
- **High**: Significant issues (missing labels, poor contrast)
- **Medium**: Important improvements (missing focus support)
- **Low**: Minor issues (slightly small tap targets)

## Advanced Usage

### Custom Color Contrast Checking

```dart
import 'package:flutter_accessibility_scanner/flutter_accessibility_scanner.dart';

// Check specific colors
double contrastRatio = ColorContrastUtils.calculateContrastRatio(
  Colors.black,   // Text color
  Colors.white,   // Background color
);

//print('Contrast ratio: $contrastRatio'); // Should be >= 4.5 for WCAG AA

// Check if colors meet standards
bool meetsWCAGAA = ColorContrastUtils.meetsWCAGAA(contrastRatio);
//print('Meets WCAG AA: $meetsWCAGAA');

// Get suggested better color
Color betterColor = ColorContrastUtils.suggestBetterColor(
  Colors.grey[400]!, // Current poor color
  Colors.white,      // Background
);
```

### Widget Testing Integration

Use in your widget tests to ensure accessibility:

```dart
testWidgets('App should be accessible', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  
  final scanner = AccessibilityScanner();
  final report = await scanner.scan(tester.element(find.byType(MyApp)));
  
  // Ensure no critical accessibility issues
  final criticalIssues = report.issuesBySeverity[AccessibilityIssueSeverity.critical];
  expect(criticalIssues.length ?? 0, equals(0), 
    reason: 'App should have no critical accessibility issues');
});
```

## How It Works Under the Hood

### Architecture Overview

The package is built with a modular architecture:

```
AccessibilityScanner
├── SemanticsDetector      → Finds missing labels
├── ContrastDetector       → Checks color contrast
├── TapTargetDetector      → Measures tap target sizes
└── FocusDetector          → Verifies focus support
```

### The Scanning Process

1. **Widget Tree Traversal**: The scanner walks through your Flutter widget tree recursively
2. **Render Object Analysis**: Each detector examines Flutter's render objects (the actual visual elements)
3. **Issue Detection**: Detectors apply WCAG rules to identify problems
4. **Report Generation**: All issues are collected into a comprehensive report

### Key Technical Components

#### 1. Render Object Detection
```dart
// The scanner examines Flutter's render objects
RenderObject renderObject = context.findRenderObject();

// Each detector looks for specific patterns
bool isInteractive = renderObject is RenderPointerListener ||
                    renderObject.runtimeType.toString().contains('button');
```

#### 2. WCAG Color Contrast Calculation
```dart
// Implements the official WCAG formula
double relativeLuminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue;
double contrastRatio = (lighterLuminance + 0.05) / (darkerLuminance + 0.05);
```

#### 3. Semantic Analysis
```dart
// Checks Flutter's semantic tree
SemanticsNode? semantics = renderObject.debugSemantics;
bool hasLabel = semantics.label.isNotEmpty == true;
```

## WCAG Guidelines Covered

This package helps you comply with these WCAG 2.1 Level AA guidelines:

- **1.1.1 Non-text Content**: Detects images and interactive elements missing alternative text
- **1.4.3 Contrast (Minimum)**: Ensures text has sufficient color contrast (4.5:1 ratio)
- **1.4.11 Non-text Contrast**: Checks contrast for UI components and graphics
- **2.1.1 Keyboard**: Identifies interactive elements lacking keyboard support
- **2.5.5 Target Size**: Ensures interactive elements meet minimum size requirements (48x48px)

## Best Practices

### 1. Run Scans Regularly
```dart
// Add to your development workflow
void main() {
  runApp(
    AccessibilityScannerWidget(
      enabled: kDebugMode, // Only in development
      child: MyApp(),
    ),
  );
}
```

### 2. Use Helper Widgets
```dart
// Instead of manual fixes, use provided widgets
AccessibilityFixerButton(
  semanticsLabel: 'Delete item',
  onPressed: () => delete(),
  child: Icon(Icons.delete),
)

AccessibilityFixerText(
  'Important message',
  style: TextStyle(fontSize: 16), // Automatically ensures good contrast
)
```

### 3. Test with Real Users
While this package catches many issues automatically, always test with real screen readers and assistive technologies.

## Example JSON Report

```json
{
  "timestamp": "2023-12-07T10:30:00.000Z",
  "totalIssues": 3,
  "issuesBySeverity": {
    "critical": 1,
    "high": 1,
    "medium": 1,
    "low": 0
  },
  "issues": [
    {
      "type": "AccessibilityIssueType.poorColorContrast",
      "description": "Text color contrast ratio 2.1 does not meet WCAG AA standards",
      "severity": "AccessibilityIssueSeverity.critical",
      "suggestion": "Use a color with better contrast. Suggested: #000000",
      "metadata": {
        "contrastRatio": 2.1,
        "foregroundColor": "#666666",
        "backgroundColor": "#cccccc",
        "requiredRatio": 4.5
      },
      "bounds": {
        "left": 16.0,
        "top": 100.0,
        "right": 200.0,
        "bottom": 120.0
      }
    }
  ]
}
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## Testing

Run the package tests:

```bash
flutter test
```

The package includes comprehensive tests for:
- Scanner functionality
- Color contrast calculations  
- Helper widgets
- Report generation

## License

This project is licensed under the MIT License.

## Acknowledgments

- WCAG 2.1 Guidelines for accessibility standards
- Flutter team for the excellent accessibility framework
- Community feedback and contributions

---

**Remember**: This package helps identify and fix common accessibility issues, but manual testing with actual assistive technologies is still recommended for comprehensive accessibility validation.

**Need Help?** Check out Flutter's [accessibility documentation](https://docs.flutter.dev/development/accessibility-and-localization/accessibility) for more information about building accessible Flutter apps.
