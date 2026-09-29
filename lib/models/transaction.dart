enum TransactionType { expense, income, transfer, refund }

class TransactionSplit {
  final String categoryId;
  final String categoryName;
  final double amount;
  final String note;

  TransactionSplit({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'categoryName': categoryName,
        'amount': amount,
        'note': note,
      };

  factory TransactionSplit.fromJson(Map<String, dynamic> json) =>
      TransactionSplit(
        categoryId: json['categoryId'],
        categoryName: json['categoryName'],
        amount: (json['amount'] as num).toDouble(),
        note: json['note'] ?? '',
      );
}

class TransactionItem {
  final String id;
  final TransactionType type;
  final double amount;
  final String categoryId;
  final String categoryName;
  final String accountId;
  final String accountName;
  final String? toAccountId; // For transfers
  final String? toAccountName;
  final String merchant;
  final String note;
  final DateTime date;
  final List<String> tags;
  String? receiptImagePath;
  final String? location;
  final bool isRecurring;
  final bool isReviewed;
  final String source; // 'manual', 'autoCaptured'
  final String? refundedTransactionId;
  final List<TransactionSplit> splits;

  TransactionItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    required this.accountId,
    required this.accountName,
    this.toAccountId,
    this.toAccountName,
    required this.merchant,
    this.note = '',
    required this.date,
    this.tags = const [],
    this.receiptImagePath,
    this.location,
    this.isRecurring = false,
    this.isReviewed = true,
    this.source = 'manual',
    this.refundedTransactionId,
    this.splits = const [],
  });

  bool get isSplit => splits.isNotEmpty;

  TransactionItem copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    String? categoryId,
    String? categoryName,
    String? accountId,
    String? accountName,
    String? toAccountId,
    String? toAccountName,
    String? merchant,
    String? note,
    DateTime? date,
    List<String>? tags,
    String? receiptImagePath,
    String? location,
    bool? isRecurring,
    bool? isReviewed,
    String? source,
    String? refundedTransactionId,
    List<TransactionSplit>? splits,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      toAccountId: toAccountId ?? this.toAccountId,
      toAccountName: toAccountName ?? this.toAccountName,
      merchant: merchant ?? this.merchant,
      note: note ?? this.note,
      date: date ?? this.date,
      tags: tags ?? this.tags,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      location: location ?? this.location,
      isRecurring: isRecurring ?? this.isRecurring,
      isReviewed: isReviewed ?? this.isReviewed,
      source: source ?? this.source,
      refundedTransactionId: refundedTransactionId ?? this.refundedTransactionId,
      splits: splits ?? this.splits,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'amount': amount,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'accountId': accountId,
        'accountName': accountName,
        'toAccountId': toAccountId,
        'toAccountName': toAccountName,
        'merchant': merchant,
        'note': note,
        'date': date.toIso8601String(),
        'tags': tags,
        'receiptImagePath': receiptImagePath,
        'location': location,
        'isRecurring': isRecurring,
        'isReviewed': isReviewed,
        'source': source,
        'refundedTransactionId': refundedTransactionId,
        'splits': splits.map((s) => s.toJson()).toList(),
      };

  factory TransactionItem.fromJson(Map<String, dynamic> json) =>
      TransactionItem(
        id: json['id'],
        type: TransactionType.values[json['type'] ?? 0],
        amount: (json['amount'] as num).toDouble(),
        categoryId: json['categoryId'],
        categoryName: json['categoryName'],
        accountId: json['accountId'],
        accountName: json['accountName'],
        toAccountId: json['toAccountId'],
        toAccountName: json['toAccountName'],
        merchant: json['merchant'] ?? '',
        note: json['note'] ?? '',
        date: DateTime.parse(json['date']),
        tags: List<String>.from(json['tags'] ?? []),
        receiptImagePath: json['receiptImagePath'],
        location: json['location'],
        isRecurring: json['isRecurring'] ?? false,
        isReviewed: json['isReviewed'] ?? true,
        source: json['source'] ?? 'manual',
        refundedTransactionId: json['refundedTransactionId'],
        splits: (json['splits'] as List?)
                ?.map((s) => TransactionSplit.fromJson(s))
                .toList() ??
            [],
      );
}
