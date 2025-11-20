import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/student_profile.dart';
import '../../models/driver.dart';
import '../../models/bus_booking.dart';
import '../../services/driver_service.dart';
import '../../services/student_profile_service.dart';

class TripStudentsScreen extends StatefulWidget {
  const TripStudentsScreen({super.key});

  @override
  State<TripStudentsScreen> createState() => _TripStudentsScreenState();
}

class _TripStudentsScreenState extends State<TripStudentsScreen> {
  final DriverService _driverService = DriverService();
  final StudentProfileService _studentService = StudentProfileService();
  
  List<StudentProfile> _tripStudents = [];
  Driver? _driverProfile;
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedDay;
  String? _selectedTrip;

  @override
  void initState() {
    super.initState();
    _loadTripStudents();
  }

  // Determine which day to show based on current time
  String _getTargetDay() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;
    
    // Convert current time to minutes since midnight for easier comparison
    final currentTimeInMinutes = currentHour * 60 + currentMinute;
    
    // 3:30 PM = 15:30 = 15 * 60 + 30 = 930 minutes
    const cutoffTimeInMinutes = 15 * 60 + 30; // 3:30 PM
    
    DateTime targetDate;
    
    // If current time is after 3:30 PM, show next day's students
    if (currentTimeInMinutes >= cutoffTimeInMinutes) {
      targetDate = now.add(const Duration(days: 1));
    } else {
      // Before 3:30 PM, show today's students
      targetDate = now;
    }
    
