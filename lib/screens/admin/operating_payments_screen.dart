import 'package:flutter/material.dart';
import '../../models/operating_payment.dart';
import '../../services/operating_payment_service.dart';
import '../../services/auth_service.dart';
import '../../services/accounting_service.dart';

class OperatingPaymentsScreen extends StatefulWidget {
  const OperatingPaymentsScreen({super.key});

  @override
  State<OperatingPaymentsScreen> createState() =>
      _OperatingPaymentsScreenState();
}

class _OperatingPaymentsScreenState extends State<OperatingPaymentsScreen> {
  final OperatingPaymentService _service = OperatingPaymentService();
  final AuthService _authService = AuthService();
  final AccountingService _accountingService = AccountingService();

  List<OperatingPayment> _payments = [];
  List<OperatingPayment> _filteredPayments = [];
  bool _isLoading = false;

  // Form fields
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _selectedPaymentType = 'fuel';
  String _selectedCurrency = 'USD';
  String? _selectedDriverId;

  // Filter fields
  String _filterPaymentType = 'all';
  String _filterCurrency = 'all';

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  @override
  void dispose() {
    _driverNameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    try {
      final payments = await _service.getRecentPayments(limit: 50);
      setState(() {
        _payments = payments;
        _applyFilters();
      });
    } catch (e) {
      _showError('Failed to load payments: $e');
    }
    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    List<OperatingPayment> filtered = List.from(_payments);

    // Apply payment type filter
    if (_filterPaymentType != 'all') {
      filtered = filtered
          .where((p) => p.paymentType == _filterPaymentType)
          .toList();
    }

    // Apply currency filter
    if (_filterCurrency != 'all') {
      filtered = filtered.where((p) => p.currency == _filterCurrency).toList();
    }

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final searchLower = _searchController.text.toLowerCase();
      filtered = filtered.where((p) {
        return p.driverName.toLowerCase().contains(searchLower) ||
            p.paymentTypeLabel.toLowerCase().contains(searchLower) ||
            (p.notes?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    }

    setState(() => _filteredPayments = filtered);
  }

  Future<void> _addPayment() async {
    if (_driverNameController.text.isEmpty || _amountController.text.isEmpty) {
      _showError('Please fill all required fields');
      return;
    }

    try {
      final amount = double.parse(_amountController.text);
      final currentUser = _authService.currentUser;

      if (currentUser == null) {
        _showError('User not authenticated');
        return;
      }

      await _service.addOperatingPayment(
        driverId:
            _selectedDriverId ??
            'driver_${DateTime.now().millisecondsSinceEpoch}',
        driverName: _driverNameController.text,
        paymentType: _selectedPaymentType,
        amount: amount,
        currency: _selectedCurrency,
        adminId: currentUser.uid,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      // Record negative transaction in payment_transactions
      await _accountingService.addTransaction(
        studentId:
            _selectedDriverId ??
            'driver_${DateTime.now().millisecondsSinceEpoch}',
        studentName: _driverNameController.text,
        amount: -amount,
        paymentType:
            'Operating Payment - ${_selectedPaymentType[0].toUpperCase()}${_selectedPaymentType.substring(1)}',
        subscriptionMonth: DateTime.now().month,
        subscriptionYear: DateTime.now().year,
        adminId: currentUser.uid,
        currency: _selectedCurrency,
        notes: _notesController.text.isNotEmpty
            ? _notesController.text
            : 'Operating payment',
      );

      _showSuccess('Payment added successfully');
      _clearForm();
      _loadPayments();
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Failed to add payment: $e');
    }
  }

  void _clearForm() {
    _driverNameController.clear();
    _amountController.clear();
    _notesController.clear();
    _selectedPaymentType = 'fuel';
    _selectedCurrency = 'USD';
    _selectedDriverId = null;
  }

  void _showAddPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Operating Payment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _driverNameController,
                decoration: const InputDecoration(
                  labelText: 'Driver Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPaymentType,
                decoration: const InputDecoration(
                  labelText: 'Payment Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'fuel', child: Text('Fuel')),
                  DropdownMenuItem(
                    value: 'maintenance',
                    child: Text('Maintenance'),
                  ),
                  DropdownMenuItem(value: 'salary', child: Text('Salary')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPaymentType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCurrency,
                decoration: const InputDecoration(
                  labelText: 'Currency',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                  DropdownMenuItem(value: 'LBP', child: Text('Lebanese Pound')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCurrency = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _addPayment();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
            ),
            child: const Text('Add Payment'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Operating Payments'),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPayments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by driver name, type, or notes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) => _applyFilters(),
            ),
          ),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Type: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                _buildFilterChip('All', 'all', _filterPaymentType, (value) {
                  setState(() => _filterPaymentType = value);
                  _applyFilters();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Fuel', 'fuel', _filterPaymentType, (value) {
                  setState(() => _filterPaymentType = value);
                  _applyFilters();
                }),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Maintenance',
                  'maintenance',
                  _filterPaymentType,
                  (value) {
                    setState(() => _filterPaymentType = value);
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip('Salary', 'salary', _filterPaymentType, (
                  value,
                ) {
                  setState(() => _filterPaymentType = value);
                  _applyFilters();
                }),
                const SizedBox(width: 24),
                const Text(
                  'Currency: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                _buildFilterChip('All', 'all', _filterCurrency, (value) {
                  setState(() => _filterCurrency = value);
                  _applyFilters();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('USD', 'USD', _filterCurrency, (value) {
                  setState(() => _filterCurrency = value);
                  _applyFilters();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('LBP', 'LBP', _filterCurrency, (value) {
                  setState(() => _filterCurrency = value);
                  _applyFilters();
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${_filteredPayments.length} of ${_payments.length} payments',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                if (_filterPaymentType != 'all' ||
                    _filterCurrency != 'all' ||
                    _searchController.text.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _filterPaymentType = 'all';
                        _filterCurrency = 'all';
                        _searchController.clear();
                      });
                      _applyFilters();
                    },
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Clear Filters'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.amber.shade700,
                    ),
                  ),
              ],
            ),
          ),
          // Payments List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPayments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _payments.isEmpty
                              ? Icons.directions_bus
                              : Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _payments.isEmpty
                              ? 'No payments recorded'
                              : 'No payments match your filters',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (_payments.isNotEmpty) const SizedBox(height: 8),
                        if (_payments.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _filterPaymentType = 'all';
                                _filterCurrency = 'all';
                                _searchController.clear();
                              });
                              _applyFilters();
                            },
                            child: const Text('Clear all filters'),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredPayments.length,
                    itemBuilder: (context, index) {
                      final payment = _filteredPayments[index];
                      return _buildPaymentCard(payment);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPaymentDialog,
        backgroundColor: Colors.amber.shade700,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPaymentCard(OperatingPayment payment) {
    final typeColor = _getPaymentTypeColor(payment.paymentType);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getPaymentTypeIcon(payment.paymentType),
            color: typeColor,
            size: 24,
          ),
        ),
        title: Text(
          payment.driverName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              payment.paymentTypeLabel,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 2),
            Text(
              payment.formattedDate,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              payment.formattedAmount,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: typeColor,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                payment.currency,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: typeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPaymentTypeColor(String type) {
    switch (type) {
      case 'fuel':
        return Colors.orange;
      case 'maintenance':
        return Colors.blue;
      case 'salary':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentTypeIcon(String type) {
    switch (type) {
      case 'fuel':
        return Icons.local_gas_station;
      case 'maintenance':
        return Icons.construction;
      case 'salary':
        return Icons.attach_money;
      default:
        return Icons.money;
    }
  }

  Widget _buildFilterChip(
    String label,
    String value,
    String currentValue,
    Function(String) onSelected,
  ) {
    final isSelected = currentValue == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => onSelected(value),
      backgroundColor: Colors.white,
      selectedColor: Colors.amber.shade100,
      checkmarkColor: Colors.amber.shade700,
      labelStyle: TextStyle(
        color: isSelected ? Colors.amber.shade700 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
