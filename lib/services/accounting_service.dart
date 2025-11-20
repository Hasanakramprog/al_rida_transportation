import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_transaction.dart';
import '../models/admin_wallet.dart';

class AccountingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int pageSize = 15; // Load 15 transactions per page

  // Add a new payment transaction
  Future<void> addTransaction({
    required String studentId,
    required String studentName,
    required double amount,
    required String paymentType,
    required int subscriptionMonth,
    required int subscriptionYear,
    required String adminId,
    required String currency, // 'USD' or 'LBP'
    String? notes,
  }) async {
    try {
      await _firestore.collection('payment_transactions').add({
        'studentId': studentId,
        'studentName': studentName,
        'amount': amount,
        'paymentType': paymentType,
        'currency': currency,
        'timestamp': FieldValue.serverTimestamp(),
        'subscriptionMonth': subscriptionMonth,
        'subscriptionYear': subscriptionYear,
        'adminId': adminId,
        'notes': notes,
      });
      
      // Add payment amount to admin wallet
      await addToAdminWallet(amount, currency);
    } catch (e) {
      throw Exception('Failed to add transaction: $e');
    }
  }

  // Add payment amount to admin wallet
  Future<void> addToAdminWallet(double amount, String currency) async {
    try {
      final docRef = _firestore.collection('admin_wallet').doc('main');
      
      if (currency == 'USD') {
        await docRef.set({
          'totalBalanceUSD': FieldValue.increment(amount),
          'totalTransactionsUSD': FieldValue.increment(1),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else if (currency == 'LBP') {
        await docRef.set({
          'totalBalanceLBP': FieldValue.increment(amount),
          'totalTransactionsLBP': FieldValue.increment(1),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        throw Exception('Invalid currency: $currency');
      }
    } catch (e) {
      throw Exception('Failed to add amount to admin wallet: $e');
    }
  }

  // Get admin wallet balance
  Future<AdminWallet?> getAdminWallet() async {
    try {
      final doc = await _firestore.collection('admin_wallet').doc('main').get();
      
      if (!doc.exists) {
        return null;
      }
      
      return AdminWallet.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get admin wallet: $e');
    }
  }

  // Stream admin wallet updates (real-time)
  Stream<AdminWallet?> watchAdminWallet() {
    return _firestore.collection('admin_wallet').doc('main').snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }
      return AdminWallet.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    });
  }

  // Subtract from admin wallet (for refunds or operating payments)
  Future<void> subtractFromAdminWallet(double amount, String currency) async {
    try {
      final docRef = _firestore.collection('admin_wallet').doc('main');
      
      if (currency == 'USD') {
        await docRef.update({
          'totalBalanceUSD': FieldValue.increment(-amount),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else if (currency == 'LBP') {
        await docRef.update({
          'totalBalanceLBP': FieldValue.increment(-amount),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        throw Exception('Invalid currency: $currency');
      }
    } catch (e) {
      throw Exception('Failed to subtract from admin wallet: $e');
    }
  }

  // Get recent transactions with limit (for dashboard)
  Future<List<PaymentTransaction>> getRecentTransactions({int limit = 5}) async {
    try {
      final snapshot = await _firestore
          .collection('payment_transactions')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => PaymentTransaction.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get recent transactions: $e');
    }
  }

  // Get paginated transactions
  Future<List<PaymentTransaction>> getPaginatedTransactions({
    DocumentSnapshot? lastDocument,
    int limit = pageSize,
  }) async {
    try {
      Query query = _firestore
          .collection('payment_transactions')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => PaymentTransaction.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get paginated transactions: $e');
    }
  }

  // Get paginated transactions by date range
  Future<List<PaymentTransaction>> getPaginatedTransactionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    DocumentSnapshot? lastDocument,
    int limit = pageSize,
  }) async {
    try {
      Query query = _firestore
          .collection('payment_transactions')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => PaymentTransaction.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get paginated transactions by date range: $e');
    }
  }

  // Get document snapshot from transaction (for pagination cursor)
  Future<DocumentSnapshot?> getDocumentSnapshot(String transactionId) async {
    try {
      return await _firestore.collection('payment_transactions').doc(transactionId).get();
    } catch (e) {
      return null;
    }
  }

  // Get all transactions (kept for backward compatibility, but not recommended for large datasets)
  Stream<List<PaymentTransaction>> getAllTransactions() {
    return _firestore
        .collection('payment_transactions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PaymentTransaction.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Get all transactions as Future (one-time read, use with caution for large datasets)
  Future<List<PaymentTransaction>> getAllTransactionsOnce({int? limit}) async {
    try {
      Query query = _firestore
          .collection('payment_transactions')
          .orderBy('timestamp', descending: true);
      
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => PaymentTransaction.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all transactions: $e');
    }
  }

  // Get transactions filtered by date range (one-time read)
  Future<List<PaymentTransaction>> getTransactionsByDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _firestore
          .collection('payment_transactions')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => PaymentTransaction.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get transactions by date range: $e');
    }
  }

  // Get transactions for today (one-time read)
  Future<List<PaymentTransaction>> getTodayTransactions() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return getTransactionsByDateRange(startOfDay, endOfDay);
  }

  // Get transactions for current month (one-time read)
  Future<List<PaymentTransaction>> getMonthTransactions(int year, int month) async {
    final startOfMonth = DateTime(year, month, 1, 0, 0, 0);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);
    return getTransactionsByDateRange(startOfMonth, endOfMonth);
  }

  // Get transactions for current year (one-time read)
  Future<List<PaymentTransaction>> getYearTransactions(int year) async {
    final startOfYear = DateTime(year, 1, 1, 0, 0, 0);
    final endOfYear = DateTime(year, 12, 31, 23, 59, 59);
    return getTransactionsByDateRange(startOfYear, endOfYear);
  }

  // Calculate total balance from admin wallet for USD (not from transactions)
  Future<double> calculateBalanceUSD() async {
    try {
      final wallet = await getAdminWallet();
      return wallet?.totalBalanceUSD ?? 0.0;
    } catch (e) {
      throw Exception('Failed to calculate USD balance: $e');
    }
  }

  // Calculate total balance from admin wallet for LBP (not from transactions)
  Future<double> calculateBalanceLBP() async {
    try {
      final wallet = await getAdminWallet();
      return wallet?.totalBalanceLBP ?? 0.0;
    } catch (e) {
      throw Exception('Failed to calculate LBP balance: $e');
    }
  }

  // Calculate total balance for a specific currency
  Future<double> calculateBalance(String currency) async {
    if (currency == 'USD') {
      return calculateBalanceUSD();
    } else if (currency == 'LBP') {
      return calculateBalanceLBP();
    } else {
      throw Exception('Invalid currency: $currency');
    }
  }

  // Get transaction count
  int getTransactionCount(List<PaymentTransaction> transactions) {
    return transactions.length;
  }

  // Get transactions by student (one-time read)
  Future<List<PaymentTransaction>> getTransactionsByStudent(String studentId) async {
    try {
      final snapshot = await _firestore
          .collection('payment_transactions')
          .where('studentId', isEqualTo: studentId)
          .orderBy('timestamp', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => PaymentTransaction.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get transactions by student: $e');
    }
  }

  // Get payment statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      // Get admin wallet data
      final wallet = await getAdminWallet();
      final totalBalanceUSD = wallet?.totalBalanceUSD ?? 0.0;
      final totalBalanceLBP = wallet?.totalBalanceLBP ?? 0.0;
      final totalTransactionsUSD = wallet?.totalTransactionsUSD ?? 0;
      final totalTransactionsLBP = wallet?.totalTransactionsLBP ?? 0;
      final averagePaymentUSD = totalTransactionsUSD > 0 ? totalBalanceUSD / totalTransactionsUSD : 0.0;
      final averagePaymentLBP = totalTransactionsLBP > 0 ? totalBalanceLBP / totalTransactionsLBP : 0.0;

      // Get today's transactions for stats
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final todaySnapshot = await _firestore
          .collection('payment_transactions')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();
      final todayTransactions = todaySnapshot.docs
          .map((doc) => PaymentTransaction.fromMap(doc.id, doc.data()))
          .toList();
      final todayBalanceUSD = todayTransactions
          .where((t) => t.currency == 'USD')
          .fold(0.0, (sum, t) => sum + t.amount);
      final todayBalanceLBP = todayTransactions
          .where((t) => t.currency == 'LBP')
          .fold(0.0, (sum, t) => sum + t.amount);

      // Get month's transactions for stats
      final startOfMonth = DateTime(now.year, now.month, 1, 0, 0, 0);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final monthSnapshot = await _firestore
          .collection('payment_transactions')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();
      final monthTransactions = monthSnapshot.docs
          .map((doc) => PaymentTransaction.fromMap(doc.id, doc.data()))
          .toList();
      final monthBalanceUSD = monthTransactions
          .where((t) => t.currency == 'USD')
          .fold(0.0, (sum, t) => sum + t.amount);
      final monthBalanceLBP = monthTransactions
          .where((t) => t.currency == 'LBP')
          .fold(0.0, (sum, t) => sum + t.amount);

      return {
        'totalBalanceUSD': totalBalanceUSD,
        'totalBalanceLBP': totalBalanceLBP,
        'totalTransactionsUSD': totalTransactionsUSD,
        'totalTransactionsLBP': totalTransactionsLBP,
        'averagePaymentUSD': averagePaymentUSD,
        'averagePaymentLBP': averagePaymentLBP,
        'todayBalanceUSD': todayBalanceUSD,
        'todayBalanceLBP': todayBalanceLBP,
        'todayCountUSD': todayTransactions.where((t) => t.currency == 'USD').length,
        'todayCountLBP': todayTransactions.where((t) => t.currency == 'LBP').length,
        'monthBalanceUSD': monthBalanceUSD,
        'monthBalanceLBP': monthBalanceLBP,
        'monthCountUSD': monthTransactions.where((t) => t.currency == 'USD').length,
        'monthCountLBP': monthTransactions.where((t) => t.currency == 'LBP').length,
      };
    } catch (e) {
      throw Exception('Failed to get statistics: $e');
    }
  }
}
