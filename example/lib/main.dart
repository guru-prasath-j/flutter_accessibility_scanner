import 'package:flutter/material.dart';
import 'package:flutter_accessibility_scanner/flutter_accessibility_scanner.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AccessibilityScannerWidget(
      child: MaterialApp(
        title: 'Accessibility Scanner Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _scanResults = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Accessibility Scanner Demo'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Accessibility Issues Examples',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 20),

            // Example 1: Button with accessibility issues
            Text('❌ Bad: Button with issues'),
            SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showSnackBar('Tapped bad button'),
              child: Container(
                width: 30, // Too small
                height: 30, // Too small
                color: Colors.grey[300], // Poor contrast
                child:
                    Icon(Icons.star, color: Colors.grey[400]), // Poor contrast
              ),
            ),
            SizedBox(height: 20),

            // Example 2: Fixed button
            Text('✅ Good: Accessibility-enhanced button'),
            SizedBox(height: 8),
            AccessibilityFixerButton(
              onPressed: () => _showSnackBar('Tapped good button'),
              semanticsLabel: 'Add to favorites',
              semanticsHint: 'Adds this item to your favorites list',
              child: Icon(Icons.star, color: Colors.blue),
            ),
            SizedBox(height: 20),

            // Example 3: Text with poor contrast
            Text('❌ Bad: Poor contrast text'),
            SizedBox(height: 8),
            Text(
              'This text has poor contrast and is hard to read',
              style: TextStyle(color: Colors.grey[400]),
            ),
            SizedBox(height: 20),

            // Example 4: Fixed text
            Text('✅ Good: Accessible text'),
            SizedBox(height: 8),
            AccessibilityFixerText(
              text: 'This text has good contrast and is easy to read',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 30),

            // Manual scan button
            ElevatedButton.icon(
              onPressed: _performManualScan,
              icon: Icon(Icons.accessibility),
              label: Text('Run Manual Accessibility Scan'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
            ),
            SizedBox(height: 20),

            // Scan results
            if (_scanResults.isNotEmpty) ...[
              Text(
                'Scan Results:',
                style: Theme.of(context).textTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  _scanResults,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _performManualScan() async {
    try {
      final scanner = AccessibilityScanner();
      final report = await scanner.scan(context);

      setState(() {
        _scanResults = '''
${report.summary}

Detailed Issues:
${report.issues.map((issue) => '''
• ${issue.type.toString().split('.').last}
  ${issue.description}
  Severity: ${issue.severity.toString().split('.').last}
  ${issue.suggestion ?? 'No suggestion available'}
''').join('\n')}

JSON Report:
${report.toJson()}
        ''';
      });

      _showSnackBar(
          'Accessibility scan completed! Found ${report.totalIssues} issues.');
    } catch (e) {
      _showSnackBar('Scan failed: $e');
    }
  }
}
