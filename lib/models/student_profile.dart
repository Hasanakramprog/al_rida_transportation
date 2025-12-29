import 'package:cloud_firestore/cloud_firestore.dart';
import 'bus_booking.dart';

class PaymentHistory {
  final int year;
  final int month;
  final double amount;
  final DateTime paidAt;
  final bool isPaid;

  PaymentHistory({
    required this.year,
    required this.month,
    required this.amount,
    required this.paidAt,
    required this.isPaid,
  });

  String get monthName {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  Map<String, dynamic> toMap() {
    return {
      'year': year,
      'month': month,
      'amount': amount,
      'paidAt': Timestamp.fromDate(paidAt),
      'isPaid': isPaid,
    };
  }

  factory PaymentHistory.fromMap(Map<String, dynamic> map) {
    return PaymentHistory(
      year: map['year'] ?? 0,
      month: map['month'] ?? 0,
      amount: (map['amount'] ?? 0.0).toDouble(),
      paidAt: (map['paidAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPaid: map['isPaid'] ?? false,
    );
  }
}

enum SubscriptionType {
  monthly,
  daily;

  String get displayName {
    switch (this) {
      case SubscriptionType.monthly:
        return 'Monthly';
      case SubscriptionType.daily:
        return 'Daily';
    }
  }

  static SubscriptionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'monthly':
        return SubscriptionType.monthly;
      case 'daily':
        return SubscriptionType.daily;
      default:
        return SubscriptionType.monthly;
    }
  }
}

class SubscriptionPricing {
  // Calculate cost description using the suffix's stored cost
  static String getCostDescription({
    required SubscriptionType subscriptionType,
    required ScheduleSuffix scheduleSuffix,
  }) {
    if (subscriptionType == SubscriptionType.daily) {
      return '\$${scheduleSuffix.dailyCost.toStringAsFixed(2)} per day';
    } else {
      return '\$${scheduleSuffix.monthlyCost.toStringAsFixed(2)} per month';
    }
  }

  // Get actual cost value
  static double getCost({
    required SubscriptionType subscriptionType,
    required ScheduleSuffix scheduleSuffix,
  }) {
    if (subscriptionType == SubscriptionType.daily) {
      return scheduleSuffix.dailyCost;
    } else {
      return scheduleSuffix.monthlyCost;
    }
  }
}

class ScheduleSuffix {
  final String id; // Document ID in Firestore
  final String code; // e.g., "A1", "B2", "C3"
  final String zone; // A, B, C, or D
  final int daysPerWeek; // 1, 2, 3, 4, or 5
  final double dailyCost; // Cost per day for this suffix
  final double monthlyCost; // Cost per month for this suffix
  final String description; // Description of the schedule

  ScheduleSuffix({
    required this.id,
    required this.code,
    required this.zone,
    required this.daysPerWeek,
    required this.dailyCost,
    required this.monthlyCost,
    required this.description,
  });

  String get displayName =>
      '$code ($daysPerWeek ${daysPerWeek == 1 ? 'day' : 'days'} per week) - $description';

  // Create from Firestore document
  factory ScheduleSuffix.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ScheduleSuffix(
      id: doc.id,
      code: data['code'] ?? '',
      zone: data['zone'] ?? '',
      daysPerWeek: data['daysPerWeek'] ?? 1,
      dailyCost: (data['dailyCost'] ?? 0.0).toDouble(),
      monthlyCost: (data['monthlyCost'] ?? 0.0).toDouble(),
      description: data['description'] ?? '',
    );
  }

  // Convert to Firestore document
  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'zone': zone,
      'daysPerWeek': daysPerWeek,
      'dailyCost': dailyCost,
      'monthlyCost': monthlyCost,
      'description': description,
    };
  }

  // Equality and hashCode implementation
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduleSuffix &&
        other.id == id &&
        other.code == code &&
        other.zone == zone &&
        other.daysPerWeek == daysPerWeek;
  }

  @override
  int get hashCode =>
      id.hashCode ^ code.hashCode ^ zone.hashCode ^ daysPerWeek.hashCode;

  @override
  String toString() =>
      'ScheduleSuffix(id: $id, code: $code, zone: $zone, daysPerWeek: $daysPerWeek)';
}

