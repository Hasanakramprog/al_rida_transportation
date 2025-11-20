# Database Setup Instructions

This guide will help you populate your Firestore database with the necessary data for the Al Rida App.

## Prerequisites

1. Make sure your Firebase project is set up and configured
2. Ensure Firestore is enabled in your Firebase project
3. Your `firebase_options.dart` file should be properly configured
4. **Update Firestore security rules** (see step below)

## Step 1: Update Firestore Security Rules

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Firestore Database** > **Rules**
4. Replace your current rules with the content from `firestore.rules` file in the project root
5. Click **Publish**

## Step 2: Run Database Population

### Method 1: Using Flutter App (Recommended)

1. Run the database setup app:
   ```bash
   cd d:\coding-repo\al_rida_app
   flutter run lib/database_setup_runner.dart
   ```

2. Click the "Populate Database" button in the app
3. Wait for the process to complete
4. You should see success messages and logs

### Method 2: Using Command Line

1. Run the script directly:
   ```bash
   cd d:\coding-repo\al_rida_app
   dart run lib/scripts/run_database_setup.dart
   ```

## What Gets Created

### Schedule Suffixes Collection (`schedule_suffixes`)
- **20 schedule options** (A1-A5, B1-B5, C1-C5, D1-D5)
- Each document contains:
  - `code`: Schedule code (e.g., "A1", "B2")
  - `zone`: Transportation zone (A, B, C, D)
  - `daysPerWeek`: Number of days (1-5)
  - `dailyCost`: Cost per day
  - `monthlyCost`: Monthly subscription cost (with 15% discount)
  - `description`: Human-readable description

### Cities Collection (`cities`)
- **20 cities** across 4 zones
- Each document contains:
  - `name`: City name
  - `zone`: Transportation zone (A, B, C, D)
  - `description`: City description

## Pricing Structure

### Zone A (Premium Locations)
- Daily: $5.00
- Monthly: $17.00 - $85.00 (depending on days per week)

### Zone B (Business District)
- Daily: $7.00
- Monthly: $23.80 - $119.00 (depending on days per week)

### Zone C (Residential Areas)
- Daily: $6.00
- Monthly: $20.40 - $102.00 (depending on days per week)

### Zone D (Extended Areas)
- Daily: $8.00
- Monthly: $27.20 - $136.00 (depending on days per week)

## Verification

After running the script, you can verify the data in your Firebase Console:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Firestore Database
4. Check for collections: `schedule_suffixes` and `cities`

## Troubleshooting

### If you get Firebase initialization errors:
- Check your `firebase_options.dart` file
- Ensure your Firebase project is properly configured
- Make sure you have internet connection

### If you get permission errors:
- Check your Firestore security rules
- Make sure your Firebase project allows writes

### To reset and repopulate:
1. Delete the collections in Firebase Console
2. Run the script again

## Next Steps

After successful population:
1. Run your main app: `flutter run`
2. Test student registration and profile setup
3. The app will now load real data from Firestore instead of hardcoded values

## Support

If you encounter issues, check the Firebase Console for error messages and ensure all Firebase services are properly enabled.
