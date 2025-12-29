import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/driver.dart';
import '../models/student_profile.dart';

class DriverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _driversCollection = 'drivers';
  final String _profilesCollection = 'student_profiles';

  // Get all drivers
  Future<List<Driver>> getAllDrivers() async {
    try {
      final snapshot = await _firestore
          .collection(_driversCollection)
          .orderBy('fullName')
          .get();

      return snapshot.docs.map((doc) => Driver.fromFirestore(doc)).toList();
    } catch (e) {
      throw 'Error fetching drivers: $e';
    }
  }

  // Get drivers by zone
  Future<List<Driver>> getDriversByZone(String zone) async {
    try {
      final snapshot = await _firestore
          .collection(_driversCollection)
          .where('zone', isEqualTo: zone)
          .where('isActive', isEqualTo: true)
          .orderBy('fullName')
          .get();

      return snapshot.docs.map((doc) => Driver.fromFirestore(doc)).toList();
    } catch (e) {
      throw 'Error fetching drivers by zone: $e';
    }
  }

  // Get active drivers
  Future<List<Driver>> getActiveDrivers() async {
    try {
      final snapshot = await _firestore
          .collection(_driversCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('fullName')
          .get();

      return snapshot.docs.map((doc) => Driver.fromFirestore(doc)).toList();
    } catch (e) {
      throw 'Error fetching active drivers: $e';
    }
  }

  // Create new driver
  Future<String> createDriver(Driver driver) async {
    try {
      final docRef = await _firestore
          .collection(_driversCollection)
          .add(driver.toMap());
      return docRef.id;
    } catch (e) {
      throw 'Error creating driver: $e';
    }
  }

  // Update driver
  Future<void> updateDriver(Driver driver) async {
    try {
      await _firestore
          .collection(_driversCollection)
          .doc(driver.uid)
          .update(driver.toMap());
    } catch (e) {
      throw 'Error updating driver: $e';
    }
  }

  // Delete driver
  Future<void> deleteDriver(String driverId) async {
    try {
      await _firestore.collection(_driversCollection).doc(driverId).delete();
    } catch (e) {
      throw 'Error deleting driver: $e';
    }
  }

  // Assign students to driver
  Future<void> assignStudentsToDriver({
    required String driverId,
    required List<String> studentIds,
  }) async {
    try {
      final batch = _firestore.batch();

      // Get current driver data
      final driverDoc = await _firestore
          .collection(_driversCollection)
          .doc(driverId)
          .get();
      final driver = Driver.fromFirestore(driverDoc);

      // Get all drivers to check for existing assignments
      final allDrivers = await getAllDrivers();

      // Remove students from their previous drivers
      for (final otherDriver in allDrivers) {
        if (otherDriver.uid == driverId) continue;

        // Find students that are currently assigned to this driver
        final studentsToRemove = otherDriver.assignedStudentIds
            .where((sid) => studentIds.contains(sid))
            .toList();

        if (studentsToRemove.isNotEmpty) {
          // Remove these students from the old driver
          final updatedOldDriverStudents = otherDriver.assignedStudentIds
              .where((sid) => !studentIds.contains(sid))
              .toList();

          batch.update(
            _firestore.collection(_driversCollection).doc(otherDriver.uid),
            {
              'assignedStudentIds': updatedOldDriverStudents,
              'updatedAt': Timestamp.now(),
            },
          );
        }
      }

      // Combine existing and new student IDs, remove duplicates
      final updatedStudentIds = {
        ...driver.assignedStudentIds,
        ...studentIds,
      }.toList();

      // Update driver document
      batch.update(_firestore.collection(_driversCollection).doc(driverId), {
        'assignedStudentIds': updatedStudentIds,
        'updatedAt': Timestamp.now(),
      });

      // Update each student profile with driver ID
      for (final studentId in studentIds) {
        batch.update(
          _firestore.collection(_profilesCollection).doc(studentId),
          {'assignedDriverId': driverId, 'updatedAt': Timestamp.now()},
        );
      }

      await batch.commit();
    } catch (e) {
      throw 'Error assigning students to driver: $e';
    }
  }

  // Unassign students from driver
  Future<void> unassignStudentsFromDriver({
    required String driverId,
    required List<String> studentIds,
  }) async {
    try {
      final batch = _firestore.batch();

      // Get current driver data
      final driverDoc = await _firestore
          .collection(_driversCollection)
          .doc(driverId)
          .get();
      final driver = Driver.fromFirestore(driverDoc);

      // Remove student IDs from driver's list
      final updatedStudentIds = driver.assignedStudentIds
          .where((id) => !studentIds.contains(id))
          .toList();

      // Update driver document
      batch.update(_firestore.collection(_driversCollection).doc(driverId), {
        'assignedStudentIds': updatedStudentIds,
        'updatedAt': Timestamp.now(),
      });

      // Remove driver ID from each student profile
      for (final studentId in studentIds) {
        batch.update(
          _firestore.collection(_profilesCollection).doc(studentId),
          {
            'assignedDriverId': FieldValue.delete(),
            'updatedAt': Timestamp.now(),
          },
        );
      }

      await batch.commit();
    } catch (e) {
      throw 'Error unassigning students from driver: $e';
    }
  }

  // Update student order for a driver
  Future<void> updateStudentOrder(
    String driverId,
    List<String> orderedStudentIds,
  ) async {
    try {
      await _firestore.collection(_driversCollection).doc(driverId).update({
        'assignedStudentIds': orderedStudentIds,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw 'Error updating student order: $e';
    }
  }

  // Get students assigned to a driver
  Future<List<StudentProfile>> getDriverStudents(String driverId) async {
    try {
      await _firestore
          .collection(_profilesCollection)
          .where('assignedDriverId', isEqualTo: driverId)
          .get();

      // Note: This is a simplified version. In production, you'd need to load
      // the full StudentProfile with all related data (city, scheduleSuffix, etc.)
      return []; // TODO: Implement full student loading
    } catch (e) {
      throw 'Error fetching driver students: $e';
    }
  }

  // Assign trips to driver for a specific day
  Future<void> assignTripsToDriver({
    required String driverId,
    required String day,
    required List<String> tripTypes, // ['trip1', 'trip2', 'trip3']
  }) async {
    try {
      final batch = _firestore.batch();

      // Get all drivers to check for conflicts
      final allDrivers = await getAllDrivers();

      // Remove conflicting trips from other drivers
      for (final driver in allDrivers) {
        if (driver.uid == driverId) continue;

        final driverTrips = driver.tripAssignments[day] ?? [];
        final conflictingTrips = driverTrips
            .where((trip) => tripTypes.contains(trip))
            .toList();

        if (conflictingTrips.isNotEmpty) {
          // Remove conflicting trips from this driver
          final updatedTrips = driverTrips
              .where((trip) => !tripTypes.contains(trip))
              .toList();
          final updatedAssignments = Map<String, List<String>>.from(
            driver.tripAssignments,
          );

          if (updatedTrips.isEmpty) {
            updatedAssignments.remove(day);
          } else {
            updatedAssignments[day] = updatedTrips;
          }

          batch.update(
            _firestore.collection(_driversCollection).doc(driver.uid),
            {
              'tripAssignments': updatedAssignments,
              'updatedAt': Timestamp.now(),
            },
          );
        }
      }

      // Get current driver to update their assignments
      final driverDoc = await _firestore
          .collection(_driversCollection)
          .doc(driverId)
          .get();
      final currentDriver = Driver.fromFirestore(driverDoc);
      final updatedAssignments = Map<String, List<String>>.from(
        currentDriver.tripAssignments,
      );
      updatedAssignments[day] = tripTypes;

      // Update the target driver with new trip assignments
      batch.update(_firestore.collection(_driversCollection).doc(driverId), {
        'tripAssignments': updatedAssignments,
        'updatedAt': Timestamp.now(),
      });

      await batch.commit();
    } catch (e) {
      throw 'Error assigning trips to driver: $e';
    }
  }

  // Get all trip assignments across all drivers
  Future<Map<String, Map<String, String>>> getAllTripAssignments() async {
    // Returns: {day: {tripType: driverId}}
    try {
      final drivers = await getAllDrivers();
      final Map<String, Map<String, String>> assignments = {};

      for (final driver in drivers) {
        driver.tripAssignments.forEach((day, trips) {
          if (!assignments.containsKey(day)) {
            assignments[day] = {};
          }
          for (final trip in trips) {
            assignments[day]![trip] = driver.uid;
          }
        });
      }

      return assignments;
    } catch (e) {
      throw 'Error fetching trip assignments: $e';
    }
  }

  // Remove specific trips from a driver
  Future<void> removeTripsFromDriver({
    required String driverId,
    required String day,
    required List<String> tripTypes,
  }) async {
    try {
      final driverDoc = await _firestore
          .collection(_driversCollection)
          .doc(driverId)
          .get();
      final driver = Driver.fromFirestore(driverDoc);

      final updatedAssignments = Map<String, List<String>>.from(
        driver.tripAssignments,
      );
      final currentTrips = updatedAssignments[day] ?? [];
      final remainingTrips = currentTrips
          .where((trip) => !tripTypes.contains(trip))
          .toList();

      if (remainingTrips.isEmpty) {
        updatedAssignments.remove(day);
      } else {
        updatedAssignments[day] = remainingTrips;
      }

      await _firestore.collection(_driversCollection).doc(driverId).update({
        'tripAssignments': updatedAssignments,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw 'Error removing trips from driver: $e';
    }
  }
}
