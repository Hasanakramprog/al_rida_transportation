import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_profile.dart';

enum TimeSlot { onepm, twopm, threepm }

extension TimeSlotExtension on TimeSlot {
  String get displayName {
    switch (this) {
      case TimeSlot.onepm:
        return '1:00 PM';
      case TimeSlot.twopm:
        return '2:00 PM';
      case TimeSlot.threepm:
        return '3:00 PM';
    }
  }

  String get value {
    switch (this) {
      case TimeSlot.onepm:
        return '1pm';
      case TimeSlot.twopm:
        return '2pm';
      case TimeSlot.threepm:
        return '3pm';
    }
  }

  static TimeSlot fromString(String value) {
    switch (value) {
      case '1pm':
        return TimeSlot.onepm;
      case '2pm':
        return TimeSlot.twopm;
      case '3pm':
        return TimeSlot.threepm;
      default:
        throw ArgumentError('Invalid time slot: $value');
    }
  }
}

class BusBooking {
  final String id;
  final String studentUid;
  final String studentName;
  final String phoneNumber;
  final String university;
  final String scheduleSuffixCode;
  final String cityName;
  final String zone;
  final SubscriptionType subscriptionType;
  final List<String> selectedDays; // ['Monday', 'Tuesday', etc.]
  final TimeSlot timeSlot;
  final double totalCost;
  final double paymentAmount;
  final bool isPaid;
  final DateTime createdAt;
  final DateTime? paidAt;

  BusBooking({
    required this.id,
    required this.studentUid,
    required this.studentName,
    required this.phoneNumber,
    required this.university,
    required this.scheduleSuffixCode,
    required this.cityName,
    required this.zone,
    required this.subscriptionType,
    required this.selectedDays,
    required this.timeSlot,
    required this.totalCost,
    this.paymentAmount = 0.0,
    this.isPaid = false,
    required this.createdAt,
    this.paidAt,
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'studentUid': studentUid,
      'studentName': studentName,
      'phoneNumber': phoneNumber,
      'university': university,
      'scheduleSuffixCode': scheduleSuffixCode,
      'cityName': cityName,
      'zone': zone,
      'subscriptionType': subscriptionType.name,
      'selectedDays': selectedDays,
      'timeSlot': timeSlot.value,
      'totalCost': totalCost,
      'paymentAmount': paymentAmount,
      'isPaid': isPaid,
      'createdAt': Timestamp.fromDate(createdAt),
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
    };
  }

  // Create from Firestore document
  factory BusBooking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BusBooking(
      id: doc.id,
      studentUid: data['studentUid'] ?? '',
      studentName: data['studentName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      university: data['university'] ?? '',
      scheduleSuffixCode: data['scheduleSuffixCode'] ?? '',
      cityName: data['cityName'] ?? '',
      zone: data['zone'] ?? '',
      subscriptionType: SubscriptionType.values.firstWhere(
        (e) => e.name == data['subscriptionType'],
        orElse: () => SubscriptionType.monthly,
      ),
      selectedDays: List<String>.from(data['selectedDays'] ?? []),
      timeSlot: TimeSlotExtension.fromString(data['timeSlot'] ?? '1pm'),
      totalCost: (data['totalCost'] ?? 0.0).toDouble(),
      paymentAmount: (data['paymentAmount'] ?? 0.0).toDouble(),
      isPaid: data['isPaid'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
    );
  }

  BusBooking copyWith({
    String? id,
    String? studentUid,
    String? studentName,
    String? phoneNumber,
    String? university,
    String? scheduleSuffixCode,
    String? cityName,
    String? zone,
    SubscriptionType? subscriptionType,
    List<String>? selectedDays,
    TimeSlot? timeSlot,
    double? totalCost,
    double? paymentAmount,
    bool? isPaid,
    DateTime? createdAt,
    DateTime? paidAt,
  }) {
    return BusBooking(
      id: id ?? this.id,
      studentUid: studentUid ?? this.studentUid,
      studentName: studentName ?? this.studentName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      university: university ?? this.university,
      scheduleSuffixCode: scheduleSuffixCode ?? this.scheduleSuffixCode,
      cityName: cityName ?? this.cityName,
      zone: zone ?? this.zone,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      selectedDays: selectedDays ?? this.selectedDays,
      timeSlot: timeSlot ?? this.timeSlot,
      totalCost: totalCost ?? this.totalCost,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      isPaid: isPaid ?? this.isPaid,
      createdAt: createdAt ?? this.createdAt,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  String get paymentStatus {
    if (isPaid) return 'Paid';
    if (paymentAmount > 0) return 'Partial Payment';
    return 'Unpaid';
  }

  String get selectedDaysDisplay {
    return selectedDays.join(', ');
  }
}
