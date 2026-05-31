import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/user_profile.dart';

/// Summary of a month's expenses: totals, per-user paid vs share, and balances.
class MonthlySummary {
  final double totalSpent;
  final double userAPaid;
  final double userBPaid;
  final double userAShare;
  final double userBShare;

  MonthlySummary({
    required this.totalSpent,
    required this.userAPaid,
    required this.userBPaid,
    required this.userAShare,
    required this.userBShare,
  });

  double get balanceA => userAPaid - userAShare;
  double get balanceB => userBPaid - userBShare;

  /// Returns a human-readable string describing the settlement needed.
  String settlementText(String nameA, String nameB) {
    if (balanceA > balanceB.abs()) {
      return '$nameB owes $nameA: ${Calculations.currency(balanceA)}';
    } else if (balanceB > balanceA.abs()) {
      return '$nameA owes $nameB: ${Calculations.currency(balanceB)}';
    }
    return 'All settled';
  }
}

/// Utility class with static methods for expense calculations and formatting.
class Calculations {
  /// Computes monthly summary from list of expenses and two users.
  static MonthlySummary summary({
    required List<Expense> expenses,
    required UserProfile userA,
    required UserProfile userB,
  }) {
    final userAPaid = expenses
        .where((e) => e.paidById == userA.id)
        .fold(0.0, (sum, e) => sum + e.totalAmount);

    final userBPaid = expenses
        .where((e) => e.paidById == userB.id)
        .fold(0.0, (sum, e) => sum + e.totalAmount);

    final userAShare = expenses.fold(0.0, (sum, e) => sum + e.shareA);
    final userBShare = expenses.fold(0.0, (sum, e) => sum + e.shareB);
    final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.totalAmount);

    return MonthlySummary(
      totalSpent: totalSpent,
      userAPaid: userAPaid,
      userBPaid: userBPaid,
      userAShare: userAShare,
      userBShare: userBShare,
    );
  }

  /// Groups total spending by category ID.
  static Map<String?, double> categorySpending(List<Expense> expenses) {
    final map = <String?, double>{};
    for (final e in expenses) {
      map[e.categoryId] = (map[e.categoryId] ?? 0) + e.totalAmount;
    }
    return map;
  }

  /// Formats a number as currency string (e.g. "RM12.34").
  static String currency(double value) {
    return NumberFormat.currency(symbol: 'RM', decimalDigits: 2).format(value);
  }
}
