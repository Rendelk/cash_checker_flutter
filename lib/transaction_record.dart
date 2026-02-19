class TransactionRecord {
  final String id;
  final String accountId;
  final String type; // expense | income
  final String categoryRaw;
  final String currencyCode;
  final double amount;
  final String merchant;
  final String note;
  final int createdAtMs;

  const TransactionRecord({
    required this.id,
    required this.accountId,
    required this.type,
    required this.categoryRaw,
    required this.currencyCode,
    required this.amount,
    required this.merchant,
    required this.note,
    required this.createdAtMs,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'accountId': accountId,
        'type': type,
        'categoryRaw': categoryRaw,
        'currencyCode': currencyCode,
        'amount': amount,
        'merchant': merchant,
        'note': note,
        'createdAtMs': createdAtMs,
      };

  static TransactionRecord fromMap(Map<String, Object?> m) => TransactionRecord(
        id: m['id'] as String,
        accountId: m['accountId'] as String,
        type: m['type'] as String,
        categoryRaw: m['categoryRaw'] as String,
        currencyCode: m['currencyCode'] as String,
        amount: (m['amount'] as num).toDouble(),
        merchant: m['merchant'] as String,
        note: m['note'] as String,
        createdAtMs: m['createdAtMs'] as int,
      );
}
