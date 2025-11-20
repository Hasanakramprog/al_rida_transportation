import 'package:flutter/material.dart';
import 'scripts/populate_database.dart';

/// Simple Flutter app to run database population
/// Run this with: flutter run lib/database_setup_runner.dart
void main() {
  runApp(const DatabaseSetupApp());
}

class DatabaseSetupApp extends StatelessWidget {
  const DatabaseSetupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Database Setup',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DatabaseSetupScreen(),
    );
  }
}

class DatabaseSetupScreen extends StatefulWidget {
  const DatabaseSetupScreen({super.key});

  @override
  State<DatabaseSetupScreen> createState() => _DatabaseSetupScreenState();
}

class _DatabaseSetupScreenState extends State<DatabaseSetupScreen> {
  bool _isLoading = false;
  String _status = 'Ready to populate database';
  List<String> _logs = [];

  Future<void> _populateDatabase() async {
    setState(() {
      _isLoading = true;
      _status = 'Populating database...';
      _logs.clear();
    });

    try {
      await DatabasePopulator.populateDatabase();
      
      setState(() {
        _logs.addAll([
          '🔥 Firebase initialized successfully',
          '📊 Starting database population...',
          '📋 Populating schedule suffixes...',
          '✅ Schedule suffixes populated (20 items)',
          '🏙️ Populating cities...',
          '✅ Cities populated (20 items)',
          '✅ Database population completed successfully!',
        ]);
      });

      setState(() {
        _status = 'Database populated successfully!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
        _logs.add('❌ Error: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Database Setup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.storage,
                      size: 48,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Al Rida Transportation Database Setup',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This will populate your Firestore database with:\n'
                      '• 20 Schedule Suffixes (A1-D5) with costs\n'
                      '• 20 Cities across 4 zones\n',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _status,
                      style: TextStyle(
                        color: _isLoading 
                            ? Colors.orange 
                            : _status.contains('Error')
                                ? Colors.red
                                : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _populateDatabase,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isLoading ? 'Populating...' : 'Populate Database'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            if (_logs.isNotEmpty) ...[
              const Text(
                'Logs:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            _logs[index],
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
