import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/student_profile_service.dart';
import '../models/user_role.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/admin_home.dart';
import '../screens/home/student_home.dart';
import '../screens/home/driver_home.dart';
import '../screens/student/student_profile_setup_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: Provider.of<AuthService>(context).authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking authentication state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // User is not logged in
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        // User is logged in, show role-based home screen
        return const RoleBasedHome();
      },
    );
  }
}

class RoleBasedHome extends StatelessWidget {
  const RoleBasedHome({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Provider.of<AuthService>(context, listen: false).getCurrentAppUser(),
      builder: (context, snapshot) {
        // Show loading while fetching user data
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If there's an error or no user data, redirect to login
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        final appUser = snapshot.data!;

        // Navigate to appropriate screen based on user role
        switch (appUser.role) {
          case UserRole.admin:
            return const AdminHomeScreen();
          case UserRole.student:
            return const StudentProfileChecker();
          case UserRole.driver:
            return const DriverHomeScreen();
        }
      },
    );
  }
}

class StudentProfileChecker extends StatelessWidget {
  const StudentProfileChecker({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    if (user == null) {
      return const LoginScreen();
    }

    return FutureBuilder<bool>(
      future: StudentProfileService().hasCompletedProfile(user.uid),
      builder: (context, snapshot) {
        // Show loading while checking profile
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking profile...'),
                ],
              ),
            ),
          );
        }

        // Check if profile is completed
        final hasProfile = snapshot.data ?? false;
        
        if (hasProfile) {
          // Profile exists, go to student home
          return const StudentHomeScreen();
        } else {
          // Profile not completed, show setup screen
          return const StudentProfileSetupScreen();
        }
      },
    );
  }
}
