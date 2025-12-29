import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/payment_transaction.dart';
import '../../services/accounting_service.dart';

enum FilterType { all, today, month, year }

class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  final AccountingService _accountingService = AccountingService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  FilterType _selectedFilter = FilterType.all;
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';

  List<PaymentTransaction> _transactions = [];
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
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      List<PaymentTransaction> newTransactions;

      if (_selectedFilter == FilterType.all) {
        newTransactions = await _accountingService.getPaginatedTransactions(
          lastDocument: _lastDocument,
        );
      } else {
        final dateRange = _getDateRange();
        newTransactions = await _accountingService
            .getPaginatedTransactionsByDateRange(
              startDate: dateRange['start']!,
              endDate: dateRange['end']!,
              lastDocument: _lastDocument,
            );
      }

      if (newTransactions.isNotEmpty) {
        // Get the last document for next pagination
        final lastTransaction = newTransactions.last;
        final doc = await _accountingService.getDocumentSnapshot(
          lastTransaction.id,
        );

        setState(() {
          _transactions.addAll(newTransactions);
          _lastDocument = doc;
          _hasMore = newTransactions.length == AccountingService.pageSize;
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

  Map<String, DateTime> _getDateRange() {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case FilterType.today:
        return {
          'start': DateTime(now.year, now.month, now.day, 0, 0, 0),
          'end': DateTime(now.year, now.month, now.day, 23, 59, 59),
        };
      case FilterType.month:
        return {
          'start': DateTime(
            _selectedDate.year,
            _selectedDate.month,
            1,
            0,
            0,
            0,
          ),
          'end': DateTime(
            _selectedDate.year,
            _selectedDate.month + 1,
            0,
            23,
            59,
            59,
          ),
        };
      case FilterType.year:
        return {
          'start': DateTime(_selectedDate.year, 1, 1, 0, 0, 0),
          'end': DateTime(_selectedDate.year, 12, 31, 23, 59, 59),
        };
      case FilterType.all:
        return {'start': DateTime(2000, 1, 1), 'end': DateTime(2100, 12, 31)};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            // Search Bar
            _buildSearchBar(),

            // Filter Chips
            _buildFilterSection(),

            // Summary Stats Bar
            _buildSummaryBar(),

            // Transactions List
            Expanded(child: _buildTransactionsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search by student name...',
          prefixIcon: Icon(Icons.search, color: Colors.green.shade700),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
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
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green.shade700, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All Time', FilterType.all, Icons.all_inclusive),
            const SizedBox(width: 8),
            _buildFilterChip('Today', FilterType.today, Icons.today),
            const SizedBox(width: 8),
            _buildFilterChip(
              'This Month',
              FilterType.month,
              Icons.calendar_month,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'This Year',
              FilterType.year,
              Icons.calendar_today,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, FilterType type, IconData icon) {
    final isSelected = _selectedFilter == type;
    return FilterChip(
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? Colors.green.shade700 : Colors.grey.shade600,
      ),
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = type;
        });
        _loadInitialTransactions(); // Reload with new filter
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.green.shade100,
      checkmarkColor: Colors.green.shade700,
      labelStyle: TextStyle(
        color: isSelected ? Colors.green.shade700 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      elevation: isSelected ? 2 : 0,
    );
  }

  Widget _buildSummaryBar() {
    final filteredTransactions = _getFilteredTransactions(_transactions);
    final balance = filteredTransactions.fold(0.0, (sum, t) => sum + t.amount);
    final count = filteredTransactions.length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade500],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryStat(
            icon: Icons.receipt_long,
            label: 'Showing',
            value: '$count${!_hasMore ? "" : "+"}',
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          _buildSummaryStat(
            icon: Icons.account_balance_wallet,
            label: 'Total',
            value: '\$${balance.toStringAsFixed(0)}',
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          _buildSummaryStat(
            icon: Icons.trending_up,
            label: 'Average',
            value: count > 0
                ? '\$${(balance / count).toStringAsFixed(0)}'
                : '\$0',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsList() {
    if (_isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredTransactions = _getFilteredTransactions(_transactions);

    if (filteredTransactions.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No transactions found'
                  : 'No transactions yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'Transactions will appear here when students make payments',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: filteredTransactions.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == filteredTransactions.length) {
                // Load more button
                return _buildLoadMoreButton();
              }
              final transaction = filteredTransactions[index];
              return _buildTransactionCard(transaction, index);
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
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
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

  Widget _buildTransactionCard(PaymentTransaction transaction, int index) {
    final isOperatingPayment = transaction.paymentType.toLowerCase().contains(
      'operating payment',
    );
    final isDriverTransfer = transaction.paymentType.toLowerCase().contains(
      'driver transfer',
    );

    Color cardColor;
    Color textColor;
    IconData iconData;
    String badgeLabel;

    if (isOperatingPayment) {
      cardColor = Colors.red.shade100;
      textColor = Colors.red.shade700;
      iconData = Icons.trending_down;
      badgeLabel = 'EXPENSE';
    } else if (isDriverTransfer) {
      cardColor = Colors.purple.shade100;
      textColor = Colors.purple.shade700;
      iconData = Icons.download;
      badgeLabel = 'TRANSFER';
    } else if (transaction.paymentType == 'full') {
      cardColor = Colors.green.shade100;
      textColor = Colors.green.shade700;
      iconData = Icons.person;
      badgeLabel = 'FULL';
    } else {
      cardColor = Colors.orange.shade100;
      textColor = Colors.orange.shade700;
      iconData = Icons.person;
      badgeLabel = transaction.paymentType.toUpperCase();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showTransactionDetails(transaction),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Left: Icon and Number
              Container(
                width: 50,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(iconData, color: textColor, size: 24),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#${index + 1}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Middle: Student Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.studentName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            isOperatingPayment || isDriverTransfer
                                ? transaction.paymentType
                                : 'Period: ${transaction.subscriptionPeriod}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          transaction.formattedDate,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Right: Amount and Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    transaction.formattedAmount,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cardColor),
                    ),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(PaymentTransaction transaction) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: Colors.green.shade700,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Transaction Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow(
                'Student Name',
                transaction.studentName,
                Icons.person,
              ),
              _buildDetailRow(
                'Amount',
                transaction.formattedAmount,
                Icons.attach_money,
              ),
              _buildDetailRow(
                'Payment Type',
                transaction.paymentType.toUpperCase(),
                Icons.payment,
              ),
              _buildDetailRow(
                'Period',
                transaction.subscriptionPeriod,
                Icons.calendar_month,
              ),
              _buildDetailRow(
                'Date & Time',
                transaction.formattedDate,
                Icons.access_time,
              ),
              if (transaction.notes != null && transaction.notes!.isNotEmpty)
                _buildDetailRow('Notes', transaction.notes!, Icons.note),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
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

  List<PaymentTransaction> _getFilteredTransactions(
    List<PaymentTransaction> transactions,
  ) {
    if (_searchQuery.isEmpty) {
      return transactions;
    }

    return transactions.where((transaction) {
      return transaction.studentName.toLowerCase().contains(_searchQuery);
    }).toList();
  }
}
