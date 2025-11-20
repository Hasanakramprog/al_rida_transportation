class AdminWallet {
  final String id;
  final double totalBalanceUSD;
  final double totalBalanceLBP;
  final int totalTransactionsUSD;
  final int totalTransactionsLBP;
  final DateTime lastUpdated;

  AdminWallet({
    required this.id,
    required this.totalBalanceUSD,
    required this.totalBalanceLBP,
    required this.totalTransactionsUSD,
    required this.totalTransactionsLBP,
    required this.lastUpdated,
  });

  // Convert AdminWallet to map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'totalBalanceUSD': totalBalanceUSD,
      'totalBalanceLBP': totalBalanceLBP,
      'totalTransactionsUSD': totalTransactionsUSD,
      'totalTransactionsLBP': totalTransactionsLBP,
      'lastUpdated': lastUpdated,
    };
  }

  // Create AdminWallet from map (from Firestore)
  factory AdminWallet.fromMap(String id, Map<String, dynamic> map) {
    return AdminWallet(
      id: id,
      totalBalanceUSD: (map['totalBalanceUSD'] ?? 0.0).toDouble(),
      totalBalanceLBP: (map['totalBalanceLBP'] ?? 0.0).toDouble(),
      totalTransactionsUSD: map['totalTransactionsUSD'] ?? 0,
      totalTransactionsLBP: map['totalTransactionsLBP'] ?? 0,
      lastUpdated: map['lastUpdated']?.toDate() ?? DateTime.now(),
    );
  }

  // Copy with method
  AdminWallet copyWith({
    double? totalBalanceUSD,
    double? totalBalanceLBP,
    int? totalTransactionsUSD,
    int? totalTransactionsLBP,
    DateTime? lastUpdated,
  }) {
    return AdminWallet(
      id: id,
      totalBalanceUSD: totalBalanceUSD ?? this.totalBalanceUSD,
      totalBalanceLBP: totalBalanceLBP ?? this.totalBalanceLBP,
      totalTransactionsUSD: totalTransactionsUSD ?? this.totalTransactionsUSD,
      totalTransactionsLBP: totalTransactionsLBP ?? this.totalTransactionsLBP,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