class City {
  final String id;
  final String name;
  final String zone; // A, B, C, or D

  City({required this.id, required this.name, required this.zone});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'zone': zone};
  }

  factory City.fromMap(Map<String, dynamic> map) {
    return City(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      zone: map['zone'] ?? 'A',
    );
  }

  // Create from Firestore document
  factory City.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return City(
      id: doc.id,
      name: data['name'] ?? '',
      zone: data['zone'] ?? 'A',
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {'name': name, 'zone': zone};
  }

  // Equality and hashCode implementation
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is City &&
        other.id == id &&
        other.name == name &&
        other.zone == zone;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ zone.hashCode;

  @override
  String toString() => 'City(id: $id, name: $name, zone: $zone)';
}

class StudentProfile {
  final String uid;
  final String fullName;
  final String university;
  final String phoneNumber;
  final SubscriptionType subscriptionType;
  final ScheduleSuffix scheduleSuffix;
  final City city;
  final double subscriptionCost;
  final List<String> selectedDays; // Days selected for bus booking
  final Map<String, TimeSlot> dayTimeSlots; // Time slot for each selected day
  final double paymentAmount; // Amount paid
  final bool isPaid; // Payment status for current month
  final bool isActive; // Whether student is active or deactivated
  final List<PaymentHistory> paymentHistory; // History of all payments
  final String? assignedDriverId; // ID of assigned driver (nullable)
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? paidAt; // When current month payment was made

