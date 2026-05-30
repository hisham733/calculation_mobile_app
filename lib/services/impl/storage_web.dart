import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_profile.dart';
import '../../models/category.dart';
import '../../models/expense.dart';
import '../../helpers/id_generator.dart';
import '../storage_service.dart';

class StorageServiceWeb implements StorageService {
  SharedPreferences? _prefs;

  StorageServiceWeb();

  Future<SharedPreferences> get _p async => _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final hasUsers = _prefs!.containsKey('users');
    if (!hasUsers) await _seed();
  }

  Future<void> _seed() async {
    final p = await _p;
    final users = [
      {'id': 'user_a', 'name': 'User A', 'color_value': 0xFF007AFF},
      {'id': 'user_b', 'name': 'User B', 'color_value': 0xFFFF9500},
    ];
    p.setString('users', jsonEncode(users));

    final categories = [
      {'id': 'cat_1', 'name': 'Groceries', 'icon_code_point': 0xe8cc, 'monthly_budget': 800.0},
      {'id': 'cat_2', 'name': 'Dining', 'icon_code_point': 0xe56c, 'monthly_budget': 400.0},
      {'id': 'cat_3', 'name': 'Utilities', 'icon_code_point': 0xe3b3, 'monthly_budget': 200.0},
      {'id': 'cat_4', 'name': 'Transport', 'icon_code_point': 0xe530, 'monthly_budget': 150.0},
      {'id': 'cat_5', 'name': 'Entertainment', 'icon_code_point': 0xe404, 'monthly_budget': 200.0},
      {'id': 'cat_6', 'name': 'Other', 'icon_code_point': 0xe3e9, 'monthly_budget': null},
    ];
    p.setString('categories', jsonEncode(categories));
    p.setString('expenses', jsonEncode([]));
  }

  List<Map<String, dynamic>> _list(String key) {
    final s = _prefs!.getString(key);
    if (s == null) return [];
    return (jsonDecode(s) as List).cast<Map<String, dynamic>>();
  }

  void _save(String key, List<Map<String, dynamic>> data) {
    _prefs!.setString(key, jsonEncode(data));
  }

  @override
  Future<List<UserProfile>> getUsers() async {
    await init();
    return _list('users').map((m) => UserProfile.fromMap(m)).toList();
  }

  @override
  Future<void> updateUser(UserProfile user) async {
    await init();
    final list = _list('users');
    final idx = list.indexWhere((m) => m['id'] == user.id);
    if (idx != -1) {
      list[idx] = user.toMap();
      _save('users', list);
    }
  }

  @override
  Future<List<Category>> getCategories() async {
    await init();
    return _list('categories').map((m) => Category.fromMap(m)).toList();
  }

  @override
  Future<void> insertCategory(Category category) async {
    await init();
    final list = _list('categories');
    final c = category.toMap();
    c['id'] = generateId();
    list.add(c);
    _save('categories', list);
  }

  @override
  Future<void> updateCategory(Category category) async {
    await init();
    final list = _list('categories');
    final idx = list.indexWhere((m) => m['id'] == category.id);
    if (idx != -1) {
      list[idx] = category.toMap();
      _save('categories', list);
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    await init();
    final list = _list('categories');
    list.removeWhere((m) => m['id'] == id);
    _save('categories', list);
  }

  @override
  Future<void> insertExpense(Expense expense) async {
    await init();
    final list = _list('expenses');
    final e = expense.toMap();
    e['id'] = generateId();
    list.insert(0, e);
    _save('expenses', list);
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    await init();
    final list = _list('expenses');
    final idx = list.indexWhere((m) => m['id'] == expense.id);
    if (idx != -1) {
      list[idx] = expense.toMap();
      _save('expenses', list);
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    await init();
    final list = _list('expenses');
    list.removeWhere((m) => m['id'] == id);
    _save('expenses', list);
  }

  @override
  Future<List<Expense>> getExpensesForMonth(DateTime month) async {
    await init();
    final start = DateTime(month.year, month.month, 1).millisecondsSinceEpoch;
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59).millisecondsSinceEpoch;
    final all = _list('expenses');
    final filtered = all
        .where((m) {
          final date = m['date'] as int;
          return date >= start && date <= end;
        })
        .toList();
    filtered.sort((a, b) => (b['date'] as int).compareTo(a['date'] as int));
    return filtered.map((m) => Expense.fromMap(m)).toList();
  }

  @override
  Future<List<Expense>> getAllExpenses() async {
    await init();
    final list = _list('expenses');
    list.sort((a, b) => (b['date'] as int).compareTo(a['date'] as int));
    return list.map((m) => Expense.fromMap(m)).toList();
  }

  @override
  Future<void> resetAll() async {
    final p = await _p;
    p.clear();
    await _seed();
  }
}
