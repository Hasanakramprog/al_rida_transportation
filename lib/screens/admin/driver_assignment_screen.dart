import 'package:flutter/material.dart';
import '../../models/student_profile.dart';
import '../../models/driver.dart';
import '../../services/student_profile_service.dart';
import '../../services/driver_service.dart';

class DriverAssignmentScreen extends StatefulWidget {
  const DriverAssignmentScreen({super.key});

  @override
  State<DriverAssignmentScreen> createState() => _DriverAssignmentScreenState();
}

class _DriverAssignmentScreenState extends State<DriverAssignmentScreen> {
  final StudentProfileService _studentService = StudentProfileService();
  final DriverService _driverService = DriverService();

  List<StudentProfile> _allStudents = [];
  List<StudentProfile> _filteredStudents = [];
  List<Driver> _allDrivers = [];
  
  Set<String> _selectedStudentIds = {};
  bool _isLoading = true;
  
  // Filters
  String _searchQuery = '';
  String? _zoneFilter;
  String? _scheduleFilter;
  String? _assignmentFilter; // 'all', 'assigned', 'unassigned'
  String _activeFilter = 'active'; // 'all', 'active', 'inactive'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Determine which day's students to show based on current time
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

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      final allStudents = await _studentService.getAllStudents();
      final drivers = await _driverService.getAllDrivers();
      
      // Get the target day based on current time
      final targetDay = _getTargetDay();
      
      // Filter students who have the target day in their schedule
      final studentsForDay = allStudents.where((student) {
        return student.selectedDays.contains(targetDay);
      }).toList();
      
