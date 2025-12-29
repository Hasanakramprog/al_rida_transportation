import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/monthly_payment.dart';
import '../../models/student_profile.dart';
import '../../services/monthly_payment_service.dart';
import '../../services/student_profile_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final MonthlyPaymentService _paymentService = MonthlyPaymentService();
  final StudentProfileService _studentService = StudentProfileService();

  bool _isLoading = true;
  List<MonthlyPayment> _paymentHistory = [];
  StudentProfile? _studentProfile;
  double _totalRemaining = 0.0;
  double _totalPaid = 0.0;
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    try {
      setState(() => _isLoading = true);

      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Get student profile to know registration date
      _studentProfile = await _studentService.getStudentProfile(
        currentUser.uid,
      );
      if (_studentProfile == null) return;

      final registrationDate = _studentProfile!.createdAt;
      final currentDate = DateTime.now();

      // Generate all months from registration to current
      final payments = <MonthlyPayment>[];
      DateTime monthIterator = DateTime(
        registrationDate.year,
        registrationDate.month,
        1,
      );

      while (monthIterator.isBefore(
        DateTime(currentDate.year, currentDate.month + 1, 1),
      )) {
        final payment = await _paymentService.getPaymentStatus(
          studentUid: _studentProfile!.uid,
          year: monthIterator.year,
          month: monthIterator.month,
        );

        if (payment != null) {
          payments.add(payment);
        }

        // Move to next month
        if (monthIterator.month == 12) {
          monthIterator = DateTime(monthIterator.year + 1, 1, 1);
        } else {
          monthIterator = DateTime(
            monthIterator.year,
            monthIterator.month + 1,
            1,
          );
        }
      }

      // Sort by date (newest first)
      payments.sort(
        (a, b) =>
            DateTime(b.year, b.month).compareTo(DateTime(a.year, a.month)),
      );

      // Calculate totals
      _totalAmount = payments.fold(
        0.0,
        (sum, payment) => sum + payment.monthlyAmount,
      );
      _totalPaid = payments.fold(
        0.0,
        (sum, payment) => sum + payment.paidAmount,
      );
      _totalRemaining = payments.fold(
        0.0,
        (sum, payment) => sum + payment.remainingAmount,
      );

      setState(() {
        _paymentHistory = payments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading payment history: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _paymentHistory.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                _buildSummaryCards(),
                Expanded(child: _buildPaymentTable()),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Payment History',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Payment records will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Total Amount',
              '\$${_totalAmount.toStringAsFixed(2)}',
              Icons.account_balance_wallet,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Total Paid',
              '\$${_totalPaid.toStringAsFixed(2)}',
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Total Remaining',
              '\$${_totalRemaining.toStringAsFixed(2)}',
              Icons.pending,
              _totalRemaining > 0 ? Colors.orange : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTable() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Month',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Amount',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Paid',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Left',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Status',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Table Body
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _paymentHistory.length,
              itemBuilder: (context, index) {
                final payment = _paymentHistory[index];
                return _buildPaymentRow(payment, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(MonthlyPayment payment, int index) {
    final monthName = DateFormat(
      'MMM yyyy',
    ).format(DateTime(payment.year, payment.month));
    final isEven = index % 2 == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isEven
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      child: Row(
        children: [
          // Month
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                if (payment.paidAt != null)
                  Text(
                    'Paid: ${DateFormat('dd/MM').format(payment.paidAt!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          // Amount
          Expanded(
            flex: 2,
            child: Text(
              '\$${payment.monthlyAmount.toStringAsFixed(0)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          // Paid
          Expanded(
            flex: 2,
            child: Text(
              '\$${payment.paidAmount.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: payment.paidAmount > 0 ? Colors.green : null,
                fontWeight: payment.paidAmount > 0 ? FontWeight.w600 : null,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Remaining
          Expanded(
            flex: 2,
            child: Text(
              '\$${payment.remainingAmount.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: payment.remainingAmount > 0
                    ? Colors.orange
                    : Colors.green,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Status
          Expanded(flex: 2, child: _buildStatusChip(payment)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(MonthlyPayment payment) {
    Color color;
    String text;
    IconData icon;

    if (payment.isFullyPaid) {
      color = Colors.green;
      text = 'Paid';
      icon = Icons.check_circle;
    } else if (payment.isPartiallyPaid) {
      color = Colors.orange;
      text = '${payment.paymentPercentage.toInt()}%';
      icon = Icons.hourglass_empty;
    } else {
      color = Colors.red;
      text = 'Unpaid';
      icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
