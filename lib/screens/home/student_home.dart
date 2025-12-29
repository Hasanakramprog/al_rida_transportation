import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/student_profile_service.dart';
import '../../services/monthly_payment_service.dart';
import '../../services/driver_service.dart';
import '../../models/student_profile.dart';
import '../../models/monthly_payment.dart';
import '../../models/bus_booking.dart';
import '../auth/login_screen.dart';
import '../student/week_calendar_screen.dart';
import '../student/driver_location_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final _profileService = StudentProfileService();
  final _paymentService = MonthlyPaymentService();
  final _driverService = DriverService();
  StudentProfile? _studentProfile;
  MonthlyPayment? _currentMonthPayment;
  List<MonthlyPayment> _recentPayments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStudentProfile();
  }

  Future<void> _loadStudentProfile() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;

      if (user != null) {
        final profile = await _profileService.getStudentProfile(user.uid);

        // Load current month payment status
        MonthlyPayment? currentPayment;
        List<MonthlyPayment> recentPayments = [];

        if (profile != null) {
          try {
            currentPayment = await _paymentService.getCurrentMonthPayment(
              user.uid,
            );
            recentPayments = await _paymentService.getMyPaymentHistory(
              user.uid,
              limit: 3,
            );
          } catch (e) {
            print('Error loading payment data: $e');
          }
        }

        if (mounted) {
          setState(() {
            _studentProfile = profile;
            _currentMonthPayment = currentPayment;
            _recentPayments = recentPayments;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'User not found';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading profile: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadStudentProfile,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _signOut(context),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : _studentProfile == null
          ? _buildNoProfileView()
          : _buildProfileView(user),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 16, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadStudentProfile,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoProfileView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No profile found',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Please complete your profile setup',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView(user) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colorScheme.primary.withOpacity(0.05), Colors.white],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _loadStudentProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Header
              _buildWelcomeHeader(user),
              const SizedBox(height: 16),

              // Profile Information Cards
              _buildPersonalInfoCard(),
              const SizedBox(height: 12),

              _buildPaymentCard(),
              const SizedBox(height: 12),

              _buildTransportationCard(),
              const SizedBox(height: 12),

              _buildScheduleCard(),
              const SizedBox(height: 16),

              // Action Buttons
              _buildActionButtons(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(user) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white,
              child: Text(
                (user?.displayName?.isNotEmpty == true
                    ? user!.displayName![0].toUpperCase()
                    : user?.email?[0].toUpperCase() ?? 'S'),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Welcome Back!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.displayName ?? user?.email ?? 'Student',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.school, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _studentProfile!.university,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildInfoRow(
              'University',
              _studentProfile!.university,
              Icons.school_outlined,
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              'Phone Number',
              _studentProfile!.phoneNumber,
              Icons.phone_outlined,
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              'Student ID',
              _studentProfile!.uid.substring(0, 8) + '...',
              Icons.badge_outlined,
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              'Registration Date',
              '${_studentProfile!.createdAt.day}/${_studentProfile!.createdAt.month}/${_studentProfile!.createdAt.year}',
              Icons.calendar_today_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.directions_bus_outlined,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Transportation Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildInfoRow(
              'City',
              '${_studentProfile!.city.name} (Zone ${_studentProfile!.city.zone})',
              Icons.location_on_outlined,
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              'Schedule Code',
              _studentProfile!.scheduleSuffix.code,
              Icons.schedule_outlined,
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              'Days Per Week',
              '${_studentProfile!.scheduleSuffix.daysPerWeek} ${_studentProfile!.scheduleSuffix.daysPerWeek == 1 ? 'day' : 'days'}',
              Icons.calendar_today_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.access_time_outlined,
                    color: Colors.purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'My Schedule',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_studentProfile!.selectedDays.isNotEmpty) ...[
              _buildInfoRow(
                'Selected Days',
                _studentProfile!.selectedDays.join(', '),
                Icons.calendar_month_outlined,
              ),
              const SizedBox(height: 10),
              _buildDayTimeSlots(),
            ] else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No schedule selected yet',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard() {
    final currentMonth = DateTime.now();
    final isCurrentMonthPaid = _currentMonthPayment?.isPaid ?? false;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCurrentMonthPaid
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/payment_history');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isCurrentMonthPaid ? Colors.green : Colors.red)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isCurrentMonthPaid
                          ? Icons.check_circle_outline
                          : Icons.payment_outlined,
                      color: isCurrentMonthPaid ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Subscription & Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCurrentMonthPaid ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Subscription Information
              _buildInfoRow(
                'Subscription Type',
                _studentProfile!.subscriptionType.displayName,
                Icons.card_membership_outlined,
              ),
              const SizedBox(height: 10),
              _buildInfoRow(
                'Monthly Cost',
                _currentMonthPayment != null
                    ? '\$${_currentMonthPayment!.monthlyAmount.toStringAsFixed(2)}'
                    : '\$${_studentProfile!.subscriptionCost.toStringAsFixed(2)}',
                Icons.attach_money_outlined,
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(height: 1, color: Colors.grey.shade300),
              ),

              // Current Month Status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCurrentMonthPaid
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCurrentMonthPaid
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          size: 16,
                          color: isCurrentMonthPaid ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_getMonthName(currentMonth.month)} ${currentMonth.year}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isCurrentMonthPaid
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          isCurrentMonthPaid
                              ? Icons.check_circle
                              : Icons.pending_outlined,
                          size: 18,
                          color: isCurrentMonthPaid ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isCurrentMonthPaid ? 'Paid' : 'Unpaid',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isCurrentMonthPaid
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    if (isCurrentMonthPaid &&
                        _currentMonthPayment?.paidAt != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.event_available,
                            size: 14,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Paid on ${_currentMonthPayment!.paidAt!.day}/${_currentMonthPayment!.paidAt!.month}/${_currentMonthPayment!.paidAt!.year}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Payment History
              if (_recentPayments.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.history_outlined,
                      size: 16,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Recent Payments',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildPaymentHistory(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentHistory() {
    final paidPayments = _recentPayments
        .where((payment) => payment.isPaid)
        .toList();

    if (paidPayments.isEmpty) {
      return const Text(
        'No payment history available',
        style: TextStyle(fontSize: 14, color: Colors.grey),
      );
    }

    return Column(
      children: paidPayments.map((payment) {
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${payment.monthName} ${payment.year}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      payment.paidAt != null
                          ? 'Paid on ${payment.paidAt!.day}/${payment.paidAt!.month}/${payment.paidAt!.year}'
                          : 'Payment date not available',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${payment.monthlyAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  Widget _buildActionButtons() {
    final canEdit = StudentProfile.canEditThisMonth();

    return Column(
      children: [
        // Edit Restriction Info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: canEdit ? Colors.green.shade50 : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: canEdit ? Colors.green.shade200 : Colors.orange.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                canEdit ? Icons.check_circle : Icons.info,
                color: canEdit ? Colors.green : Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  StudentProfile.getEditRestrictionMessage(),
                  style: TextStyle(
                    fontSize: 12,
                    color: canEdit
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 45,
          child: ElevatedButton.icon(
            onPressed: canEdit
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WeekCalendarScreen(
                          studentProfile: _studentProfile!,
                        ),
                      ),
                    );
                  }
                : () => _showSnackBar(
                    context,
                    StudentProfile.getEditRestrictionMessage(),
                  ),
            icon: Icon(canEdit ? Icons.edit : Icons.lock),
            label: Text(canEdit ? 'Edit Schedule' : 'Schedule Locked'),
            style: ElevatedButton.styleFrom(
              backgroundColor: canEdit ? Colors.blue : Colors.grey,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _navigateToDriverLocation(),
                icon: const Icon(Icons.location_on),
                label: const Text('Track Driver'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    _showSnackBar(context, 'Payment feature coming soon!'),
                icon: const Icon(Icons.payment),
                label: const Text('Pay Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _studentProfile!.isPaid
                      ? Colors.grey
                      : Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayTimeSlots() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.schedule, color: Colors.orange, size: 20),
            SizedBox(width: 8),
            Text(
              'Schedule Times:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...(_studentProfile!.dayTimeSlots.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const SizedBox(width: 28), // Align with icon
                Text(
                  '${entry.key}:',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  entry.value.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          );
        }).toList()),
      ],
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.blue),
    );
  }

  Future<void> _navigateToDriverLocation() async {
    if (_studentProfile == null) {
      _showSnackBar(context, 'Profile not loaded');
      return;
    }

    try {
      // Check if student has an assigned driver
      if (_studentProfile!.assignedDriverId == null ||
          _studentProfile!.assignedDriverId!.isEmpty) {
        if (mounted) {
          _showSnackBar(context, 'No driver assigned to you yet');
        }
        return;
      }

      // Get the assigned driver directly by ID (single Firestore read)
      final driver = await _driverService.getDriverById(
        _studentProfile!.assignedDriverId!,
      );

      if (driver == null) {
        if (mounted) {
          _showSnackBar(context, 'Driver not found');
        }
        return;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DriverLocationScreen(
              driverId: driver.uid,
              driverName: driver.fullName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(context, 'Error: ${e.toString()}');
      }
    }
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
