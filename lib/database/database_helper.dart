// ============================================================
// database/database_helper.dart
// Singleton class managing all SQLite database interactions.
// Uses the sqflite package. Handles:
//   - Database initialization & schema creation
//   - Migrations (versioned upgrades)
//   - Full CRUD operations for transactions
//   - Seeding sample data on first launch
// ============================================================

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart' as model;

class DatabaseHelper {
  // ── Singleton setup ──────────────────────────────────────
  // Only one instance of DatabaseHelper exists throughout the app lifecycle.
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // Cached database reference — lazily initialized
  static Database? _database;

  // Database file name on device storage
  static const String _dbName = 'finance_tracker.db';

  // Current schema version — increment when you change table structure
  static const int _dbVersion = 1;

  // Table and column names as constants (avoids typos)
  static const String tableTransactions = 'transactions';
  static const String colId = 'id';
  static const String colTitle = 'title';
  static const String colDescription = 'description';
  static const String colAmount = 'amount';
  static const String colType = 'type';
  static const String colCategory = 'category';
  static const String colDate = 'date';
  static const String colCreatedAt = 'created_at';

  // ── Database accessor ────────────────────────────────────

  /// Returns the open database, initializing it if needed.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Opens (or creates) the SQLite database file.
  Future<Database> _initDatabase() async {
    // getDatabasesPath() returns the correct platform-specific directory
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ── Schema ───────────────────────────────────────────────

  /// Called once when the database is first created.
  /// Creates all tables and seeds sample data.
  Future<void> _onCreate(Database db, int version) async {
    // Create the transactions table
    // SQLite types: INTEGER, TEXT, REAL, BLOB, NULL
    await db.execute('''
      CREATE TABLE $tableTransactions (
        $colId          INTEGER PRIMARY KEY AUTOINCREMENT,
        $colTitle       TEXT    NOT NULL,
        $colDescription TEXT    DEFAULT '',
        $colAmount      REAL    NOT NULL,
        $colType        TEXT    NOT NULL,     -- 'income' | 'expense'
        $colCategory    TEXT    NOT NULL,     -- TransactionCategory.name
        $colDate        TEXT    NOT NULL,     -- ISO8601 date string
        $colCreatedAt   TEXT    NOT NULL      -- ISO8601 datetime string
      )
    ''');

    // Insert sample data so the app has content on first launch
    await _seedSampleData(db);
  }

  /// Called when _dbVersion is incremented — handles schema migrations.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Example migration: add a 'note' column in version 2
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE $tableTransactions ADD COLUMN note TEXT DEFAULT ""');
    // }
  }

  // ── Seed Data ────────────────────────────────────────────

