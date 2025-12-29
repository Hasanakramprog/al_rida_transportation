import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/driver_payment_transaction.dart';

class DriverPaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _transactionsCollection = 'driver_payment_transactions';
  static const int pageSize = 15; // Load 15 transactions per page

  // Add a new driver payment transaction
  Future<void> addDriverPaymentTransaction({
    required String driverId,
    required String driverName,
    required String studentId,
    required String studentName,
    required double amount,
    required String currency,
    String? notes,
  }) async {
    try {
      await _firestore.collection(_transactionsCollection).add({
        'driverId': driverId,
        'driverName': driverName,
        'studentId': studentId,
        'studentName': studentName,
        'amount': amount,
        'currency': currency,
        'timestamp': FieldValue.serverTimestamp(),
        'notes': notes,
      });
    } catch (e) {
      throw Exception('Failed to add driver payment transaction: $e');
    }
  }

  // Get all transactions for a specific driver
  Future<List<DriverPaymentTransaction>> getDriverTransactions(
    String driverId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_transactionsCollection)
          .where('driverId', isEqualTo: driverId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DriverPaymentTransaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get driver transactions: $e');
    }
  }

  // Get paginated transactions for a specific driver
  Future<List<DriverPaymentTransaction>> getPaginatedDriverTransactions({
    required String driverId,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection(_transactionsCollection)
          .where('driverId', isEqualTo: driverId)
          .orderBy('timestamp', descending: true)
          .limit(pageSize);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => DriverPaymentTransaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get paginated driver transactions: $e');
    }
  }

  // Get document snapshot by transaction ID
  Future<DocumentSnapshot?> getDocumentSnapshot(String transactionId) async {
    try {
      final doc = await _firestore
          .collection(_transactionsCollection)
          .doc(transactionId)
          .get();
      return doc.exists ? doc : null;
    } catch (e) {
      throw Exception('Failed to get document snapshot: $e');
    }
  }

  // Watch driver transactions in real-time
  Stream<List<DriverPaymentTransaction>> watchDriverTransactions(
    String driverId,
  ) {
    return _firestore
        .collection(_transactionsCollection)
        .where('driverId', isEqualTo: driverId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DriverPaymentTransaction.fromFirestore(doc))
              .toList(),
        );
  }

  // Get transactions by currency
  Future<List<DriverPaymentTransaction>> getDriverTransactionsByCurrency(
    String driverId,
    String currency,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_transactionsCollection)
          .where('driverId', isEqualTo: driverId)
          .where('currency', isEqualTo: currency)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DriverPaymentTransaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get driver transactions by currency: $e');
    }
  }

  // Get transactions for a date range
  Future<List<DriverPaymentTransaction>> getDriverTransactionsByDateRange(
    String driverId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_transactionsCollection)
          .where('driverId', isEqualTo: driverId)
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DriverPaymentTransaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get driver transactions by date range: $e');
    }
  }

  // Calculate total for driver by currency
  Future<double> calculateDriverTotal(String driverId, String currency) async {
    try {
      final transactions = await getDriverTransactionsByCurrency(
        driverId,
        currency,
      );
      return transactions.fold<double>(
        0.0,
        (sum, transaction) => sum + transaction.amount,
      );
    } catch (e) {
      throw Exception('Failed to calculate driver total: $e');
    }
  }
}
