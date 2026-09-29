import 'package:flutter/material.dart';
import 'package:expensetracker/models/audit_log.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/utils/date_formatter.dart';
import 'package:expensetracker/features/audit/presentation/entity_history_screen.dart';
import 'package:intl/intl.dart';

class AuditLogDetailScreen extends StatelessWidget {
  final AppState state;
  final AuditLog log;

  const AuditLogDetailScreen({
    super.key,
    required this.state,
    required this.log,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = state.profile.isDarkMode;
    final dateStr = DateFormatter.formatDateOnly(log.timestamp);
    final timeStr = DateFormat('HH:mm:ss').format(log.timestamp);

    final sevColor = switch (log.severity) {
      AuditSeverity.success => AppColors.incomeGreen,
      AuditSeverity.warning => AppColors.warningOrange,
      AuditSeverity.error || AuditSeverity.critical => AppColors.expenseRed,
      _ => AppColors.infoBlue,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Detail'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER CARD
            Card(
              color: sevColor.withValues(alpha: 0.12),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: sevColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            log.action,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: log.result == AuditResult.success
                                ? AppColors.incomeGreen.withValues(alpha: 0.2)
                                : AppColors.expenseRed.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Status: ${log.result.name.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: log.result == AuditResult.success
                                  ? AppColors.incomeGreen
                                  : AppColors.expenseRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      log.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$dateStr at $timeStr',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // DESCRIPTION & SUMMARY
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                    const SizedBox(height: 6),
                    Text(
                      log.description.isNotEmpty ? log.description : 'No additional description provided.',
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // METADATA & FIELD DIFFS (Old Value vs New Value)
            if (log.oldValue != null || log.newValue != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Data Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                      const SizedBox(height: 12),
                      if (log.oldValue != null) ...[
                        const Text('State Before Change:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.expenseRed)),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(log.oldValue!, style: const TextStyle(fontSize: 12, height: 1.4)),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (log.newValue != null) ...[
                        const Text('State After Change:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.incomeGreen)),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(log.newValue!, style: const TextStyle(fontSize: 12, height: 1.4)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ENTITY DETAILS TABLE
            Card(
              child: Column(
                children: [
                  _detailRow('Entity Type', log.entityType, isDark),
                  const Divider(height: 1),
                  _detailRow('Entity ID', log.entityId ?? 'N/A', isDark),
                  const Divider(height: 1),
                  _detailRow('Screen / Source', log.screen ?? 'Background', isDark),
                  if (log.durationMs != null) ...[
                    const Divider(height: 1),
                    _detailRow('Duration', '${log.durationMs} ms', isDark),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ERROR & STACK TRACE (if error)
            if (log.errorMessage != null || log.errorCode != null) ...[
              Card(
                color: AppColors.expenseRed.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Technical Diagnostic Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.expenseRed)),
                      if (log.errorCode != null) ...[
                        const SizedBox(height: 6),
                        Text('Error Code: ${log.errorCode}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                      if (log.errorMessage != null) ...[
                        const SizedBox(height: 6),
                        Text(log.errorMessage!, style: const TextStyle(fontSize: 12)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ENTITY HISTORY BUTTON
            if (log.entityId != null && log.entityId!.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.history_rounded),
                  label: Text('View Full History for ${log.entityType}'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EntityHistoryScreen(
                          state: state,
                          entityType: log.entityType,
                          entityId: log.entityId!,
                          entityName: log.title,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
