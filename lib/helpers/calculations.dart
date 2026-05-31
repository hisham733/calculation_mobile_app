import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/user_profile.dart';

/// Per-user summary within a month: how much they paid vs how much they owe.
class UserBalance {
  final String userId;
  final String userName;
  final double paid;
  final double share;

  UserBalance({
    required this.userId,
    required this.userName,
    required this.paid,
    required this.share,
  });

  double get balance => paid - share;

  /// Positive means they overpaid (others owe them), negative means they underpaid.
  String formattedBalance() {
    if (balance >= 0) return Calculations.currency(balance);
    return '-${Calculations.currency(-balance)}';
  }
}

/// Summary of a month's expenses with N-user support.
class MonthlySummary {
  final double totalSpent;
  final List<UserBalance> userBalances;
  final List<UserProfile> users;

  MonthlySummary({
    required this.totalSpent,
    required this.userBalances,
    required this.users,
  });

  /// Maps userId -> UserBalance for quick lookup.
  UserBalance? balanceFor(String userId) {
    try {
      return userBalances.firstWhere((b) => b.userId == userId);
    } catch (_) {
      return null;
    }
  }

  /// Returns a list of settlement descriptions (who owes whom how much).
  List<String> settlementTexts() {
    final debtors = userBalances
        .where((b) => b.balance < -0.005)
        .toList()
      ..sort((a, b) => a.balance.compareTo(b.balance));
    final creditors = userBalances
        .where((b) => b.balance > 0.005)
        .toList()
      ..sort((a, b) => b.balance.compareTo(a.balance));

    final result = <String>[];
    var di = 0, ci = 0;
    while (di < debtors.length && ci < creditors.length) {
      final debtor = debtors[di];
      final creditor = creditors[ci];
      final amount = debtor.balance.abs().clamp(0, creditor.balance) as double;
      if (amount > 0.005) {
        result.add('${debtor.userName} owes ${creditor.userName}: ${Calculations.currency(amount)}');
      }
      debtors[di] = UserBalance(
        userId: debtor.userId,
        userName: debtor.userName,
        paid: debtor.paid,
        share: debtor.share + amount,
      );
      creditors[ci] = UserBalance(
        userId: creditor.userId,
        userName: creditor.userName,
        paid: creditor.paid,
        share: creditor.share - amount,
      );
      if (debtors[di].balance >= -0.005) di++;
      if (creditors[ci].balance <= 0.005) ci++;
    }
    if (result.isEmpty) result.add('All settled');
    return result;
  }
}

/// Utility class with static methods for expense calculations and formatting.
class Calculations {
  /// Computes monthly summary from list of expenses and all users.
  static MonthlySummary summary({
    required List<Expense> expenses,
    required List<UserProfile> users,
  }) {
    final totalSpent = expenses.fold(0.0, (s, e) => s + e.totalAmount);

    final userBalances = users.map((user) {
      final paid = expenses
          .where((e) => e.paidById == user.id)
          .fold(0.0, (sum, e) => sum + e.totalAmount);
      final share = expenses.fold(0.0, (sum, e) => sum + e.shareFor(user.id!));
      return UserBalance(
        userId: user.id!,
        userName: user.name,
        paid: paid,
        share: share,
      );
    }).toList();

    return MonthlySummary(
      totalSpent: totalSpent,
      userBalances: userBalances,
      users: users,
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
