class TransactionRecord {
  final String id;
  final String accountId;
  final String type; // income | expense
  final String categoryRaw;
  final String currencyCode;
  final double amount;
  final String note;
  final int createdAtMs;

  const TransactionRecord({
    required this.id,
    required this.accountId,
    required this.type,
    required this.categoryRaw,
    required this.currencyCode,
    required this.amount,
    required this.note,
    required this.createdAtMs,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'accountId': accountId,
      'type': type,
      'categoryRaw': categoryRaw,
      'currencyCode': currencyCode,
      'amount': amount,
      'note': note,
      'createdAtMs': createdAtMs,
    };
  }

  factory TransactionRecord.fromMap(Map<String, Object?> m) {
    return TransactionRecord(
      id: (m['id'] ?? '').toString(),
      accountId: (m['accountId'] ?? '').toString(),
      type: (m['type'] ?? '').toString(),
      categoryRaw: (m['categoryRaw'] ?? '').toString(),
      currencyCode: (m['currencyCode'] ?? 'UAH').toString(),
      amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
      note: (m['note'] ?? '').toString(),
      createdAtMs: (m['createdAtMs'] as num?)?.toInt() ?? 0,
    );
  }
}