import 'dart:convert';

enum SplitMode { equal, custom }

class Expense {
  String? id;
  String description;
  DateTime date;
  double totalAmount;
  SplitMode splitMode;
  String paidById;
  String categoryId;
  bool isRecurring;
  String recurringInterval;
  String notes;
  List<String> participantIds;
  Map<String, double> splits;

  Expense({
    this.id,
    required this.description,
    required this.date,
    required this.totalAmount,
    this.splitMode = SplitMode.equal,
    required this.paidById,
    required this.categoryId,
    this.isRecurring = false,
    this.recurringInterval = 'none',
    this.notes = '',
    List<String>? participantIds,
    Map<String, double>? splits,
  })  : participantIds = participantIds ?? [],
        splits = splits ?? {};

  double shareFor(String userId) => splits[userId] ?? 0;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'description': description,
        'date': date.millisecondsSinceEpoch,
        'total_amount': totalAmount,
        'split_mode': splitMode.name,
        'paid_by_id': paidById,
        'category_id': categoryId,
        'is_recurring': isRecurring,
        'recurring_interval': recurringInterval,
        'notes': notes,
        'participant_ids': participantIds.join(','),
        'splits': jsonEncode(splits),
      };

  factory Expense.fromMap(Map<String, dynamic> map) {
    final participantIdsRaw = map['participant_ids'] as String?;
    final splitsRaw = map['splits'] as String?;

    List<String> participantIds;
    Map<String, double> splits;

    if (participantIdsRaw != null && participantIdsRaw.isNotEmpty) {
      participantIds = participantIdsRaw.split(',').where((s) => s.isNotEmpty).toList();
    } else {
      participantIds = [];
    }

    if (splitsRaw != null && splitsRaw.isNotEmpty) {
      final decoded = jsonDecode(splitsRaw) as Map<String, dynamic>;
      splits = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } else {
      splits = {};
    }

    if (participantIds.isEmpty) {
      final legacyA = map['legacy_user_a_id'] as String?;
      final legacyB = map['legacy_user_b_id'] as String?;
      if (legacyA != null) participantIds.add(legacyA);
      if (legacyB != null) participantIds.add(legacyB);
    }

    if (splits.isEmpty && participantIds.length == 2) {
      final legacyPctA = (map['split_percentage_a'] as num?)?.toDouble();
      final legacyPctB = (map['split_percentage_b'] as num?)?.toDouble();
      final legacyAmountA = (map['amount_a'] as num?)?.toDouble();
      final legacyAmountB = (map['amount_b'] as num?)?.toDouble();
      final total = (map['total_amount'] as num).toDouble();

      if (legacyAmountA != null && legacyAmountB != null) {
        splits[participantIds[0]] = legacyAmountA;
        splits[participantIds[1]] = legacyAmountB;
      } else {
        final pctA = (legacyPctA ?? 50) / 100;
        final pctB = (legacyPctB ?? 50) / 100;
        splits[participantIds[0]] = total * pctA;
        splits[participantIds[1]] = total * pctB;
      }
    }

    return Expense(
      id: map['id'] as String?,
      description: map['description'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      totalAmount: (map['total_amount'] as num).toDouble(),
      splitMode: _parseSplitMode(map['split_mode'] as String?),
      paidById: map['paid_by_id'] as String,
      categoryId: map['category_id'] as String,
      isRecurring: map['is_recurring'] is bool
          ? map['is_recurring'] as bool
          : (map['is_recurring'] as int? ?? 0) == 1,
      recurringInterval: map['recurring_interval'] as String? ?? 'none',
      notes: map['notes'] as String? ?? '',
      participantIds: participantIds,
      splits: splits,
    );
  }

  static SplitMode _parseSplitMode(String? name) {
    if (name == 'percentage' || name == 'individual') return SplitMode.custom;
    return SplitMode.values.firstWhere(
      (e) => e.name == name,
      orElse: () => SplitMode.equal,
    );
  }

  Expense copyWith({
    String? id,
    String? description,
    DateTime? date,
    double? totalAmount,
    SplitMode? splitMode,
    String? paidById,
    String? categoryId,
    bool? isRecurring,
    String? recurringInterval,
    String? notes,
    List<String>? participantIds,
    Map<String, double>? splits,
  }) =>
      Expense(
        id: id ?? this.id,
        description: description ?? this.description,
        date: date ?? this.date,
        totalAmount: totalAmount ?? this.totalAmount,
        splitMode: splitMode ?? this.splitMode,
        paidById: paidById ?? this.paidById,
        categoryId: categoryId ?? this.categoryId,
        isRecurring: isRecurring ?? this.isRecurring,
        recurringInterval: recurringInterval ?? this.recurringInterval,
        notes: notes ?? this.notes,
        participantIds: participantIds ?? this.participantIds,
        splits: splits ?? this.splits,
      );
}
