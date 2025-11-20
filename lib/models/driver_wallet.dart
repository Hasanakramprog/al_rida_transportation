class DriverWallet {
  final String id;
  final String driverId;
  final double balanceUSD;
  final double balanceLBP;
  final int transactionsUSD;
  final int transactionsLBP;
  final DateTime lastUpdated;

  DriverWallet({
    required this.id,
    required this.driverId,
    required this.balanceUSD,
    required this.balanceLBP,
    required this.transactionsUSD,
    required this.transactionsLBP,
    required this.lastUpdated,
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'balanceUSD': balanceUSD,
      'balanceLBP': balanceLBP,
      'transactionsUSD': transactionsUSD,
      'transactionsLBP': transactionsLBP,
      'lastUpdated': lastUpdated,
    };
  }

  // Create from Firestore document
  factory DriverWallet.fromMap(String id, Map<String, dynamic> map) {
    return DriverWallet(
      id: id,
      driverId: map['driverId'] ?? '',
      balanceUSD: (map['balanceUSD'] ?? 0.0).toDouble(),
      balanceLBP: (map['balanceLBP'] ?? 0.0).toDouble(),
      transactionsUSD: map['transactionsUSD'] ?? 0,
      transactionsLBP: map['transactionsLBP'] ?? 0,
      lastUpdated: map['lastUpdated']?.toDate() ?? DateTime.now(),
    );
  }

  // Copy with method
  DriverWallet copyWith({
    double? balanceUSD,
    double? balanceLBP,
    int? transactionsUSD,
    int? transactionsLBP,
    DateTime? lastUpdated,
  }) {
    return DriverWallet(
      id: id,
      driverId: driverId,
      balanceUSD: balanceUSD ?? this.balanceUSD,
      balanceLBP: balanceLBP ?? this.balanceLBP,
      transactionsUSD: transactionsUSD ?? this.transactionsUSD,
      transactionsLBP: transactionsLBP ?? this.transactionsLBP,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
