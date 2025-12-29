import 'package:cloud_firestore/cloud_firestore.dart';

class DriverLocation {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final bool isSharingLocation;

  DriverLocation({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.isSharingLocation = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': Timestamp.fromDate(timestamp),
      'isSharingLocation': isSharingLocation,
    };
  }

  factory DriverLocation.fromMap(Map<String, dynamic> map) {
    return DriverLocation(
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSharingLocation: map['isSharingLocation'] ?? false,
    );
  }
}

class Driver {
  final String uid;
  final String fullName;
  final String phoneNumber;
  final String zone; // A, B, C, or D
  final List<String> assignedStudentIds;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, List<String>>
  tripAssignments; // day -> list of trips ['trip1', 'trip2', 'trip3']
  final DriverLocation? location; // Current location (nullable)

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
    this.location,
  });

  // Create from Firestore document
  factory Driver.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Parse tripAssignments
    Map<String, List<String>> tripAssignments = {};
    if (data['tripAssignments'] != null) {
      Map<String, dynamic> tripData = Map<String, dynamic>.from(
        data['tripAssignments'],
      );
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
      location: data['location'] != null
          ? DriverLocation.fromMap(data['location'])
          : null,
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
      'location': location?.toMap(),
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
    DriverLocation? location,
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
      location: location ?? this.location,
    );
  }

  // Get student count
  int get studentCount => assignedStudentIds.length;
}
