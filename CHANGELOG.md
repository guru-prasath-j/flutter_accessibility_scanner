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
