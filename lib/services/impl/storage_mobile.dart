import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/user_profile.dart';
import '../../models/category.dart';
import '../../models/expense.dart';
import '../../helpers/id_generator.dart';
import '../storage_service.dart';

class StorageServiceMobile implements StorageService {
  Database? _db;

  StorageServiceMobile();

  @override
  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'shared_expense.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            color_value INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE categories (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            icon_code_point INTEGER NOT NULL,
            monthly_budget REAL
          )
        ''');
        await db.execute('''
          CREATE TABLE expenses (
            id TEXT PRIMARY KEY,
            description TEXT NOT NULL,
            date INTEGER NOT NULL,
            total_amount REAL NOT NULL,
            split_mode TEXT NOT NULL,
            split_percentage_a REAL,
            split_percentage_b REAL,
            amount_a REAL,
            amount_b REAL,
            paid_by_id TEXT NOT NULL,
            category_id TEXT NOT NULL,
            FOREIGN KEY (paid_by_id) REFERENCES users(id),
            FOREIGN KEY (category_id) REFERENCES categories(id)
          )
        ''');
        await _seed(db);
      },
    );
  }

  Database get _database => _db!;

  Future<void> _seed(Database db) async {
    await db.insert('users', {'id': 'user_a', 'name': 'User A', 'color_value': 0xFF007AFF});
    await db.insert('users', {'id': 'user_b', 'name': 'User B', 'color_value': 0xFFFF9500});

    final categories = [
      {'id': 'cat_1', 'name': 'Groceries', 'icon_code_point': 0xe8cc, 'monthly_budget': 800.0},
      {'id': 'cat_2', 'name': 'Dining', 'icon_code_point': 0xe56c, 'monthly_budget': 400.0},
      {'id': 'cat_3', 'name': 'Utilities', 'icon_code_point': 0xe3b3, 'monthly_budget': 200.0},
      {'id': 'cat_4', 'name': 'Transport', 'icon_code_point': 0xe530, 'monthly_budget': 150.0},
      {'id': 'cat_5', 'name': 'Entertainment', 'icon_code_point': 0xe404, 'monthly_budget': 200.0},
      {'id': 'cat_6', 'name': 'Other', 'icon_code_point': 0xe3e9, 'monthly_budget': null},
    ];
    for (final cat in categories) {
      await db.insert('categories', cat);
    }
  }

  @override
  Future<List<UserProfile>> getUsers() async {
    final maps = await _database.query('users');
    return maps.map((m) => UserProfile.fromMap(m)).toList();
  }

  @override
  Future<void> updateUser(UserProfile user) async {
    await _database.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  @override
  Future<List<Category>> getCategories() async {
    final maps = await _database.query('categories');
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  @override
  Future<void> insertCategory(Category category) async {
    final c = category.toMap();
    c['id'] = generateId();
    await _database.insert('categories', c);
  }

  @override
  Future<void> updateCategory(Category category) async {
    await _database.update('categories', category.toMap(),
        where: 'id = ?', whereArgs: [category.id]);
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _database.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> insertExpense(Expense expense) async {
    final e = expense.toMap();
    e['id'] = generateId();
    await _database.insert('expenses', e);
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _database.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<Expense>> getExpensesForMonth(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final maps = await _database.query(
      'expenses',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'date DESC',
    );
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  @override
  Future<List<Expense>> getAllExpenses() async {
    final maps = await _database.query('expenses', orderBy: 'date DESC');
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  @override
  Future<void> resetAll() async {
    await _database.delete('expenses');
    await _database.delete('categories');
    await _database.delete('users');
    await _seed(_database);
  }
}
