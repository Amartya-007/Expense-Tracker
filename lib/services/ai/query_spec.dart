class DateRangeSpec {
  final String? from;
  final String? to;

  DateRangeSpec({this.from, this.to});

  Map<String, dynamic> toJson() => {'from': from, 'to': to};

  factory DateRangeSpec.fromJson(Map<String, dynamic> json) => DateRangeSpec(
        from: json['from'] as String?,
        to: json['to'] as String?,
      );
}

class QuerySpec {
  final String intent; // sum, count, average, max, min, list, compare, breakdown, budget_status, balance, goal_progress, recurring_bills, unknown
  final String type; // expense, income, transfer, any
  final List<String> categories;
  final List<String> subcategories;
  final List<String> merchants;
  final List<String> tags;
  final List<String> accounts;
  final DateRangeSpec? dateRange;
  final DateRangeSpec? compareTo;
  final String? groupBy; // category, merchant, day, month, account, tag
  final String? sort; // amount_desc, amount_asc, date_desc
  final int limit;

  QuerySpec({
    this.intent = 'sum',
    this.type = 'expense',
    this.categories = const [],
    this.subcategories = const [],
    this.merchants = const [],
    this.tags = const [],
    this.accounts = const [],
    this.dateRange,
    this.compareTo,
    this.groupBy,
    this.sort,
    this.limit = 10,
  });

  Map<String, dynamic> toJson() => {
        'intent': intent,
        'type': type,
        'categories': categories,
        'subcategories': subcategories,
        'merchants': merchants,
        'tags': tags,
        'accounts': accounts,
        'date_range': dateRange?.toJson(),
        'compare_to': compareTo?.toJson(),
        'group_by': groupBy,
        'sort': sort,
        'limit': limit,
      };

  factory QuerySpec.fromJson(Map<String, dynamic> json) => QuerySpec(
        intent: json['intent'] as String? ?? 'sum',
        type: json['type'] as String? ?? 'expense',
        categories: List<String>.from(json['categories'] ?? []),
        subcategories: List<String>.from(json['subcategories'] ?? []),
        merchants: List<String>.from(json['merchants'] ?? []),
        tags: List<String>.from(json['tags'] ?? []),
        accounts: List<String>.from(json['accounts'] ?? []),
        dateRange: json['date_range'] != null ? DateRangeSpec.fromJson(json['date_range']) : null,
        compareTo: json['compare_to'] != null ? DateRangeSpec.fromJson(json['compare_to']) : null,
        groupBy: json['group_by'] as String?,
        sort: json['sort'] as String?,
        limit: (json['limit'] as num?)?.toInt() ?? 10,
      );
}
