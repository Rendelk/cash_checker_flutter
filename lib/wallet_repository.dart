import 'package:uuid/uuid.dart';
import '../db/app_db.dart';
import '../models/account.dart';

class WalletRepository {
  final _uuid = const Uuid();

  Future<List<Account>> getAccounts() async {
    final db = await AppDb.instance();
    final rows = await db.query('accounts', orderBy: 'createdAtMs ASC');
    return rows.map(Account.fromMap).toList();
  }

  Future<void> addAccount({
    required String name,
    required String type,
    required String currencyCode,
    required double balance,
    String accentHex = '#1E293B',
  }) async {
    final db = await AppDb.instance();
    await db.insert('accounts', Account(
      id: _uuid.v4(),
      name: name,
      type: type,
      currencyCode: currencyCode,
      balance: balance,
      accentHex: accentHex,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    ).toMap());
  }

  Future<void> deleteAccount(String accountId) async {
    final db = await AppDb.instance();
    await db.delete('transactions', where: 'accountId = ?', whereArgs: [accountId]);
    await db.delete('accounts', where: 'id = ?', whereArgs: [accountId]);
  }
}
