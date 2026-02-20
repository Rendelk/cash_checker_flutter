class DebtItem {
  final String id;
  final String personName;
  final String direction;
  final String currencyCode;
  final double amount;
  final double repaid;
  final String note;
  final int createdAtMs;

  const DebtItem({
    required this.id,
    required this.personName,
    required this.direction,
    required this.currencyCode,
    required this.amount,
    required this.repaid,
    required this.note,
    required this.createdAtMs,
  });

  double get remaining {
    final v = amount - repaid;
    return v < 0 ? 0 : v;
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'personName': personName,
        'direction': direction,
        'currencyCode': currencyCode,
        'amount': amount,
        'repaid': repaid,
        'note': note,
        'createdAtMs': createdAtMs,
      };

  factory DebtItem.fromMap(Map<String, Object?> m) => DebtItem(
        id: (m['id'] ?? '').toString(),
        personName: (m['personName'] ?? '').toString(),
        direction: (m['direction'] ?? '').toString(),
        currencyCode: (m['currencyCode'] ?? 'UAH').toString(),
        amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
        repaid: (m['repaid'] as num?)?.toDouble() ?? 0.0,
        note: (m['note'] ?? '').toString(),
        createdAtMs: (m['createdAtMs'] as num?)?.toInt() ?? 0,
      );
}

