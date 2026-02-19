class Account {
  final String id;
  final String name;
  final String type; // card | cash
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

  Account copyWith({double? balance}) => Account(
        id: id,
        name: name,
        type: type,
        currencyCode: currencyCode,
        balance: balance ?? this.balance,
        accentHex: accentHex,
        createdAtMs: createdAtMs,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'currencyCode': currencyCode,
        'balance': balance,
        'accentHex': accentHex,
        'createdAtMs': createdAtMs,
      };

  static Account fromMap(Map<String, Object?> m) => Account(
        id: m['id'] as String,
        name: m['name'] as String,
        type: m['type'] as String,
        currencyCode: m['currencyCode'] as String,
        balance: (m['balance'] as num).toDouble(),
        accentHex: m['accentHex'] as String,
        createdAtMs: m['createdAtMs'] as int,
      );
}
