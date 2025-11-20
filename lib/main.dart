import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'widgets/auth_wrapper.dart';
import 'screens/payment/payment_history_screen.dart';
import 'screens/admin/student_management_screen.dart';
import 'screens/admin/student_detail_screen.dart';
import 'screens/admin/driver_assignment_screen.dart';
import 'screens/admin/trip_management_screen.dart';
import 'screens/admin/subscription_management_screen.dart';
import 'screens/admin/accounting_screen.dart';
import 'screens/admin/transactions_list_screen.dart';
import 'screens/driver/my_students_screen.dart';
import 'screens/driver/trip_students_screen.dart';
import 'screens/admin/operating_payments_screen.dart';
import 'models/student_profile.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
      ],
      child: MaterialApp(
        title: 'Al Rida Transportation',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            elevation: 2,
            centerTitle: true,
          ),
          cardTheme: CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        home: const AuthWrapper(),
        routes: {
          '/payment_history': (context) => const PaymentHistoryScreen(),
          '/admin/students': (context) => const StudentManagementScreen(),
          '/admin/driver_assignment': (context) => const DriverAssignmentScreen(),
          '/admin/trip-management': (context) => const TripManagementScreen(),
          '/admin/subscriptions': (context) => const SubscriptionManagementScreen(),
          '/admin/accounting': (context) => const AccountingScreen(),
          '/admin/transactions': (context) => const TransactionsListScreen(),
          '/driver/my-students': (context) => const MyStudentsScreen(),
          '/driver/trip-students': (context) => const TripStudentsScreen(),
          '/admin/operating-payments': (context) => const OperatingPaymentsScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/admin/student_detail') {
            final student = settings.arguments as StudentProfile;
            return MaterialPageRoute(
              builder: (context) => StudentDetailScreen(student: student),
            );
          }
          return null;
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
