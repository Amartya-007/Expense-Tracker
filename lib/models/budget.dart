enum BudgetPeriod { weekly, monthly, yearly, custom }

class Budget {
  final String id;
  final String categoryId;
  final String categoryName;
  final double limitAmount;
  final BudgetPeriod period;
  final bool isActive;

  Budget({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.limitAmount,
    this.period = BudgetPeriod.monthly,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'limitAmount': limitAmount,
        'period': period.index,
        'isActive': isActive,
      };

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
        id: json['id'],
        categoryId: json['categoryId'],
        categoryName: json['categoryName'],
        limitAmount: (json['limitAmount'] as num).toDouble(),
        period: BudgetPeriod.values[json['period'] ?? 1],
        isActive: json['isActive'] ?? true,
      );
}
