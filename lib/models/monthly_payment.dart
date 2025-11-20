import 'package:cloud_firestore/cloud_firestore.dart';

class MonthlyPayment {
  final String id; // Document ID
  final String studentUid; // Reference to student
  final int year;
  final int month;
  final double monthlyAmount; // Total cost for this month
  final double paidAmount; // Amount already paid
  final double remainingAmount; // Amount still owed (monthlyAmount - paidAmount)
  final bool isPaid; // True when remainingAmount is 0
  final DateTime? paidAt;
  final String? paidBy; // Admin who processed the payment
  final DateTime createdAt;
  final DateTime? updatedAt;

  MonthlyPayment({
    required this.id,
    required this.studentUid,
    required this.year,
    required this.month,
    required this.monthlyAmount,
    this.paidAmount = 0.0,
    double? remainingAmount,
    this.isPaid = false,
    this.paidAt,
    this.paidBy,
    required this.createdAt,
    this.updatedAt,
  }) : remainingAmount = remainingAmount ?? monthlyAmount;

  String get monthName {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String get displayText => '$monthName $year';

  // Helper getters for payment status
  bool get isFullyPaid => remainingAmount <= 0;
  bool get isPartiallyPaid => paidAmount > 0 && remainingAmount > 0;
  bool get isUnpaid => paidAmount <= 0;
  
  // Payment status text
  String get paymentStatus {
    if (isFullyPaid) return 'Fully Paid';
    if (isPartiallyPaid) return 'Partially Paid';
    return 'Unpaid';
  }
  
  // Percentage paid
  double get paymentPercentage {
    if (monthlyAmount <= 0) return 0.0;
    return (paidAmount / monthlyAmount) * 100;
  }

  Map<String, dynamic> toMap() {
    return {
      'studentUid': studentUid,
      'year': year,
      'month': month,
      'monthlyAmount': monthlyAmount,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'isPaid': isPaid,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'paidBy': paidBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory MonthlyPayment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final monthlyAmount = (data['monthlyAmount'] ?? 0.0).toDouble();
    final paidAmount = (data['paidAmount'] ?? 0.0).toDouble();
    
    return MonthlyPayment(
      id: doc.id,
      studentUid: data['studentUid'] ?? '',
      year: data['year'] ?? 0,
      month: data['month'] ?? 0,
      monthlyAmount: monthlyAmount,
      paidAmount: paidAmount,
      remainingAmount: (data['remainingAmount'] ?? monthlyAmount).toDouble(),
      isPaid: data['isPaid'] ?? false,
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
      paidBy: data['paidBy'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  MonthlyPayment copyWith({
    String? id,
    String? studentUid,
    int? year,
    int? month,
    double? monthlyAmount,
    double? paidAmount,
    double? remainingAmount,
    bool? isPaid,
    DateTime? paidAt,
    String? paidBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MonthlyPayment(
      id: id ?? this.id,
      studentUid: studentUid ?? this.studentUid,
      year: year ?? this.year,
      month: month ?? this.month,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt ?? this.paidAt,
      paidBy: paidBy ?? this.paidBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
