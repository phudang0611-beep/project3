import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import 'receipt_storage_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expenses.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        merchant TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        category TEXT NOT NULL,
        imagePath TEXT,
        rawOcrText TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_date ON transactions (date)
    ''');
    await db.execute('''
      CREATE INDEX idx_transactions_category ON transactions (category)
    ''');
  }

  // --- CRUD Operations ---

  Future<int> insertTransaction(ExpenseTransaction transaction) async {
    final db = await database;
    return await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ExpenseTransaction>> getAllTransactions() async {
    final db = await database;
    final result = await db.query(
      'transactions',
      orderBy: 'date DESC, createdAt DESC',
    );
    return result.map((json) => ExpenseTransaction.fromMap(json)).toList();
  }

  Future<int> updateTransaction(ExpenseTransaction transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(String id) async {
    final db = await database;
    // Check if there is an image to delete
    final records = await db.query(
      'transactions',
      columns: ['imagePath'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (records.isNotEmpty && records.first['imagePath'] != null) {
      await ReceiptStorageService.deleteReceiptImage(
        records.first['imagePath'] as String,
      );
    }

    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Analytics Queries ---

  /// Total spending across all transactions
  Future<double> getTotalSpending() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(amount) as total FROM transactions');
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  /// Category breakdown for Donut Chart
  Future<Map<ExpenseCategory, double>> getCategoryTotals() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM transactions
      GROUP BY category
    ''');

    final Map<ExpenseCategory, double> data = {
      for (final cat in ExpenseCategory.values) cat: 0.0,
    };

    for (final row in result) {
      final catStr = row['category'] as String?;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      final cat = ExpenseCategory.fromString(catStr);
      data[cat] = (data[cat] ?? 0.0) + total;
    }

    return data;
  }

  /// Weekly spending: aggregates spending for the current week (Monday to Sunday)
  /// Returns a map of weekday integer (1=Mon, ..., 7=Sun) to total amount
  Future<Map<int, double>> getWeeklySpending() async {
    final now = DateTime.now();
    // Start of current week (Monday)
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final db = await database;
    final result = await db.rawQuery('''
      SELECT date, amount
      FROM transactions
      WHERE date >= ? AND date < ?
    ''', [startOfWeek.toIso8601String(), endOfWeek.toIso8601String()]);

    final Map<int, double> weekly = {
      1: 0.0, // Mon
      2: 0.0, // Tue
      3: 0.0, // Wed
      4: 0.0, // Thu
      5: 0.0, // Fri
      6: 0.0, // Sat
      7: 0.0, // Sun
    };

    for (final row in result) {
      final dateStr = row['date'] as String;
      final amount = (row['amount'] as num?)?.toDouble() ?? 0.0;
      final date = DateTime.tryParse(dateStr);
      if (date != null) {
        weekly[date.weekday] = (weekly[date.weekday] ?? 0.0) + amount;
      }
    }

    return weekly;
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
