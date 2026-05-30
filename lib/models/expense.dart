enum SplitMode { percentage, individual }

class Expense {
  final int? id;
  final String description;
  final DateTime date;
  final double totalAmount;
  final SplitMode splitMode;
  final double? splitPercentageA;
  final double? splitPercentageB;
  final double? amountA;
  final double? amountB;
  final int paidById;
  final int categoryId;

  Expense({
    this.id,
    required this.description,
    required this.date,
    required this.totalAmount,
    this.splitMode = SplitMode.percentage,
    this.splitPercentageA,
    this.splitPercentageB,
    this.amountA,
    this.amountB,
    required this.paidById,
    required this.categoryId,
  });

  double get shareA {
    switch (splitMode) {
      case SplitMode.percentage:
        final pct = (splitPercentageA ?? 50) / 100;
        return totalAmount * pct;
      case SplitMode.individual:
        return amountA ?? 0;
    }
  }

  double get shareB {
    switch (splitMode) {
      case SplitMode.percentage:
        final pct = (splitPercentageB ?? 50) / 100;
        return totalAmount * pct;
      case SplitMode.individual:
        return amountB ?? 0;
    }
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'description': description,
        'date': date.millisecondsSinceEpoch,
        'total_amount': totalAmount,
        'split_mode': splitMode.name,
        'split_percentage_a': splitPercentageA,
        'split_percentage_b': splitPercentageB,
        'amount_a': amountA,
        'amount_b': amountB,
        'paid_by_id': paidById,
        'category_id': categoryId,
      };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'] as int,
        description: map['description'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
        totalAmount: map['total_amount'] as double,
        splitMode: SplitMode.values.firstWhere(
          (e) => e.name == map['split_mode'],
          orElse: () => SplitMode.percentage,
        ),
        splitPercentageA: map['split_percentage_a'] as double?,
        splitPercentageB: map['split_percentage_b'] as double?,
        amountA: map['amount_a'] as double?,
        amountB: map['amount_b'] as double?,
        paidById: map['paid_by_id'] as int,
        categoryId: map['category_id'] as int,
      );
}
