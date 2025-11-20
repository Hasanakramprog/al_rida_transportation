import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/monthly_payment.dart';
import 'accounting_service.dart';

class MonthlyPaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AccountingService _accountingService = AccountingService();
  
  static const String _paymentsCollection = 'monthly_payments';

  // ADMIN ONLY: Create payment records for a student for entire year
  Future<void> createYearlyPaymentRecords(String studentUid, double monthlyAmount, int year) async {
    try {
      final batch = _firestore.batch();
      
      for (int month = 1; month <= 12; month++) {
        final paymentId = '${studentUid}_${year}_$month';
        final docRef = _firestore.collection(_paymentsCollection).doc(paymentId);
        
        final payment = MonthlyPayment(
          id: paymentId,
          studentUid: studentUid,
          year: year,
          month: month,
          monthlyAmount: monthlyAmount,
          isPaid: false,
          createdAt: DateTime.now(),
        );
        
        batch.set(docRef, payment.toMap());
      }
      
      await batch.commit();
    } catch (e) {
      throw 'Error creating yearly payment records: $e';
    }
  }

  // ADMIN ONLY: Process payment (partial or full)
  Future<void> processPayment({
    required String studentUid,
    required int year,
    required int month,
    required String adminUid,
    required double paymentAmount,
    String? studentName,
  }) async {
    try {
      final paymentId = '${studentUid}_${year}_$month';
      final docRef = _firestore.collection(_paymentsCollection).doc(paymentId);
      
      // Get current payment record
      final doc = await docRef.get();
      if (!doc.exists) {
        throw 'Payment record not found';
      }
      
      final currentPayment = MonthlyPayment.fromFirestore(doc);
      final newPaidAmount = currentPayment.paidAmount + paymentAmount;
      final newRemainingAmount = currentPayment.monthlyAmount - newPaidAmount;
      final isFullyPaid = newRemainingAmount <= 0;
      
      // Update payment record
      await docRef.update({
        'paidAmount': newPaidAmount,
        'remainingAmount': newRemainingAmount >= 0 ? newRemainingAmount : 0,
        'isPaid': isFullyPaid,
        'paidAt': isFullyPaid ? Timestamp.fromDate(DateTime.now()) : currentPayment.paidAt,
        'paidBy': adminUid,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Create accounting transaction
      // Determine payment type based on whether this completes the payment
      String paymentType = isFullyPaid ? 'full' : 'partial';
      
      await _accountingService.addTransaction(
        studentId: studentUid,
        studentName: studentName ?? 'Unknown Student',
        amount: paymentAmount,
        paymentType: paymentType,
        subscriptionMonth: month,
        subscriptionYear: year,
        adminId: adminUid,
        currency: 'USD', // TODO: Get from student profile or payment settings
        notes: isFullyPaid 
            ? 'Full payment completed' 
            : 'Partial payment (\$${newPaidAmount.toStringAsFixed(0)} of \$${currentPayment.monthlyAmount.toStringAsFixed(0)})',
      );
    } catch (e) {
      throw 'Error processing payment: $e';
    }
  }

  // ADMIN ONLY: Mark payment as fully paid
  Future<void> markPaymentAsPaid({
    required String studentUid,
    required int year,
    required int month,
    required String adminUid,
    String? studentName,
  }) async {
    try {
      final paymentId = '${studentUid}_${year}_$month';
      final docRef = _firestore.collection(_paymentsCollection).doc(paymentId);
      
      // Get current payment record
      final doc = await docRef.get();
      if (!doc.exists) {
        throw 'Payment record not found';
      }
      
      final currentPayment = MonthlyPayment.fromFirestore(doc);
      final remainingAmount = currentPayment.remainingAmount;
      
      // Update payment record
      await docRef.update({
        'paidAmount': currentPayment.monthlyAmount,
        'remainingAmount': 0,
        'isPaid': true,
        'paidAt': Timestamp.fromDate(DateTime.now()),
        'paidBy': adminUid,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Create accounting transaction only for the remaining amount
      // This prevents double-counting if partial payments were already made
      if (remainingAmount > 0) {
        await _accountingService.addTransaction(
          studentId: studentUid,
          studentName: studentName ?? 'Unknown Student',
          amount: remainingAmount,
          paymentType: 'full',
          subscriptionMonth: month,
          subscriptionYear: year,
          adminId: adminUid,
          currency: 'USD', // TODO: Get from student profile or payment settings
          notes: 'Full payment marked as paid',
        );
      }
    } catch (e) {
      throw 'Error marking payment as paid: $e';
    }
  }

  // Get payment status for a specific student and month
  Future<MonthlyPayment?> getPaymentStatus({
    required String studentUid,
    required int year,
    required int month,
  }) async {
    try {
      final paymentId = '${studentUid}_${year}_$month';
      final doc = await _firestore.collection(_paymentsCollection).doc(paymentId).get();
      
      if (doc.exists) {
        return MonthlyPayment.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw 'Error getting payment status: $e';
    }
  }

  // ADMIN ONLY: Get all payments for a specific month/year
  Future<List<MonthlyPayment>> getPaymentsForMonth(int year, int month) async {
    try {
      final snapshot = await _firestore
          .collection(_paymentsCollection)
          .where('year', isEqualTo: year)
          .where('month', isEqualTo: month)
          .orderBy('studentUid')
          .get();
      
      return snapshot.docs
          .map((doc) => MonthlyPayment.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Error getting payments for month: $e';
    }
  }

  // ADMIN ONLY: Get all payments for a student
  Future<List<MonthlyPayment>> getStudentPayments(String studentUid, {int? year}) async {
    try {
      Query query = _firestore
          .collection(_paymentsCollection)
          .where('studentUid', isEqualTo: studentUid);
      
      if (year != null) {
        query = query.where('year', isEqualTo: year);
      }
      
      final snapshot = await query.orderBy('year').orderBy('month').get();
      
      return snapshot.docs
          .map((doc) => MonthlyPayment.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Error getting student payments: $e';
    }
  }

  // Get payment status for current month
  Future<MonthlyPayment?> getCurrentMonthPayment(String studentUid) async {
    try {
      final now = DateTime.now();
      final paymentId = '${studentUid}_${now.year}_${now.month}';
      
      final doc = await _firestore
          .collection(_paymentsCollection)
          .doc(paymentId)
          .get();
      
      if (doc.exists) {
        return MonthlyPayment.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw 'Error getting current month payment: $e';
    }
  }

  // Student view: Get their payment history
  Future<List<MonthlyPayment>> getMyPaymentHistory(String studentUid, {int limit = 12}) async {
    try {
      final snapshot = await _firestore
          .collection(_paymentsCollection)
          .where('studentUid', isEqualTo: studentUid)
          .orderBy('year', descending: true)
          .orderBy('month', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => MonthlyPayment.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Error getting payment history: $e';
    }
  }

  // ADMIN ONLY: Update monthly amount for all future payments of a student
  Future<void> updateFuturePaymentAmounts(String studentUid, double newMonthlyAmount) async {
    try {
      final now = DateTime.now();
      final batch = _firestore.batch();
      
      // Update current month and future months
      for (int month = now.month; month <= 12; month++) {
        final paymentId = '${studentUid}_${now.year}_$month';
        final docRef = _firestore.collection(_paymentsCollection).doc(paymentId);
        
        batch.update(docRef, {
          'monthlyAmount': newMonthlyAmount,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
      
      await batch.commit();
    } catch (e) {
      throw 'Error updating future payment amounts: $e';
    }
  }

  // ADMIN ONLY: Get unpaid payments summary
  Future<Map<String, dynamic>> getUnpaidPaymentsSummary() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection(_paymentsCollection)
          .where('isPaid', isEqualTo: false)
          .where('year', isEqualTo: now.year)
          .where('month', isLessThanOrEqualTo: now.month)
          .get();
      
      double totalUnpaid = 0;
      int unpaidCount = 0;
      
      for (final doc in snapshot.docs) {
        final payment = MonthlyPayment.fromFirestore(doc);
        totalUnpaid += payment.monthlyAmount;
        unpaidCount++;
      }
      
      return {
        'totalUnpaid': totalUnpaid,
        'unpaidCount': unpaidCount,
        'payments': snapshot.docs
            .map((doc) => MonthlyPayment.fromFirestore(doc))
            .toList(),
      };
    } catch (e) {
      throw 'Error getting unpaid payments summary: $e';
    }
  }
}
