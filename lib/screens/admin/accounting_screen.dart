import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/payment_transaction.dart';
import '../../services/accounting_service.dart';

enum FilterType { all, today, month, year }

class AccountingScreen extends StatefulWidget {
  const AccountingScreen({super.key});

  @override
  State<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends State<AccountingScreen> {
  final AccountingService _accountingService = AccountingService();
  FilterType _selectedFilter = FilterType.all;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<PaymentTransaction> _transactions = [];
  List<PaymentTransaction> _recentTransactions = [];

  // Cache for statistics to minimize Firestore reads
  Map<String, dynamic>? _cachedStatistics;
  bool _isLoadingStatistics = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Reload statistics when in All Time view
      if (_selectedFilter == FilterType.all) {
        setState(() => _isLoadingStatistics = true);
        _cachedStatistics = await _accountingService.getStatistics();
        setState(() => _isLoadingStatistics = false);
      }

      final filtered = await _getFilteredTransactions();
      final recent = await _accountingService.getRecentTransactions(limit: 5);

      setState(() {
        _transactions = filtered;
        _recentTransactions = recent;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingStatistics = false;
      });
    }
  }

  Future<List<PaymentTransaction>> _getFilteredTransactions() async {
    switch (_selectedFilter) {
      case FilterType.today:
        return await _accountingService.getTodayTransactions();
      case FilterType.month:
        return await _accountingService.getMonthTransactions(
          _selectedDate.year,
          _selectedDate.month,
        );
      case FilterType.year:
        return await _accountingService.getYearTransactions(_selectedDate.year);
      case FilterType.all:
        return await _accountingService.getAllTransactionsOnce(
          limit: 1000,
        ); // Limit to prevent excessive reads
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounting & Transactions'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
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
            // Filter Chips
            _buildFilterSection(),

            // Balance Summary Card
            _buildBalanceSummary(),

            // Transactions List
            Expanded(child: _buildTransactionsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All Time', FilterType.all),
            const SizedBox(width: 8),
            _buildFilterChip('Today', FilterType.today),
            const SizedBox(width: 8),
            _buildFilterChip('This Month', FilterType.month),
            const SizedBox(width: 8),
            _buildFilterChip('This Year', FilterType.year),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, FilterType type) {
    final isSelected = _selectedFilter == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = type;
        });
        _loadData(); // Reload with new filter
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.green.shade100,
      checkmarkColor: Colors.green.shade700,
      labelStyle: TextStyle(
        color: isSelected ? Colors.green.shade700 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildBalanceSummary() {
    if (_isLoading) {
      return const Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // For "All Time" filter, use admin wallet. For others, calculate from filtered transactions
    final isTotalBalance = _selectedFilter == FilterType.all;

    if (isTotalBalance) {
      // Use cached statistics to minimize Firestore reads
      if (_isLoadingStatistics) {
        return const Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }

      final stats = _cachedStatistics ?? {};
      final balanceUSD = (stats['totalBalanceUSD'] as num?)?.toDouble() ?? 0.0;
      final balanceLBP = (stats['totalBalanceLBP'] as num?)?.toDouble() ?? 0.0;
      final countUSD = (stats['totalTransactionsUSD'] as num?)?.toInt() ?? 0;
      final countLBP = (stats['totalTransactionsLBP'] as num?)?.toInt() ?? 0;

      return _buildDualWalletCard(balanceUSD, balanceLBP, countUSD, countLBP);
    } else {
      // For filtered views, calculate from transactions by currency
      final usdTransactions = _transactions
          .where((t) => t.currency == 'USD')
          .toList();
      final lbpTransactions = _transactions
          .where((t) => t.currency == 'LBP')
          .toList();

      final balanceUSD = usdTransactions.fold(0.0, (sum, t) => sum + t.amount);
      final balanceLBP = lbpTransactions.fold(0.0, (sum, t) => sum + t.amount);

      return _buildDualWalletCard(
        balanceUSD,
        balanceLBP,
        usdTransactions.length,
        lbpTransactions.length,
      );
    }
  }

  Widget _buildDualWalletCard(
    double balanceUSD,
    double balanceLBP,
    int countUSD,
    int countLBP,
  ) {
    return Column(
      children: [
        _buildWalletCard(
          'USD Wallet',
          balanceUSD,
          countUSD,
          Colors.green.shade700,
          '\$',
        ),
        const SizedBox(height: 12),
        _buildWalletCard(
          'LBP Wallet',
          balanceLBP,
          countLBP,
          Colors.blue.shade700,
          '',
        ),
      ],
    );
  }

  Widget _buildWalletCard(
    String title,
    double balance,
    int count,
    Color color,
    String symbol,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$symbol${NumberFormat('#,###').format(balance.toInt())}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'Transactions',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Column(
                    children: [
                      const Text(
                        'Average',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        count > 0
                            ? '$symbol${(balance / count).toStringAsFixed(0)}'
                            : '$symbol'
                                  '0',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recentTransactions.isEmpty) {
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
              'No transactions found',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Transactions will appear here when students make payments',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header with "View All" button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/admin/transactions');
                },
                icon: const Icon(Icons.list_alt),
                label: const Text('View All'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
        // List of recent transactions
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recentTransactions.length,
            itemBuilder: (context, index) {
              final transaction = _recentTransactions[index];
              return _buildTransactionCard(transaction);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(PaymentTransaction transaction) {
    final isOperatingPayment = transaction.paymentType.toLowerCase().contains(
      'operating payment',
    );
    final isDriverTransfer = transaction.paymentType.toLowerCase().contains(
      'driver transfer',
    );

    Color cardColor;
    Color textColor;
    IconData iconData;

    if (isOperatingPayment) {
      cardColor = Colors.red.shade100;
      textColor = Colors.red.shade700;
      iconData = Icons.trending_down;
    } else if (isDriverTransfer) {
      cardColor = Colors.purple.shade100;
      textColor = Colors.purple.shade700;
      iconData = Icons.download;
    } else if (transaction.paymentType == 'full') {
      cardColor = Colors.green.shade100;
      textColor = Colors.green.shade700;
      iconData = Icons.person;
    } else {
      cardColor = Colors.orange.shade100;
      textColor = Colors.orange.shade700;
      iconData = Icons.person;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(iconData, color: textColor, size: 24),
        ),
        title: Text(
          transaction.studentName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              isOperatingPayment || isDriverTransfer
                  ? transaction.paymentType
                  : 'Period: ${transaction.subscriptionPeriod}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 2),
            Text(
              transaction.formattedDate,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isOperatingPayment
                    ? 'EXPENSE'
                    : (isDriverTransfer
                          ? 'TRANSFER'
                          : transaction.paymentType.toUpperCase()),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
