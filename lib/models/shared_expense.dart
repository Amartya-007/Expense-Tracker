class SharedExpense {
  final String id;
  final String title;
  final double totalAmount;
  final String paidBy;
  final List<String> participants;
  final Map<String, double> splits; // Participant -> share, including payer
  final Map<String, bool> settledStatus; // Participant -> settled boolean
  final DateTime date;

  SharedExpense({
    required this.id,
    required this.title,
    required this.totalAmount,
    required this.paidBy,
    required this.participants,
    required this.splits,
    required this.settledStatus,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'totalAmount': totalAmount,
    'paidBy': paidBy,
    'participants': participants,
    'splits': splits,
    'settledStatus': settledStatus,
    'date': date.toIso8601String(),
  };

  factory SharedExpense.fromJson(Map<String, dynamic> json) => SharedExpense(
    id: json['id'],
    title: json['title'],
    totalAmount: (json['totalAmount'] as num).toDouble(),
    paidBy: json['paidBy'],
    participants: List<String>.from(json['participants'] ?? []),
    splits: Map<String, double>.from(
      (json['splits'] as Map?)?.map(
            (k, v) => MapEntry(k as String, (v as num).toDouble()),
          ) ??
          {},
    ),
    settledStatus: Map<String, bool>.from(
      (json['settledStatus'] as Map?)?.map(
            (k, v) => MapEntry(k as String, v as bool),
          ) ??
          {},
    ),
    date: DateTime.parse(json['date']),
  );
}
