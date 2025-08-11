# Manual Testing Guide for Flutter Accessibility Scanner

## Quick Verification Steps

### 1. Run the Tests
```bash
cd flutter_accessibility_scanner
flutter test
```

Expected output:
- All tests should pass
- You should see test results for scanner, utils, widgets, and reports

### 2. Run the Example App
```bash
cd example
flutter run
```

What to look for:
- App launches successfully
- Floating accessibility button appears in top-right
- Manual scan button works in the app

### 3. Test Real-time Scanning

1. **Tap the floating accessibility button** (blue circle with accessibility icon)
2. **Wait for scan to complete** (button shows loading spinner)
3. **Check the overlay** that appears showing scan results
4. **Verify color changes**: 
   - Green = No issues
   - Yellow = Minor issues  
   - Orange = Medium issues
   - Red = Critical issues

### 4. Test Manual Scanning

1. **Tap "Run Manual Accessibility Scan"** button in the example app
2. **Check console output** for detailed scan results
3. **Verify the results display** shows:
   - Issue count
   - Issue types found
   - Severity levels
   - JSON report

### 5. Verify Issue Detection

The example app contains intentional accessibility issues:

#### Expected Issues to be Detected:
1. **Small Tap Target**: 30x30px button (should be ≥48x48px)
2. **Poor Color Contrast**: Grey text on grey background
3. **Missing Semantics**: GestureDetector without labels
4. **Missing Focus Support**: Interactive elements without keyboard support

#### Expected Good Examples:
1. **AccessibilityFixerButton**: Should NOT trigger issues
2. **AccessibilityFixerText**: Should have good contrast

### 6. Test Color Contrast Utils

Create a simple test to verify contrast calculations:

```dart
void testContrast() {
  // Maximum contrast (black on white)
  final maxContrast = ColorContrastUtils.calculateContrastRatio(
    Colors.black, 
    Colors.white
  );
  //print('Max contrast: $maxContrast'); // Should be ~21.0
  
  // Poor contrast
  final poorContrast = ColorContrastUtils.calculateContrastRatio(
    Colors.grey[400]!, 
    Colors.grey[300]!
  );
  //print('Poor contrast: $poorContrast'); // Should be < 4.5
  
  // Check WCAG compliance
  //print('Meets WCAG AA: ${ColorContrastUtils.meetsWCAGAA(maxContrast)}'); // true
  //print('Poor meets WCAG AA: ${ColorContrastUtils.meetsWCAGAA(poorContrast)}'); // false
}
```

## Debugging Common Issues

### Issue: Tests Failing
**Check:**
- All imports are correct
- Dependencies in pubspec.yaml are properly added
- Flutter SDK version compatibility

### Issue: Scanner Not Finding Issues
**Possible causes:**
- Widget tree not fully built when scan runs
- RenderObjects not accessible
- Semantic information already present

**Debug steps:**
1. Add //print statements in detectors
2. Check if `context.findRenderObject()` returns valid objects
3. Verify render object types match expected patterns

### Issue: No Contrast Issues Detected
**Check:**
- Background color estimation logic
- Theme colors overriding text colors
- Text styles being applied correctly

### Issue: Tap Target Issues Not Found
**Verify:**
- Interactive elements are actually GestureDetectors or similar
- Size calculations are working correctly
- paintBounds are accessible

## Sample Console Output

When working correctly, you should see output like:

```
=== ACCESSIBILITY SCAN RESULTS ===
Total issues found: 4

Issue breakdown:
- AccessibilityIssueType.smallTapTarget: Interactive element tap target is smaller than recommended 48.0x48.0 pixels
  Severity: AccessibilityIssueSeverity.high
  Suggestion: Increase the tap target size to at least 48.0x48.0 pixels

- AccessibilityIssueType.poorColorContrast: Text color contrast ratio 1.2 does not meet WCAG AA standards
  Severity: AccessibilityIssueSeverity.critical
  Suggestion: Use a color with better contrast. Suggested: #000000

- AccessibilityIssueType.missingSemanticsLabel: Interactive widget missing semantic label
  Severity: AccessibilityIssueSeverity.high
  Suggestion: Add a Semantics widget or semanticsLabel property

JSON Report:
{"timestamp":"2023-12-07T10:30:00.000Z","totalIssues":4,"issuesBySeverity":{"critical":1,"high":2,"medium":1,"low":0},"issues":[...]}
```

## Performance Testing

1. **Large Widget Trees**: Test with apps containing 100+ widgets
2. **Complex Layouts**: Test with nested scrollviews, tabs, complex navigations
3. **Animation Testing**: Verify scanner works during animations
4. **Memory Usage**: Monitor memory consumption during scans

## Screen Reader Testing

To fully verify accessibility:

1. **Enable TalkBack** (Android) or **VoiceOver** (iOS)
2. **Navigate the example app** using only screen reader
3. **Verify announcements** match semantic labels
4. **Test button interactions** work with screen reader

## Integration with CI/CD

Add to your test pipeline:

```yaml
# In .github/workflows/test.yml
- name: Run Accessibility Tests
  run: |
    cd flutter_accessibility_scanner
    flutter test
    cd example
    flutter test integration_test/
```
