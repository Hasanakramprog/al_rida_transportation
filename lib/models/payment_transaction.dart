import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PaymentTransaction {
  final String id;
  final String studentId;
  final String studentName;
  final double amount;
  final String paymentType; // 'partial' or 'full'
  final String currency; // 'USD' or 'LBP'
  final DateTime timestamp;
  final int subscriptionMonth;
  final int subscriptionYear;
  final String adminId;
  final String? notes;

  PaymentTransaction({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.amount,
    required this.paymentType,
    required this.currency,
    required this.timestamp,
    required this.subscriptionMonth,
    required this.subscriptionYear,
    required this.adminId,
    this.notes,
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'amount': amount,
      'paymentType': paymentType,
      'currency': currency,
      'timestamp': Timestamp.fromDate(timestamp),
      'subscriptionMonth': subscriptionMonth,
      'subscriptionYear': subscriptionYear,
      'adminId': adminId,
      'notes': notes,
    };
  }

  // Create from Firestore document
  factory PaymentTransaction.fromMap(String id, Map<String, dynamic> map) {
    return PaymentTransaction(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      paymentType: map['paymentType'] ?? 'full',
      currency: (map['currency'] as String?) ?? 'USD',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      subscriptionMonth: map['subscriptionMonth'] ?? 0,
      subscriptionYear: map['subscriptionYear'] ?? 0,
      adminId: map['adminId'] ?? '',
      notes: map['notes'],
    );
  }

  // Format display
  String get formattedAmount => '${currency == 'USD' ? '\$' : 'LL'}${NumberFormat('#,###').format(amount.toInt())}';
  
  String get formattedDate {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String get subscriptionPeriod => '$subscriptionMonth/$subscriptionYear';
}

