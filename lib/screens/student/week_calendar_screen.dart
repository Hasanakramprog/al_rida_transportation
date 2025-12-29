import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/student_profile.dart';
import '../../models/bus_booking.dart'; // For TimeSlot enum
import '../../services/auth_service.dart';
import '../../services/student_profile_service.dart';
import '../home/student_home.dart';

class WeekCalendarScreen extends StatefulWidget {
  final StudentProfile studentProfile;

  const WeekCalendarScreen({super.key, required this.studentProfile});

  @override
  State<WeekCalendarScreen> createState() => _WeekCalendarScreenState();
}

class _WeekCalendarScreenState extends State<WeekCalendarScreen> {
  final _profileService = StudentProfileService();

  final List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  Set<String> _selectedDays = {};
  Map<String, TimeSlot> _dayTimeSlots = {};
  bool _isLoading = false;

  int get _maxSelectableDays {
    // Extract the number from suffix code (e.g., A1 -> 1, A5 -> 5)
    final suffixCode = widget.studentProfile.scheduleSuffix.code;
    final lastChar = suffixCode.substring(suffixCode.length - 1);
    return int.tryParse(lastChar) ?? 1;
  }

  String get _costDescription {
    return SubscriptionPricing.getCostDescription(
      subscriptionType: widget.studentProfile.subscriptionType,
      scheduleSuffix: widget.studentProfile.scheduleSuffix,
    );
  }

  void _onDayToggled(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
        _dayTimeSlots.remove(day); // Remove time slot when day is unselected
      } else {
        if (_selectedDays.length < _maxSelectableDays) {
          _selectedDays.add(day);
          _dayTimeSlots[day] = TimeSlot.onepm; // Default time slot
        } else {
          // Show message that max days reached
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You can only select $_maxSelectableDays ${_maxSelectableDays == 1 ? 'day' : 'days'} per week',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }

  void _onTimeSlotChanged(String day, TimeSlot timeSlot) {
    setState(() {
      _dayTimeSlots[day] = timeSlot;
    });
  }

  Future<void> _completeBooking() async {
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if all selected days have time slots assigned
    for (String day in _selectedDays) {
      if (!_dayTimeSlots.containsKey(day)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a time slot for $day'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;

      if (user == null) {
        throw 'User not found';
      }

      // Update student profile with selected days and their time slots
      final updatedProfile = widget.studentProfile.copyWith(
        selectedDays: _selectedDays.toList(),
        dayTimeSlots: _dayTimeSlots,
        paymentAmount: 0.0, // Default to zero as requested
        isPaid: false,
        updatedAt: DateTime.now(),
      );

      // Save only the updated student profile
      await _profileService.saveStudentProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to student home
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const StudentHomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Days'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Icon(Icons.calendar_month, size: 80, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                'Choose Your Bus Days & Times',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select up to $_maxSelectableDays ${_maxSelectableDays == 1 ? 'day' : 'days'} per week and choose a time for each day',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // Days Selection
              const Text(
                'Select Days:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildDaySelectionGrid(),
              const SizedBox(height: 32),

              // Time Slots for Selected Days
              if (_selectedDays.isNotEmpty) ...[
                const Text(
                  'Select Time for Each Day:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildTimeSlotSelection(),
                const SizedBox(height: 32),
              ],

              // Profile Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Profile Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'University',
                      widget.studentProfile.university,
                    ),
                    _buildInfoRow('Phone', widget.studentProfile.phoneNumber),
                    _buildInfoRow(
                      'Schedule',
                      '${widget.studentProfile.scheduleSuffix.displayName} (${widget.studentProfile.scheduleSuffix.code})',
                    ),
                    _buildInfoRow(
                      'City',
                      '${widget.studentProfile.city.name} (Zone ${widget.studentProfile.city.zone})',
                    ),
                    _buildInfoRow(
                      'Subscription',
                      '${widget.studentProfile.subscriptionType.name.toUpperCase()} - $_costDescription',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // // Day Selection
              // const Text(
              //   'Select Your Dayss',
              //   style: TextStyle(
              //     fontSize: 18,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
              // const SizedBox(height: 16),
              // GridView.builder(
              //   shrinkWrap: true,
              //   physics: const NeverScrollableScrollPhysics(),
              //   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              //     crossAxisCount: 2,
              //     childAspectRatio: 2.5,
              //     crossAxisSpacing: 12,
              //     mainAxisSpacing: 12,
              //   ),
              //   itemCount: _weekDays.length,
              //   itemBuilder: (context, index) {
              //     final day = _weekDays[index];
              //     final isSelected = _selectedDays.contains(day);
              //     final canSelect = _selectedDays.length < _maxSelectableDays;

              //     return InkWell(
              //       onTap: () => _onDayToggled(day),
              //       child: Container(
              //         decoration: BoxDecoration(
              //           color: isSelected
              //               ? Colors.blue
              //               : canSelect || isSelected
              //                   ? Colors.white
              //                   : Colors.grey.shade100,
              //           border: Border.all(
              //             color: isSelected
              //                 ? Colors.blue
              //                 : canSelect || isSelected
              //                     ? Colors.blue.shade300
              //                     : Colors.grey.shade300,
              //             width: 2,
              //           ),
              //           borderRadius: BorderRadius.circular(8),
              //         ),
              //         child: Center(
              //           child: Text(
              //             day,
              //             style: TextStyle(
              //               color: isSelected
              //                   ? Colors.white
              //                   : canSelect || isSelected
              //                       ? Colors.blue
              //                       : Colors.grey,
              //               fontWeight: FontWeight.w500,
              //               fontSize: 16,
              //             ),
              //           ),
              //         ),
              //       ),
              //     );
              //   },
              // ),
              const SizedBox(height: 24),

              // Selected Days Display
              if (_selectedDays.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected Days:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedDays.join(', '),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Complete Booking Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      _isLoading ||
                          _selectedDays.isEmpty ||
                          !_selectedDays.every(
                            (day) => _dayTimeSlots.containsKey(day),
                          )
                      ? null
                      : _completeBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Complete Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Instructions
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Instructions:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '• Select up to $_maxSelectableDays ${_maxSelectableDays == 1 ? 'day' : 'days'} based on your ${widget.studentProfile.scheduleSuffix.code} plan',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const Text(
                      '• Choose your preferred time slot (1 PM or 3 PM)',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const Text(
                      '• Payment status will be set to unpaid by default',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const Text(
                      '• You can modify your booking later from your profile',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Bottom padding for safe scrolling
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelectionGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: _weekDays.length,
      itemBuilder: (context, index) {
        final day = _weekDays[index];
        final isSelected = _selectedDays.contains(day);

        return InkWell(
          onTap: () => _onDayToggled(day),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeSlotSelection() {
    return Column(
      children: _selectedDays.map((day) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                day,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: TimeSlot.values.map((timeSlot) {
                  final isSelected = _dayTimeSlots[day] == timeSlot;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () => _onTimeSlotChanged(day, timeSlot),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            timeSlot.displayName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
