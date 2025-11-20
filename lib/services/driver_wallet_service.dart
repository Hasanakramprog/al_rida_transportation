import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/driver_wallet.dart';

class DriverWalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _walletsCollection = 'driver_wallets';

  // Create wallet when driver is registered
  Future<void> createDriverWallet(String driverId) async {
    try {
      await _firestore.collection(_walletsCollection).doc(driverId).set({
        'driverId': driverId,
        'balanceUSD': 0.0,
        'balanceLBP': 0.0,
        'transactionsUSD': 0,
        'transactionsLBP': 0,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to create driver wallet: $e');
    }
  }

  // Get driver wallet
  Future<DriverWallet?> getDriverWallet(String driverId) async {
    try {
      final doc = await _firestore.collection(_walletsCollection).doc(driverId).get();

      if (!doc.exists) {
        return null;
      }

      return DriverWallet.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get driver wallet: $e');
    }
  }

  // Add amount to driver wallet (for operating payments)
  Future<void> addToDriverWallet(String driverId, double amount, String currency) async {
    try {
      final docRef = _firestore.collection(_walletsCollection).doc(driverId);

      if (currency == 'USD') {
        await docRef.set({
          'driverId': driverId,
          'balanceUSD': FieldValue.increment(amount),
          'transactionsUSD': FieldValue.increment(1),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else if (currency == 'LBP') {
        await docRef.set({
          'driverId': driverId,
          'balanceLBP': FieldValue.increment(amount),
          'transactionsLBP': FieldValue.increment(1),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        throw Exception('Invalid currency: $currency');
      }
    } catch (e) {
      throw Exception('Failed to add amount to driver wallet: $e');
    }
  }

  // Subtract amount from driver wallet (for payments out)
  Future<void> subtractFromDriverWallet(String driverId, double amount, String currency) async {
    try {
      final docRef = _firestore.collection(_walletsCollection).doc(driverId);

      if (currency == 'USD') {
        await docRef.update({
          'balanceUSD': FieldValue.increment(-amount),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else if (currency == 'LBP') {
        await docRef.update({
          'balanceLBP': FieldValue.increment(-amount),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        throw Exception('Invalid currency: $currency');
      }
    } catch (e) {
      throw Exception('Failed to subtract from driver wallet: $e');
    }
  }

  // Watch driver wallet in real-time
  Stream<DriverWallet?> watchDriverWallet(String driverId) {
    return _firestore.collection(_walletsCollection).doc(driverId).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }
      return DriverWallet.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    });
  }

  // Get all driver wallets
  Future<List<DriverWallet>> getAllDriverWallets() async {
    try {
      final snapshot = await _firestore.collection(_walletsCollection).get();

      return snapshot.docs
          .map((doc) => DriverWallet.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get driver wallets: $e');
    }
  }
}
