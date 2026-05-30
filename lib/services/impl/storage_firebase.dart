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
      {'name': 'Groceries', 'icon_code_point': 0xe8cc, 'monthly_budget': 800.0},
      {'name': 'Dining', 'icon_code_point': 0xe56c, 'monthly_budget': 400.0},
      {'name': 'Utilities', 'icon_code_point': 0xe3b3, 'monthly_budget': 200.0},
      {'name': 'Transport', 'icon_code_point': 0xe530, 'monthly_budget': 150.0},
      {'name': 'Entertainment', 'icon_code_point': 0xe404, 'monthly_budget': 200.0},
      {'name': 'Other', 'icon_code_point': 0xe3e9, 'monthly_budget': null},
    ];
    for (final cat in categories) {
      batch.set(_firestore.collection('categories').doc(), cat);
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

  Future<void> _generateRecurring() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final recurring = await _firestore
        .collection('expenses')
        .where('is_recurring', isEqualTo: true)
        .get();

    for (final doc in recurring.docs) {
      final data = doc.data();
      final lastDate = (data['date'] as num?)?.toInt() ?? 0;
      final last = DateTime.fromMillisecondsSinceEpoch(lastDate);
      final interval = data['recurring_interval'] as String? ?? 'none';

      bool shouldGenerate = false;
      if (interval == 'monthly') {
        shouldGenerate = last.year < now.year || (last.year == now.year && last.month < now.month);
      } else if (interval == 'weekly') {
        shouldGenerate = now.difference(last).inDays >= 7;
      }

      if (shouldGenerate) {
        data.remove('id');
        data['date'] = startOfMonth.millisecondsSinceEpoch;
        final newRef = _firestore.collection('expenses').doc();
        data['id'] = newRef.id;
        await newRef.set(data);
      }
    }
  }

  @override
  Future<List<Expense>> getExpensesForMonth(DateTime month) async {
    await _generateRecurring();
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
