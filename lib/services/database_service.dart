import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_profile.dart';
import '../models/category.dart';
import '../models/expense.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._();
  static Database? _database;

  DatabaseService._();

  factory DatabaseService() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _init();
    return _database!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'shared_expense.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color_value INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon_code_point INTEGER NOT NULL,
        monthly_budget REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        date INTEGER NOT NULL,
        total_amount REAL NOT NULL,
        split_mode TEXT NOT NULL,
        split_percentage_a REAL,
        split_percentage_b REAL,
        amount_a REAL,
        amount_b REAL,
        paid_by_id INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        FOREIGN KEY (paid_by_id) REFERENCES users(id),
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    await _seedDefaults(db);
  }

  Future<void> _seedDefaults(Database db) async {
    await db.insert('users', {'name': 'User A', 'color_value': 0xFF007AFF});
    await db.insert('users', {'name': 'User B', 'color_value': 0xFFFF9500});

    final categories = [
      {'name': 'Groceries', 'icon_code_point': 0xe8cc, 'monthly_budget': 800.0},
      {'name': 'Dining', 'icon_code_point': 0xe56c, 'monthly_budget': 400.0},
      {'name': 'Utilities', 'icon_code_point': 0xe3b3, 'monthly_budget': 200.0},
      {'name': 'Transport', 'icon_code_point': 0xe530, 'monthly_budget': 150.0},
      {'name': 'Entertainment', 'icon_code_point': 0xe404, 'monthly_budget': 200.0},
      {'name': 'Other', 'icon_code_point': 0xe3e9, 'monthly_budget': null},
    ];
    for (final cat in categories) {
      await db.insert('categories', cat);
    }
  }

  Future<List<UserProfile>> getUsers() async {
    final db = await database;
    final maps = await db.query('users');
    return maps.map((m) => UserProfile.fromMap(m)).toList();
  }

  Future<void> updateUser(UserProfile user) async {
    final db = await database;
    await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<List<Category>> getCategories() async {
    final db = await database;
    final maps = await db.query('categories');
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  Future<void> insertCategory(Category category) async {
    final db = await database;
    await db.insert('categories', category.toMap());
  }

  Future<void> updateCategory(Category category) async {
    final db = await database;
    await db.update('categories', category.toMap(),
        where: 'id = ?', whereArgs: [category.id]);
  }

  Future<void> deleteCategory(int id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertExpense(Expense expense) async {
    final db = await database;
    await db.insert('expenses', expense.toMap());
  }

  Future<void> deleteExpense(int id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Expense>> getExpensesForMonth(DateTime month) async {
    final db = await database;
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final maps = await db.query(
      'expenses',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'date DESC',
    );
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final maps =
        await db.query('expenses', orderBy: 'date DESC');
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<void> resetAll() async {
    final db = await database;
    await db.delete('expenses');
    await db.delete('categories');
    await db.delete('users');
    await _seedDefaults(db);
  }
}
