import '../scripts/populate_database.dart';

/// Command line version to populate database
/// Run with: dart run lib/scripts/run_database_setup.dart
void main() async {
  await DatabasePopulator.populateDatabase();
}
