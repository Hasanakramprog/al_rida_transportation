import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/driver_service.dart';
import '../../services/location_service.dart';
import '../../models/driver.dart';

class DriverLocationScreen extends StatefulWidget {
  final String driverId;
  final String driverName;

  const DriverLocationScreen({
    super.key,
    required this.driverId,
    required this.driverName,
  });

  @override
  State<DriverLocationScreen> createState() => _DriverLocationScreenState();
}

class _DriverLocationScreenState extends State<DriverLocationScreen> {
  final LocationService _locationService = LocationService();

  GoogleMapController? _mapController;
  DriverLocation? _driverLocation;
  bool _isLoading = true;
  String? _errorMessage;

  // Cached driver location to minimize Firestore reads
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    _loadDriverLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadDriverLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final location = await _locationService.getDriverLocation(
        widget.driverId,
      );

      if (location == null || !location.isSharingLocation) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Driver is not sharing location at the moment';
        });
        return;
      }

      // Check if location is stale (more than 5 minutes old)
      final now = DateTime.now();
      final minutesSinceUpdate = now.difference(location.timestamp).inMinutes;

      if (minutesSinceUpdate > 5) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Driver location was last updated $minutesSinceUpdate minutes ago';
        });
        return;
      }

      setState(() {
        _driverLocation = location;
        _isLoading = false;
        _lastRefreshTime = DateTime.now();
      });

      // Move camera to driver location (wait for map to rebuild)
      if (_driverLocation != null) {
        // Wait for the map to rebuild after setState
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Check if widget is still mounted and controller exists
        if (mounted && _mapController != null) {
          try {
            await _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(_driverLocation!.latitude, _driverLocation!.longitude),
                15.0,
              ),
            );
          } catch (e) {
            // Controller may have been disposed, ignore
          }
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load driver location: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.driverName}\'s Location'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDriverLocation,
            tooltip: 'Refresh Location',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : _buildMapView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDriverLocation,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    if (_driverLocation == null) {
      return _buildErrorView();
    }

    final driverPosition = LatLng(
      _driverLocation!.latitude,
      _driverLocation!.longitude,
    );

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: driverPosition,
            zoom: 15.0,
          ),
          markers: {
            Marker(
              markerId: MarkerId(widget.driverId),
              position: driverPosition,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
              infoWindow: InfoWindow(
                title: widget.driverName,
                snippet:
                    'Last updated: ${_formatTimestamp(_driverLocation!.timestamp)}',
              ),
            ),
          },
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          mapToolbarEnabled: true,
        ),
        // Info card at top
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Driver is online',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last updated: ${_formatTimestamp(_driverLocation!.timestamp)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  if (_lastRefreshTime != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Refreshed: ${_formatTimestamp(_lastRefreshTime!)}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
