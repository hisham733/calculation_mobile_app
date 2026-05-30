class Category {
  final String? id;
  String name;
  int iconCodePoint;
  double? monthlyBudget;

  Category({
    this.id,
    required this.name,
    this.iconCodePoint = 0xe8cc,
    this.monthlyBudget,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'icon_code_point': iconCodePoint,
        'monthly_budget': monthlyBudget,
      };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as String?,
        name: map['name'] as String,
        iconCodePoint: map['icon_code_point'] as int,
        monthlyBudget: map['monthly_budget'] as double?,
      );
}
