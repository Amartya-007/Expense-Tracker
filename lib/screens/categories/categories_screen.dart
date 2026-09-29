import 'package:flutter/material.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/models/category.dart';
import 'package:expensetracker/theme/app_theme.dart';

class CategoriesScreen extends StatelessWidget {
  final AppState state;
  const CategoriesScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = state.profile.isDarkMode;
    final expenseCategories = state.categories
        .where((c) => c.type == CategoryType.expense)
        .toList();
    final incomeCategories = state.categories
        .where((c) => c.type == CategoryType.income)
        .toList();

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Categories',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.add_circle_rounded, size: 28),
              color: Theme.of(context).primaryColor,
              onPressed: () => _showAddCategoryDialog(context),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        physics: const BouncingScrollPhysics(),
        children: [
          if (expenseCategories.isNotEmpty) ...[
            _sectionHeader(
              'Expense Categories',
              Icons.arrow_downward_rounded,
              AppColors.expenseRed,
              isDark,
            ),
            const SizedBox(height: 12),
            ...expenseCategories.map(
              (cat) => _buildCategoryCard(context, cat, isDark),
            ),
            const SizedBox(height: 32),
          ],
          if (incomeCategories.isNotEmpty) ...[
            _sectionHeader(
              'Income Categories',
              Icons.arrow_upward_rounded,
              const Color(0xFF10B981),
              isDark,
            ),
            const SizedBox(height: 12),
            ...incomeCategories.map(
              (cat) => _buildCategoryCard(context, cat, isDark),
            ),
            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(
    String title,
    IconData icon,
    Color iconColor,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(int iconCode) => switch (iconCode) {
    0xe56c => Icons.security_update_warning,
    0xe59c => Icons.shopping_cart,
    0xe1d5 => Icons.directions_bus,
    0xe0be => Icons.auto_graph,
    0xe038 => Icons.access_alarm,
    0xe318 => Icons.home,
    0xe57e => Icons.set_meal,
    0xe0cd => Icons.batch_prediction,
    0xe3f3 => Icons.mode_edit_outline,
    0xe227 => Icons.electric_scooter,
    0xe8f9 => Icons.door_front_door_sharp,
    0xe043 => Icons.account_circle,
    0xe0bf => Icons.auto_stories,
    _ => Icons.category_rounded,
  };

  Widget _buildCategoryCard(BuildContext context, Category cat, bool isDark) {
    final catColor = Color(cat.colorHex);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          width: 1.5,
        ),
      ),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_categoryIcon(cat.iconCode), color: catColor, size: 24),
          ),
          title: Text(
            cat.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '${cat.subcategories.length} subcategories',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  onPressed: () => _showEditCategoryDialog(context, cat),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  tooltip: 'Edit Category',
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.expenseRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.delete_rounded,
                    size: 18,
                    color: AppColors.expenseRed,
                  ),
                  onPressed: () => _confirmDeleteCategory(context, cat),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  tooltip: 'Delete Category',
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more_rounded,
                size: 20,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ],
          ),
          children: [
            Container(
              color: isDark ? Colors.black12 : const Color(0xFFF8F9FA),
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Column(
                children: [
                  ...cat.subcategories.map((sub) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2C2C2C)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.03),
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.only(
                            left: 16,
                            right: 8,
                          ),
                          leading: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: catColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          minLeadingWidth: 10,
                          title: Text(
                            sub,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.remove_circle_outline_rounded,
                              size: 20,
                              color: AppColors.expenseRed.withValues(
                                alpha: 0.8,
                              ),
                            ),
                            tooltip: 'Remove subcategory',
                            onPressed: () {
                              final updated = Category(
                                id: cat.id,
                                name: cat.name,
                                type: cat.type,
                                iconCode: cat.iconCode,
                                colorHex: cat.colorHex,
                                subcategories: cat.subcategories
                                    .where((s) => s != sub)
                                    .toList(),
                              );
                              state.updateCategory(updated);
                            },
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: InkWell(
                      onTap: () => _showAddSubcategoryDialog(context, cat),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: catColor.withValues(alpha: 0.5),
                            style: BorderStyle.solid,
                          ),
                          color: catColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded, size: 18, color: catColor),
                            const SizedBox(width: 8),
                            Text(
                              'Add Subcategory',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: catColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCategory(BuildContext context, Category cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('Delete Category?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${cat.name}"? This action cannot be undone.',
          style: const TextStyle(height: 1.4),
        ),
        actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              state.deleteCategory(cat.id);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.expenseRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, Category cat) {
    final nameController = TextEditingController(text: cat.name);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Edit Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  final updated = Category(
                    id: cat.id,
                    name: nameController.text.trim(),
                    type: cat.type,
                    iconCode: cat.iconCode,
                    colorHex: cat.colorHex,
                    subcategories: cat.subcategories,
                  );
                  state.updateCategory(updated);
                  Navigator.pop(ctx);
                }
              },
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  void _showAddSubcategoryDialog(BuildContext context, Category cat) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'New Subcategory in ${cat.name}',
            style: const TextStyle(fontSize: 18),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Subcategory Name',
              hintText: 'e.g. Groceries',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
          ),
          actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  final updated = Category(
                    id: cat.id,
                    name: cat.name,
                    type: cat.type,
                    iconCode: cat.iconCode,
                    colorHex: cat.colorHex,
                    subcategories: [
                      ...cat.subcategories,
                      controller.text.trim(),
                    ],
                  );
                  state.updateCategory(updated);
                  Navigator.pop(ctx);
                }
              },
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    CategoryType type = CategoryType.expense;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Create Category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<CategoryType>(
                      style: SegmentedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      segments: const [
                        ButtonSegment(
                          value: CategoryType.expense,
                          label: Text('Expense'),
                          icon: Icon(Icons.arrow_downward_rounded, size: 16),
                        ),
                        ButtonSegment(
                          value: CategoryType.income,
                          label: Text('Income'),
                          icon: Icon(Icons.arrow_upward_rounded, size: 16),
                        ),
                      ],
                      selected: {type},
                      onSelectionChanged: (s) =>
                          setDialogState(() => type = s.first),
                    ),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (nameController.text.trim().isNotEmpty) {
                      final newCat = Category(
                        id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
                        name: nameController.text.trim(),
                        type: type,
                        iconCode: type == CategoryType.expense
                            ? 0xe59c
                            : 0xe227,
                        colorHex: type == CategoryType.expense
                            ? 0xFF0D9488
                            : 0xFF10B981,
                      );
                      state.addCategory(newCat);
                      Navigator.pop(ctx);
                    }
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Save Category'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
