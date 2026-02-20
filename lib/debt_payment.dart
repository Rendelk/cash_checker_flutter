class DebtPayment {
  final String id;
  final String debtId;
  final double amount;
  final int paidAtMs;
  final String note;

  const DebtPayment({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.paidAtMs,
    required this.note,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'debtId': debtId,
      'amount': amount,
      'paidAtMs': paidAtMs,
      'note': note,
    };
  }

  factory DebtPayment.fromMap(Map<String, Object?> m) {
    return DebtPayment(
      id: (m['id'] ?? '').toString(),
      debtId: (m['debtId'] ?? '').toString(),
      amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
      paidAtMs: (m['paidAtMs'] as num?)?.toInt() ?? 0,
      note: (m['note'] ?? '').toString(),
    );
  }
}