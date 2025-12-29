import 'package:cloud_firestore/cloud_firestore.dart';

class OperatingPayment {
  final String id;
  final String driverId;
  final String driverName;
  final String paymentType; // 'fuel', 'maintenance', 'salary'
  final double amount;
  final String currency; // 'USD' or 'LBP'
  final DateTime timestamp;
  final String adminId;
  final String? notes;
  final String? receiptUrl;

  OperatingPayment({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.paymentType,
    required this.amount,
    required this.currency,
    required this.timestamp,
    required this.adminId,
    this.notes,
    this.receiptUrl,
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'paymentType': paymentType,
      'amount': amount,
      'currency': currency,
      'timestamp': Timestamp.fromDate(timestamp),
      'adminId': adminId,
      'notes': notes,
      'receiptUrl': receiptUrl,
    };
  }

  // Create from Firestore document
  factory OperatingPayment.fromMap(String id, Map<String, dynamic> map) {
    return OperatingPayment(
      id: id,
      driverId: map['driverId'] ?? '',
      driverName: map['driverName'] ?? '',
      paymentType: map['paymentType'] ?? 'fuel',
      amount: (map['amount'] ?? 0).toDouble(),
      currency: (map['currency'] as String?) ?? 'USD',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminId: map['adminId'] ?? '',
      notes: map['notes'],
      receiptUrl: map['receiptUrl'],
    );
  }

  // Format display
  String get formattedAmount =>
      '${currency == 'USD' ? '\$' : '₾'}${amount.toStringAsFixed(0)}';

  String get formattedDate {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String get paymentTypeLabel {
    switch (paymentType) {
      case 'fuel':
        return 'Fuel';
      case 'maintenance':
        return 'Maintenance';
      case 'salary':
        return 'Salary';
      default:
        return paymentType;
    }
  }
}
