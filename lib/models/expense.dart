enum SplitMode { percentage, individual }

class Expense {
  final String? id;
  final String description;
  final DateTime date;
  final double totalAmount;
  final SplitMode splitMode;
  final double? splitPercentageA;
  final double? splitPercentageB;
  final double? amountA;
  final double? amountB;
  final String paidById;
  final String categoryId;

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
        id: map['id'] as String?,
        description: map['description'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
        totalAmount: (map['total_amount'] as num).toDouble(),
        splitMode: SplitMode.values.firstWhere(
          (e) => e.name == map['split_mode'],
          orElse: () => SplitMode.percentage,
        ),
        splitPercentageA: (map['split_percentage_a'] as num?)?.toDouble(),
        splitPercentageB: (map['split_percentage_b'] as num?)?.toDouble(),
        amountA: (map['amount_a'] as num?)?.toDouble(),
        amountB: (map['amount_b'] as num?)?.toDouble(),
        paidById: map['paid_by_id'] as String,
        categoryId: map['category_id'] as String,
      );
}
