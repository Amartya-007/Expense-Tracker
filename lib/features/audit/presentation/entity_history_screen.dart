import 'package:flutter/material.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/models/audit_log.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/utils/date_formatter.dart';
import 'package:intl/intl.dart';

class EntityHistoryScreen extends StatefulWidget {
  final AppState state;
  final String entityType;
  final String entityId;
  final String entityName;

  const EntityHistoryScreen({
    super.key,
    required this.state,
    required this.entityType,
    required this.entityId,
    required this.entityName,
  });

  @override
  State<EntityHistoryScreen> createState() => _EntityHistoryScreenState();
}

class _EntityHistoryScreenState extends State<EntityHistoryScreen> {
  List<AuditLog> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await widget.state.databaseService.auditRepo.getEntityHistory(
      widget.entityType,
      widget.entityId,
    );
    if (mounted) {
      setState(() {
        _history = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.profile.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text('History: ${widget.entityName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(
                  child: Text(
                    'No recorded history for ${widget.entityName}',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final item = _history[idx];
                    final dateStr = DateFormatter.formatDateOnly(item.timestamp);
                    final timeStr = DateFormat('HH:mm:ss').format(item.timestamp);

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.action,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  '$dateStr $timeStr',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            if (item.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.description,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                            if (item.oldValue != null || item.newValue != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (item.oldValue != null)
                                      Text('Before:\n${item.oldValue}', style: const TextStyle(fontSize: 11, color: AppColors.expenseRed)),
                                    if (item.oldValue != null && item.newValue != null) const Divider(height: 12),
                                    if (item.newValue != null)
                                      Text('After:\n${item.newValue}', style: const TextStyle(fontSize: 11, color: AppColors.incomeGreen)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
