import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Card
            Card(
              color: Colors.red.shade50,
              child: const Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      size: 60,
                      color: Colors.red,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Welcome, Admin!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Manage users, drivers, and system settings',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Admin Features Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildFeatureCard(
                    icon: Icons.school,
                    title: 'Manage Students',
                    subtitle: 'View and manage all students',
                    color: Colors.blue,
                    onTap: () => Navigator.pushNamed(context, '/admin/students'),
                  ),
                  _buildFeatureCard(
                    icon: Icons.wb_sunny,
                    title: 'Morning Trips',
                    subtitle: 'Assign students to drivers',
                    color: Colors.green,
                    onTap: () => Navigator.pushNamed(context, '/admin/driver_assignment'),
                  ),
                  _buildFeatureCard(
                    icon: Icons.wb_twilight,
                    title: 'Trip Management',
                    subtitle: 'Assign afternoon trips (1-3 PM)',
                    color: Colors.deepPurple,
                    onTap: () => Navigator.pushNamed(context, '/admin/trip-management'),
                  ),
                  _buildFeatureCard(
                    icon: Icons.calendar_month,
                    title: 'Subscriptions',
                    subtitle: 'Manage schedule suffixes & pricing',
                    color: Colors.orange,
                    onTap: () => Navigator.pushNamed(context, '/admin/subscriptions'),
                  ),
                  _buildFeatureCard(
                    icon: Icons.map,
                    title: 'Routes & Schedules',
                    subtitle: 'Manage bus routes and schedules',
                    color: Colors.brown,
                    onTap: () => _showSnackBar(context, 'Routes & Schedules feature coming soon!'),
                  ),
                  _buildFeatureCard(
                    icon: Icons.bar_chart,
                    title: 'Reports',
                    subtitle: 'View analytics and reports',
                    color: Colors.purple,
                    onTap: () => _showSnackBar(context, 'Reports feature coming soon!'),
                  ),
                  _buildFeatureCard(
                    icon: Icons.tune,
                    title: 'System Settings',
                    subtitle: 'Configure app settings',
                    color: Colors.teal,
                    onTap: () => _showSnackBar(context, 'System Settings feature coming soon!'),
                  ),
                  _buildFeatureCard(
                    icon: Icons.campaign,
                    title: 'Send Notifications',
                    subtitle: 'Send alerts to users',
                    color: Colors.indigo,
                    onTap: () => _showSnackBar(context, 'Send Notifications feature coming soon!'),
                  ),
                  _buildFeatureCard(
                    icon: Icons.account_balance_wallet,
                    title: 'Accounting',
                    subtitle: 'View payments & transactions',
                    color: Colors.green.shade700,
                    onTap: () => Navigator.pushNamed(context, '/admin/accounting'),
                  ),
                  _buildFeatureCard(
                    icon: Icons.directions_bus,
                    title: 'Operating Payments',
                    subtitle: 'Fuel, maintenance & salaries',
                    color: Colors.amber.shade700,
                    onTap: () => Navigator.pushNamed(context, '/admin/operating-payments'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 36,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut();
    
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }
}
