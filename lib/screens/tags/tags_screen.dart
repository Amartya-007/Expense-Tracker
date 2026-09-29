import 'package:flutter/material.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/theme/app_theme.dart';

class TagsScreen extends StatelessWidget {
  final AppState state;
  const TagsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final isDark = state.profile.isDarkMode;
        final tags = state.allAvailableTags;

        return Scaffold(
          backgroundColor: isDark ? null : Colors.grey.shade50,
          appBar: AppBar(
            title: const Text(
              'Manage Tags',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            actions: [
              IconButton(
                tooltip: 'Add Tag',
                icon: const Icon(Icons.add_circle_outline_rounded),
                onPressed: () => _showAddTagDialog(context),
              ),
              const SizedBox(width: 8),
            ],
          ),
          floatingActionButton: tags.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: () => _showAddTagDialog(context),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New Tag'),
                )
              : null,
          body: tags.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : AppColors.primary.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.style_outlined,
                            size: 64,
                            color: isDark ? Colors.white54 : AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No Tags Yet',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tags help you flexibly group transactions across categories (e.g., #Travel, #Work, #Reimbursement).',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text(
                            'Create First Tag',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          onPressed: () => _showAddTagDialog(context),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: tags.length,
                  itemBuilder: (context, index) {
                    final tag = tags[index];
                    final usageCount = state.getTagUsageCount(tag);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade900 : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.shade200,
                        ),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '#$tag',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  usageCount == 0
                                      ? 'Not in use'
                                      : '$usageCount Transaction${usageCount == 1 ? '' : 's'}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.grey.shade100,
                                ),
                                icon: const Icon(Icons.edit_rounded, size: 18),
                                tooltip: 'Rename',
                                onPressed: () =>
                                    _showEditTagDialog(context, tag),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.expenseRed
                                      .withValues(alpha: 0.1),
                                ),
                                icon: const Icon(
                                  Icons.delete_rounded,
                                  size: 18,
                                  color: AppColors.expenseRed,
                                ),
                                tooltip: 'Delete',
                                onPressed: () =>
                                    _confirmDeleteTag(context, tag, usageCount),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  void _showAddTagDialog(BuildContext context) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('New Tag', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Tag Name',
            hintText: 'e.g. Vacation, Office',
            prefixText: '# ',
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              state.addTag(val.trim());
              Navigator.pop(ctx);
            }
          },
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                state.addTag(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add Tag', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showEditTagDialog(BuildContext context, String currentTag) {
    final controller = TextEditingController(text: currentTag);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rename Tag', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Tag Name',
            prefixText: '# ',
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              state.renameTag(currentTag, val.trim());
              Navigator.pop(ctx);
            }
          },
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                state.renameTag(currentTag, controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTag(BuildContext context, String tag, int usageCount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete #$tag?', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          usageCount > 0
              ? 'This tag is currently used in $usageCount transaction${usageCount == 1 ? '' : 's'}. Deleting it will remove the tag from those transactions.'
              : 'Are you sure you want to permanently delete this tag?',
          style: const TextStyle(height: 1.4),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expenseRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              state.removeTag(tag);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}