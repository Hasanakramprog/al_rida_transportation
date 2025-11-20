import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_profile.dart';
import 'monthly_payment_service.dart';

class StudentProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collections
  static const String _schedulesCollection = 'schedule_suffixes';
  static const String _profilesCollection = 'student_profiles';

  // Get all schedule suffixes from Firestore
  Future<List<ScheduleSuffix>> getScheduleSuffixes() async {
    try {
      final snapshot = await _firestore
          .collection(_schedulesCollection)
          .orderBy('code')
          .get();
      
      return snapshot.docs
          .map((doc) => ScheduleSuffix.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Error loading schedule suffixes: $e';
    }
  }

  // Get a specific schedule suffix by ID
  Future<ScheduleSuffix?> getScheduleSuffixById(String id) async {
    try {
      final doc = await _firestore
          .collection(_schedulesCollection)
          .doc(id)
          .get();
      
      if (doc.exists) {
        return ScheduleSuffix.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw 'Error loading schedule suffix: $e';
    }
  }

  // Get cities by zone from Firestore
  Future<List<City>> getCitiesByZone(String zone) async {
    try {
      final snapshot = await _firestore
          .collection('cities')
          .where('zone', isEqualTo: zone)
          .orderBy('name')
          .get();
      
      return snapshot.docs.map((doc) => City.fromFirestore(doc)).toList();
    } catch (e) {
      throw 'Error loading cities: $e';
    }
  }



  // Get all cities from Firestore
  Future<List<City>> getAllCities() async {
    try {
      final snapshot = await _firestore
          .collection('cities')
          .orderBy('zone')
          .orderBy('name')
          .get();
      
      return snapshot.docs.map((doc) => City.fromFirestore(doc)).toList();
    } catch (e) {
      throw 'Error loading all cities: $e';
    }
  }

  // ADMIN ONLY: Get all student profiles
  Future<List<StudentProfile>> getAllStudents() async {
    try {
      final snapshot = await _firestore
          .collection(_profilesCollection)
          .orderBy('createdAt', descending: true)
          .get();
      
      final students = <StudentProfile>[];
      for (var doc in snapshot.docs) {
        if (doc.exists) {
          final data = doc.data();
          final scheduleSuffixId = data['scheduleSuffixId'] as String?;
          
          if (scheduleSuffixId != null) {
            final scheduleSuffix = await getScheduleSuffixById(scheduleSuffixId);
            if (scheduleSuffix != null) {
              students.add(StudentProfile.fromMap(data, scheduleSuffix));
            }
          }
        }
      }
      return students;
    } catch (e) {
      throw 'Error getting all students: $e';
    }
  }

  // Get student profile
  Future<StudentProfile?> getStudentProfile(String uid) async {
    try {
      final doc = await _firestore
          .collection(_profilesCollection)
          .doc(uid)
          .get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final scheduleSuffixId = data['scheduleSuffixId'] as String?;
        
        if (scheduleSuffixId != null) {
          final scheduleSuffix = await getScheduleSuffixById(scheduleSuffixId);
          if (scheduleSuffix != null) {
            return StudentProfile.fromMap(data, scheduleSuffix);
          }
        }
      }
      return null;
    } catch (e) {
      print('Error getting student profile: $e');
      return null;
    }
  }

  // Check if student has completed profile setup
  Future<bool> hasCompletedProfile(String uid) async {
    try {
      final profile = await getStudentProfile(uid);
      return profile != null;
    } catch (e) {
      return false;
    }
  }

  // Save/Update student profile
  Future<void> saveStudentProfile(StudentProfile profile) async {
    try {
      await _firestore
          .collection(_profilesCollection)
          .doc(profile.uid)
          .set(profile.toMap());

      // Create yearly payment records using MonthlyPaymentService
      final paymentService = MonthlyPaymentService();
      final currentYear = DateTime.now().year;
      await paymentService.createYearlyPaymentRecords(profile.uid, profile.subscriptionCost, currentYear);
      await paymentService.createYearlyPaymentRecords(profile.uid, profile.subscriptionCost, currentYear + 1);
    } catch (e) {
      throw 'Error saving profile: $e';
    }
  }

  // ADMIN ONLY: Update student payment status
  Future<void> updatePaymentStatus({
    required String studentUid,
    required bool isPaid,
  }) async {
    try {
      await _firestore
          .collection(_profilesCollection)
          .doc(studentUid)
          .update({
        'isPaid': isPaid,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'paidAt': isPaid ? Timestamp.fromDate(DateTime.now()) : null,
      });
    } catch (e) {
      throw 'Error updating payment status: $e';
    }
  }

  // Update student profile
  Future<void> updateStudentProfile(StudentProfile profile) async {
    try {
      final updatedProfile = profile.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection(_profilesCollection)
          .doc(profile.uid)
          .update(updatedProfile.toMap());
    } catch (e) {
      throw 'Error updating profile: $e';
    }
  }

  // Delete student profile
  Future<void> deleteStudentProfile(String uid) async {
    try {
      await _firestore
          .collection(_profilesCollection)
          .doc(uid)
          .delete();
    } catch (e) {
      throw 'Error deleting profile: $e';
    }
  }

  // ADMIN ONLY: Process monthly payment for a student
  // TODO: Add admin role verification when implementing admin functionality
  Future<void> processPayment(String uid, double amount) async {
    // This method should only be accessible by admin users
    // Add role check: if (!isAdmin) throw 'Unauthorized access';
    try {
      final profile = await getStudentProfile(uid);
      if (profile == null) {
        throw 'Profile not found';
      }

      final now = DateTime.now();
      final newPaymentHistory = PaymentHistory(
        year: now.year,
        month: now.month,
        amount: amount,
        paidAt: now,
        isPaid: true,
      );

      // Remove existing payment for this month if exists
      final updatedHistory = profile.paymentHistory
          .where((payment) => !(payment.year == now.year && payment.month == now.month))
          .toList();
      
      updatedHistory.add(newPaymentHistory);

      final updatedProfile = profile.copyWith(
        paymentHistory: updatedHistory,
        isPaid: true,
        paymentAmount: amount,
        paidAt: now,
        updatedAt: now,
      );

      await saveStudentProfile(updatedProfile);
    } catch (e) {
      throw 'Error processing payment: $e';
    }
  }

  // ADMIN ONLY: Reset monthly payment status for a student
  // TODO: Add admin role verification when implementing admin functionality
  Future<void> resetMonthlyPaymentStatus(String uid) async {
    // This method should only be accessible by admin users
    // Add role check: if (!isAdmin) throw 'Unauthorized access';
    try {
      final profile = await getStudentProfile(uid);
      if (profile == null) {
        throw 'Profile not found';
      }

      final now = DateTime.now();
      
      // Check if already paid for current month
      if (profile.isPaidForMonth(now.year, now.month)) {
        return; // Already paid for this month
      }

      // Reset payment status for new month
      final updatedProfile = profile.copyWith(
        isPaid: false,
        paymentAmount: 0.0,
        paidAt: null,
        updatedAt: now,
      );

      await saveStudentProfile(updatedProfile);
    } catch (e) {
      throw 'Error resetting payment status: $e';
    }
  }

  // ADMIN ONLY: Check and update payment status for all users (batch operation)
  // TODO: Add admin role verification when implementing admin functionality
  Future<void> checkAndResetAllPayments() async {
    // This method should only be accessible by admin users
    // Add role check: if (!isAdmin) throw 'Unauthorized access';
    try {
      final now = DateTime.now();
      final snapshot = await _firestore.collection(_profilesCollection).get();
      
      for (final doc in snapshot.docs) {
        try {
          final profile = await getStudentProfile(doc.id);
          if (profile != null && !profile.isPaidForMonth(now.year, now.month)) {
            await resetMonthlyPaymentStatus(doc.id);
          }
        } catch (e) {
          print('Error updating payment status for ${doc.id}: $e');
        }
      }
    } catch (e) {
      throw 'Error checking payment statuses: $e';
    }
  }

  // ADMIN ONLY: Toggle student active status
  // When deactivated, removes student from all driver assignments
  Future<void> toggleStudentActiveStatus(String studentUid, bool isActive) async {
    try {
      // Update student's isActive status
      await _firestore
          .collection(_profilesCollection)
          .doc(studentUid)
          .update({
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // If deactivating student, remove from all driver assignments
      if (!isActive) {
        await _removeStudentFromAllDrivers(studentUid);
      }
    } catch (e) {
      throw 'Error toggling student active status: $e';
    }
  }

  // Private method to remove student from all driver assignments
  Future<void> _removeStudentFromAllDrivers(String studentUid) async {
    try {
      // Get all drivers
      final driversSnapshot = await _firestore.collection('drivers').get();

      for (var driverDoc in driversSnapshot.docs) {
        final driverData = driverDoc.data();
        
        // Remove from morning trip (assignedStudentIds)
        final assignedStudentIds = List<String>.from(driverData['assignedStudentIds'] ?? []);
        final updatedMorningStudents = assignedStudentIds.where((id) => id != studentUid).toList();

        // Remove from afternoon trips (tripAssignments)
        final tripAssignments = Map<String, dynamic>.from(driverData['tripAssignments'] ?? {});
        final updatedTripAssignments = <String, dynamic>{};

        tripAssignments.forEach((day, trips) {
          if (trips is List) {
            // Remove student from each trip's list
            updatedTripAssignments[day] = trips
                .where((tripId) => tripId != studentUid)
                .toList();
          }
        });

        // Update driver document
        await _firestore.collection('drivers').doc(driverDoc.id).update({
          'assignedStudentIds': updatedMorningStudents,
          'tripAssignments': updatedTripAssignments,
        });
      }
    } catch (e) {
      throw 'Error removing student from drivers: $e';
    }
  }
}
