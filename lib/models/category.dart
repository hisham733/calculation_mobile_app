class Category {
  final String? id;
  String name;
  int iconCodePoint;
  int colorValue;
  double? monthlyBudget;

  Category({
    this.id,
    required this.name,
    this.iconCodePoint = 0xe8cc,
    this.colorValue = 0xFF006D77,
    this.monthlyBudget,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'icon_code_point': iconCodePoint,
        'color_value': colorValue,
        'monthly_budget': monthlyBudget,
      };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as String?,
        name: map['name'] as String,
        iconCodePoint: map['icon_code_point'] as int,
        colorValue: (map['color_value'] as int?) ?? 0xFF006D77,
        monthlyBudget: map['monthly_budget'] as double?,
      );
}
