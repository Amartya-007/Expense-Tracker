class Goal {
  final String id;
  final String name;
  final double targetAmount;
  double currentAmount;
  final DateTime targetDate;
  final String iconName;
  final String note;
  bool isCompleted;

  Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.targetDate,
    this.iconName = 'savings',
    this.note = '',
    this.isCompleted = false,
  });

  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    final ratio = currentAmount / targetAmount;
    return ratio > 1.0 ? 1.0 : ratio;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'targetDate': targetDate.toIso8601String(),
        'iconName': iconName,
        'note': note,
        'isCompleted': isCompleted,
      };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'],
        name: json['name'],
        targetAmount: (json['targetAmount'] as num).toDouble(),
        currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
        targetDate: DateTime.parse(json['targetDate']),
        iconName: json['iconName'] ?? 'savings',
        note: json['note'] ?? '',
        isCompleted: json['isCompleted'] ?? false,
      );
}
