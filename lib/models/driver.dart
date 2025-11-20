import 'package:cloud_firestore/cloud_firestore.dart';

class Driver {
  final String uid;
  final String fullName;
  final String phoneNumber;
  final String zone; // A, B, C, or D
  final List<String> assignedStudentIds;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, List<String>> tripAssignments; // day -> list of trips ['trip1', 'trip2', 'trip3']

  Driver({
    required this.uid,
    required this.fullName,
    required this.phoneNumber,
    required this.zone,
    this.assignedStudentIds = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.tripAssignments = const {},
  });

  // Create from Firestore document
  factory Driver.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Parse tripAssignments
    Map<String, List<String>> tripAssignments = {};
    if (data['tripAssignments'] != null) {
      Map<String, dynamic> tripData = Map<String, dynamic>.from(data['tripAssignments']);
      tripData.forEach((day, trips) {
        tripAssignments[day] = List<String>.from(trips ?? []);
      });
    }
    
    return Driver(
      uid: doc.id,
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      zone: data['zone'] ?? '',
      assignedStudentIds: List<String>.from(data['assignedStudentIds'] ?? []),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tripAssignments: tripAssignments,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'zone': zone,
      'assignedStudentIds': assignedStudentIds,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'tripAssignments': tripAssignments,
    };
  }

  // Copy with method
  Driver copyWith({
    String? uid,
    String? fullName,
    String? phoneNumber,
    String? zone,
    List<String>? assignedStudentIds,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, List<String>>? tripAssignments,
  }) {
    return Driver(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      zone: zone ?? this.zone,
      assignedStudentIds: assignedStudentIds ?? this.assignedStudentIds,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tripAssignments: tripAssignments ?? this.tripAssignments,
    );
  }

  // Get student count
  int get studentCount => assignedStudentIds.length;
}
