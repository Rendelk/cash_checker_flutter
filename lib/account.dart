class Account {
  final String id;
  final String name;
  final String type; // card | cash | wallet
  final String currencyCode;
  final double balance;
  final String accentHex;
  final int createdAtMs;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.currencyCode,
    required this.balance,
    required this.accentHex,
    required this.createdAtMs,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'currencyCode': currencyCode,
      'balance': balance,
      'accentHex': accentHex,
      'createdAtMs': createdAtMs,
    };
  }

  factory Account.fromMap(Map<String, Object?> m) {
    return Account(
      id: (m['id'] ?? '').toString(),
      name: (m['name'] ?? '').toString(),
      type: (m['type'] ?? '').toString(),
      currencyCode: (m['currencyCode'] ?? 'UAH').toString(),
      balance: (m['balance'] as num?)?.toDouble() ?? 0.0,
      accentHex: (m['accentHex'] ?? '#20232A').toString(),
      createdAtMs: (m['createdAtMs'] as num?)?.toInt() ?? 0,
    );
  }

  Account copyWith({
    String? id,
    String? name,
    String? type,
    String? currencyCode,
    double? balance,
    String? accentHex,
    int? createdAtMs,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      currencyCode: currencyCode ?? this.currencyCode,
      balance: balance ?? this.balance,
      accentHex: accentHex ?? this.accentHex,
      createdAtMs: createdAtMs ?? this.createdAtMs,
    );
  }
}