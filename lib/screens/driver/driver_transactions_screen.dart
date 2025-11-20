import 'package:flutter/material.dart';
import '../../models/driver_payment_transaction.dart';
import '../../services/driver_payment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverTransactionsScreen extends StatefulWidget {
  const DriverTransactionsScreen({super.key});

  @override
  State<DriverTransactionsScreen> createState() =>
      _DriverTransactionsScreenState();
}

class _DriverTransactionsScreenState extends State<DriverTransactionsScreen> {
  final DriverPaymentService _paymentService = DriverPaymentService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _filterCurrency = 'ALL';
  String _searchQuery = '';
  DateTimeRange? _dateRange;
  
  // Pagination
  List<DriverPaymentTransaction> _transactions = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isInitialLoad = true;
  
  @override
  void initState() {
    super.initState();
    _loadInitialTransactions();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialTransactions() async {
    setState(() {
      _isInitialLoad = true;
      _transactions = [];
      _lastDocument = null;
      _hasMore = true;
    });
    await _loadMoreTransactions();
    setState(() {
      _isInitialLoad = false;
    });
  }

  Future<void> _loadMoreTransactions() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newTransactions = await _paymentService.getPaginatedDriverTransactions(
        driverId: currentUser.uid,
        lastDocument: _lastDocument,
      );

      if (newTransactions.isNotEmpty) {
        // Get the last document for next pagination
        final lastTransaction = newTransactions.last;
        final doc = await _paymentService.getDocumentSnapshot(lastTransaction.id);
        
        setState(() {
          _transactions.addAll(newTransactions);
          _lastDocument = doc;
          _hasMore = newTransactions.length == DriverPaymentService.pageSize;
        });
      } else {
        setState(() {
          _hasMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading transactions: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view transactions')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Payment Transactions'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _showDateRangePicker,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by student name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  // Reset to reload with search filter
                  _loadInitialTransactions();
                });
              },
            ),
          ),
          
          // Active Filters Display
          if (_filterCurrency != 'ALL' || _dateRange != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  const Icon(Icons.filter_alt, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: [
                        if (_filterCurrency != 'ALL')
                          Chip(
                            label: Text(_filterCurrency),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _filterCurrency = 'ALL';
                              });
                            },
                            backgroundColor: Colors.white,
                          ),
                        if (_dateRange != null)
                          Chip(
                            label: Text(
                              '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
                            ),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _dateRange = null;
                              });
                            },
                            backgroundColor: Colors.white,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Transactions List
          Expanded(
            child: _buildTransactionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    // Apply filters
    var filteredTransactions = _transactions.where((t) {
      // Currency filter
      if (_filterCurrency != 'ALL' && t.currency != _filterCurrency) {
        return false;
      }
      
      // Search filter
      if (_searchQuery.isNotEmpty && 
          !t.studentName.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      
      // Date range filter
      if (_dateRange != null) {
        final transactionDate = DateTime(
          t.timestamp.year,
          t.timestamp.month,
          t.timestamp.day,
        );
        final startDate = DateTime(
          _dateRange!.start.year,
          _dateRange!.start.month,
          _dateRange!.start.day,
        );
        final endDate = DateTime(
          _dateRange!.end.year,
          _dateRange!.end.month,
          _dateRange!.end.day,
        );
        
        if (transactionDate.isBefore(startDate) || 
            transactionDate.isAfter(endDate)) {
          return false;
        }
      }
      
      return true;
    }).toList();

    if (filteredTransactions.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long,
                size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _filterCurrency != 'ALL' || _dateRange != null
                  ? 'No matching transactions'
                  : 'No transactions yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _filterCurrency != 'ALL' || _dateRange != null
                  ? 'Try adjusting your filters'
                  : 'Student payments will appear here',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    // Calculate totals for filtered transactions
    final totalUSD = filteredTransactions
        .where((t) => t.currency == 'USD')
        .fold<double>(0.0, (sum, t) => sum + t.amount);
    final totalLBP = filteredTransactions
        .where((t) => t.currency == 'LBP')
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    return Column(
      children: [
        // Summary Card
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade700, Colors.green.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Text(
                'Total Collected',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (_filterCurrency == 'ALL' || _filterCurrency == 'USD')
                    Column(
                      children: [
                        const Text(
                          'USD',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${NumberFormat('#,###.##').format(totalUSD)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  if (_filterCurrency == 'ALL')
                    Container(
                      width: 1,
                      height: 50,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  if (_filterCurrency == 'ALL' || _filterCurrency == 'LBP')
                    Column(
                      children: [
                        const Text(
                          'LBP',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'LL${NumberFormat('#,###.##').format(totalLBP)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${filteredTransactions.length} transactions',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // Transactions List
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredTransactions.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == filteredTransactions.length) {
                // Load more button
                return _buildLoadMoreButton();
              }
              
              final transaction = filteredTransactions[index];
              return _buildTransactionCard(transaction);
            },
          ),
        ),
        
        // Show status at bottom
        if (_transactions.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade100,
            child: Text(
              _hasMore 
                  ? 'Loaded ${filteredTransactions.length} transactions • Tap "Load More" for next batch'
                  : 'All ${filteredTransactions.length} transactions loaded',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildLoadMoreButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Center(
        child: _isLoading
            ? Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(
                    'Loading more transactions...',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              )
            : Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: _loadMoreTransactions,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.expand_more, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Load More Transactions',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.expand_more, color: Colors.green.shade700),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter by Currency'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('All Currencies'),
                value: 'ALL',
                groupValue: _filterCurrency,
                onChanged: (value) {
                  setState(() {
                    _filterCurrency = value!;
                    _loadInitialTransactions();
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('USD Only'),
                value: 'USD',
                groupValue: _filterCurrency,
                onChanged: (value) {
                  setState(() {
                    _filterCurrency = value!;
                    _loadInitialTransactions();
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('LBP Only'),
                value: 'LBP',
                groupValue: _filterCurrency,
                onChanged: (value) {
                  setState(() {
                    _filterCurrency = value!;
                    _loadInitialTransactions();
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green.shade700,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _loadInitialTransactions();
      });
    }
  }

  Widget _buildTransactionCard(DriverPaymentTransaction transaction) {
    final isAdminTransfer = transaction.studentId == 'ADMIN';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAdminTransfer
              ? Colors.red.shade100
              : (transaction.currency == 'USD'
                  ? Colors.green.shade100
                  : Colors.blue.shade100),
          child: Icon(
            isAdminTransfer ? Icons.upload : Icons.person,
            color: isAdminTransfer
                ? Colors.red.shade700
                : (transaction.currency == 'USD'
                    ? Colors.green.shade700
                    : Colors.blue.shade700),
          ),
        ),
        title: Text(
          transaction.studentName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${transaction.formattedDate} at ${transaction.formattedTime}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            if (transaction.notes != null) ...[
              const SizedBox(height: 2),
              Text(
                transaction.notes!,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isAdminTransfer
                ? Colors.red.shade50
                : (transaction.currency == 'USD'
                    ? Colors.green.shade50
                    : Colors.blue.shade50),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            transaction.formattedAmount,
            style: TextStyle(
              color: isAdminTransfer
                  ? Colors.red.shade700
                  : (transaction.currency == 'USD'
                      ? Colors.green.shade700
                      : Colors.blue.shade700),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
