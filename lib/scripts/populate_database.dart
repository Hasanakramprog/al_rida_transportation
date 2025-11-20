import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

/// Script to populate Firestore with initial data
/// Run this script once to set up the database with schedule suffixes and cities
class DatabasePopulator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize Firebase and populate database
  static Future<void> populateDatabase() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      print('🔥 Firebase initialized successfully');
      print('📊 Starting database population...\n');

      // Populate schedule suffixes
      await _populateScheduleSuffixes();

      // Populate cities
      await _populateCities();

      print('✅ Database population completed successfully!');
    } catch (e) {
      print('❌ Error populating database: $e');
    }
  }

  /// Populate schedule suffixes with costs
  static Future<void> _populateScheduleSuffixes() async {
    print('📋 Populating schedule suffixes...');

    final scheduleSuffixes = [
      // Zone A - Premium locations ($5-8 per day)
      {
        'code': 'A1',
        'zone': 'A',
        'daysPerWeek': 1,
        'dailyCost': 5.0,
        'monthlyCost': 17.0, // Monthly discount: ~15%
        'description': 'Premium Area - 1 day per week'
      },
      {
        'code': 'A2',
        'zone': 'A',
        'daysPerWeek': 2,
        'dailyCost': 5.0,
        'monthlyCost': 34.0,
        'description': 'Premium Area - 2 days per week'
      },
      {
        'code': 'A3',
        'zone': 'A',
        'daysPerWeek': 3,
        'dailyCost': 5.0,
        'monthlyCost': 51.0,
        'description': 'Premium Area - 3 days per week'
      },
      {
        'code': 'A4',
        'zone': 'A',
        'daysPerWeek': 4,
        'dailyCost': 5.0,
        'monthlyCost': 68.0,
        'description': 'Premium Area - 4 days per week'
      },
      {
        'code': 'A5',
        'zone': 'A',
        'daysPerWeek': 5,
        'dailyCost': 5.0,
        'monthlyCost': 85.0,
        'description': 'Premium Area - 5 days per week'
      },

      // Zone B - Business district ($7-10 per day)
      {
        'code': 'B1',
        'zone': 'B',
        'daysPerWeek': 1,
        'dailyCost': 7.0,
        'monthlyCost': 23.8,
        'description': 'Business District - 1 day per week'
      },
      {
        'code': 'B2',
        'zone': 'B',
        'daysPerWeek': 2,
        'dailyCost': 7.0,
        'monthlyCost': 47.6,
        'description': 'Business District - 2 days per week'
      },
      {
        'code': 'B3',
        'zone': 'B',
        'daysPerWeek': 3,
        'dailyCost': 7.0,
        'monthlyCost': 71.4,
        'description': 'Business District - 3 days per week'
      },
      {
        'code': 'B4',
        'zone': 'B',
        'daysPerWeek': 4,
        'dailyCost': 7.0,
        'monthlyCost': 95.2,
        'description': 'Business District - 4 days per week'
      },
      {
        'code': 'B5',
        'zone': 'B',
        'daysPerWeek': 5,
        'dailyCost': 7.0,
        'monthlyCost': 119.0,
        'description': 'Business District - 5 days per week'
      },

      // Zone C - Residential area ($6-9 per day)
      {
        'code': 'C1',
        'zone': 'C',
        'daysPerWeek': 1,
        'dailyCost': 6.0,
        'monthlyCost': 20.4,
        'description': 'Residential Area - 1 day per week'
      },
      {
        'code': 'C2',
        'zone': 'C',
        'daysPerWeek': 2,
        'dailyCost': 6.0,
        'monthlyCost': 40.8,
        'description': 'Residential Area - 2 days per week'
      },
      {
        'code': 'C3',
        'zone': 'C',
        'daysPerWeek': 3,
        'dailyCost': 6.0,
        'monthlyCost': 61.2,
        'description': 'Residential Area - 3 days per week'
      },
      {
        'code': 'C4',
        'zone': 'C',
        'daysPerWeek': 4,
        'dailyCost': 6.0,
        'monthlyCost': 81.6,
        'description': 'Residential Area - 4 days per week'
      },
      {
        'code': 'C5',
        'zone': 'C',
        'daysPerWeek': 5,
        'dailyCost': 6.0,
        'monthlyCost': 102.0,
        'description': 'Residential Area - 5 days per week'
      },

      // Zone D - Extended area ($8-12 per day)
      {
        'code': 'D1',
        'zone': 'D',
        'daysPerWeek': 1,
        'dailyCost': 8.0,
        'monthlyCost': 27.2,
        'description': 'Extended Area - 1 day per week'
      },
      {
        'code': 'D2',
        'zone': 'D',
        'daysPerWeek': 2,
        'dailyCost': 8.0,
        'monthlyCost': 54.4,
        'description': 'Extended Area - 2 days per week'
      },
      {
        'code': 'D3',
        'zone': 'D',
        'daysPerWeek': 3,
        'dailyCost': 8.0,
        'monthlyCost': 81.6,
        'description': 'Extended Area - 3 days per week'
      },
      {
        'code': 'D4',
        'zone': 'D',
        'daysPerWeek': 4,
        'dailyCost': 8.0,
        'monthlyCost': 108.8,
        'description': 'Extended Area - 4 days per week'
      },
      {
        'code': 'D5',
        'zone': 'D',
        'daysPerWeek': 5,
        'dailyCost': 8.0,
        'monthlyCost': 136.0,
        'description': 'Extended Area - 5 days per week'
      },
    ];

    final batch = _firestore.batch();
    final collection = _firestore.collection('schedule_suffixes');

    for (int i = 0; i < scheduleSuffixes.length; i++) {
      final docRef = collection.doc(); // Auto-generate ID
      batch.set(docRef, scheduleSuffixes[i]);
      print('  ➕ Adding ${scheduleSuffixes[i]['code']} - \$${scheduleSuffixes[i]['dailyCost']}/day, \$${scheduleSuffixes[i]['monthlyCost']}/month');
    }

    await batch.commit();
    print('✅ Schedule suffixes populated (${scheduleSuffixes.length} items)\n');
  }

  /// Populate cities for each zone
  static Future<void> _populateCities() async {
    print('🏙️ Populating cities...');

    final cities = [
      // Zone A Cities - Premium locations
      {'name': 'Downtown Central', 'zone': 'A', 'description': 'Main business district'},
      {'name': 'Financial District', 'zone': 'A', 'description': 'Banking and finance hub'},
      {'name': 'Government Quarter', 'zone': 'A', 'description': 'Administrative center'},
      {'name': 'Premium Mall Area', 'zone': 'A', 'description': 'High-end shopping district'},
      {'name': 'Corporate Plaza', 'zone': 'A', 'description': 'Major corporate offices'},

      // Zone B Cities - Business district
      {'name': 'Tech Park', 'zone': 'B', 'description': 'Technology companies hub'},
      {'name': 'Industrial Complex', 'zone': 'B', 'description': 'Manufacturing area'},
      {'name': 'Medical Center', 'zone': 'B', 'description': 'Hospital and clinics'},
      {'name': 'University District', 'zone': 'B', 'description': 'Educational institutions'},
      {'name': 'Airport Zone', 'zone': 'B', 'description': 'Airport and logistics'},

      // Zone C Cities - Residential areas
      {'name': 'Green Valley', 'zone': 'C', 'description': 'Residential suburbs'},
      {'name': 'Family Heights', 'zone': 'C', 'description': 'Family-friendly neighborhood'},
      {'name': 'Student Village', 'zone': 'C', 'description': 'Student accommodation area'},
      {'name': 'Peaceful Gardens', 'zone': 'C', 'description': 'Quiet residential zone'},
      {'name': 'Community Center', 'zone': 'C', 'description': 'Local services hub'},

      // Zone D Cities - Extended areas
      {'name': 'Coastal Region', 'zone': 'D', 'description': 'Beachfront communities'},
      {'name': 'Mountain View', 'zone': 'D', 'description': 'Highland residential area'},
      {'name': 'Rural Connect', 'zone': 'D', 'description': 'Rural and farming areas'},
      {'name': 'Border Town', 'zone': 'D', 'description': 'Edge of service area'},
      {'name': 'Remote Station', 'zone': 'D', 'description': 'Distant pickup points'},
    ];

    final batch = _firestore.batch();
    final collection = _firestore.collection('cities');

    for (int i = 0; i < cities.length; i++) {
      final docRef = collection.doc(); // Auto-generate ID
      batch.set(docRef, cities[i]);
      print('  🏙️ Adding ${cities[i]['name']} (Zone ${cities[i]['zone']})');
    }

    await batch.commit();
    print('✅ Cities populated (${cities.length} items)\n');
  }
}

/// Main function to run the population script
Future<void> main() async {
  print('🚀 Starting Database Population Script');
  print('=====================================\n');
  
  await DatabasePopulator.populateDatabase();
  
  print('\n=====================================');
  print('🎉 Database setup complete!');
  print('You can now use the app with real data from Firestore.');
}
