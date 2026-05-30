enum SplitMode { percentage, individual }

/// Represents a single shared expense with split details.
class Expense {
  String? id;
  String description;
  DateTime date;
  double totalAmount;
  SplitMode splitMode;
  double? splitPercentageA;
  double? splitPercentageB;
  double? amountA;
  double? amountB;
  String paidById;
  String categoryId;
  bool isRecurring;
  String recurringInterval;
  String notes;

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
    this.isRecurring = false,
    this.recurringInterval = 'none',
    this.notes = '',
  });

  /// How much user A should pay based on split mode.
  double get shareA {
    switch (splitMode) {
      case SplitMode.percentage:
        final pct = (splitPercentageA ?? 50) / 100;
        return totalAmount * pct;
      case SplitMode.individual:
        return amountA ?? 0;
    }
  }

  /// How much user B should pay based on split mode.
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
        'is_recurring': isRecurring,
        'recurring_interval': recurringInterval,
        'notes': notes,
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
        isRecurring: map['is_recurring'] is bool
            ? map['is_recurring'] as bool
            : (map['is_recurring'] as int? ?? 0) == 1,
        recurringInterval: map['recurring_interval'] as String? ?? 'none',
        notes: map['notes'] as String? ?? '',
      );

  Expense copyWith({
    String? id,
    String? description,
    DateTime? date,
    double? totalAmount,
    SplitMode? splitMode,
    double? splitPercentageA,
    double? splitPercentageB,
    double? amountA,
    double? amountB,
    String? paidById,
    String? categoryId,
    bool? isRecurring,
    String? recurringInterval,
    String? notes,
  }) =>
      Expense(
        id: id ?? this.id,
        description: description ?? this.description,
        date: date ?? this.date,
        totalAmount: totalAmount ?? this.totalAmount,
        splitMode: splitMode ?? this.splitMode,
        splitPercentageA: splitPercentageA ?? this.splitPercentageA,
        splitPercentageB: splitPercentageB ?? this.splitPercentageB,
        amountA: amountA ?? this.amountA,
        amountB: amountB ?? this.amountB,
        paidById: paidById ?? this.paidById,
        categoryId: categoryId ?? this.categoryId,
        isRecurring: isRecurring ?? this.isRecurring,
        recurringInterval: recurringInterval ?? this.recurringInterval,
        notes: notes ?? this.notes,
      );
}
