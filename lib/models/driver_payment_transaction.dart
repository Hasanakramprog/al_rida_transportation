import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DriverPaymentTransaction {
  final String id;
  final String driverId;
  final String driverName;
  final String studentId;
  final String studentName;
  final double amount;
  final String currency; // 'USD' or 'LBP'
  final DateTime timestamp;
  final String? notes;

  DriverPaymentTransaction({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.studentId,
    required this.studentName,
    required this.amount,
    required this.currency,
    required this.timestamp,
    this.notes,
  });

  // Create from Firestore document
  factory DriverPaymentTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DriverPaymentTransaction(
      id: doc.id,
      driverId: data['driverId'] ?? '',
      driverName: data['driverName'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      currency: (data['currency'] as String?) ?? 'USD',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: data['notes'] as String?,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'studentId': studentId,
      'studentName': studentName,
      'amount': amount,
      'currency': currency,
      'timestamp': Timestamp.fromDate(timestamp),
      'notes': notes,
    };
  }

  // Formatted amount with currency symbol
  String get formattedAmount {
    final symbol = currency == 'USD' ? '\$' : 'LL';
    return '$symbol${NumberFormat('#,###.##').format(amount)}';
  }

  // Formatted date
  String get formattedDate {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  // Formatted time
  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