    // Get day name (Monday, Tuesday, etc.)
    const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return dayNames[targetDate.weekday - 1]; // weekday is 1-7, where 1 is Monday
  }

  // Set the initial selected day after data is loaded
  void _setInitialDay() {
    final targetDay = _getTargetDay();
    // Only set if the target day exists in available days
    if (_availableDays.contains(targetDay)) {
      setState(() {
        _selectedDay = targetDay;
      });
    }
  }

  Future<void> _loadTripStudents() async {
    try {
      setState(() => _isLoading = true);
      
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Get driver profile
      final drivers = await _driverService.getAllDrivers();
      _driverProfile = drivers.firstWhere(
        (d) => d.uid == currentUser.uid,
        orElse: () => throw 'Driver profile not found',
      );

      // Get all students
      final allStudents = await _studentService.getAllStudents();
      
      // Filter students based on driver's trip assignments
      _tripStudents = _filterStudentsByTripAssignments(allStudents);

      setState(() => _isLoading = false);
      
      // Set initial day after data is loaded
      _setInitialDay();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading trip students: $e')),
        );
      }
    }
  }

  List<StudentProfile> _filterStudentsByTripAssignments(List<StudentProfile> allStudents) {
    if (_driverProfile == null || _driverProfile!.tripAssignments.isEmpty) {
      return [];
    }

    final List<StudentProfile> filteredStudents = [];

    // Loop through each day the driver has trip assignments
    _driverProfile!.tripAssignments.forEach((day, trips) {
      for (final student in allStudents) {
        // Check if student has this day selected
        if (!student.selectedDays.contains(day)) continue;

        // Get student's time slot for this day
        final timeSlot = student.dayTimeSlots[day];
        if (timeSlot == null) continue;

        // Map TimeSlot to trip type
        String? tripType;
        if (timeSlot == TimeSlot.onepm) {
          tripType = 'trip1';
        } else if (timeSlot == TimeSlot.twopm) {
          tripType = 'trip2';
        } else if (timeSlot == TimeSlot.threepm) {
          tripType = 'trip3';
        }

        // Check if driver has this trip assigned for this day
        if (tripType != null && trips.contains(tripType)) {
          // Avoid duplicates
          if (!filteredStudents.any((s) => s.uid == student.uid)) {
            filteredStudents.add(student);
          }
        }
      }
    });

    return filteredStudents;
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    // Remove any non-digit characters from phone number
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    
    // WhatsApp URL scheme
    final whatsappUrl = Uri.parse('https://wa.me/$cleanNumber');
    
    try {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp. Please make sure it is installed.')),
        );
      }
    }
  }

  List<StudentProfile> get _filteredStudents {
    // First filter for active students only
    var students = _tripStudents.where((student) => student.isActive).toList();

    // Apply day filter
    if (_selectedDay != null) {
      students = students.where((student) {
        return student.selectedDays.contains(_selectedDay);
      }).toList();
    }

    // Apply trip filter
    if (_selectedTrip != null) {
      students = students.where((student) {
        final timeSlot = _selectedDay != null 
            ? student.dayTimeSlots[_selectedDay]
            : student.dayTimeSlots.values.first;
        
        if (_selectedTrip == 'trip1') return timeSlot == TimeSlot.onepm;
        if (_selectedTrip == 'trip2') return timeSlot == TimeSlot.twopm;
        if (_selectedTrip == 'trip3') return timeSlot == TimeSlot.threepm;
        return false;
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      students = students.where((student) {
        final query = _searchQuery.toLowerCase();
        return student.fullName.toLowerCase().contains(query) ||
               student.phoneNumber.contains(query) ||
               student.university.toLowerCase().contains(query);
      }).toList();
    }

    return students;
  }

  List<String> get _availableDays {
    return _driverProfile?.tripAssignments.keys.toList() ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('My Trip Students', style: TextStyle(fontSize: 18)),
            if (_selectedDay != null)
              Text(
                '$_selectedDay ($timeStr)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
              ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadTripStudents(); // This will call _setInitialDay() after loading
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                _buildFilters(),
                _buildSearchBar(),
                Expanded(child: _buildStudentsList()),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.deepPurple.shade50,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.deepPurple,
            radius: 30,
            child: Text(
              _driverProfile?.fullName.isNotEmpty == true 
                  ? _driverProfile!.fullName[0].toUpperCase() 
                  : 'D',
              style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _driverProfile?.fullName ?? 'Driver',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Zone ${_driverProfile?.zone ?? '-'} • ${_tripStudents.length} Trip ${_tripStudents.length == 1 ? 'Student' : 'Students'}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          Icon(Icons.access_time, color: Colors.deepPurple, size: 32),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    if (_availableDays.isEmpty) return const SizedBox.shrink();

    final targetDay = _getTargetDay();
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;
    final currentTimeInMinutes = currentHour * 60 + currentMinute;
    const cutoffTimeInMinutes = 15 * 60 + 30; // 3:30 PM
    final isAfterCutoff = currentTimeInMinutes >= cutoffTimeInMinutes;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner about auto-selected day
          if (_availableDays.contains(targetDay))
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAfterCutoff
                          ? 'Showing tomorrow\'s students ($targetDay) - After 3:30 PM cutoff'
                          : 'Showing today\'s students ($targetDay) - Before 3:30 PM cutoff',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade900, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No trips assigned for $targetDay. Showing all available trip days.',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade900, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          const Text('Filter by:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _availableDays.contains(_selectedDay) ? _selectedDay : null,
                  decoration: InputDecoration(
                    labelText: 'Day',
                    prefixIcon: const Icon(Icons.calendar_today, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Days')),
                    ..._availableDays.map((day) {
                      return DropdownMenuItem(value: day, child: Text(day));
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedDay = value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedTrip,
                  decoration: InputDecoration(
                    labelText: 'Trip',
                    prefixIcon: const Icon(Icons.local_shipping, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Trips')),
                    DropdownMenuItem(value: 'trip1', child: Text('1:00 PM')),
                    DropdownMenuItem(value: 'trip2', child: Text('2:00 PM')),
                    DropdownMenuItem(value: 'trip3', child: Text('3:00 PM')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedTrip = value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search students by name, phone, or university',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  Widget _buildStudentsList() {
    if (_tripStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No trip students assigned yet',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Trip students will appear here once admin assigns trips to you',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final students = _filteredStudents;

    if (students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No students found',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedDay = null;
                  _selectedTrip = null;
                });
              },
              child: const Text('Clear filters'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        return _buildStudentCard(student, index + 1);
      },
    );
  }

  Widget _buildStudentCard(StudentProfile student, int number) {
    // Get the day and time for display
    String dayTimeInfo = '';
    student.selectedDays.forEach((day) {
      final timeSlot = student.dayTimeSlots[day];
      if (timeSlot != null && _driverProfile!.tripAssignments[day]?.isNotEmpty == true) {
        if (dayTimeInfo.isNotEmpty) dayTimeInfo += ', ';
        dayTimeInfo += '$day ${timeSlot.displayName}';
      }
    });

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showStudentDetails(student),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Number badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Student avatar
              CircleAvatar(
                backgroundColor: Colors.blue.shade600,
                radius: 28,
                child: Text(
                  student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              // Student info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dayTimeInfo,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          student.phoneNumber,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // WhatsApp button
              IconButton(
                onPressed: () => _openWhatsApp(student.phoneNumber),
                icon: const Icon(Icons.phone, color: Colors.green),
                tooltip: 'Open WhatsApp',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green.shade50,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStudentDetails(StudentProfile student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade600,
                      radius: 35,
                      child: Text(
                        student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.fullName,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Trip Student',
                            style: TextStyle(fontSize: 12, color: Colors.deepPurple.shade600, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                // Details
                _buildDetailRow(Icons.phone, 'Phone', student.phoneNumber),
                _buildDetailRow(Icons.school, 'University', student.university),
                _buildDetailRow(Icons.location_city, 'City', '${student.city.name} (Zone ${student.city.zone})'),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                // Trip Days & Times
                const Text('Trip Schedule:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...student.selectedDays.map((day) {
                  final timeSlot = student.dayTimeSlots[day];
                  final driverHasTrip = _driverProfile?.tripAssignments[day]?.isNotEmpty == true;
                  
                  if (!driverHasTrip) return const SizedBox.shrink();
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Text(day, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.deepPurple.shade200),
                          ),
                          child: Text(
                            timeSlot?.displayName ?? 'No time',
                            style: TextStyle(color: Colors.deepPurple.shade700, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _openWhatsApp(student.phoneNumber);
                        },
                        icon: const Icon(Icons.phone),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
