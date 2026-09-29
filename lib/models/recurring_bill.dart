enum RecurringType { bill, subscription, emi, income }

enum BillingCycle { weekly, monthly, yearly }

class RecurringBill {
  final String id;
  final String title;
  final double amount;
  final RecurringType type;
  final BillingCycle billingCycle;
  final int dueDay; // 1 to 31 day of month
  DateTime? nextDueDate;
  int? installmentTotal;
  int? installmentsRemaining;
  final String categoryId;
  final String categoryName;
  final String accountId;
  final String accountName;
  bool isPaid;
  bool isPaused;
  bool isCompleted;

  RecurringBill({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    this.billingCycle = BillingCycle.monthly,
    required this.dueDay,
    this.nextDueDate,
    this.installmentTotal,
    this.installmentsRemaining,
    required this.categoryId,
    required this.categoryName,
    required this.accountId,
    required this.accountName,
    this.isPaid = false,
    this.isPaused = false,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'type': type.index,
    'billingCycle': billingCycle.index,
    'dueDay': dueDay,
    'nextDueDate': nextDueDate?.toIso8601String(),
    'installmentTotal': installmentTotal,
    'installmentsRemaining': installmentsRemaining,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'accountId': accountId,
    'accountName': accountName,
    'isPaid': isPaid,
    'isPaused': isPaused,
    'isCompleted': isCompleted,
  };

  factory RecurringBill.fromJson(Map<String, dynamic> json) => RecurringBill(
    id: json['id'],
    title: json['title'],
    amount: (json['amount'] as num).toDouble(),
    type: RecurringType.values[json['type'] ?? 0],
    billingCycle: BillingCycle.values[json['billingCycle'] ?? 0],
    dueDay: json['dueDay'] ?? 1,
    nextDueDate: json['nextDueDate'] == null
        ? null
        : DateTime.tryParse(json['nextDueDate'] as String),
    installmentTotal: json['installmentTotal'] as int?,
    installmentsRemaining: json['installmentsRemaining'] as int?,
    categoryId: json['categoryId'],
    categoryName: json['categoryName'],
    accountId: json['accountId'],
    accountName: json['accountName'],
    isPaid: json['isPaid'] ?? false,
    isPaused: json['isPaused'] ?? false,
    isCompleted: json['isCompleted'] ?? false,
  );
}
