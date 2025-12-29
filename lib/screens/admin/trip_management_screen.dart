import 'package:flutter/material.dart';
import '../../models/driver.dart';
import '../../services/driver_service.dart';

class TripManagementScreen extends StatefulWidget {
  const TripManagementScreen({super.key});

  @override
  State<TripManagementScreen> createState() => _TripManagementScreenState();
}

class _TripManagementScreenState extends State<TripManagementScreen> {
  final DriverService _driverService = DriverService();

  List<Driver> _allDrivers = [];
  Map<String, Map<String, String>> _allTripAssignments =
      {}; // {day: {tripType: driverId}}
  bool _isLoading = true;

  // Form state
  Driver? _selectedDriver;
  String? _selectedDay;
  final Set<String> _selectedTrips = {};

  final List<String> _days = [
    'Saturday',
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  final List<Map<String, String>> _trips = [
    {'id': 'trip1', 'name': 'Trip 1', 'time': '1:00 PM'},
    {'id': 'trip2', 'name': 'Trip 2', 'time': '2:00 PM'},
    {'id': 'trip3', 'name': 'Trip 3', 'time': '3:00 PM'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      final drivers = await _driverService.getAllDrivers();
      final assignments = await _driverService.getAllTripAssignments();

      setState(() {
        _allDrivers = drivers.where((d) => d.isActive).toList();
        _allTripAssignments = assignments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  String? _getTripDriver(String day, String tripId) {
    return _allTripAssignments[day]?[tripId];
  }

  Driver? _getDriverById(String driverId) {
    try {
      return _allDrivers.firstWhere((d) => d.uid == driverId);
    } catch (e) {
      return null;
    }
  }

  bool _isTripAvailable(String day, String tripId) {
    if (_selectedDriver == null) return false;
    final assignedDriverId = _getTripDriver(day, tripId);
    return assignedDriverId == null || assignedDriverId == _selectedDriver!.uid;
  }

  Future<void> _assignTrips() async {
    if (_selectedDriver == null ||
        _selectedDay == null ||
        _selectedTrips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select driver, day, and at least one trip'),
        ),
      );
      return;
    }

    try {
      await _driverService.assignTripsToDriver(
        driverId: _selectedDriver!.uid,
        day: _selectedDay!,
        tripTypes: _selectedTrips.toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Assigned ${_selectedTrips.length} trip(s) to ${_selectedDriver!.fullName} for $_selectedDay',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form
        setState(() {
          _selectedDriver = null;
          _selectedDay = null;
          _selectedTrips.clear();
        });

        // Reload data
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error assigning trips: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Management'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAssignmentForm(),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  _buildCurrentAssignmentsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildAssignmentForm() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment, color: Colors.deepPurple, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Assign Trips to Driver',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Driver Selector
            const Text(
              'Select Driver',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Driver>(
              value: _selectedDriver,
              decoration: InputDecoration(
                hintText: 'Choose a driver',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              items: _allDrivers.map((driver) {
                return DropdownMenuItem(
                  value: driver,
                  child: Text('${driver.fullName} (Zone ${driver.zone})'),
                );
              }).toList(),
              onChanged: (driver) {
                setState(() {
                  _selectedDriver = driver;
                  _selectedTrips.clear();
                });
              },
            ),
            const SizedBox(height: 20),

            // Day Selector
            const Text(
              'Select Day',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedDay,
              decoration: InputDecoration(
                hintText: 'Choose a day',
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              items: _days.map((day) {
                return DropdownMenuItem(value: day, child: Text(day));
              }).toList(),
              onChanged: (day) {
                setState(() {
                  _selectedDay = day;
                  _selectedTrips.clear();
                });
              },
            ),
            const SizedBox(height: 20),

            // Trip Selectors
            const Text(
              'Select Trips',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_selectedDay != null && _selectedDriver != null)
              ..._trips.map((trip) {
                final isAvailable = _isTripAvailable(
                  _selectedDay!,
                  trip['id']!,
                );
                final assignedDriver = _getTripDriver(
                  _selectedDay!,
                  trip['id']!,
                );
                final driverInfo = assignedDriver != null
                    ? _getDriverById(assignedDriver)
                    : null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CheckboxListTile(
                    value: _selectedTrips.contains(trip['id']),
                    onChanged: isAvailable
                        ? (value) {
                            setState(() {
                              if (value == true) {
                                _selectedTrips.add(trip['id']!);
                              } else {
                                _selectedTrips.remove(trip['id']!);
                              }
                            });
                          }
                        : null,
                    title: Text(
                      '${trip['name']} - ${trip['time']}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isAvailable ? Colors.black : Colors.grey,
                      ),
                    ),
                    subtitle: !isAvailable && driverInfo != null
                        ? Text(
                            'Currently assigned to ${driverInfo.fullName}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          )
                        : null,
                    secondary: Icon(
                      Icons.local_shipping,
                      color: isAvailable ? Colors.deepPurple : Colors.grey,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: _selectedTrips.contains(trip['id']!)
                            ? Colors.deepPurple
                            : Colors.grey.shade300,
                      ),
                    ),
                    tileColor: _selectedTrips.contains(trip['id']!)
                        ? Colors.deepPurple.shade50
                        : Colors.grey.shade50,
                  ),
                );
              })
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Please select a driver and day first',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Assign Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _selectedDriver != null &&
                        _selectedDay != null &&
                        _selectedTrips.isNotEmpty
                    ? _assignTrips
                    : null,
                icon: const Icon(Icons.check_circle),
                label: const Text('Assign Selected Trips'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentAssignmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.list_alt, color: Colors.deepPurple, size: 28),
            const SizedBox(width: 12),
            const Text(
              'Current Trip Assignments',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._days.map((day) => _buildDayAssignments(day)),
      ],
    );
  }

  Widget _buildDayAssignments(String day) {
    final dayAssignments = _allTripAssignments[day] ?? {};

    if (dayAssignments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple,
          child: Text(
            day.substring(0, 2),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${dayAssignments.length} trip(s) assigned'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _trips.map((trip) {
                final driverId = dayAssignments[trip['id']];
                final driver = driverId != null
                    ? _getDriverById(driverId)
                    : null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      Icons.local_shipping,
                      color: driver != null ? Colors.green : Colors.grey,
                    ),
                    title: Text('${trip['name']} - ${trip['time']}'),
                    subtitle: driver != null
                        ? Text(
                            'Assigned to: ${driver.fullName} (Zone ${driver.zone})',
                          )
                        : const Text(
                            'Not assigned',
                            style: TextStyle(color: Colors.grey),
                          ),
                    trailing: driver != null
                        ? IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _confirmRemoveTrip(day, trip['id']!, driver),
                            tooltip: 'Remove assignment',
                          )
                        : null,
                    tileColor: driver != null
                        ? Colors.green.shade50
                        : Colors.grey.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemoveTrip(
    String day,
    String tripId,
    Driver driver,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Trip Assignment'),
        content: Text(
          'Remove this trip from ${driver.fullName}?\n\n'
          'Day: $day\n'
          'Trip: ${_trips.firstWhere((t) => t['id'] == tripId)['name']}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _driverService.removeTripsFromDriver(
          driverId: driver.uid,
          day: day,
          tripTypes: [tripId],
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trip assignment removed'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error removing trip: $e')));
        }
      }
    }
  }
}
