import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDb {
  static Database? _db;

  static Future<Database> instance() async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'cash_checker.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE accounts(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            currencyCode TEXT NOT NULL,
            balance REAL NOT NULL,
            accentHex TEXT NOT NULL,
            createdAtMs INTEGER NOT NULL
          );
        ''');
        await db.execute('''
          CREATE TABLE transactions(
            id TEXT PRIMARY KEY,
            accountId TEXT NOT NULL,
            type TEXT NOT NULL,
            categoryRaw TEXT NOT NULL,
            currencyCode TEXT NOT NULL,
            amount REAL NOT NULL,
            merchant TEXT NOT NULL,
            note TEXT NOT NULL,
            createdAtMs INTEGER NOT NULL
          );
        ''');
      },
    );
    return _db!;
  }
}
