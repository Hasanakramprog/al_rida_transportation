import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/student_profile.dart';
import '../../models/monthly_payment.dart';
import '../../services/student_profile_service.dart';
import '../../services/monthly_payment_service.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final StudentProfileService _studentService = StudentProfileService();
  final MonthlyPaymentService _paymentService = MonthlyPaymentService();
  
  List<StudentProfile> _allStudents = [];
  List<StudentProfile> _filteredStudents = [];
  Map<String, MonthlyPayment?> _currentMonthPayments = {};
  Map<String, String> _studentEmails = {}; // Cache student emails
  
  bool _isLoading = true;
  String _searchQuery = '';
  String _paymentFilter = 'all'; // all, paid, unpaid, partial
  String _activeFilter = 'active'; // all, active, inactive
  
  // Sorting
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  
  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      setState(() => _isLoading = true);
      
      _allStudents = await _studentService.getAllStudents();
      
      // Load current month payment status for each student
      final currentDate = DateTime.now();
      for (var student in _allStudents) {
        // Use UID as placeholder for email (in production, get from Firebase Auth)
        _studentEmails[student.uid] = student.uid;
        
        // Get current month payment
        final payment = await _paymentService.getPaymentStatus(
          studentUid: student.uid,
          year: currentDate.year,
          month: currentDate.month,
        );
        _currentMonthPayments[student.uid] = payment;
      }
      
      _applyFiltersAndSort();
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: $e')),
        );
      }
    }
  }

  void _applyFiltersAndSort() {
    _filteredStudents = _allStudents.where((student) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final email = _studentEmails[student.uid] ?? '';
        final matchesEmail = email.toLowerCase().contains(query);
        final matchesName = student.fullName.toLowerCase().contains(query);
        final matchesPhone = student.phoneNumber.toLowerCase().contains(query);
        final matchesUni = student.university.toLowerCase().contains(query);
        if (!matchesEmail && !matchesName && !matchesPhone && !matchesUni) return false;
      }
      
      // Active status filter
      if (_activeFilter != 'all') {
        if (_activeFilter == 'active' && !student.isActive) return false;
        if (_activeFilter == 'inactive' && student.isActive) return false;
      }
      
      // Payment filter
      if (_paymentFilter != 'all') {
        final payment = _currentMonthPayments[student.uid];
        if (_paymentFilter == 'paid' && (payment == null || !payment.isFullyPaid)) return false;
        if (_paymentFilter == 'unpaid' && (payment != null && payment.paidAmount > 0)) return false;
        if (_paymentFilter == 'partial' && (payment == null || !payment.isPartiallyPaid)) return false;
      }
      
      return true;
    }).toList();
    
    _sortStudents();
  }

  void _sortStudents() {
    _filteredStudents.sort((a, b) {
      int compare = 0;
      switch (_sortColumnIndex) {
        case 0: // Name
          compare = a.fullName.compareTo(b.fullName);
          break;
        case 1: // Phone
          compare = a.phoneNumber.compareTo(b.phoneNumber);
          break;
        case 2: // University
          compare = a.university.compareTo(b.university);
          break;
        case 3: // Registration Date
          compare = a.createdAt.compareTo(b.createdAt);
          break;
        case 4: // Subscription
          compare = a.subscriptionCost.compareTo(b.subscriptionCost);
          break;
        case 5: // Payment Status
          final paymentA = _currentMonthPayments[a.uid];
          final paymentB = _currentMonthPayments[b.uid];
          final remainingA = paymentA?.remainingAmount ?? 0;
          final remainingB = paymentB?.remainingAmount ?? 0;
          compare = remainingA.compareTo(remainingB);
          break;
      }
      return _sortAscending ? compare : -compare;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Manage Students'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          _buildStatsBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStudents.isEmpty
                    ? _buildEmptyState()
                    : _buildStudentsTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.red.shade50,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by name, email, phone, or university...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFiltersAndSort();
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  label: 'Status',
                  value: _activeFilter,
                  items: const {'all': 'All Students', 'active': 'Active', 'inactive': 'Inactive'},
                  onChanged: (value) {
                    setState(() {
                      _activeFilter = value!;
                      _applyFiltersAndSort();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  label: 'Payment Status',
                  value: _paymentFilter,
                  items: const {'all': 'All', 'paid': 'Paid', 'unpaid': 'Unpaid', 'partial': 'Partial'},
                  onChanged: (value) {
                    setState(() {
                      _paymentFilter = value!;
                      _applyFiltersAndSort();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      value: value,
      items: items.entries.map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildStatsBar() {
    final totalStudents = _allStudents.length;
    final filteredCount = _filteredStudents.length;
    final paidCount = _filteredStudents.where((s) {
      final payment = _currentMonthPayments[s.uid];
      return payment != null && payment.isFullyPaid;
    }).length;
    final unpaidCount = _filteredStudents.where((s) {
      final payment = _currentMonthPayments[s.uid];
      return payment == null || payment.paidAmount == 0;
    }).length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', '$totalStudents', Colors.blue),
          _buildStatItem('Showing', '$filteredCount', Colors.purple),
          _buildStatItem('Paid', '$paidCount', Colors.green),
          _buildStatItem('Unpaid', '$unpaidCount', Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text('No Students Found', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
          const SizedBox(height: 8),
          Text('Try adjusting your filters', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline)),
        ],
      ),
    );
  }

  Widget _buildStudentsTable() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            showCheckboxColumn: false,
            columnSpacing: 20,
            horizontalMargin: 16,
            headingRowHeight: 56,
            dataRowMinHeight: 60,
            dataRowMaxHeight: 80,
            sortColumnIndex: _sortColumnIndex,
            sortAscending: _sortAscending,
            headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            columns: [
              DataColumn(
                label: SizedBox(
                  width: 130,
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      const Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                onSort: (idx, asc) => _onSort(idx, asc),
              ),
              DataColumn(
                label: SizedBox(
                  width: 120,
                  child: Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      const Text('Phone', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                onSort: (idx, asc) => _onSort(idx, asc),
              ),
              DataColumn(
                label: SizedBox(
                  width: 140,
                  child: Row(
                    children: [
                      Icon(Icons.school, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      const Text('University', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                onSort: (idx, asc) => _onSort(idx, asc),
              ),
              DataColumn(
                label: SizedBox(
                  width: 100,
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      const Text('Registered', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                onSort: (idx, asc) => _onSort(idx, asc),
              ),
              DataColumn(
                label: SizedBox(
                  width: 90,
                  child: Row(
                    children: [
                      Icon(Icons.attach_money, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      const Text('Cost', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                numeric: true,
                onSort: (idx, asc) => _onSort(idx, asc),
              ),
              DataColumn(
                label: SizedBox(
                  width: 120,
                  child: Row(
                    children: [
                      Icon(Icons.payment, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      const Text('Payment', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                onSort: (idx, asc) => _onSort(idx, asc),
              ),
              const DataColumn(
                label: SizedBox(
                  width: 100,
                  child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
            rows: _filteredStudents.asMap().entries.map((entry) {
              final index = entry.key;
              final student = entry.value;
              final payment = _currentMonthPayments[student.uid];
              
              return DataRow(
                color: MaterialStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.blue.shade100;
                  }
                  if (states.contains(MaterialState.hovered)) {
                    return Colors.grey.shade50;
                  }
                  return index.isEven ? Colors.white : Colors.grey.shade50.withOpacity(0.5);
                }),
                onSelectChanged: (selected) {
                  if (selected == true) {
                    Navigator.pushNamed(context, '/admin/student_detail', arguments: student);
                  }
                },
                cells: [
                  DataCell(
                    SizedBox(
                      width: 130,
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue.shade600,
                            radius: 18,
                            child: Text(
                              student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              student.fullName,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 120,
                      child: Row(
                        children: [
                          Icon(Icons.phone_android, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              student.phoneNumber,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 140,
                      child: Text(
                        student.university,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 100,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          DateFormat('MMM dd, yyyy').format(student.createdAt),
                          style: TextStyle(fontSize: 11, color: Colors.purple.shade700, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 90,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          '\$${student.subscriptionCost.toStringAsFixed(2)}',
                          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.green.shade700, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  DataCell(SizedBox(width: 120, child: _buildPaymentStatusChip(payment))),
                  DataCell(
                    SizedBox(
                      width: 100,
                      child: _buildActiveToggle(student),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentStatusChip(MonthlyPayment? payment) {
    if (payment == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade400, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.help_outline, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              'No Data',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    Color color;
    Color bgColor;
    String text;
    IconData icon;
    
    if (payment.isFullyPaid) {
      color = Colors.green.shade700;
      bgColor = Colors.green.shade50;
      text = 'Paid';
      icon = Icons.check_circle;
    } else if (payment.isPartiallyPaid) {
      color = Colors.orange.shade700;
      bgColor = Colors.orange.shade50;
      text = '${payment.paymentPercentage.toInt()}%';
      icon = Icons.hourglass_empty;
    } else {
      color = Colors.red.shade700;
      bgColor = Colors.red.shade50;
      text = 'Unpaid';
      icon = Icons.cancel;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveToggle(StudentProfile student) {
    return Switch(
      value: student.isActive,
      onChanged: (value) async {
        try {
          await _studentService.toggleStudentActiveStatus(student.uid, value);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  value 
                    ? '${student.fullName} is now active'
                    : '${student.fullName} has been deactivated and removed from all trips',
                ),
                backgroundColor: value ? Colors.green : Colors.orange,
              ),
            );
            
            // Reload students to reflect the change
            _loadStudents();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error updating status: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      activeColor: Colors.green,
      inactiveThumbColor: Colors.red,
    );
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _sortStudents();
    });
  }
}
