import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/driver.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int _updateIntervalSeconds =
      30; // Update every 30 seconds minimum
  static const double _minimumDistanceMeters =
      10; // Only update if moved 10+ meters

  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _lastPosition;
  DateTime? _lastUpdateTime;
  bool _isSharing = false;

  // Check and request location permissions using Geolocator (more reliable)
  Future<bool> _handlePermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        'Location services are disabled.\nPlease enable GPS in your device settings.',
      );
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(
          'Location permissions are denied.\nPlease grant location permission in app settings.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied.\nPlease enable location permission in device settings.',
      );
    }

    // At this point, permissions are granted
    return true;
  }

  // Get current position with timeout
  Future<Position?> getCurrentPosition() async {
    try {
      await _handlePermissions();

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('❌ Error getting current position: $e');
      rethrow;
    }
  }

  // Start location sharing for driver
  Future<void> startLocationSharing(String driverId) async {
    try {
      print('🚗 Starting location sharing for driver: $driverId');

      // Handle permissions
      await _handlePermissions();
      print('✅ Permissions granted');

      // Get initial position with multiple retries and progressive accuracy
      print('📍 Getting initial GPS position...');
      Position? initialPosition;
      
      // Try 1: High accuracy with 20 second timeout
      try {
        print('🎯 Attempt 1: High accuracy (20s timeout)...');
        initialPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 20),
        );
        print('✅ Success with high accuracy');
      } catch (e) {
        print('⚠️ High accuracy failed: $e');
        
        // Try 2: Medium accuracy with 15 second timeout
        try {
          print('🎯 Attempt 2: Medium accuracy (15s timeout)...');
          initialPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 15),
          );
          print('✅ Success with medium accuracy');
        } catch (e2) {
          print('⚠️ Medium accuracy failed: $e2');
          
          // Try 3: Low accuracy with 10 second timeout
          try {
            print('🎯 Attempt 3: Low accuracy (10s timeout)...');
            initialPosition = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
              timeLimit: const Duration(seconds: 10),
            );
            print('✅ Success with low accuracy');
          } catch (e3) {
            print('⚠️ Low accuracy failed: $e3');
            
            // Try 4: Last resort - get last known position
            try {
              print('🎯 Attempt 4: Getting last known position...');
              initialPosition = await Geolocator.getLastKnownPosition();
              if (initialPosition != null) {
                print('✅ Using last known position (may be outdated)');
              }
            } catch (e4) {
              print('❌ Last known position failed: $e4');
            }
          }
        }
      }

      if (initialPosition == null) {
        throw Exception(
          'Could not get GPS location after multiple attempts.\n\n'
          'Please try:\n'
          '1. Go outdoors or near a window\n'
          '2. Make sure GPS is enabled in device settings\n'
          '3. Wait a few moments for GPS to initialize\n'
          '4. Try again',
        );
      }

      print('✅ Got position: ${initialPosition.latitude}, ${initialPosition.longitude} '
          '(accuracy: ${initialPosition.accuracy}m)');
      
      // Save initial position to Firestore
      await _updateLocationInFirestore(driverId, initialPosition, true);
      print('✅ Initial location saved to Firestore');

      _isSharing = true;
      _lastPosition = initialPosition;
      _lastUpdateTime = DateTime.now();

      // Start listening to position updates with best effort accuracy
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
      );

      print('🎧 Starting location stream...');
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          print('📍 Update: ${position.latitude}, ${position.longitude} (±${position.accuracy.toStringAsFixed(0)}m)');
          _handlePositionUpdate(position, driverId);
        },
        onError: (error) {
          print('❌ Location stream error: $error');
        },
      );

      print('✅ Location sharing started successfully');
    } catch (e) {
      print('❌ Failed to start location sharing: $e');
      _isSharing = false;
      rethrow;
    }
  }

  // Handle position update with throttling
  void _handlePositionUpdate(Position position, String driverId) async {
    if (!_isSharing) return;

    final now = DateTime.now();

    // Throttle updates: only update every _updateIntervalSeconds
    if (_lastUpdateTime != null &&
        now.difference(_lastUpdateTime!).inSeconds < _updateIntervalSeconds) {
      return;
    }

    // Check if driver moved significantly
    if (_lastPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      // If moved less than minimum distance, don't update
      if (distance < _minimumDistanceMeters) {
        return;
      }
    }

    // Update location in Firestore
    await _updateLocationInFirestore(driverId, position, true);
    _lastPosition = position;
    _lastUpdateTime = now;
  }

  // Update location in Firestore (atomic update)
  Future<void> _updateLocationInFirestore(
    String driverId,
    Position position,
    bool isSharingLocation,
  ) async {
    try {
      final driverLocation = DriverLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        isSharingLocation: isSharingLocation,
      );

      await _firestore.collection('drivers').doc(driverId).update({
        'location': driverLocation.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating location in Firestore: $e');
    }
  }

  // Stop location sharing
  Future<void> stopLocationSharing(String driverId) async {
    _isSharing = false;
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _lastPosition = null;
    _lastUpdateTime = null;

    // Update Firestore to indicate location sharing stopped
    try {
      await _firestore.collection('drivers').doc(driverId).update({
        'location.isSharingLocation': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error stopping location sharing: $e');
    }
  }

  // Check if currently sharing location
  bool get isSharingLocation => _isSharing;

  // Get driver's location from Firestore
  Future<DriverLocation?> getDriverLocation(String driverId) async {
    try {
      final doc = await _firestore.collection('drivers').doc(driverId).get();
      if (doc.exists && doc.data()?['location'] != null) {
        return DriverLocation.fromMap(doc.data()!['location']);
      }
      return null;
    } catch (e) {
      print('Error getting driver location: $e');
      return null;
    }
  }

  // Stream driver's location updates (for real-time map updates)
  Stream<DriverLocation?> watchDriverLocation(String driverId) {
    return _firestore.collection('drivers').doc(driverId).snapshots().map((
      doc,
    ) {
      if (doc.exists && doc.data()?['location'] != null) {
        return DriverLocation.fromMap(doc.data()!['location']);
      }
      return null;
    });
  }

  // Clean up resources
  void dispose() {
    _positionStreamSubscription?.cancel();
  }
}