      setState(() {
        _allStudents = studentsForDay;
        _filteredStudents = studentsForDay;
        _allDrivers = drivers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredStudents = _allStudents.where((student) {
        // Active status filter
        if (_activeFilter == 'active' && !student.isActive) {
          return false;
        }
        if (_activeFilter == 'inactive' && student.isActive) {
          return false;
        }
        
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!student.fullName.toLowerCase().contains(query) &&
              !student.phoneNumber.contains(query) &&
              !student.university.toLowerCase().contains(query)) {
            return false;
          }
        }

        // Zone filter
        if (_zoneFilter != null && student.city.zone != _zoneFilter) {
          return false;
        }

        // Schedule filter
        if (_scheduleFilter != null && student.scheduleSuffix.code != _scheduleFilter) {
          return false;
        }

        // Assignment filter
        if (_assignmentFilter == 'assigned') {
          // Check if student has assignedDriverId
          // Note: You'll need to add this field to StudentProfile model
          // For now, we'll check if any driver has this student
          final isAssigned = _allDrivers.any((driver) => driver.assignedStudentIds.contains(student.uid));
          if (!isAssigned) return false;
        } else if (_assignmentFilter == 'unassigned') {
          final isAssigned = _allDrivers.any((driver) => driver.assignedStudentIds.contains(student.uid));
          if (isAssigned) return false;
        }

        return true;
      }).toList();
    });
  }

  void _selectAll() {
    setState(() {
      _selectedStudentIds = _filteredStudents.map((s) => s.uid).toSet();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedStudentIds.clear();
    });
  }

  Future<void> _showAssignDriverDialog() async {
    if (_selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one student')),
      );
      return;
    }

    // Get zones of selected students
    final selectedStudents = _allStudents.where((s) => _selectedStudentIds.contains(s.uid)).toList();
    final zones = selectedStudents.map((s) => s.city.zone).toSet().toList();

    Driver? selectedDriver;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Assign ${_selectedStudentIds.length} Student${_selectedStudentIds.length > 1 ? 's' : ''} to Driver'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (zones.length > 1)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Warning: Selected students are from multiple zones (${zones.join(', ')})',
                            style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Selected Students:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...selectedStudents.take(5).map((student) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('• ${student.fullName} (${student.scheduleSuffix.code})', style: const TextStyle(fontSize: 12)),
                      )),
                      if (selectedStudents.length > 5)
                        Text('... and ${selectedStudents.length - 5} more', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                const Text('Select Driver:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                ..._allDrivers.map((driver) {
                  final isCompatible = zones.length == 1 && zones.first == driver.zone;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: selectedDriver?.uid == driver.uid ? Colors.green.shade50 : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCompatible ? Colors.green : Colors.grey,
                        child: Text(driver.zone, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(driver.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Zone ${driver.zone} • ${driver.studentCount} students • ${driver.phoneNumber}'),
                      trailing: selectedDriver?.uid == driver.uid
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: () {
                        setState(() => selectedDriver = driver);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedDriver == null
                  ? null
                  : () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );

    if (result == true && selectedDriver != null) {
      try {
        await _driverService.assignStudentsToDriver(
          driverId: selectedDriver!.uid,
          studentIds: _selectedStudentIds.toList(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${_selectedStudentIds.length} student(s) assigned to ${selectedDriver!.fullName}')),
          );
          _clearSelection();
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error assigning students: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetDay = _getTargetDay();
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Assign Students to Drivers', style: TextStyle(fontSize: 18)),
            Text(
              'Showing $targetDay students ($timeStr)',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedStudentIds.isNotEmpty)
            IconButton(
              icon: Badge(
                label: Text('${_selectedStudentIds.length}'),
                child: const Icon(Icons.assignment_ind),
              ),
              onPressed: _showAssignDriverDialog,
              tooltip: 'Assign to Driver',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildDayInfoBanner(),
                _buildFiltersSection(),
                _buildSelectionBar(),
                Expanded(child: _buildStudentsTable()),
              ],
            ),
    );
  }

  Widget _buildDayInfoBanner() {
    final targetDay = _getTargetDay();
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;
    final currentTimeInMinutes = currentHour * 60 + currentMinute;
    const cutoffTimeInMinutes = 15 * 60 + 30; // 3:30 PM
    
    final isAfterCutoff = currentTimeInMinutes >= cutoffTimeInMinutes;
    
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(8),
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
              style: TextStyle(fontSize: 13, color: Colors.blue.shade900, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    final zones = _allStudents.map((s) => s.city.zone).toSet().toList()..sort();
    final schedules = _allStudents.map((s) => s.scheduleSuffix.code).toSet().toList()..sort();

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by name, phone, or university',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              _searchQuery = value;
              _applyFilters();
            },
          ),
          const SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: Text('Zone: ${_zoneFilter ?? 'All'}'),
                  selected: _zoneFilter != null,
                  onSelected: (selected) {
                    showDialog(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Select Zone'),
                        children: [
                          SimpleDialogOption(
                            child: const Text('All Zones'),
                            onPressed: () {
                              setState(() => _zoneFilter = null);
                              _applyFilters();
                              Navigator.pop(context);
                            },
                          ),
                          ...zones.map((zone) => SimpleDialogOption(
                            child: Text('Zone $zone'),
                            onPressed: () {
                              setState(() => _zoneFilter = zone);
                              _applyFilters();
                              Navigator.pop(context);
                            },
                          )),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text('Schedule: ${_scheduleFilter ?? 'All'}'),
                  selected: _scheduleFilter != null,
                  onSelected: (selected) {
                    showDialog(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Select Schedule'),
                        children: [
                          SimpleDialogOption(
                            child: const Text('All Schedules'),
                            onPressed: () {
                              setState(() => _scheduleFilter = null);
                              _applyFilters();
                              Navigator.pop(context);
                            },
                          ),
                          ...schedules.map((schedule) => SimpleDialogOption(
                            child: Text(schedule),
                            onPressed: () {
                              setState(() => _scheduleFilter = schedule);
                              _applyFilters();
                              Navigator.pop(context);
                            },
                          )),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(_activeFilter == 'active' ? 'Active' : _activeFilter == 'inactive' ? 'Inactive' : 'All Students'),
                  selected: _activeFilter != 'all',
                  onSelected: (selected) {
                    showDialog(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Filter by Status'),
                        children: [
                          SimpleDialogOption(
                            child: const Text('All Students'),
                            onPressed: () {
                              setState(() => _activeFilter = 'all');
                              _applyFilters();
                              Navigator.pop(context);
                            },
                          ),
                          SimpleDialogOption(
                            child: const Text('Active Only'),
                            onPressed: () {
                              setState(() => _activeFilter = 'active');
                              _applyFilters();
                              Navigator.pop(context);
                            },
                          ),
                          SimpleDialogOption(
                            child: const Text('Inactive Only'),
                            onPressed: () {
                              setState(() => _activeFilter = 'inactive');
                              _applyFilters();
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(_assignmentFilter == 'assigned' ? 'Assigned' : _assignmentFilter == 'unassigned' ? 'Unassigned' : 'All'),
                  selected: _assignmentFilter != null,
                  onSelected: (selected) {
                    showDialog(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Filter by Assignment'),
                        children: [
                          SimpleDialogOption(
                            child: const Text('All Students'),
                            onPressed: () {
                              setState(() => _assignmentFilter = null);
                              _applyFilters();
                              Navigator.pop(context);
                            },
                          ),
                          SimpleDialogOption(
                            child: const Text('Assigned Only'),
                            onPressed: () {
                              setState(() => _assignmentFilter = 'assigned');
                              _applyFilters();
                              Navigator.pop(context);
                            },
                          ),
                          SimpleDialogOption(
                            child: const Text('Unassigned Only'),
                            onPressed: () {
                              setState(() => _assignmentFilter = 'unassigned');
                              _applyFilters();
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_selectedStudentIds.length} of ${_filteredStudents.length} selected',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (_selectedStudentIds.isNotEmpty) ...[
            TextButton(
              onPressed: _clearSelection,
              child: const Text('Clear'),
            ),
            const SizedBox(width: 4),
          ],
          TextButton(
            onPressed: _selectAll,
            child: const Text('Select All'),
          ),
          if (_selectedStudentIds.isNotEmpty) ...[
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _showAssignDriverDialog,
              icon: const Icon(Icons.assignment_ind, size: 18),
              label: const Text('Assign'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStudentsTable() {
    if (_filteredStudents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No students found', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: true,
          headingRowColor: MaterialStateProperty.all(Colors.green.shade50),
          columns: const [
            DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('University', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Zone', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Schedule', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _filteredStudents.map((student) {
            final isSelected = _selectedStudentIds.contains(student.uid);
            final isAssigned = _allDrivers.any((driver) => driver.assignedStudentIds.contains(student.uid));
            final assignedDriver = isAssigned ? _allDrivers.firstWhere((d) => d.assignedStudentIds.contains(student.uid)) : null;

            return DataRow(
              selected: isSelected,
              onSelectChanged: (selected) {
                setState(() {
                  if (selected == true) {
                    _selectedStudentIds.add(student.uid);
                  } else {
                    _selectedStudentIds.remove(student.uid);
                  }
                });
              },
              cells: [
                DataCell(Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.w500))),
                DataCell(Text(student.phoneNumber)),
                DataCell(Text(student.university)),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(student.city.zone, style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                )),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(student.scheduleSuffix.code, style: TextStyle(color: Colors.purple.shade700, fontWeight: FontWeight.bold)),
                )),
                DataCell(
                  isAssigned
                      ? Tooltip(
                          message: 'Assigned to ${assignedDriver?.fullName}',
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green, width: 1.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle, size: 14, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  assignedDriver?.fullName ?? 'Assigned',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange, width: 1.5),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.pending, size: 14, color: Colors.orange),
                              SizedBox(width: 4),
                              Text(
                                'Unassigned',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
