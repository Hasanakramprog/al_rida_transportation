import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/operating_payment.dart';
import 'accounting_service.dart';
import 'driver_wallet_service.dart';

class OperatingPaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AccountingService _accountingService = AccountingService();
  final DriverWalletService _driverWalletService = DriverWalletService();
  
  static const String _paymentsCollection = 'operating_payments';

  // Add operating payment and decrement from admin wallet, increment driver wallet
  Future<void> addOperatingPayment({
    required String driverId,
    required String driverName,
    required String paymentType, // 'fuel', 'maintenance', 'salary'
    required double amount,
    required String currency, // 'USD' or 'LBP'
    required String adminId,
    String? notes,
  }) async {
    try {
      // Add payment record
      await _firestore.collection(_paymentsCollection).add({
        'driverId': driverId,
        'driverName': driverName,
        'paymentType': paymentType,
        'amount': amount,
        'currency': currency,
        'timestamp': FieldValue.serverTimestamp(),
        'adminId': adminId,
        'notes': notes,
      });

      // Decrement from admin wallet
      await _accountingService.subtractFromAdminWallet(amount, currency);
      
      // Increment driver wallet
      await _driverWalletService.addToDriverWallet(driverId, amount, currency);
    } catch (e) {
      throw Exception('Failed to add operating payment: $e');
    }
  }

  // Get all operating payments
  Future<List<OperatingPayment>> getAllPayments({int limit = 100}) async {
    try {
      final snapshot = await _firestore
          .collection(_paymentsCollection)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => OperatingPayment.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get operating payments: $e');
    }
  }

  // Get payments by driver
  Future<List<OperatingPayment>> getPaymentsByDriver(String driverId) async {
    try {
      final snapshot = await _firestore
          .collection(_paymentsCollection)
          .where('driverId', isEqualTo: driverId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => OperatingPayment.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get driver payments: $e');
    }
  }

  // Get payments by type
  Future<List<OperatingPayment>> getPaymentsByType(String paymentType) async {
    try {
      final snapshot = await _firestore
          .collection(_paymentsCollection)
          .where('paymentType', isEqualTo: paymentType)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => OperatingPayment.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get payments by type: $e');
    }
  }

  // Get recent payments
  Future<List<OperatingPayment>> getRecentPayments({int limit = 5}) async {
    try {
      final snapshot = await _firestore
          .collection(_paymentsCollection)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => OperatingPayment.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get recent payments: $e');
    }
  }

  // Get operating payments summary
  Future<Map<String, dynamic>> getOperatingPaymentsSummary() async {
    try {
      final snapshot = await _firestore.collection(_paymentsCollection).get();
      final payments = snapshot.docs
          .map((doc) => OperatingPayment.fromMap(doc.id, doc.data()))
          .toList();

      double totalUSD = 0;
      double totalLBP = 0;
      int fuelCount = 0;
      int maintenanceCount = 0;
      int salaryCount = 0;

      for (final payment in payments) {
        if (payment.currency == 'USD') {
          totalUSD += payment.amount;
        } else {
          totalLBP += payment.amount;
        }

        switch (payment.paymentType) {
          case 'fuel':
            fuelCount++;
            break;
          case 'maintenance':
            maintenanceCount++;
            break;
          case 'salary':
            salaryCount++;
            break;
        }
      }

      return {
        'totalUSD': totalUSD,
        'totalLBP': totalLBP,
        'fuelCount': fuelCount,
        'maintenanceCount': maintenanceCount,
        'salaryCount': salaryCount,
        'totalPayments': payments.length,
      };
    } catch (e) {
      throw Exception('Failed to get operating payments summary: $e');
    }
  }
}
