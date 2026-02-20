class PlannedExpense {
  final String id;
  final String title;
  final String currencyCode;
  final double amount;
  final int plannedAtMs;
  final String note;
  final int createdAtMs;

  const PlannedExpense({
    required this.id,
    required this.title,
    required this.currencyCode,
    required this.amount,
    required this.plannedAtMs,
    required this.note,
    required this.createdAtMs,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'currencyCode': currencyCode,
      'amount': amount,
      'plannedAtMs': plannedAtMs,
      'note': note,
      'createdAtMs': createdAtMs,
    };
  }

  factory PlannedExpense.fromMap(Map<String, Object?> m) {
    return PlannedExpense(
      id: (m['id'] ?? '').toString(),
      title: (m['title'] ?? '').toString(),
      currencyCode: (m['currencyCode'] ?? 'UAH').toString(),
      amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
      plannedAtMs: (m['plannedAtMs'] as num?)?.toInt() ?? 0,
      note: (m['note'] ?? '').toString(),
      createdAtMs: (m['createdAtMs'] as num?)?.toInt() ?? 0,
    );
  }
}