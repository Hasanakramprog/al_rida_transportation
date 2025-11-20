# 🚌 Al Rida Transportation Management System

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.8.1+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)

A comprehensive Flutter mobile application for managing school transportation services, payments, and driver operations with real-time tracking and dual-currency support (USD/LBP).

[Features](#features) • [Screenshots](#screenshots) • [Installation](#installation) • [Architecture](#architecture) • [Contributing](#contributing)

</div>

---

## 📋 Overview

Al Rida Transportation is a complete school transportation management solution that streamlines payment tracking, driver operations, and administrative oversight. Built with Flutter and Firebase, it provides a robust platform for managing daily operations, financial transactions, and student-driver coordination.

## ✨ Features

### 🔐 Authentication & Authorization
- **Firebase Authentication** with Google Sign-In and Email/Password
- **Role-Based Access Control** (Admin, Driver, Student)
- Secure password reset and account management

### 💰 Financial Management (Dual Currency: USD/LBP)
- **Admin Wallet System** - Centralized financial tracking
- **Driver Wallets** - Individual driver balance management
- **Operating Payments** - Track fuel, maintenance, and salary expenses
- **Student Payment Recording** - Daily payment tracking by drivers
- **Transaction History** - Complete audit trail with pagination
- **Automated Calculations** - Real-time balance updates with Firestore transactions
- **Number Formatting** - Professional display with thousand separators (1,000 / 1,200,000)

### 👨‍💼 Admin Dashboard
- **Accounting Overview** - Real-time wallet balances and statistics
- **Student Management** - Complete student profile system
- **Driver Assignment** - Route and student assignment tools
- **Operating Payments** - Track and manage operational expenses
- **Transaction Lists** - Searchable, filterable payment history
- **Firestore Quota Optimization** - Cached data with manual refresh to minimize costs

### 🚗 Driver Features
- **Personal Wallet** - View USD and LBP balances in real-time
- **Payment Recording** - Record student payments with searchable student selector
- **Wallet Transfers** - Long-press transfer to admin wallet
- **Transaction History** - View personal payment records with search and filters
- **Student Management** - View assigned students and routes

### 👨‍🎓 Student Features
- **Profile Management** - Complete student information system
- **Payment History** - Track all subscription payments
- **Route Information** - View assigned driver and schedule
- **Week Calendar** - Visual schedule overview

### 🎨 UI/UX Highlights
- **Modern Material Design** - Clean and intuitive interface
- **Color-Coded Transactions** - Visual differentiation of payment types
  - 🟢 Green: Student payments (Full)
  - 🟠 Orange: Partial payments
  - 🔴 Red: Operating expenses
  - 🟣 Purple: Driver transfers
- **Real-time Input Formatting** - Auto-format numbers as users type
- **Search & Filter** - Advanced filtering across all transaction views
- **Pagination** - Efficient data loading with Firestore cursors

## 🏗️ Architecture

### Tech Stack
- **Frontend:** Flutter 3.8.1+ (Dart)
- **Backend:** Firebase (Authentication, Firestore, Cloud Functions)
- **State Management:** StatefulWidget with manual state optimization
- **Database:** Cloud Firestore with atomic transactions

### Key Design Patterns
- **Service Layer Architecture** - Separation of business logic
- **Repository Pattern** - Data access abstraction
- **Cached Data Strategy** - Minimize Firestore reads (~95% reduction)
- **Atomic Transactions** - Ensure data consistency with FieldValue.increment()
- **Cursor-based Pagination** - Efficient large dataset handling

### Database Collections
```
├── users/                    # User authentication data
├── student_profiles/         # Student information
├── drivers/                  # Driver profiles
├── admin_wallet/            # Central admin wallet
├── driver_wallets/          # Individual driver wallets
├── payment_transactions/    # All payment records
├── driver_payment_transactions/ # Driver-recorded payments
├── operating_payments/      # Operational expenses
└── monthly_payments/        # Subscription tracking
```

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

## 🚀 Installation

### Prerequisites
- Flutter SDK 3.8.1 or higher
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Firebase account
- Git

### Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/Hasanakramprog/al_rida_transportation.git
   cd al_rida_transportation
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication (Email/Password and Google Sign-In)
   - Create Firestore Database
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place configuration files in respective directories:
     - `android/app/google-services.json`
     - `ios/Runner/GoogleService-Info.plist`
   - Update `lib/firebase_options.dart` with your Firebase config

4. **Run the app**
   ```bash
   flutter run
   ```

### Detailed Firebase Setup

<details>
<summary>Click to expand Firebase setup instructions</summary>

#### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `al-rida-transportation`
4. Enable Google Analytics (optional)

#### 2. Enable Authentication
1. Navigate to Authentication → Get Started
2. Enable sign-in methods:
   - ✅ Email/Password
   - ✅ Google

#### 3. Create Firestore Database
1. Navigate to Firestore Database → Create Database
2. Start in test mode (for development)
3. Choose your preferred location

#### 4. Add Android App
1. Project Settings → Add App → Android
2. Package name: `com.alrida.app.al_rida_app`
3. Download `google-services.json`
4. Place in `android/app/`

#### 5. Add iOS App (Optional)
1. Project Settings → Add App → iOS
2. Bundle ID: `com.alrida.app.alRidaApp`
3. Download `GoogleService-Info.plist`
4. Place in `ios/Runner/`

#### 6. Security Rules
Deploy Firestore security rules from `firestore.rules`:
```bash
firebase deploy --only firestore:rules
```

</details>

## 📁 Project Structure

```
lib/
├── main.dart                          # Application entry point
├── firebase_options.dart              # Firebase configuration
│
├── models/                            # Data models
│   ├── admin_wallet.dart             # Admin wallet model
│   ├── driver_wallet.dart            # Driver wallet model
│   ├── payment_transaction.dart      # Payment transaction model
│   ├── driver_payment_transaction.dart
│   ├── operating_payment.dart        # Operating payment model
│   ├── student_profile.dart          # Student profile model
│   ├── driver.dart                   # Driver model
│   ├── app_user.dart                 # User authentication model
│   └── user_role.dart                # User role enum
│
├── services/                          # Business logic layer
│   ├── auth_service.dart             # Authentication service
│   ├── accounting_service.dart       # Accounting & wallet management
│   ├── driver_wallet_service.dart    # Driver wallet operations
│   ├── driver_payment_service.dart   # Driver payment transactions
│   ├── operating_payment_service.dart
│   ├── student_profile_service.dart
│   ├── driver_service.dart
│   └── monthly_payment_service.dart
│
├── screens/                           # UI screens
│   ├── auth/                         # Authentication screens
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   │
│   ├── home/                         # Role-based home screens
│   │   ├── admin_home.dart
│   │   ├── driver_home.dart
│   │   └── student_home.dart
│   │
│   ├── admin/                        # Admin-only screens
│   │   ├── accounting_screen.dart
│   │   ├── student_management_screen.dart
│   │   ├── operating_payments_screen.dart
│   │   ├── transactions_list_screen.dart
│   │   ├── driver_assignment_screen.dart
│   │   └── subscription_management_screen.dart
│   │
│   ├── driver/                       # Driver-only screens
│   │   ├── driver_transactions_screen.dart
│   │   ├── my_students_screen.dart
│   │   └── trip_students_screen.dart
│   │
│   └── student/                      # Student-only screens
│       ├── student_profile_setup_screen.dart
│       └── week_calendar_screen.dart
│
└── widgets/                           # Reusable widgets
    └── auth_wrapper.dart             # Authentication state handler
```

## 💡 Key Features Explained

### Dual Currency System
The app supports both USD and Lebanese Pound (LBP) with separate tracking:
- Admin maintains two wallets (USD and LBP)
- Drivers have dual-currency personal wallets
- All transactions tagged with currency type
- Automatic balance calculations per currency

### Firestore Quota Optimization
To minimize Firebase costs, the app implements:
- **Cached Data Pattern**: Load once, refresh manually
- **Pagination**: 15 items per page with cursor-based loading
- **Client-side Filtering**: Search and filter without additional reads
- Result: ~95% reduction in Firestore reads

### Transaction Recording Flow
1. **Student Payment** → Driver records → Updates driver wallet → Creates transaction record
2. **Operating Payment** → Admin pays driver → Updates both wallets → Creates expense record
3. **Wallet Transfer** → Driver transfers to admin → Updates both wallets → Creates transfer records

## 🎯 Use Cases

- 🏫 **Schools** - Manage transportation payments and driver coordination
- 🚌 **Transportation Companies** - Track driver operations and expenses
- 👨‍👩‍👧‍👦 **Parents** - Monitor student payment history and route information
- 🚗 **Drivers** - Record daily collections and manage personal finances
- 💼 **Administrators** - Oversee all financial operations and reporting

## 🔐 Security

- Firebase Authentication with secure token management
- Role-based access control (RBAC) at application level
- Firestore security rules for database access control
- Atomic transactions for financial operations
- Password reset functionality with email verification

## 🛠️ Development

### Running Tests
```bash
flutter test
```

### Building for Production

**Android APK:**
```bash
flutter build apk --release
```

**iOS App:**
```bash
flutter build ios --release
```

## 📱 Supported Platforms

- ✅ Android (5.0+)
- ✅ iOS (11.0+)
- ⚠️ Web (Experimental)
- ⚠️ Desktop (Windows, macOS, Linux - Experimental)

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Hasan Akram**
- GitHub: [@Hasanakramprog](https://github.com/Hasanakramprog)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend infrastructure
- Material Design for UI guidelines
- The open-source community

## 📞 Support

For support, email hasanakram@example.com or open an issue in the repository.

---

<div align="center">

Made with ❤️ using Flutter

**[⬆ Back to Top](#-al-rida-transportation-management-system)**

</div>
