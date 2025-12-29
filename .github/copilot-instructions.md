# Al Rida Transportation - AI Agent Instructions

## Project Overview
Flutter mobile app for managing school transportation: payment tracking, driver operations, and student subscriptions. Built with Firebase (Authentication, Firestore) and dual-currency support (USD/LBP). Role-based access: Admin, Driver, Student.

## Architecture Patterns

### State Management Strategy
- **StatefulWidget-based with manual caching** - NOT using ChangeNotifier or state management packages
- Cache data in local state variables (e.g., `_cachedBalanceUSD`, `_cachedStatistics`)
- Explicit manual refresh via IconButton actions with `_loadData()` methods
- Provider used ONLY for dependency injection of services (see [main.dart](../lib/main.dart#L33-L37))

### Firestore Optimization (Critical)
- **Minimize reads** - Cache data and use manual refresh instead of real-time streams for lists
- **Atomic updates** - Always use `FieldValue.increment()` for wallet balances, never read-modify-write
- **Pagination** - Use cursor-based pagination with `startAfterDocument` for transaction lists (see [accounting_service.dart](../lib/services/accounting_service.dart))
- Real-time streams ONLY for critical data (admin wallet balance, auth state)

### Financial Data Handling
```dart
// CORRECT: Atomic increment for wallet updates
await docRef.update({
  'balanceUSD': FieldValue.increment(amount),
  'transactionsUSD': FieldValue.increment(1),
});

// WRONG: Read-modify-write creates race conditions
final wallet = await docRef.get();
await docRef.update({'balanceUSD': wallet['balanceUSD'] + amount});
```

### Number Formatting Convention
- Use `NumberFormat('#,###')` for integer amounts (USD/LBP balances)
- Use `NumberFormat('#,###.##')` for decimal amounts (transaction details)
- Currency symbols: `\$` for USD, `LL` for LBP
- Real-time input formatting in TextFields with `_formatNumber()` helper (see [driver_home.dart](../lib/screens/home/driver_home.dart#L733-L750))

## Code Organization

### Service Layer Pattern
All Firestore operations go through dedicated services in `lib/services/`:
- `auth_service.dart` - Firebase Auth, user role management
- `accounting_service.dart` - Admin wallet, payment transactions, statistics
- `driver_wallet_service.dart` - Driver wallet operations, transfers
- `student_profile_service.dart` - Student data, subscription management

### Model Structure
Models in `lib/models/` use factory constructors for Firestore serialization:
```dart
factory StudentProfile.fromSnapshot(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  return StudentProfile(
    id: doc.id,
    // Map fields from Firestore
  );
}

Map<String, dynamic> toMap() {
  return {
    // Convert to Firestore format
  };
}
```

### Navigation & Routes
- Named routes defined in [main.dart](../lib/main.dart#L60-L71)
- Arguments passed via `onGenerateRoute` for detail screens (see StudentDetailScreen pattern)
- Role-based routing in [auth_wrapper.dart](../lib/widgets/auth_wrapper.dart)

## Key Workflows

### Initial Setup
```bash
# Database population (run once)
flutter run lib/database_setup_runner.dart
# OR
dart run lib/scripts/run_database_setup.dart
```
Creates `schedule_suffixes` and `cities` collections. See [DATABASE_SETUP.md](../DATABASE_SETUP.md).

### Development Commands
```bash
flutter pub get                          # Install dependencies
flutter run                              # Run on connected device
flutter build apk --release              # Android production build
flutter build ios --release              # iOS production build
flutter analyze                          # Lint check
```

### Firebase Configuration
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`
- Configuration: `lib/firebase_options.dart`
- Security rules: `firestore.rules` (deploy via Firebase Console)

## Color-Coded Transaction UI
Consistent color scheme across all transaction displays:
- **Green** (`Colors.green.shade700`) - Full student payments
- **Orange** (`Colors.orange.shade700`) - Partial payments
- **Red** (`Colors.red.shade700`) - Operating expenses (fuel, maintenance, salary)
- **Purple** (`Colors.purple.shade700`) - Driver-to-admin transfers

## Critical Conventions

### Role-Based Access
Check user role from Firestore `users/{uid}` collection (field: `role`):
- Admin: Full access to accounting, student/driver management
- Driver: Wallet view, payment recording, assigned students
- Student: Profile view, payment history, route information

### Subscription Pricing
Pricing data stored in Firestore `schedule_suffixes` collection (NOT hardcoded):
- `dailyCost` - Cost per transportation day
- `monthlyCost` - Pre-calculated with 15% discount
- Zone-based pricing (A: $5, B: $7, C: $6, D: $8 daily)
- Use `SubscriptionPricing.getCost()` helper in [student_profile.dart](../lib/models/student_profile.dart)

### Firestore Collections
- `users` - Authentication data, user roles
- `student_profiles` - Student info, subscription details
- `drivers` - Driver profiles, zone assignments
- `admin_wallet` - Single doc (`main`) with USD/LBP balances
- `driver_wallets/{driverId}` - Individual driver balances
- `payment_transactions` - All payment records with filters
- `operating_payments` - Expense tracking (fuel, maintenance, salary)

## Common Gotchas

1. **Never use real-time streams for transaction lists** - Use cached data with manual refresh
2. **Always use FieldValue.increment()** for balance updates - Prevents race conditions
3. **Check for null DocumentSnapshots** - Firestore may return non-existent documents
4. **Provider.of<AuthService>(context, listen: false)** - Set listen: false in event handlers
5. **Currency field is required** - All transactions must specify 'USD' or 'LBP'
6. **Security rules are permissive** - Temporary "REMOVE AFTER SETUP" rule in [firestore.rules](../firestore.rules#L29-L31)

## When Adding Features

- Financial operations → Add to appropriate service, use atomic increments
- New screens → Follow StatefulWidget + cached data pattern, add manual refresh
- Transaction types → Update color-coding scheme and filtering logic
- User roles → Update role checks in AuthWrapper and screen access logic
