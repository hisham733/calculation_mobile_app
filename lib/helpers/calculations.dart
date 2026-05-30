import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/user_profile.dart';

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

  String settlementText(String nameA, String nameB) {
    if (balanceA > balanceB.abs()) {
      return '$nameB owes $nameA: ${Calculations.currency(balanceA)}';
    } else if (balanceB > balanceA.abs()) {
      return '$nameA owes $nameB: ${Calculations.currency(balanceB)}';
    }
    return 'All settled';
  }
}

class Calculations {
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

  static Map<String?, double> categorySpending(List<Expense> expenses) {
    final map = <String?, double>{};
    for (final e in expenses) {
      map[e.categoryId] = (map[e.categoryId] ?? 0) + e.totalAmount;
    }
    return map;
  }

  static String currency(double value) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(value);
  }
}