  StudentProfile({
    required this.uid,
    required this.fullName,
    required this.university,
    required this.phoneNumber,
    required this.subscriptionType,
    required this.scheduleSuffix,
    required this.city,
    required this.selectedDays,
    required this.dayTimeSlots,
    this.paymentAmount = 0.0,
    this.isPaid = false,
    this.isActive = true,
    this.paymentHistory = const [],
    this.assignedDriverId,
    required this.createdAt,
    this.updatedAt,
    this.paidAt,
  }) : subscriptionCost = SubscriptionPricing.getCost(
         subscriptionType: subscriptionType,
         scheduleSuffix: scheduleSuffix,
       );

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'university': university,
      'phoneNumber': phoneNumber,
      'subscriptionType': subscriptionType.name,
      'scheduleSuffixId':
          scheduleSuffix.id, // Store reference to schedule document
      'cityId': city.id,
      'cityName': city.name,
      'cityZone': city.zone,
      'subscriptionCost': subscriptionCost,
      'selectedDays': selectedDays,
      'dayTimeSlots': dayTimeSlots.map(
        (day, timeSlot) => MapEntry(day, timeSlot.value),
      ),
      'paymentAmount': paymentAmount,
      'isPaid': isPaid,
      'isActive': isActive,
      'paymentHistory': paymentHistory
          .map((history) => history.toMap())
          .toList(),
      'assignedDriverId': assignedDriverId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
    };
  }

  factory StudentProfile.fromMap(
    Map<String, dynamic> map,
    ScheduleSuffix scheduleSuffix,
  ) {
    return StudentProfile(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      university: map['university'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      subscriptionType: SubscriptionType.fromString(
        map['subscriptionType'] ?? 'monthly',
      ),
      scheduleSuffix: scheduleSuffix,
      city: City(
        id: map['cityId'] ?? '',
        name: map['cityName'] ?? '',
        zone: map['cityZone'] ?? 'A',
      ),
      selectedDays: List<String>.from(map['selectedDays'] ?? []),
      dayTimeSlots: (map['dayTimeSlots'] as Map<String, dynamic>? ?? {}).map(
        (key, value) =>
            MapEntry(key, TimeSlotExtension.fromString(value ?? '1pm')),
      ),
      paymentAmount: (map['paymentAmount'] ?? 0.0).toDouble(),
      isPaid: map['isPaid'] ?? false,
      isActive: map['isActive'] ?? true,
      paymentHistory: (map['paymentHistory'] as List<dynamic>? ?? [])
          .map((item) => PaymentHistory.fromMap(item as Map<String, dynamic>))
          .toList(),
      assignedDriverId: map['assignedDriverId'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      paidAt: (map['paidAt'] as Timestamp?)?.toDate(),
    );
  }

  // Helper methods for cost information
  String get costDescription => SubscriptionPricing.getCostDescription(
    subscriptionType: subscriptionType,
    scheduleSuffix: scheduleSuffix,
  );

  // Check if current month payment is needed
  bool get needsPaymentThisMonth {
    final now = DateTime.now();
    return !isPaidForMonth(now.year, now.month);
  }

  // Check if specific month is paid
  bool isPaidForMonth(int year, int month) {
    return paymentHistory.any(
      (payment) =>
          payment.year == year && payment.month == month && payment.isPaid,
    );
  }

  // Get payment for specific month
  PaymentHistory? getPaymentForMonth(int year, int month) {
    try {
      return paymentHistory.firstWhere(
        (payment) => payment.year == year && payment.month == month,
      );
    } catch (e) {
      return null;
    }
  }

  // Get current month payment status
  String get currentMonthStatus {
    final now = DateTime.now();
    if (isPaidForMonth(now.year, now.month)) {
      return 'Paid';
    } else {
      return 'Unpaid';
    }
  }

  // Check if student can edit subscription/schedule (only on specific dates)
  static bool canEditThisMonth([DateTime? date]) {
    final checkDate = date ?? DateTime.now();
    final day = checkDate.day;

    // Can edit on 29th, 30th, 31st, or 1st of any month
    return day == 1 || day == 14;
  }

  // Get next edit date
  static DateTime getNextEditDate([DateTime? fromDate]) {
    final now = fromDate ?? DateTime.now();

    // If today is an edit day, return today
    if (canEditThisMonth(now)) {
      return now;
    }

    // Find next edit date
    if (now.day < 29) {
      // Next edit date is 29th of current month
      return DateTime(now.year, now.month, 29);
    } else {
      // Next edit date is 1st of next month
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      final nextYear = now.month == 12 ? now.year + 1 : now.year;
      return DateTime(nextYear, nextMonth, 1);
    }
  }

  // Get edit restriction message
  static String getEditRestrictionMessage() {
    if (canEditThisMonth()) {
      return 'You can edit your subscription and schedule today!';
    } else {
      final nextDate = getNextEditDate();
      return 'You can edit your subscription and schedule on ${nextDate.day}/${nextDate.month}/${nextDate.year}';
    }
  }

  StudentProfile copyWith({
    String? uid,
    String? fullName,
    String? university,
    String? phoneNumber,
    SubscriptionType? subscriptionType,
    ScheduleSuffix? scheduleSuffix,
    City? city,
    List<String>? selectedDays,
    Map<String, TimeSlot>? dayTimeSlots,
    double? paymentAmount,
    bool? isPaid,
    bool? isActive,
    List<PaymentHistory>? paymentHistory,
    String? assignedDriverId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? paidAt,
  }) {
    return StudentProfile(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      university: university ?? this.university,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      scheduleSuffix: scheduleSuffix ?? this.scheduleSuffix,
      city: city ?? this.city,
      selectedDays: selectedDays ?? this.selectedDays,
      dayTimeSlots: dayTimeSlots ?? this.dayTimeSlots,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      isPaid: isPaid ?? this.isPaid,
      isActive: isActive ?? this.isActive,
      paymentHistory: paymentHistory ?? this.paymentHistory,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paidAt: paidAt ?? this.paidAt,
    );
  }
}
