import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_profile.dart';
import '../../models/category.dart';
import '../../models/expense.dart';
import '../storage_service.dart';

class StorageServiceFirebase implements StorageService {
  final _firestore = FirebaseFirestore.instance;

  StorageServiceFirebase();

  @override
  Future<void> init() async {
    final users = await _firestore.collection('users').get();
    if (users.docs.isEmpty) await _seed();
  }

  Future<void> _seed() async {
    final batch = _firestore.batch();
    final userARef = _firestore.collection('users').doc('user_a');
    final userBRef = _firestore.collection('users').doc('user_b');
    batch.set(userARef, {'name': 'User A', 'color_value': 0xFF007AFF});
    batch.set(userBRef, {'name': 'User B', 'color_value': 0xFFFF9500});

    final categories = [
      {'id': 'cat_1', 'name': 'Groceries', 'icon_code_point': 0xe8cc, 'monthly_budget': 800.0},
      {'id': 'cat_2', 'name': 'Dining', 'icon_code_point': 0xe56c, 'monthly_budget': 400.0},
      {'id': 'cat_3', 'name': 'Utilities', 'icon_code_point': 0xe3b3, 'monthly_budget': 200.0},
      {'id': 'cat_4', 'name': 'Transport', 'icon_code_point': 0xe530, 'monthly_budget': 150.0},
      {'id': 'cat_5', 'name': 'Entertainment', 'icon_code_point': 0xe404, 'monthly_budget': 200.0},
      {'id': 'cat_6', 'name': 'Other', 'icon_code_point': 0xe3e9, 'monthly_budget': null},
    ];
    for (final cat in categories) {
      final ref = _firestore.collection('categories').doc(cat['id'] as String);
      batch.set(ref, cat);
    }
    await batch.commit();
  }

  @override
  Future<List<UserProfile>> getUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return UserProfile.fromMap(data);
    }).toList();
  }

  @override
  Future<void> updateUser(UserProfile user) async {
    await _firestore.collection('users').doc(user.id).update(user.toMap());
  }

  @override
  Future<List<Category>> getCategories() async {
    final snapshot = await _firestore.collection('categories').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Category.fromMap(data);
    }).toList();
  }

  @override
  Future<void> insertCategory(Category category) async {
    final ref = _firestore.collection('categories').doc();
    final data = category.toMap();
    data['id'] = ref.id;
    await ref.set(data);
  }

  @override
  Future<void> updateCategory(Category category) async {
    final map = category.toMap();
    map.remove('id');
    await _firestore.collection('categories').doc(category.id).update(map);
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _firestore.collection('categories').doc(id).delete();
  }

  @override
  Future<void> insertExpense(Expense expense) async {
    final ref = _firestore.collection('expenses').doc();
    final data = expense.toMap();
    data['id'] = ref.id;
    data['date'] = expense.date.millisecondsSinceEpoch;
    await ref.set(data);
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _firestore.collection('expenses').doc(id).delete();
  }

  @override
  Future<List<Expense>> getExpensesForMonth(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final snapshot = await _firestore
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: start.millisecondsSinceEpoch)
        .where('date', isLessThanOrEqualTo: end.millisecondsSinceEpoch)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Expense.fromMap(data);
    }).toList();
  }

  @override
  Future<List<Expense>> getAllExpenses() async {
    final snapshot = await _firestore
        .collection('expenses')
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Expense.fromMap(data);
    }).toList();
  }

  @override
  Future<void> resetAll() async {
    final collections = ['users', 'categories', 'expenses'];
    for (final name in collections) {
      final docs = await _firestore.collection(name).get();
      final batch = _firestore.batch();
      for (final doc in docs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    await _seed();
  }
}

StorageService createPlatformStorage() => StorageServiceFirebase();