  /// Inserts realistic sample transactions to demonstrate the app on first run.
  Future<void> _seedSampleData(Database db) async {
    final now = DateTime.now();

    final samples = [
      model.Transaction(
        title: 'Monthly Salary',
        description: 'Regular monthly income from employer',
        amount: 4500.00,
        type: model.TransactionType.income,
        category: model.TransactionCategory.salary,
        date: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      model.Transaction(
        title: 'Grocery Shopping',
        description: 'Weekly groceries from supermarket',
        amount: 87.50,
        type: model.TransactionType.expense,
        category: model.TransactionCategory.food,
        date: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      model.Transaction(
        title: 'Netflix Subscription',
        description: 'Monthly streaming subscription',
        amount: 15.99,
        type: model.TransactionType.expense,
        category: model.TransactionCategory.entertainment,
        date: now.subtract(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      model.Transaction(
        title: 'Freelance Design Work',
        description: 'Logo design project for client',
        amount: 320.00,
        type: model.TransactionType.income,
        category: model.TransactionCategory.freelance,
        date: now.subtract(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      model.Transaction(
        title: 'Gym Membership',
        description: 'Monthly fitness center subscription',
        amount: 49.00,
        type: model.TransactionType.expense,
        category: model.TransactionCategory.health,
        date: now.subtract(const Duration(days: 7)),
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      model.Transaction(
        title: 'Electricity Bill',
        description: 'Monthly utility bill',
        amount: 125.40,
        type: model.TransactionType.expense,
        category: model.TransactionCategory.housing,
        date: now.subtract(const Duration(days: 10)),
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      model.Transaction(
        title: 'Uber Ride',
        description: 'Airport transfer',
        amount: 34.20,
        type: model.TransactionType.expense,
        category: model.TransactionCategory.transport,
        date: now.subtract(const Duration(days: 12)),
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      model.Transaction(
        title: 'Stock Dividends',
        description: 'Quarterly dividend payment',
        amount: 210.00,
        type: model.TransactionType.income,
        category: model.TransactionCategory.investment,
        date: now.subtract(const Duration(days: 15)),
        createdAt: now.subtract(const Duration(days: 15)),
      ),
    ];

    for (final tx in samples) {
      await db.insert(tableTransactions, tx.toMap());
    }
  }

  // ── CRUD Operations ──────────────────────────────────────

  /// CREATE — Insert a new transaction into the database.
  /// Returns the auto-generated row ID.
  Future<int> insertTransaction(model.Transaction transaction) async {
    final db = await database;
    return await db.insert(
      tableTransactions,
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// READ ALL — Fetch all transactions, newest first.
  Future<List<model.Transaction>> getAllTransactions() async {
    final db = await database;
    final maps = await db.query(
      tableTransactions,
      orderBy: '$colDate DESC',
    );
    return maps.map((m) => model.Transaction.fromMap(m)).toList();
  }

  /// READ ONE — Fetch a single transaction by its ID.
  Future<model.Transaction?> getTransactionById(int id) async {
    final db = await database;
    final maps = await db.query(
      tableTransactions,
      where: '$colId = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return model.Transaction.fromMap(maps.first);
  }

  /// SEARCH — Fetch transactions matching a query string in title or description.
  Future<List<model.Transaction>> searchTransactions(String query) async {
    final db = await database;
    final pattern = '%${query.toLowerCase()}%';
    final maps = await db.query(
      tableTransactions,
      where: 'LOWER($colTitle) LIKE ? OR LOWER($colDescription) LIKE ?',
      whereArgs: [pattern, pattern],
      orderBy: '$colDate DESC',
    );
    return maps.map((m) => model.Transaction.fromMap(m)).toList();
  }

  /// FILTER — Fetch transactions by type (income/expense).
  Future<List<model.Transaction>> getTransactionsByType(
      model.TransactionType type) async {
    final db = await database;
    final maps = await db.query(
      tableTransactions,
      where: '$colType = ?',
      whereArgs: [type.name],
      orderBy: '$colDate DESC',
    );
    return maps.map((m) => model.Transaction.fromMap(m)).toList();
  }

  /// FILTER BY DATE RANGE — Returns transactions within [start, end].
  Future<List<model.Transaction>> getTransactionsByDateRange(
      DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      tableTransactions,
      where: '$colDate BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: '$colDate DESC',
    );
    return maps.map((m) => model.Transaction.fromMap(m)).toList();
  }

  /// UPDATE — Modify an existing transaction record.
  /// Returns the number of rows affected (should be 1).
  Future<int> updateTransaction(model.Transaction transaction) async {
    if (transaction.id == null) return 0;
    final db = await database;
    return await db.update(
      tableTransactions,
      transaction.toMap(),
      where: '$colId = ?',
      whereArgs: [transaction.id],
    );
  }

  /// DELETE — Remove a transaction by ID.
  /// Returns the number of rows deleted.
  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      tableTransactions,
      where: '$colId = ?',
      whereArgs: [id],
    );
  }

  /// DELETE ALL — Wipe all transactions (used for testing/reset).
  Future<int> deleteAllTransactions() async {
    final db = await database;
    return await db.delete(tableTransactions);
  }

  // ── Aggregation Queries ──────────────────────────────────

  /// Returns total income and expense amounts as a summary map.
  Future<Map<String, double>> getSummary() async {
    final db = await database;

    final incomeResult = await db.rawQuery(
      'SELECT COALESCE(SUM($colAmount), 0) as total FROM $tableTransactions WHERE $colType = ?',
      ['income'],
    );

    final expenseResult = await db.rawQuery(
      'SELECT COALESCE(SUM($colAmount), 0) as total FROM $tableTransactions WHERE $colType = ?',
      ['expense'],
    );

    final income = (incomeResult.first['total'] as num).toDouble();
    final expense = (expenseResult.first['total'] as num).toDouble();

    return {
      'income': income,
      'expense': expense,
      'balance': income - expense,
    };
  }

  /// Close the database connection (call on app dispose).
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
