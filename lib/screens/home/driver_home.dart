import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/driver_service.dart';
import '../../services/driver_wallet_service.dart';
import '../../services/student_profile_service.dart';
import '../../services/accounting_service.dart';
import '../../services/driver_payment_service.dart';
import '../../models/driver.dart';
import '../../models/student_profile.dart';
import '../auth/login_screen.dart';
import '../driver/driver_transactions_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final DriverService _driverService = DriverService();
  final DriverWalletService _walletService = DriverWalletService();
  final StudentProfileService _studentService = StudentProfileService();
  final AccountingService _accountingService = AccountingService();
  final DriverPaymentService _driverPaymentService = DriverPaymentService();
  Driver? _driverProfile;
  bool _isLoading = true;
  
  // Cached wallet data to minimize Firestore reads
  double _cachedBalanceUSD = 0.0;
  double _cachedBalanceLBP = 0.0;
  bool _isLoadingWallet = false;

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
  }

  Future<void> _loadWalletData() async {
    if (_driverProfile == null) return;
    
    setState(() => _isLoadingWallet = true);
    try {
      final wallet = await _walletService.getDriverWallet(_driverProfile!.uid);
      setState(() {
        _cachedBalanceUSD = wallet?.balanceUSD ?? 0.0;
        _cachedBalanceLBP = wallet?.balanceLBP ?? 0.0;
        _isLoadingWallet = false;
      });
    } catch (e) {
      setState(() => _isLoadingWallet = false);
    }
  }

  Future<void> _loadDriverProfile() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final drivers = await _driverService.getAllDrivers();
      final driver = drivers.firstWhere(
        (d) => d.uid == currentUser.uid,
        orElse: () => throw 'Driver profile not found',
      );

      setState(() {
        _driverProfile = driver;
        _isLoading = false;
      });
      
      // Load wallet data after profile is loaded
      _loadWalletData();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWalletData,
            tooltip: 'Refresh Wallet',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Card
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.local_shipping,
                        size: 60,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isLoading
                            ? 'Welcome, Driver!'
                            : 'Welcome, ${_driverProfile?.fullName ?? 'Driver'}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Manage your routes, students, and daily trips',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Driver Wallet Card
              _buildWalletCard(),
              const SizedBox(height: 24),

              // Student Payment Card
              _buildStudentPaymentCard(),
              const SizedBox(height: 24),

              // Driver Features Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildFeatureCard(
                    icon: Icons.wb_sunny,
                    title: 'Morning Students',
                    subtitle: 'View morning trip students',
                    color: Colors.orange,
                    onTap: () => Navigator.pushNamed(context, '/driver/my-students'),
                  ),
                  _buildFeatureCard(
                    icon: Icons.wb_twilight,
                    title: 'Afternoon Students',
                    subtitle: 'Afternoon trips (1-3 PM)',
                    color: Colors.deepPurple,
                    onTap: () => Navigator.pushNamed(context, '/driver/trip-students'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 36,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard() {
    if (_isLoading || _driverProfile == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_isLoadingWallet) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return GestureDetector(
      onLongPress: () => _showTransferDialog(_cachedBalanceUSD, _cachedBalanceLBP),
      child: Card(
        elevation: 4,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade700, Colors.green.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Wallet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Long press to transfer',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'USD Balance',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${NumberFormat('#,###').format(_cachedBalanceUSD.toInt())}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Column(
                    children: [
                      const Text(
                        'LBP Balance',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'LL${NumberFormat('#,###').format(_cachedBalanceLBP.toInt())}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut();
    
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<void> _showTransferDialog(double balanceUSD, double balanceLBP) async {
    if (_driverProfile == null) return;

    // Show options dialog
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Transfer to Admin Wallet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Balance:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey[700])),
              const SizedBox(height: 8),
              Text('USD: \$${balanceUSD.toStringAsFixed(2)}'),
              Text('LBP: LL${balanceLBP.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              const Text('Choose transfer option:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            if (balanceUSD > 0)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmTransfer('USD', balanceUSD);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Transfer USD'),
              ),
            if (balanceLBP > 0)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmTransfer('LBP', balanceLBP);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Transfer LBP'),
              ),
            if (balanceUSD > 0 && balanceLBP > 0)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmTransfer('BOTH', balanceUSD, balanceLBP);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Transfer Both'),
              ),
          ],
        );
      },
    );
  }

  Future<void> _confirmTransfer(String currency,
      [double? amountUSD, double? amountLBP]) async {
    if (_driverProfile == null) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Transfer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to transfer:'),
              const SizedBox(height: 12),
              if (currency == 'USD' || currency == 'BOTH')
                Text('USD: \$${amountUSD?.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              if (currency == 'LBP' || currency == 'BOTH')
                Text('LL${(currency == 'LBP' ? amountUSD : amountLBP)?.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('This will transfer the amount to admin wallet.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      if (currency == 'USD') {
        // Transfer USD
        await _walletService.subtractFromDriverWallet(
            _driverProfile!.uid, amountUSD!, 'USD');
        await _accountingService.addToAdminWallet(amountUSD, 'USD');
        await _accountingService.addTransaction(
          studentId: _driverProfile!.uid,
          studentName: _driverProfile!.fullName,
          amount: amountUSD,
          paymentType: 'Driver Transfer',
          subscriptionMonth: DateTime.now().month,
          subscriptionYear: DateTime.now().year,
          adminId: currentUser.uid,
          currency: 'USD',
          notes: 'Driver wallet transfer to admin',
        );
        // Record negative transaction in driver_payment_transactions
        await _driverPaymentService.addDriverPaymentTransaction(
          driverId: _driverProfile!.uid,
          driverName: _driverProfile!.fullName,
          studentId: 'ADMIN',
          studentName: 'Admin Wallet',
          amount: -amountUSD,
          currency: 'USD',
          notes: 'Transfer to admin wallet',
        );
      } else if (currency == 'LBP') {
        // Transfer LBP
        final amount = amountUSD!; // Using first parameter for single currency
        await _walletService.subtractFromDriverWallet(
            _driverProfile!.uid, amount, 'LBP');
        await _accountingService.addToAdminWallet(amount, 'LBP');
        await _accountingService.addTransaction(
          studentId: _driverProfile!.uid,
          studentName: _driverProfile!.fullName,
          amount: amount,
          paymentType: 'Driver Transfer',
          subscriptionMonth: DateTime.now().month,
          subscriptionYear: DateTime.now().year,
          adminId: currentUser.uid,
          currency: 'LBP',
          notes: 'Driver wallet transfer to admin',
        );
        // Record negative transaction in driver_payment_transactions
        await _driverPaymentService.addDriverPaymentTransaction(
          driverId: _driverProfile!.uid,
          driverName: _driverProfile!.fullName,
          studentId: 'ADMIN',
          studentName: 'Admin Wallet',
          amount: -amount,
          currency: 'LBP',
          notes: 'Transfer to admin wallet',
        );
      } else if (currency == 'BOTH') {
        // Transfer both USD and LBP
        if (amountUSD != null && amountUSD > 0) {
          await _walletService.subtractFromDriverWallet(
              _driverProfile!.uid, amountUSD, 'USD');
          await _accountingService.addToAdminWallet(amountUSD, 'USD');
          await _accountingService.addTransaction(
            studentId: _driverProfile!.uid,
            studentName: _driverProfile!.fullName,
            amount: amountUSD,
            paymentType: 'Driver Transfer',
            subscriptionMonth: DateTime.now().month,
            subscriptionYear: DateTime.now().year,
            adminId: currentUser.uid,
            currency: 'USD',
            notes: 'Driver wallet transfer to admin',
          );
          // Record negative transaction in driver_payment_transactions
          await _driverPaymentService.addDriverPaymentTransaction(
            driverId: _driverProfile!.uid,
            driverName: _driverProfile!.fullName,
            studentId: 'ADMIN',
            studentName: 'Admin Wallet',
            amount: -amountUSD,
            currency: 'USD',
            notes: 'Transfer to admin wallet',
          );
        }
        if (amountLBP != null && amountLBP > 0) {
          await _walletService.subtractFromDriverWallet(
              _driverProfile!.uid, amountLBP, 'LBP');
          await _accountingService.addToAdminWallet(amountLBP, 'LBP');
          await _accountingService.addTransaction(
            studentId: _driverProfile!.uid,
            studentName: _driverProfile!.fullName,
            amount: amountLBP,
            paymentType: 'Driver Transfer',
            subscriptionMonth: DateTime.now().month,
            subscriptionYear: DateTime.now().year,
            adminId: currentUser.uid,
            currency: 'LBP',
            notes: 'Driver wallet transfer to admin',
          );
          // Record negative transaction in driver_payment_transactions
          await _driverPaymentService.addDriverPaymentTransaction(
            driverId: _driverProfile!.uid,
            driverName: _driverProfile!.fullName,
            studentId: 'ADMIN',
            studentName: 'Admin Wallet',
            amount: -amountLBP,
            currency: 'LBP',
            notes: 'Transfer to admin wallet',
          );
        }
      }

      if (mounted) {
        // Refresh wallet data after transfer
        _loadWalletData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transfer completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transfer failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStudentPaymentCard() {
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_add,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Record Student Payment',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Record daily student payments directly to your wallet',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showStudentPaymentDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'Add Payment',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DriverTransactionsScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.list),
                  label: const Text(
                    'View',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showStudentPaymentDialog() async {
    if (_driverProfile == null) return;

    final TextEditingController amountController = TextEditingController();
    String? selectedStudentId;
    StudentProfile? selectedStudent;
    String selectedCurrency = 'USD';
    List<StudentProfile> students = [];

    // Function to format number with thousand separators
    String _formatNumber(String text) {
      if (text.isEmpty) return '';
      
      // Remove all non-digit characters except decimal point
      String cleanText = text.replaceAll(RegExp(r'[^\d.]'), '');
      
      // Split by decimal point
      List<String> parts = cleanText.split('.');
      String integerPart = parts[0];
      
      // Format integer part with thousand separators
      if (integerPart.isNotEmpty) {
        final number = int.tryParse(integerPart);
        if (number != null) {
          integerPart = NumberFormat('#,###').format(number);
        }
      }
      
      // Combine with decimal part if exists
      if (parts.length > 1) {
        return '$integerPart.${parts[1]}';
      }
      return integerPart;
    }

    // Load students
    try {
      students = await _studentService.getAllStudents();
    } catch (e) {
      // Error will be shown in dialog
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Record Student Payment'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Student Selector
                    const Text(
                      'Select Student',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.person_search,
                          color: Colors.blue.shade700,
                        ),
                        title: Text(
                          selectedStudent?.fullName ?? 'Choose a student...',
                          style: TextStyle(
                            color: selectedStudent != null
                                ? Colors.black87
                                : Colors.grey.shade600,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_drop_down),
                        onTap: () async {
                          final selected = await showSearch(
                            context: context,
                            delegate: StudentSearchDelegate(students),
                          );
                          if (selected != null) {
                            setDialogState(() {
                              selectedStudentId = selected.uid;
                              selectedStudent = selected;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amount Field
                    const Text(
                      'Daily Payment Amount',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'Enter amount',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixText: selectedCurrency == 'USD' ? '\$ ' : 'LL ',
                      ),
                      onChanged: (value) {
                        // Format the input with thousand separators
                        String formatted = _formatNumber(value);
                        if (formatted != value) {
                          amountController.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(offset: formatted.length),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Currency Selector
                    const Text(
                      'Currency',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('USD'),
                            value: 'USD',
                            groupValue: selectedCurrency,
                            onChanged: (value) {
                              setDialogState(
                                () => selectedCurrency = value ?? 'USD',
                              );
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('LBP'),
                            value: 'LBP',
                            groupValue: selectedCurrency,
                            onChanged: (value) {
                              setDialogState(
                                () => selectedCurrency = value ?? 'USD',
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedStudentId == null ||
                        selectedStudent == null ||
                        amountController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      // Remove commas before parsing
                      final cleanAmount = amountController.text.replaceAll(',', '');
                      final amount = double.parse(cleanAmount);

                      // Add payment to driver wallet only
                      await _walletService.addToDriverWallet(
                        _driverProfile!.uid,
                        amount,
                        selectedCurrency,
                      );

                      // Record transaction in driver_payment_transactions
                      await _driverPaymentService.addDriverPaymentTransaction(
                        driverId: _driverProfile!.uid,
                        driverName: _driverProfile!.fullName,
                        studentId: selectedStudent!.uid,
                        studentName: selectedStudent!.fullName,
                        amount: amount,
                        currency: selectedCurrency,
                        notes: 'Daily student payment',
                      );

                      if (context.mounted) {
                        // Refresh wallet data after payment
                        _loadWalletData();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Payment from ${selectedStudent!.fullName} recorded: ${selectedCurrency == 'USD' ? '\$' : 'LL'}$amount',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error recording payment: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Record Payment'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// Student Search Delegate for modern search functionality
class StudentSearchDelegate extends SearchDelegate<StudentProfile?> {
  final List<StudentProfile> students;

  StudentSearchDelegate(this.students);

  @override
  String get searchFieldLabel => 'Search students...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          color: Colors.white,
          fontSize: 18,
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = students.where((student) {
      return student.fullName.toLowerCase().contains(query.toLowerCase()) ||
          student.university.toLowerCase().contains(query.toLowerCase()) ||
          student.phoneNumber.contains(query);
    }).toList();

    return _buildStudentList(results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty
        ? students
        : students.where((student) {
            return student.fullName.toLowerCase().contains(query.toLowerCase()) ||
                student.university.toLowerCase().contains(query.toLowerCase()) ||
                student.phoneNumber.contains(query);
          }).toList();

    return _buildStudentList(suggestions);
  }

  Widget _buildStudentList(List<StudentProfile> studentList) {
    if (studentList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No students found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: studentList.length,
      itemBuilder: (context, index) {
        final student = studentList[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Text(
              student.fullName.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            student.fullName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                student.university,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                student.phoneNumber,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey.shade400,
          ),
          onTap: () {
            close(context, student);
          },
        );
      },
    );
  }
}
