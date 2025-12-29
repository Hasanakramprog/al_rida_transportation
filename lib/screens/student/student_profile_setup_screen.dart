import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/student_profile_service.dart';
import '../../models/student_profile.dart';
import 'week_calendar_screen.dart';

class StudentProfileSetupScreen extends StatefulWidget {
  const StudentProfileSetupScreen({super.key});

  @override
  State<StudentProfileSetupScreen> createState() =>
      _StudentProfileSetupScreenState();
}

class _StudentProfileSetupScreenState extends State<StudentProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = StudentProfileService();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  SubscriptionType _selectedSubscription = SubscriptionType.monthly;
  ScheduleSuffix? _selectedSchedule;
  City? _selectedCity;
  String? _selectedUniversity;
  List<ScheduleSuffix> _availableSchedules = [];
  List<City> _availableCities = [];
  Map<String, List<City>> _allCitiesByZone = {};
  bool _isLoading = false;
  bool _loadingCities = false;
  bool _loadingSchedules = true;
  bool _loadingAllCities = true;

  // Hardcoded university list
  final List<String> _universities = [
    'Cairo University',
    'Alexandria University',
    'Ain Shams University',
    'American University in Cairo (AUC)',
    'German University in Cairo (GUC)',
    'British University in Egypt (BUE)',
    'Modern Sciences and Arts University (MSA)',
    'Helwan University',
    'Zagazig University',
    'Mansoura University',
    'Assiut University',
    'Tanta University',
    'Benha University',
    'Minia University',
    'Fayoum University',
    'Beni-Suef University',
    'Suez Canal University',
    'South Valley University',
    'Menoufia University',
    'Damanhour University',
    'Port Said University',
    'Arish University',
    'New Valley University',
    'Matrouh University',
    'Other University',
  ];

  String? get _costDescription {
    if (_selectedSchedule == null) return null;
    return SubscriptionPricing.getCostDescription(
      subscriptionType: _selectedSubscription,
      scheduleSuffix: _selectedSchedule!,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadScheduleSuffixes();
    _loadAllCities();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadScheduleSuffixes() async {
    try {
      final schedules = await _profileService.getScheduleSuffixes();
      if (mounted) {
        setState(() {
          _availableSchedules = schedules;
          _loadingSchedules = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingSchedules = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading schedules: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadAllCities() async {
    try {
      final allCities = await _profileService.getAllCities();
      if (mounted) {
        setState(() {
          _allCitiesByZone = _groupCitiesByZone(allCities);
          _loadingAllCities = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingAllCities = false;
        });
        // Silently fail for cities info, it's not critical for form function
      }
    }
  }

  Map<String, List<City>> _groupCitiesByZone(List<City> cities) {
    final Map<String, List<City>> grouped = {};
    for (final city in cities) {
      if (!grouped.containsKey(city.zone)) {
        grouped[city.zone] = [];
      }
      grouped[city.zone]!.add(city);
    }
    return grouped;
  }

  Future<void> _onScheduleChanged(ScheduleSuffix? schedule) async {
    if (schedule == null) return;

    setState(() {
      _selectedSchedule = schedule;
      _selectedCity = null; // Reset city when schedule changes
      _loadingCities = true;
    });

    try {
      final cities = await _profileService.getCitiesByZone(schedule.zone);
      if (mounted) {
        setState(() {
          _availableCities = cities;
          _loadingCities = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _availableCities = [];
          _loadingCities = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading cities: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fullNameController.text.trim().isEmpty) {
      _showSnackBar('Please enter your full name', Colors.orange);
      return;
    }
    if (_selectedUniversity == null) {
      _showSnackBar('Please select a university', Colors.orange);
      return;
    }
    if (_selectedSchedule == null) {
      _showSnackBar('Please select a schedule suffix', Colors.orange);
      return;
    }
    if (_selectedCity == null) {
      _showSnackBar('Please select a city', Colors.orange);
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showSnackBar('Please enter your phone number', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;

      if (user == null) {
        throw 'User not found';
      }

      // Format phone number with +961 prefix
      String formattedPhone = _phoneController.text.trim().replaceAll(
        RegExp(r'[\s\-\(\)]'),
        '',
      );
      // Remove leading 0 if present
      if (formattedPhone.startsWith('0')) {
        formattedPhone = formattedPhone.substring(1);
      }
      // Add +961 prefix
      formattedPhone = '+961$formattedPhone';

      final profile = StudentProfile(
        uid: user.uid,
        fullName: _fullNameController.text.trim(),
        university: _selectedUniversity!,
        phoneNumber: formattedPhone,
        subscriptionType: _selectedSubscription,
        scheduleSuffix: _selectedSchedule!,
        city: _selectedCity!,
        selectedDays: [], // Will be filled in calendar screen
        dayTimeSlots: {}, // Will be filled in calendar screen
        paymentAmount: 0.0, // Default unpaid
        isPaid: false, // Default unpaid
        createdAt: DateTime.now(),
      );

      // Don't save to database yet - save in calendar screen

      if (mounted) {
        _showSnackBar('Profile completed! Now select your days.', Colors.green);

        // Navigate to calendar screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => WeekCalendarScreen(studentProfile: profile),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error saving profile: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Prevent going back
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colorScheme.primary.withOpacity(0.05), Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.2),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.person_add_rounded,
                      size: 48,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Student Profile Setup',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Please provide your information',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),

                  // Full Name Field
                  TextFormField(
                    controller: _fullNameController,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Enter your full name',
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your full name';
                      }
                      if (value.trim().length < 3) {
                        return 'Name must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // University Dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'University Name',
                      prefixIcon: Icon(
                        Icons.school_outlined,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    isExpanded: true,
                    value: _selectedUniversity,
                    items: _universities.map((university) {
                      return DropdownMenuItem<String>(
                        value: university,
                        child: Text(
                          university,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUniversity = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select your university';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phone Number Field
                  TextFormField(
                    controller: _phoneController,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      labelText: 'Lebanese Phone Number',
                      hintText: 'e.g. 70 123 456',
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      prefixText: '+961 ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your phone number';
                      }

                      // Remove spaces, hyphens, and parentheses for validation
                      final cleanPhone = value.trim().replaceAll(
                        RegExp(r'[\s\-\(\)]'),
                        '',
                      );

                      // Lebanese mobile number patterns: 03, 70, 71, 76, 78, 79, 81 + 6 digits (total 8 digits)
                      final lebanonMobileRegex = RegExp(
                        r'^(0?3|0?70|0?71|0?76|0?78|0?79|0?81)[0-9]{6}$',
                      );

                      if (!lebanonMobileRegex.hasMatch(cleanPhone)) {
                        return 'Enter valid Lebanese mobile (e.g. 70 123 456)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Subscription Type
                  Text(
                    'Subscription Type',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      color: Colors.grey.shade50,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: RadioListTile<SubscriptionType>(
                            title: const Text(
                              'Monthly',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: const Text(
                              '15% discount',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: SubscriptionType.monthly,
                            groupValue: _selectedSubscription,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedSubscription = value);
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<SubscriptionType>(
                            title: const Text(
                              'Daily',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: const Text(
                              'Pay per day',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: SubscriptionType.daily,
                            groupValue: _selectedSubscription,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedSubscription = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Schedule Suffix Dropdown
                  if (_loadingSchedules)
                    const Center(child: CircularProgressIndicator())
                  else
                    DropdownButtonFormField<ScheduleSuffix>(
                      decoration: InputDecoration(
                        labelText: 'Schedule Suffix',
                        prefixIcon: Icon(
                          Icons.schedule_outlined,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      value: _selectedSchedule,
                      items: _availableSchedules.map((suffix) {
                        return DropdownMenuItem(
                          value: suffix,
                          child: Text(
                            '${suffix.code} (${suffix.daysPerWeek} ${suffix.daysPerWeek == 1 ? 'day' : 'days'}/week)',
                            style: const TextStyle(fontSize: 15),
                          ),
                        );
                      }).toList(),
                      onChanged: _onScheduleChanged,
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a schedule suffix';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 12),

                  // Cost Display
                  if (_costDescription != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary.withOpacity(0.1),
                            colorScheme.primary.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.payments_outlined,
                                color: colorScheme.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Subscription Cost',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _costDescription!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_selectedSchedule?.displayName} • Zone ${_selectedSchedule?.zone}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // City Dropdown
                  DropdownButtonFormField<City>(
                    decoration: InputDecoration(
                      labelText: 'City',
                      prefixIcon: Icon(
                        Icons.location_city_outlined,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      suffixIcon: _loadingCities
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : null,
                    ),
                    value: _selectedCity,
                    items: _availableCities.map((city) {
                      return DropdownMenuItem(
                        value: city,
                        child: Text(
                          '${city.name} (Zone ${city.zone})',
                          style: const TextStyle(fontSize: 15),
                        ),
                      );
                    }).toList(),
                    onChanged: _selectedSchedule == null
                        ? null
                        : (city) {
                            setState(() => _selectedCity = city);
                          },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a city';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  if (_selectedSchedule != null &&
                      _availableCities.isEmpty &&
                      !_loadingCities)
                    Text(
                      'No cities available for selected zone',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_forward, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Continue to Day Selection',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  // Schedule Suffix Information
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Schedule Suffix & Cities Information:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_loadingAllCities)
                          const Text(
                            'Loading cities information...',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          )
                        else if (_allCitiesByZone.isNotEmpty) ...[
                          ...['A', 'B', 'C', 'D'].map((zone) {
                            final cities = _allCitiesByZone[zone] ?? [];
                            final cityNames = cities
                                .map((city) => city.name)
                                .join(', ');
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                '• Zone $zone (${zone}1-${zone}5): ${cityNames.isNotEmpty ? cityNames : 'No cities'}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }),
                        ] else
                          const Text(
                            'Cities information will be loaded from database',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          'Select your schedule suffix (zone + days per week) to see available cities',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
