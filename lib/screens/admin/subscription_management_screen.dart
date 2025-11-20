import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/student_profile.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() => _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState extends State<SubscriptionManagementScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  
  late TabController _tabController;
  
  // Schedule Suffixes
  List<ScheduleSuffix> _schedules = [];
  bool _isLoadingSchedules = true;
  
  // Cities
  List<City> _cities = [];
  bool _isLoadingCities = true;
  
  // Form controllers for Schedules
  final _codeController = TextEditingController();
  final _zoneController = TextEditingController();
  final _daysController = TextEditingController();
  final _dailyCostController = TextEditingController();
  final _monthlyCostController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Form controllers for Cities
  final _cityNameController = TextEditingController();
  final _cityZoneController = TextEditingController();
  
  String? _editingScheduleId;
  String? _editingCityId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSchedules();
    _loadCities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    _zoneController.dispose();
    _daysController.dispose();
    _dailyCostController.dispose();
    _monthlyCostController.dispose();
    _descriptionController.dispose();
    _cityNameController.dispose();
    _cityZoneController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedules() async {
    try {
      setState(() => _isLoadingSchedules = true);
      
      final snapshot = await _firestore
          .collection('schedule_suffixes')
          .orderBy('code')
          .get();
      
      setState(() {
        _schedules = snapshot.docs
            .map((doc) => ScheduleSuffix.fromFirestore(doc))
            .toList();
        _isLoadingSchedules = false;
      });
    } catch (e) {
      setState(() => _isLoadingSchedules = false);
      _showSnackBar('Error loading schedules: $e', Colors.red);
    }
  }

  Future<void> _loadCities() async {
    try {
      setState(() => _isLoadingCities = true);
      
      final snapshot = await _firestore
          .collection('cities')
          .orderBy('zone')
          .orderBy('name')
          .get();
      
      setState(() {
        _cities = snapshot.docs
            .map((doc) => City.fromFirestore(doc))
            .toList();
        _isLoadingCities = false;
      });
    } catch (e) {
      setState(() => _isLoadingCities = false);
      _showSnackBar('Error loading cities: $e', Colors.red);
    }
  }

  void _clearForm() {
    _codeController.clear();
    _zoneController.clear();
    _daysController.clear();
    _dailyCostController.clear();
    _monthlyCostController.clear();
    _descriptionController.clear();
    _cityNameController.clear();
    _cityZoneController.clear();
    _editingScheduleId = null;
    _editingCityId = null;
  }

  void _fillFormForEdit(ScheduleSuffix schedule) {
    _codeController.text = schedule.code;
    _zoneController.text = schedule.zone;
    _daysController.text = schedule.daysPerWeek.toString();
    _dailyCostController.text = schedule.dailyCost.toStringAsFixed(2);
    _monthlyCostController.text = schedule.monthlyCost.toStringAsFixed(2);
    _descriptionController.text = schedule.description;
    _editingScheduleId = schedule.id;
  }

  void _fillCityFormForEdit(City city) {
    _cityNameController.text = city.name;
    _cityZoneController.text = city.zone;
    _editingCityId = city.id;
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final data = {
        'code': _codeController.text.trim(),
        'zone': _zoneController.text.trim().toUpperCase(),
        'daysPerWeek': int.parse(_daysController.text.trim()),
        'dailyCost': double.parse(_dailyCostController.text.trim()),
        'monthlyCost': double.parse(_monthlyCostController.text.trim()),
        'description': _descriptionController.text.trim(),
      };

      if (_editingScheduleId != null) {
        // Update existing
        await _firestore
            .collection('schedule_suffixes')
            .doc(_editingScheduleId)
            .update(data);
        _showSnackBar('Schedule updated successfully!', Colors.green);
      } else {
        // Create new
        await _firestore
            .collection('schedule_suffixes')
            .add(data);
        _showSnackBar('Schedule created successfully!', Colors.green);
      }

      _clearForm();
      _loadSchedules();
      Navigator.pop(context); // Close dialog
    } catch (e) {
      _showSnackBar('Error saving schedule: $e', Colors.red);
    }
  }

  Future<void> _deleteSchedule(ScheduleSuffix schedule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: Text('Are you sure you want to delete "${schedule.code}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore
            .collection('schedule_suffixes')
            .doc(schedule.id)
            .delete();
        
        _showSnackBar('Schedule deleted successfully!', Colors.green);
        _loadSchedules();
      } catch (e) {
        _showSnackBar('Error deleting schedule: $e', Colors.red);
      }
    }
  }

  Future<void> _saveCity() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final data = {
        'name': _cityNameController.text.trim(),
        'zone': _cityZoneController.text.trim().toUpperCase(),
      };

      if (_editingCityId != null) {
        // Update existing
        await _firestore
            .collection('cities')
            .doc(_editingCityId)
            .update(data);
        _showSnackBar('City updated successfully!', Colors.green);
      } else {
        // Create new
        await _firestore
            .collection('cities')
            .add(data);
        _showSnackBar('City created successfully!', Colors.green);
      }

      _clearForm();
      _loadCities();
      Navigator.pop(context); // Close dialog
    } catch (e) {
      _showSnackBar('Error saving city: $e', Colors.red);
    }
  }

  Future<void> _deleteCity(City city) async {
    try {
      // Check if any students are using this city
      final studentsSnapshot = await _firestore
          .collection('student_profiles')
          .where('cityId', isEqualTo: city.id)
          .get();
      
      // Check if any drivers are using this city
      final driversSnapshot = await _firestore
          .collection('drivers')
          .where('cityId', isEqualTo: city.id)
          .get();
      
      final studentCount = studentsSnapshot.docs.length;
      final driverCount = driversSnapshot.docs.length;
      
      if (studentCount > 0 || driverCount > 0) {
        // Show warning dialog with option to force delete
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('City In Use'),
            content: Text(
              'This city is currently assigned to:\n'
              '• $studentCount ${studentCount == 1 ? 'student' : 'students'}\n'
              '• $driverCount ${driverCount == 1 ? 'driver' : 'drivers'}\n\n'
              'If you delete this city, it will be removed from all students and drivers.\n\n'
              'Are you sure you want to continue?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete Anyway'),
              ),
            ],
          ),
        );
        
        if (confirm != true) return;
      } else {
        // No students/drivers using this city, show simple confirmation
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete City'),
            content: Text('Are you sure you want to delete "${city.name}"?\n\nThis action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        
        if (confirm != true) return;
      }
      
      // Delete the city
      await _firestore
          .collection('cities')
          .doc(city.id)
          .delete();
      
      // Remove city reference from all students
      final batch = _firestore.batch();
      for (var doc in studentsSnapshot.docs) {
        batch.update(doc.reference, {
          'cityId': '',
          'cityName': '',
          'cityZone': 'A',
        });
      }
      
      // Remove city reference from all drivers
      for (var doc in driversSnapshot.docs) {
        batch.update(doc.reference, {
          'cityId': '',
        });
      }
      
      await batch.commit();
      
      _showSnackBar(
        'City deleted and removed from ${studentCount + driverCount} ${(studentCount + driverCount) == 1 ? 'record' : 'records'}',
        Colors.green,
      );
      _loadCities();
    } catch (e) {
      _showSnackBar('Error deleting city: $e', Colors.red);
    }
  }

  void _showCityDialog({City? city}) {
    if (city != null) {
      _fillCityFormForEdit(city);
    } else {
      _clearForm();
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  city != null ? 'Edit City' : 'Add New City',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                
                // City Name
                TextFormField(
                  controller: _cityNameController,
                  decoration: const InputDecoration(
                    labelText: 'City Name *',
                    hintText: 'e.g., Beirut, Tripoli',
                    prefixIcon: Icon(Icons.location_city),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter city name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Zone
                TextFormField(
                  controller: _cityZoneController,
                  decoration: const InputDecoration(
                    labelText: 'Zone *',
                    hintText: 'A, B, C, or D',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 1,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a zone';
                    }
                    if (!['A', 'B', 'C', 'D'].contains(value.trim().toUpperCase())) {
                      return 'Zone must be A, B, C, or D';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _clearForm();
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveCity,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(city != null ? 'Update' : 'Create'),
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

  void _showScheduleDialog({ScheduleSuffix? schedule}) {
    if (schedule != null) {
      _fillFormForEdit(schedule);
    } else {
      _clearForm();
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    schedule != null ? 'Edit Schedule' : 'Add New Schedule',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  
                  // Code
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Code *',
                      hintText: 'e.g., A1, B2, C3',
                      prefixIcon: Icon(Icons.code),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a code';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Zone
                  TextFormField(
                    controller: _zoneController,
                    decoration: const InputDecoration(
                      labelText: 'Zone *',
                      hintText: 'A, B, C, or D',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 1,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a zone';
                      }
                      if (!['A', 'B', 'C', 'D'].contains(value.trim().toUpperCase())) {
                        return 'Zone must be A, B, C, or D';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Days per week
                  TextFormField(
                    controller: _daysController,
                    decoration: const InputDecoration(
                      labelText: 'Days Per Week *',
                      hintText: '1 to 5',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter days per week';
                      }
                      final days = int.tryParse(value.trim());
                      if (days == null || days < 1 || days > 5) {
                        return 'Days must be between 1 and 5';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _dailyCostController,
                          decoration: const InputDecoration(
                            labelText: 'Daily Cost *',
                            hintText: '0.00',
                            prefixIcon: Icon(Icons.attach_money),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            final cost = double.tryParse(value.trim());
                            if (cost == null || cost < 0) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _monthlyCostController,
                          decoration: const InputDecoration(
                            labelText: 'Monthly Cost *',
                            hintText: '0.00',
                            prefixIcon: Icon(Icons.attach_money),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            final cost = double.tryParse(value.trim());
                            if (cost == null || cost < 0) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      hintText: 'Describe the schedule',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _clearForm();
                            Navigator.pop(context);
                          },
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveSchedule,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(schedule != null ? 'Update' : 'Create'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Management'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadSchedules();
              _loadCities();
            },
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.schedule), text: 'Schedules'),
            Tab(icon: Icon(Icons.location_city), text: 'Cities'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSchedulesTab(),
          _buildCitiesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showScheduleDialog();
          } else {
            _showCityDialog();
          }
        },
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Add Schedule' : 'Add City'),
      ),
    );
  }

  Widget _buildSchedulesTab() {
    if (_isLoadingSchedules) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_schedules.isEmpty) {
      return _buildEmptyState('No Schedules Found', 'Add your first schedule to get started', Icons.schedule);
    }
    
    return _buildSchedulesList();
  }

  Widget _buildCitiesTab() {
    if (_isLoadingCities) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_cities.isEmpty) {
      return _buildEmptyState('No Cities Found', 'Add your first city to get started', Icons.location_city);
    }
    
    return _buildCitiesList();
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 20, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _schedules.length,
      itemBuilder: (context, index) {
        final schedule = _schedules[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Text(
                        schedule.code,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Zone ${schedule.zone}',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showScheduleDialog(schedule: schedule),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteSchedule(schedule),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  schedule.description,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        Icons.calendar_today,
                        '${schedule.daysPerWeek} ${schedule.daysPerWeek == 1 ? 'day' : 'days'}/week',
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        Icons.attach_money,
                        '\$${schedule.dailyCost.toStringAsFixed(2)}/day',
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        Icons.monetization_on,
                        '\$${schedule.monthlyCost.toStringAsFixed(2)}/month',
                        Colors.teal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCitiesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cities.length,
      itemBuilder: (context, index) {
        final city = _cities[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Icon(Icons.location_city, color: Colors.blue.shade700),
            ),
            title: Text(
              city.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Zone ${city.zone}', style: const TextStyle(fontSize: 14)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    'Zone ${city.zone}',
                    style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showCityDialog(city: city),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteCity(city),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
