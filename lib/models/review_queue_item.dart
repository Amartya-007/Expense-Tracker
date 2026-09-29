import 'package:expensetracker/models/transaction.dart';

class ReviewQueueItem {
  final String id;
  String merchant;
  double amount;
  DateTime date;
  String suggestedCategoryId;
  String suggestedCategoryName;
  String suggestedAccountId;
  String suggestedAccountName;
  final String sourceNotification;
  TransactionType suggestedType;

  ReviewQueueItem({
    required this.id,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.suggestedCategoryId,
    required this.suggestedCategoryName,
    required this.suggestedAccountId,
    required this.suggestedAccountName,
    required this.sourceNotification,
    this.suggestedType = TransactionType.expense,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'merchant': merchant,
        'amount': amount,
        'date': date.toIso8601String(),
        'suggestedCategoryId': suggestedCategoryId,
        'suggestedCategoryName': suggestedCategoryName,
        'suggestedAccountId': suggestedAccountId,
        'suggestedAccountName': suggestedAccountName,
        'sourceNotification': sourceNotification,
        'suggestedType': suggestedType.index,
      };

  factory ReviewQueueItem.fromJson(Map<String, dynamic> json) =>
      ReviewQueueItem(
        id: json['id'],
        merchant: json['merchant'],
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date']),
        suggestedCategoryId: json['suggestedCategoryId'],
        suggestedCategoryName: json['suggestedCategoryName'],
        suggestedAccountId: json['suggestedAccountId'],
        suggestedAccountName: json['suggestedAccountName'],
        sourceNotification: json['sourceNotification'],
        suggestedType: json['suggestedType'] != null
            ? TransactionType.values[json['suggestedType'] as int]
            : TransactionType.expense,
      );
}
