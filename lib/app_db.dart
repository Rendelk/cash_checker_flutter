import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDb {
  static Database? _db;

  static Future<Database> instance() async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'cash_checker.db');

    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createAll(db);
        await _seedDefaultCategories(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createV2Tables(db);
          await _seedDefaultCategories(db);
        }
      },
    );

    return _db!;
  }

  static Future<void> _createAll(Database db) async {
    await db.execute('''
      CREATE TABLE accounts(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        currencyCode TEXT NOT NULL,
        balance REAL NOT NULL,
        accentHex TEXT NOT NULL,
        createdAtMs INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions(
        id TEXT PRIMARY KEY,
        accountId TEXT NOT NULL,
        type TEXT NOT NULL,
        categoryRaw TEXT NOT NULL,
        currencyCode TEXT NOT NULL,
        amount REAL NOT NULL,
        note TEXT NOT NULL,
        createdAtMs INTEGER NOT NULL
      )
    ''');

    await _createV2Tables(db);
  }

  static Future<void> _createV2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        createdAtMs INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS debts(
        id TEXT PRIMARY KEY,
        personName TEXT NOT NULL,
        direction TEXT NOT NULL,
        currencyCode TEXT NOT NULL,
        amount REAL NOT NULL,
        repaid REAL NOT NULL,
        note TEXT NOT NULL,
        createdAtMs INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS debt_payments(
        id TEXT PRIMARY KEY,
        debtId TEXT NOT NULL,
        amount REAL NOT NULL,
        paidAtMs INTEGER NOT NULL,
        note TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS planned_expenses(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        currencyCode TEXT NOT NULL,
        amount REAL NOT NULL,
        plannedAtMs INTEGER NOT NULL,
        note TEXT NOT NULL,
        createdAtMs INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_meta(
        k TEXT PRIMARY KEY,
        v TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _seedDefaultCategories(Database db) async {
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM categories'),
        ) ??
        0;
    if (count > 0) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final items = <Map<String, Object?>>[
      {'id': 'exp_food', 'name': 'Їжа', 'type': 'expense', 'createdAtMs': now},
      {'id': 'exp_transport', 'name': 'Транспорт', 'type': 'expense', 'createdAtMs': now},
      {'id': 'exp_home', 'name': 'Дім', 'type': 'expense', 'createdAtMs': now},
      {'id': 'exp_health', 'name': 'Здоровʼя', 'type': 'expense', 'createdAtMs': now},
      {'id': 'exp_other', 'name': 'Інше', 'type': 'expense', 'createdAtMs': now},
      {'id': 'inc_salary', 'name': 'Зарплата', 'type': 'income', 'createdAtMs': now},
      {'id': 'inc_bonus', 'name': 'Бонус', 'type': 'income', 'createdAtMs': now},
      {'id': 'inc_other', 'name': 'Інше', 'type': 'income', 'createdAtMs': now},
    ];

    final batch = db.batch();
    for (final e in items) {
      batch.insert('categories', e, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }
}