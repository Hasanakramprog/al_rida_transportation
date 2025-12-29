import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/student_profile.dart';
import '../../models/monthly_payment.dart';
import '../../models/bus_booking.dart';
import '../../services/monthly_payment_service.dart';
import '../../services/student_profile_service.dart';

class StudentDetailScreen extends StatefulWidget {
  final StudentProfile student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final MonthlyPaymentService _paymentService = MonthlyPaymentService();
  final StudentProfileService _studentService = StudentProfileService();

  List<MonthlyPayment> _paymentHistory = [];
  bool _isLoading = true;
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

      final registrationDate = widget.student.createdAt;
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
          studentUid: widget.student.uid,
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
        title: const Text('Student Details'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStudentInfoCard(),
            _buildPaymentSummaryCards(),
            _buildPaymentHistorySection(),
            _buildSubscriptionCard(),
            _buildDaysAndTimesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentInfoCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  radius: 30,
                  child: Text(
                    widget.student.fullName.isNotEmpty
                        ? widget.student.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Full Name',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                      Text(
                        widget.student.fullName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: _showEditStudentDialog,
                  tooltip: 'Edit Student Info',
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.badge, 'Student ID', widget.student.uid),
            _buildInfoRow(Icons.phone, 'Phone', widget.student.phoneNumber),
            _buildInfoRow(
              Icons.school,
              'University',
              widget.student.university,
            ),
            _buildInfoRow(
              Icons.location_city,
              'City',
              '${widget.student.city.name} (Zone ${widget.student.city.zone})',
            ),
            _buildInfoRow(
              Icons.calendar_today,
              'Registered',
              DateFormat('MMM dd, yyyy').format(widget.student.createdAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subscription Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: _showEditSubscriptionDialog,
                  tooltip: 'Edit Subscription',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.schedule,
              'Schedule',
              widget.student.scheduleSuffix.code,
            ),
            _buildInfoRow(
              Icons.description,
              'Description',
              widget.student.scheduleSuffix.description,
            ),
            _buildInfoRow(
              Icons.calendar_view_week,
              'Days per Week',
              '${widget.student.scheduleSuffix.daysPerWeek} days',
            ),
            _buildInfoRow(
              Icons.attach_money,
              'Cost',
              '\$${widget.student.subscriptionCost.toStringAsFixed(2)} / ${widget.student.subscriptionType.displayName}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysAndTimesCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selected Days & Times',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: _showEditDaysTimesDialog,
                  tooltip: 'Edit Days & Times',
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...widget.student.selectedDays.map((day) {
              final timeSlot = widget.student.dayTimeSlots[day];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      day,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        timeSlot?.displayName ?? 'No time selected',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummaryCards() {
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

  Widget _buildPaymentHistorySection() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.history, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  'Payment History',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _buildPaymentTable(),
        ],
      ),
    );
  }

  Widget _buildPaymentTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
          headingRowHeight: 48,
          dataRowMinHeight: 65,
          dataRowMaxHeight: 75,
          columnSpacing: 24,
          horizontalMargin: 12,
          border: TableBorder.all(
            color: Colors.grey.shade300,
            width: 1,
            borderRadius: BorderRadius.circular(8),
          ),
          columns: [
            DataColumn(
              label: Row(
                children: [
                  Icon(
                    Icons.calendar_month,
                    size: 16,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Month',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            DataColumn(
              label: Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 16,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Amount',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              numeric: true,
            ),
            DataColumn(
              label: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Paid',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              numeric: true,
            ),
            DataColumn(
              label: Row(
                children: [
                  Icon(
                    Icons.pending_outlined,
                    size: 16,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Remaining',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              numeric: true,
            ),
            const DataColumn(
              label: Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const DataColumn(
              label: Text(
                'Actions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: _paymentHistory.map((payment) {
            final monthName = DateFormat(
              'MMM yyyy',
            ).format(DateTime(payment.year, payment.month));
            final canPayment = payment.remainingAmount > 0;
            final isCurrentMonth =
                DateTime.now().year == payment.year &&
                DateTime.now().month == payment.month;

            return DataRow(
              color: MaterialStateProperty.resolveWith<Color?>((states) {
                if (isCurrentMonth) return Colors.blue.shade50;
                if (payment.isFullyPaid)
                  return Colors.green.shade50.withOpacity(0.3);
                return null;
              }),
              cells: [
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(
                            monthName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isCurrentMonth
                                  ? Colors.blue.shade700
                                  : Colors.black87,
                            ),
                          ),
                          if (isCurrentMonth) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Current',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (payment.paidAt != null)
                        Text(
                          'Paid: ${DateFormat('MMM dd, HH:mm').format(payment.paidAt!)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '\$${payment.monthlyAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: payment.paidAmount > 0
                          ? Colors.green.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '\$${payment.paidAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: payment.paidAmount > 0
                            ? Colors.green.shade700
                            : Colors.grey.shade600,
                        fontWeight: payment.paidAmount > 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: payment.remainingAmount > 0
                          ? Colors.orange.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '\$${payment.remainingAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: payment.remainingAmount > 0
                            ? Colors.orange.shade700
                            : Colors.green.shade700,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                DataCell(_buildStatusChip(payment)),
                DataCell(
                  canPayment
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Tooltip(
                              message: 'Partial Payment',
                              child: InkWell(
                                onTap: () => _showPartialPaymentDialog(payment),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.payment,
                                    size: 18,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _processFullPayment(payment),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text(
                                'Pay Full',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Paid',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            );
          }).toList(),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processFullPayment(MonthlyPayment payment) async {
    // Confirm action
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Full Payment'),
        content: Text(
          'Mark full payment of \$${payment.remainingAmount.toStringAsFixed(2)} for ${DateFormat('MMM yyyy').format(DateTime(payment.year, payment.month))}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Get current admin UID
      final adminUser = FirebaseAuth.instance.currentUser;
      if (adminUser == null) {
        throw 'Admin not authenticated';
      }

      // Process payment with remaining amount (full payment)
      await _paymentService.processPayment(
        studentUid: widget.student.uid,
        year: payment.year,
        month: payment.month,
        adminUid: adminUser.uid,
        paymentAmount: payment.remainingAmount,
        studentName: widget.student.fullName,
      );

      // Reload payment history
      await _loadPaymentHistory();

      // Check if all payments are complete and update student profile
      await _updateStudentPaymentStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment processed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showPartialPaymentDialog(MonthlyPayment payment) async {
    final amountController = TextEditingController();

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Partial Payment - ${DateFormat('MMM yyyy').format(DateTime(payment.year, payment.month))}',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Amount: \$${payment.monthlyAmount.toStringAsFixed(2)}',
            ),
            Text('Already Paid: \$${payment.paidAmount.toStringAsFixed(2)}'),
            Text(
              'Remaining: \$${payment.remainingAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Payment Amount',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
                helperText: 'Enter amount to pay',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }
              if (amount > payment.remainingAmount) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Amount cannot exceed remaining balance of \$${payment.remainingAmount.toStringAsFixed(2)}',
                    ),
                  ),
                );
                return;
              }
              Navigator.pop(context, amount);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Process Payment'),
          ),
        ],
      ),
    );

    if (result == null) return;

    try {
      // Get current admin UID
      final adminUser = FirebaseAuth.instance.currentUser;
      if (adminUser == null) {
        throw 'Admin not authenticated';
      }

      // Process partial payment
      await _paymentService.processPayment(
        studentUid: widget.student.uid,
        year: payment.year,
        month: payment.month,
        adminUid: adminUser.uid,
        paymentAmount: result,
        studentName: widget.student.fullName,
      );

      // Reload payment history
      await _loadPaymentHistory();

      // Check if all payments are complete and update student profile
      await _updateStudentPaymentStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Partial payment of \$${result.toStringAsFixed(2)} processed successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateStudentPaymentStatus() async {
    // Check if all payments from registration to current month are fully paid
    final allPaid = _paymentHistory.every(
      (payment) => payment.remainingAmount == 0,
    );

    // Update student profile isPaid status
    await _studentService.updatePaymentStatus(
      studentUid: widget.student.uid,
      isPaid: allPaid,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditStudentDialog() async {
    final fullNameController = TextEditingController(
      text: widget.student.fullName,
    );
    final phoneController = TextEditingController(
      text: widget.student.phoneNumber,
    );
    final universityController = TextEditingController(
      text: widget.student.university,
    );

    List<City> allCities = await _studentService.getAllCities();

    // Check if student's city exists in the available cities
    City? selectedCity;
    if (widget.student.city.id.isNotEmpty) {
      // Try to find the city in the available cities by ID
      try {
        selectedCity = allCities.firstWhere(
          (city) => city.id == widget.student.city.id,
        );
      } catch (e) {
        // City not found (probably deleted), set to null
        selectedCity = null;
      }
    }

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Student Information'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: universityController,
                    decoration: const InputDecoration(
                      labelText: 'University',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<City>(
                    value: selectedCity,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      border: OutlineInputBorder(),
                    ),
                    items: allCities.map((city) {
                      return DropdownMenuItem(
                        value: city,
                        child: Text('${city.name} (Zone ${city.zone})'),
                      );
                    }).toList(),
                    onChanged: (city) {
                      setState(() => selectedCity = city);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a city';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true && selectedCity != null) {
      try {
        final updatedProfile = widget.student.copyWith(
          fullName: fullNameController.text.trim(),
          phoneNumber: phoneController.text.trim(),
          university: universityController.text.trim(),
          city: selectedCity,
        );

        await _studentService.updateStudentProfile(updatedProfile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student information updated successfully'),
            ),
          );
          // Refresh the screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  StudentDetailScreen(student: updatedProfile),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error updating student: $e')));
        }
      }
    }

    fullNameController.dispose();
    phoneController.dispose();
    universityController.dispose();
  }

  Future<void> _showEditSubscriptionDialog() async {
    List<ScheduleSuffix> allSchedules = await _studentService
        .getScheduleSuffixes();
    // Filter schedules to only show those matching the student's city zone
    List<ScheduleSuffix> filteredSchedules = allSchedules
        .where((schedule) => schedule.zone == widget.student.city.zone)
        .toList();

    ScheduleSuffix? selectedSchedule = widget.student.scheduleSuffix;
    SubscriptionType selectedType = widget.student.subscriptionType;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Subscription'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Showing schedules for Zone ${widget.student.city.zone} only',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                DropdownButtonFormField<ScheduleSuffix>(
                  value: selectedSchedule,
                  decoration: const InputDecoration(
                    labelText: 'Schedule',
                    border: OutlineInputBorder(),
                  ),
                  items: filteredSchedules.map((schedule) {
                    return DropdownMenuItem(
                      value: schedule,
                      child: Text('${schedule.code} - ${schedule.description}'),
                    );
                  }).toList(),
                  onChanged: (schedule) {
                    setState(() => selectedSchedule = schedule);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<SubscriptionType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Subscription Type',
                    border: OutlineInputBorder(),
                  ),
                  items: SubscriptionType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                  onChanged: (type) {
                    setState(() => selectedType = type!);
                  },
                ),
                if (selectedSchedule != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cost: \$${selectedType == SubscriptionType.monthly ? selectedSchedule!.monthlyCost : selectedSchedule!.dailyCost} / ${selectedType.displayName}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Days per week: ${selectedSchedule!.daysPerWeek}'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true && selectedSchedule != null) {
      // If schedule changed, need to select new days and times
      if (selectedSchedule!.id != widget.student.scheduleSuffix.id ||
          selectedSchedule!.daysPerWeek !=
              widget.student.scheduleSuffix.daysPerWeek) {
        // Show days and times selection dialog
        final daysTimesResult = await _showDaysTimesSelectionDialog(
          selectedSchedule!.daysPerWeek,
        );

        if (daysTimesResult == null) {
          // User cancelled days selection, don't save subscription change
          return;
        }

        try {
          final newCost = selectedType == SubscriptionType.monthly
              ? selectedSchedule!.monthlyCost
              : selectedSchedule!.dailyCost;

          final updatedProfile = widget.student.copyWith(
            scheduleSuffix: selectedSchedule,
            subscriptionType: selectedType,
            paymentAmount: newCost,
            selectedDays: daysTimesResult['selectedDays'] as List<String>,
            dayTimeSlots:
                daysTimesResult['dayTimeSlots'] as Map<String, TimeSlot>,
          );

          await _studentService.updateStudentProfile(updatedProfile);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Subscription and schedule updated successfully'),
              ),
            );
            // Refresh the screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    StudentDetailScreen(student: updatedProfile),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating subscription: $e')),
            );
          }
        }
      } else {
        // No schedule change, just update subscription type if changed
        try {
          final newCost = selectedType == SubscriptionType.monthly
              ? selectedSchedule!.monthlyCost
              : selectedSchedule!.dailyCost;

          final updatedProfile = widget.student.copyWith(
            scheduleSuffix: selectedSchedule,
            subscriptionType: selectedType,
            paymentAmount: newCost,
          );

          await _studentService.updateStudentProfile(updatedProfile);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Subscription updated successfully'),
              ),
            );
            // Refresh the screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    StudentDetailScreen(student: updatedProfile),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating subscription: $e')),
            );
          }
        }
      }
    }
  }

  Future<Map<String, dynamic>?> _showDaysTimesSelectionDialog(
    int requiredDays,
  ) async {
    final daysOfWeek = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    Map<String, TimeSlot?> selectedDayTimeSlots = {};
    List<String> selectedDays = [];

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Select $requiredDays ${requiredDays == 1 ? 'Day' : 'Days'} & ${requiredDays == 1 ? 'Time' : 'Times'}',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You must select exactly $requiredDays ${requiredDays == 1 ? 'day' : 'days'} (${selectedDays.length}/$requiredDays selected)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...daysOfWeek.map((day) {
                  final isSelected = selectedDays.contains(day);
                  final timeSlot = selectedDayTimeSlots[day];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isSelected ? Colors.blue.shade50 : null,
                    child: CheckboxListTile(
                      title: Text(
                        day,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      value: isSelected,
                      subtitle: isSelected && timeSlot != null
                          ? Text(
                              timeSlot.displayName,
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            if (selectedDays.length < requiredDays) {
                              selectedDays.add(day);
                              selectedDayTimeSlots[day] =
                                  TimeSlot.onepm; // Default
                            }
                          } else {
                            selectedDays.remove(day);
                            selectedDayTimeSlots.remove(day);
                          }
                        });
                      },
                      secondary: isSelected
                          ? DropdownButton<TimeSlot>(
                              value: timeSlot ?? TimeSlot.onepm,
                              underline: Container(),
                              items: TimeSlot.values.map((slot) {
                                return DropdownMenuItem(
                                  value: slot,
                                  child: Text(
                                    slot.displayName,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                              onChanged: (slot) {
                                setState(() {
                                  selectedDayTimeSlots[day] = slot;
                                });
                              },
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedDays.length == requiredDays
                  ? () => Navigator.pop(context, true)
                  : null,
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      // Filter out null values from the map
      final Map<String, TimeSlot> cleanedMap = {};
      selectedDayTimeSlots.forEach((key, value) {
        if (value != null) {
          cleanedMap[key] = value;
        }
      });

      return {'selectedDays': selectedDays, 'dayTimeSlots': cleanedMap};
    }

    return null;
  }

  Future<void> _showEditDaysTimesDialog() async {
    final requiredDays = widget.student.scheduleSuffix.daysPerWeek;
    final daysOfWeek = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    Map<String, TimeSlot?> selectedDayTimeSlots = Map.from(
      widget.student.dayTimeSlots,
    );
    List<String> selectedDays = List.from(widget.student.selectedDays);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Edit Days & Times ($requiredDays ${requiredDays == 1 ? 'Day' : 'Days'} Required)',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: selectedDays.length == requiredDays
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selectedDays.length == requiredDays
                          ? Colors.green.shade200
                          : Colors.orange.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedDays.length == requiredDays
                            ? Icons.check_circle
                            : Icons.info,
                        color: selectedDays.length == requiredDays
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You must select exactly $requiredDays ${requiredDays == 1 ? 'day' : 'days'} (${selectedDays.length}/$requiredDays selected)',
                          style: TextStyle(
                            fontSize: 12,
                            color: selectedDays.length == requiredDays
                                ? Colors.green.shade900
                                : Colors.orange.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...daysOfWeek.map((day) {
                  final isSelected = selectedDays.contains(day);
                  final timeSlot = selectedDayTimeSlots[day];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isSelected ? Colors.blue.shade50 : null,
                    child: CheckboxListTile(
                      title: Text(
                        day,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      value: isSelected,
                      subtitle: isSelected && timeSlot != null
                          ? Text(
                              timeSlot.displayName,
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            if (selectedDays.length < requiredDays) {
                              selectedDays.add(day);
                              selectedDayTimeSlots[day] =
                                  TimeSlot.onepm; // Default
                            }
                          } else {
                            selectedDays.remove(day);
                            selectedDayTimeSlots.remove(day);
                          }
                        });
                      },
                      secondary: isSelected
                          ? DropdownButton<TimeSlot>(
                              value: timeSlot ?? TimeSlot.onepm,
                              underline: Container(),
                              items: TimeSlot.values.map((slot) {
                                return DropdownMenuItem(
                                  value: slot,
                                  child: Text(
                                    slot.displayName,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                              onChanged: (slot) {
                                setState(() {
                                  selectedDayTimeSlots[day] = slot;
                                });
                              },
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedDays.length == requiredDays
                  ? () => Navigator.pop(context, true)
                  : null,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        // Filter out null values from the map
        final Map<String, TimeSlot> cleanedMap = {};
        selectedDayTimeSlots.forEach((key, value) {
          if (value != null) {
            cleanedMap[key] = value;
          }
        });

        final updatedProfile = widget.student.copyWith(
          selectedDays: selectedDays,
          dayTimeSlots: cleanedMap,
        );

        await _studentService.updateStudentProfile(updatedProfile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Days & times updated successfully')),
          );
          // Refresh the screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  StudentDetailScreen(student: updatedProfile),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating days & times: $e')),
          );
        }
      }
    }
  }
}
