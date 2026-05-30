import '../../models/user_profile.dart';
import '../../models/category.dart';
import '../../models/expense.dart';
import '../storage_service.dart';

class StorageServiceStub implements StorageService {
  StorageServiceStub();

  @override
  Future<void> init() async => throw UnsupportedError('No platform implementation');

  @override
  Future<List<UserProfile>> getUsers() => throw UnsupportedError('');

  @override
  Future<void> updateUser(UserProfile user) => throw UnsupportedError('');

  @override
  Future<List<Category>> getCategories() => throw UnsupportedError('');

  @override
  Future<void> insertCategory(Category category) => throw UnsupportedError('');

  @override
  Future<void> updateCategory(Category category) => throw UnsupportedError('');

  @override
  Future<void> deleteCategory(String id) => throw UnsupportedError('');

  @override
  Future<void> insertExpense(Expense expense) => throw UnsupportedError('');

  @override
  Future<void> updateExpense(Expense expense) => throw UnsupportedError('');

  @override
  Future<void> deleteExpense(String id) => throw UnsupportedError('');

  @override
  Future<List<Expense>> getExpensesForMonth(DateTime month) =>
      throw UnsupportedError('');

  @override
  Future<List<Expense>> getAllExpenses() => throw UnsupportedError('');

  @override
  Future<void> resetAll() => throw UnsupportedError('');
}

StorageService createPlatformStorage() => StorageServiceStub();
