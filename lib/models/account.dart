enum AccountType { bank, cash, creditCard, wallet, investment }

class Account {
  final String id;
  final String name;
  final AccountType type;
  double balance; // For credit card, this represents current outstanding amount
  final double startingBalance;
  final String? accountNumber; // e.g. "4321"
  final double? creditLimit; // For credit cards
  final String? dueDate; // e.g. "22nd of month"
  final double? minDue;
  final double? lowBalanceThreshold;
  DateTime? lastReconciledAt;
  double? lastReconciledBalance;
  final int colorHex;
  final String iconName;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.startingBalance = 0.0,
    this.accountNumber,
    this.creditLimit,
    this.dueDate,
    this.minDue,
    this.lowBalanceThreshold,
    this.lastReconciledAt,
    this.lastReconciledBalance,
    this.colorHex = 0xFF00B2E7,
    this.iconName = 'account_balance',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.index,
    'balance': balance,
    'startingBalance': startingBalance,
    'accountNumber': accountNumber,
    'creditLimit': creditLimit,
    'dueDate': dueDate,
    'minDue': minDue,
    'lowBalanceThreshold': lowBalanceThreshold,
    'lastReconciledAt': lastReconciledAt?.toIso8601String(),
    'lastReconciledBalance': lastReconciledBalance,
    'colorHex': colorHex,
    'iconName': iconName,
  };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json['id'],
    name: json['name'],
    type: AccountType.values[json['type'] ?? 0],
    balance: (json['balance'] as num).toDouble(),
    startingBalance: (json['startingBalance'] as num?)?.toDouble() ?? 0.0,
    accountNumber: json['accountNumber'],
    creditLimit: (json['creditLimit'] as num?)?.toDouble(),
    dueDate: json['dueDate'],
    minDue: (json['minDue'] as num?)?.toDouble(),
    lowBalanceThreshold: (json['lowBalanceThreshold'] as num?)?.toDouble(),
    lastReconciledAt: json['lastReconciledAt'] == null
        ? null
        : DateTime.tryParse(json['lastReconciledAt'] as String),
    lastReconciledBalance: (json['lastReconciledBalance'] as num?)?.toDouble(),
    colorHex: json['colorHex'] ?? 0xFF00B2E7,
    iconName: json['iconName'] ?? 'account_balance',
  );
}
