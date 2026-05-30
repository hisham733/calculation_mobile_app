import '../models/user_profile.dart';
import '../models/category.dart';
import '../models/expense.dart';

abstract class StorageService {
  Future<void> init();

  Future<List<UserProfile>> getUsers();
  Future<void> updateUser(UserProfile user);

  Future<List<Category>> getCategories();
  Future<void> insertCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(String id);

  Future<void> insertExpense(Expense expense);
  Future<void> deleteExpense(String id);
  Future<List<Expense>> getExpensesForMonth(DateTime month);
  Future<List<Expense>> getAllExpenses();

  Future<void> resetAll();
}
