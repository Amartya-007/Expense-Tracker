enum CategoryType { expense, income }

class Category {
  final String id;
  final String name;
  final CategoryType type;
  final int iconCode;
  final int colorHex;
  final String? parentCategoryId;
  final List<String> subcategories;

  Category({
    required this.id,
    required this.name,
    required this.type,
    required this.iconCode,
    required this.colorHex,
    this.parentCategoryId,
    this.subcategories = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.index,
        'iconCode': iconCode,
        'colorHex': colorHex,
        'parentCategoryId': parentCategoryId,
        'subcategories': subcategories,
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'],
        name: json['name'],
        type: CategoryType.values[json['type'] ?? 0],
        iconCode: json['iconCode'] ?? 0xe59c,
        colorHex: json['colorHex'] ?? 0xFF00B2E7,
        parentCategoryId: json['parentCategoryId'],
        subcategories: List<String>.from(json['subcategories'] ?? []),
      );
}
