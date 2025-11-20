# Al Rida App

A Flutter application with Firebase authentication and role-based access control for Admin, Student, and Driver users.

## Features

- **Firebase Authentication**
  - Google Sign-In
  - Email/Password Authentication
  - Password Reset functionality

- **Role-Based Access Control**
  - Admin Dashboard: Manage users, drivers, routes, and system settings
  - Student Dashboard: Track bus, view routes, check schedules
  - Driver Dashboard: Manage trips, view students, share location

- **Firebase Firestore Database**
  - User profile management
  - Role-based data access
  - Real-time data synchronization

## Setup Instructions

### 1. Prerequisites

- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Firebase account

### 2. Firebase Setup

#### Step 1: Create a Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `al-rida-app` (or your preferred name)
4. Enable Google Analytics (optional)
5. Wait for project creation

#### Step 2: Enable Authentication
1. In Firebase Console, go to "Authentication"
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable "Email/Password" and "Google" sign-in methods

#### Step 3: Enable Firestore Database
1. Go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" for development
4. Select your preferred location

#### Step 4: Add Android App
1. Click "Add app" → Android icon
2. Enter package name: `com.example.al_rida_app`
3. Download `google-services.json`
4. Replace the placeholder file at `android/app/google-services.json`

#### Step 5: Add iOS App (Optional)
1. Click "Add app" → iOS icon
2. Enter bundle ID: `com.example.alRidaApp`
3. Download `GoogleService-Info.plist`
4. Replace the placeholder file at `ios/Runner/GoogleService-Info.plist`

#### Step 6: Configure Firebase Options
1. Update `lib/firebase_options.dart` with your actual Firebase configuration values
2. Replace all placeholders like `YOUR_PROJECT_ID`, `YOUR_API_KEY`, etc.

### 3. Dependencies Installation

```bash
cd al_rida_app
flutter pub get
```

### 4. Google Sign-In Configuration

#### Android Configuration
1. Get SHA-1 fingerprint:
   ```bash
   cd android
   ./gradlew signingReport
   ```
2. In Firebase Console → Project Settings → General
3. Add SHA-1 fingerprint to your Android app

#### iOS Configuration (if using iOS)
1. In Xcode, add `GoogleService-Info.plist` to the Runner target
2. Update iOS configuration in Firebase Console

### 5. Running the App

```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── models/
│   ├── app_user.dart        # User data model
│   └── user_role.dart       # User role enum
├── services/
│   └── auth_service.dart    # Authentication service
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart    # Login UI
│   │   └── register_screen.dart # Registration UI
│   └── home/
│       ├── admin_home.dart      # Admin dashboard
│       ├── student_home.dart    # Student dashboard
│       └── driver_home.dart     # Driver dashboard
└── widgets/
    └── auth_wrapper.dart    # Authentication state wrapper
```

## User Roles

### Admin
- Manage all users (view, edit, delete)
- Manage drivers and routes
- Send system-wide notifications
- View analytics and reports
- Configure app settings

### Student
- Track bus location in real-time
- View assigned route and schedule
- Receive notifications
- Manage profile

### Driver
- Start/end trips
- View assigned students list
- Share GPS location
- Send emergency alerts
- View trip history

## Development

### Adding New Features

1. **Authentication Features**: Extend `AuthService` class
2. **UI Components**: Add to appropriate screen folders
3. **Data Models**: Add to `models/` directory
4. **Database Operations**: Extend services or create new service classes

### Database Structure (Firestore)

```
users/ {
  uid: {
    email: string,
    displayName: string,
    role: 'admin' | 'student' | 'driver',
    createdAt: timestamp,
    lastLoginAt: timestamp,
    isActive: boolean
  }
}
```

## Troubleshooting

### Common Issues

1. **Firebase Configuration Error**
   - Verify `google-services.json` and `GoogleService-Info.plist` are correctly placed
   - Check package names match Firebase configuration

2. **Google Sign-In Issues**
   - Verify SHA-1 fingerprint is added to Firebase
   - Check bundle ID/package name consistency

3. **Build Errors**
   - Run `flutter clean && flutter pub get`
   - Check minimum SDK versions in build configurations

### Support

For issues and feature requests, please check the project documentation or contact the development team.

## License

This project is developed for Al Rida App. All rights reserved.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
