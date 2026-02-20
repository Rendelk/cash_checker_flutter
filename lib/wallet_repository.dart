import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'account.dart';
import 'app_db.dart';
import 'category_item.dart';
import 'debt_item.dart';
import 'debt_payment.dart';
import 'planned_expense.dart';
import 'transaction_record.dart';

class WalletRepository {
  final _uuid = const Uuid();

  Future<List<Account>> getAccounts() async {
    final db = await AppDb.instance();
    final rows = await db.query('accounts', orderBy: 'createdAtMs DESC');
    return rows.map((e) => Account.fromMap(e)).toList();
  }

  Future<Account> addAccount({
    required String name,
    required String type,
    required String currencyCode,
    required double balance,
    required String accentHex,
  }) async {
    final db = await AppDb.instance();
    final account = Account(
      id: _uuid.v4(),
      name: name.trim(),
      type: type.trim(),
      currencyCode: currencyCode.trim().toUpperCase(),
      balance: balance,
      accentHex: accentHex,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await db.insert('accounts', account.toMap());
    return account;
  }

  Future<void> deleteAccount(String id) async {
    final db = await AppDb.instance();
    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
    await db.delete('transactions', where: 'accountId = ?', whereArgs: [id]);
  }

  Future<void> clearAccountTransactions(String accountId) async {
    final db = await AppDb.instance();
    await db.delete('transactions', where: 'accountId = ?', whereArgs: [accountId]);
    await db.update('accounts', {'balance': 0.0}, where: 'id = ?', whereArgs: [accountId]);
  }

  Future<void> addTransaction({
    required String accountId,
    required String type,
    required String categoryRaw,
    required String currencyCode,
    required double amount,
    String note = '',
    DateTime? createdAt,
  }) async {
    final db = await AppDb.instance();

    final tx = TransactionRecord(
      id: _uuid.v4(),
      accountId: accountId,
      type: type,
      categoryRaw: categoryRaw.trim(),
      currencyCode: currencyCode.trim().toUpperCase(),
      amount: amount,
      note: note.trim(),
      createdAtMs: (createdAt ?? DateTime.now()).millisecondsSinceEpoch,
    );

    await db.transaction((txn) async {
      await txn.insert('transactions', tx.toMap());

      final delta = type == 'expense' ? -amount : amount;
      await txn.rawUpdate(
        'UPDATE accounts SET balance = balance + ? WHERE id = ?',
        [delta, accountId],
      );
    });
  }

  Future<void> deleteTransaction(String id) async {
    final db = await AppDb.instance();

    await db.transaction((txn) async {
      final rows = await txn.query('transactions', where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) return;

      final tx = TransactionRecord.fromMap(rows.first);
      final rollback = tx.type == 'expense' ? tx.amount : -tx.amount;

      await txn.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [rollback, tx.accountId]);
      await txn.delete('transactions', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<TransactionRecord>> getTransactions({
    String? accountId,
    String? type,
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await AppDb.instance();

    final where = <String>[];
    final args = <Object?>[];

    if (accountId != null && accountId.isNotEmpty) {
      where.add('accountId = ?');
      args.add(accountId);
    }
    if (type != null && type.isNotEmpty) {
      where.add('type = ?');
      args.add(type);
    }
    if (from != null) {
      where.add('createdAtMs >= ?');
      args.add(from.millisecondsSinceEpoch);
    }
    if (to != null) {
      where.add('createdAtMs <= ?');
      args.add(to.millisecondsSinceEpoch);
    }

    final rows = await db.query(
      'transactions',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'createdAtMs DESC',
    );

    return rows.map((e) => TransactionRecord.fromMap(e)).toList();
  }
  Future<Map<String, double>> monthlyExpenseByCurrency() async {
    final db = await AppDb.instance();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final end = DateTime(now.year, now.month + 1, 1).millisecondsSinceEpoch;

    final rows = await db.rawQuery(
      '''
      SELECT currencyCode, SUM(amount) AS total
      FROM transactions
      WHERE type = 'expense' AND createdAtMs >= ? AND createdAtMs < ?
      GROUP BY currencyCode
      ''',
      [start, end],
    );

    final out = <String, double>{};
    for (final r in rows) {
      out[(r['currencyCode'] ?? 'UAH').toString()] = (r['total'] as num?)?.toDouble() ?? 0.0;
    }
    return out;
  }

  Future<Map<String, double>> expenseByCategoryInRange({
    required DateTime from,
    required DateTime to,
    String? currencyCode,
  }) async {
    final db = await AppDb.instance();

    final where = StringBuffer("type = 'expense' AND createdAtMs >= ? AND createdAtMs <= ?");
    final args = <Object?>[from.millisecondsSinceEpoch, to.millisecondsSinceEpoch];

    if (currencyCode != null && currencyCode.isNotEmpty) {
      where.write(' AND currencyCode = ?');
      args.add(currencyCode);
    }

    final rows = await db.rawQuery(
      '''
      SELECT categoryRaw, SUM(amount) AS total
      FROM transactions
      WHERE ${where.toString()}
      GROUP BY categoryRaw
      ORDER BY total DESC
      ''',
      args,
    );

    final out = <String, double>{};
    for (final r in rows) {
      out[(r['categoryRaw'] ?? '').toString()] = (r['total'] as num?)?.toDouble() ?? 0.0;
    }
    return out;
  }

  Future<List<CategoryItem>> getCategories(String type) async {
    final db = await AppDb.instance();
    final rows = await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map((e) => CategoryItem.fromMap(e)).toList();
  }

  Future<CategoryItem> addCategory({
    required String name,
    required String type,
  }) async {
    final db = await AppDb.instance();
    final item = CategoryItem(
      id: _uuid.v4(),
      name: name.trim(),
      type: type,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await db.insert('categories', item.toMap());
    return item;
  }

  Future<void> deleteCategory(String id) async {
    final db = await AppDb.instance();
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<DebtItem>> getDebts() async {
    final db = await AppDb.instance();
    final rows = await db.query('debts', orderBy: 'createdAtMs DESC');
    return rows.map((e) => DebtItem.fromMap(e)).toList();
  }

  Future<DebtItem> addDebt({
    required String personName,
    required String direction,
    required String currencyCode,
    required double amount,
    String note = '',
  }) async {
    final db = await AppDb.instance();
    final item = DebtItem(
      id: _uuid.v4(),
      personName: personName.trim(),
      direction: direction,
      currencyCode: currencyCode.trim().toUpperCase(),
      amount: amount,
      repaid: 0.0,
      note: note.trim(),
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await db.insert('debts', item.toMap());
    return item;
  }

  Future<void> addDebtPayment({
    required String debtId,
    required double amount,
    DateTime? paidAt,
    String note = '',
  }) async {
    final db = await AppDb.instance();

    await db.transaction((txn) async {
      final debtRows = await txn.query('debts', where: 'id = ?', whereArgs: [debtId], limit: 1);
      if (debtRows.isEmpty) return;

      final debt = DebtItem.fromMap(debtRows.first);
      final remaining = debt.remaining;
      final appliedAmount = amount > remaining ? remaining : amount;
      if (appliedAmount <= 0) return;
      final payment = DebtPayment(
        id: _uuid.v4(),
        debtId: debtId,
        amount: appliedAmount,
        paidAtMs: (paidAt ?? DateTime.now()).millisecondsSinceEpoch,
        note: note.trim(),
      );

      await txn.insert('debt_payments', payment.toMap());
      await txn.rawUpdate('UPDATE debts SET repaid = repaid + ? WHERE id = ?', [appliedAmount, debtId]);
    });
  }

  Future<List<DebtPayment>> getDebtPayments(String debtId) async {
    final db = await AppDb.instance();
    final rows = await db.query(
      'debt_payments',
      where: 'debtId = ?',
      whereArgs: [debtId],
      orderBy: 'paidAtMs DESC',
    );
    return rows.map((e) => DebtPayment.fromMap(e)).toList();
  }

  Future<void> deleteDebt(String debtId) async {
    final db = await AppDb.instance();
    await db.transaction((txn) async {
      await txn.delete('debt_payments', where: 'debtId = ?', whereArgs: [debtId]);
      await txn.delete('debts', where: 'id = ?', whereArgs: [debtId]);
    });
  }

  Future<List<PlannedExpense>> getPlannedExpenses() async {
    final db = await AppDb.instance();
    final rows = await db.query('planned_expenses', orderBy: 'plannedAtMs ASC');
    return rows.map((e) => PlannedExpense.fromMap(e)).toList();
  }

  Future<PlannedExpense> addPlannedExpense({
    required String title,
    required String currencyCode,
    required double amount,
    required DateTime plannedAt,
    String note = '',
  }) async {
    final db = await AppDb.instance();
    final item = PlannedExpense(
      id: _uuid.v4(),
      title: title.trim(),
      currencyCode: currencyCode.trim().toUpperCase(),
      amount: amount,
      plannedAtMs: plannedAt.millisecondsSinceEpoch,
      note: note.trim(),
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await db.insert('planned_expenses', item.toMap());
    return item;
  }

  Future<void> deletePlannedExpense(String id) async {
    final db = await AppDb.instance();
    await db.delete('planned_expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> isOnboardingSeen() async {
    final db = await AppDb.instance();
    final rows = await db.query('app_meta', where: 'k = ?', whereArgs: ['onboarding_seen'], limit: 1);
    if (rows.isEmpty) return false;
    return (rows.first['v'] ?? '0').toString() == '1';
  }

  Future<void> setOnboardingSeen(bool value) async {
    final db = await AppDb.instance();
    await db.insert(
      'app_meta',
      {'k': 'onboarding_seen', 'v': value ? '1' : '0'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}