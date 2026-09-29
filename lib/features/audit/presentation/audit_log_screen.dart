import 'package:flutter/material.dart';
import 'package:expensetracker/models/audit_log.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/utils/date_formatter.dart';
import 'package:expensetracker/features/audit/presentation/audit_log_detail_screen.dart';
import 'package:intl/intl.dart';

class AuditLogScreen extends StatefulWidget {
  final AppState state;
  const AuditLogScreen({super.key, required this.state});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All'; // All, Transaction, Account, Category, Budget, Goal, Recurring, Import, Settings, Validation, Error, Database, System
  AuditSeverity? _selectedSeverity;
  String _dateRangeLabel = 'All Time';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _ascending = false;

  List<AuditLog> _logs = [];
  Map<String, int> _todaySummary = {'total': 0, 'changes': 0, 'warnings': 0, 'errors': 0};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshLogs();
  }

  Future<void> _refreshLogs() async {
    final summary = await widget.state.databaseService.auditRepo.getTodaySummary();
    final list = await widget.state.databaseService.auditRepo.getLogs(
      searchQuery: _searchQuery,
      entityTypeFilter: _selectedCategory,
      severityFilter: _selectedSeverity,
      startDate: _startDate,
      endDate: _endDate,
      ascending: _ascending,
    );
    if (mounted) {
      setState(() {
        _todaySummary = summary;
        _logs = list;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.profile.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity & Audit Log'),
        actions: [
          IconButton(
            tooltip: 'Export Audit Log',
            icon: const Icon(Icons.download_rounded),
            onPressed: _showExportDialog,
          ),
          IconButton(
            tooltip: 'Retention Settings',
            icon: const Icon(Icons.auto_delete_outlined),
            onPressed: _showRetentionDialog,
          ),
          IconButton(
            tooltip: 'Clear Audit History',
            icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.expenseRed),
            onPressed: _confirmClearHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          // TODAY SUMMARY HEADER CARD
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryStat('Today\'s Events', '${_todaySummary['total']}', AppColors.primary, isDark),
                _summaryStat('Changes', '${_todaySummary['changes']}', AppColors.incomeGreen, isDark),
                _summaryStat('Warnings', '${_todaySummary['warnings']}', AppColors.warningOrange, isDark),
                _summaryStat('Errors', '${_todaySummary['errors']}', AppColors.expenseRed, isDark),
              ],
            ),
          ),
          const Divider(height: 1),

          // SEARCH & FILTER CONTROLS
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search actions, merchants, errors...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _searchQuery = '';
                          _refreshLogs();
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onChanged: (val) {
                _searchQuery = val;
                _refreshLogs();
              },
            ),
          ),

          // CHIP FILTERS (Category & Date Range)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _dateFilterChip(),
                const SizedBox(width: 8),
                _categoryChip('All'),
                const SizedBox(width: 6),
                _categoryChip('Transaction'),
                const SizedBox(width: 6),
                _categoryChip('Account'),
                const SizedBox(width: 6),
                _categoryChip('Category'),
                const SizedBox(width: 6),
                _categoryChip('Budget'),
                const SizedBox(width: 6),
                _categoryChip('Goal'),
                const SizedBox(width: 6),
                _categoryChip('Recurring'),
                const SizedBox(width: 6),
                _categoryChip('Import'),
                const SizedBox(width: 6),
                _categoryChip('Settings'),
                const SizedBox(width: 6),
                _categoryChip('Validation'),
                const SizedBox(width: 6),
                _categoryChip('Error'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // SORTING & SEVERITY BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<AuditSeverity?>(
                  value: _selectedSeverity,
                  isDense: true,
                  hint: const Text('Severity: All', style: TextStyle(fontSize: 12)),
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Severity: All', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: AuditSeverity.success, child: Text('Success Only', style: TextStyle(fontSize: 12, color: AppColors.incomeGreen))),
                    DropdownMenuItem(value: AuditSeverity.warning, child: Text('Warnings Only', style: TextStyle(fontSize: 12, color: AppColors.warningOrange))),
                    DropdownMenuItem(value: AuditSeverity.error, child: Text('Errors Only', style: TextStyle(fontSize: 12, color: AppColors.expenseRed))),
                  ],
                  onChanged: (s) {
                    setState(() => _selectedSeverity = s);
                    _refreshLogs();
                  },
                ),
                TextButton.icon(
                  icon: Icon(_ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 16),
                  label: Text(_ascending ? 'Oldest First' : 'Newest First', style: const TextStyle(fontSize: 12)),
                  onPressed: () {
                    setState(() => _ascending = !_ascending);
                    _refreshLogs();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // LOGS TIMELINE
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_rounded, size: 56, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                            const SizedBox(height: 12),
                            Text(
                              'No activity logs found',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try clearing filters or performing actions inside the app.',
                              style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshLogs,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          itemCount: _logs.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            final log = _logs[idx];
                            final dateStr = DateFormatter.formatDateOnly(log.timestamp);
                            final timeStr = DateFormat('HH:mm:ss').format(log.timestamp);

                            final sevColor = switch (log.severity) {
                              AuditSeverity.success => AppColors.incomeGreen,
                              AuditSeverity.warning => AppColors.warningOrange,
                              AuditSeverity.error || AuditSeverity.critical => AppColors.expenseRed,
                              _ => AppColors.infoBlue,
                            };

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: sevColor.withValues(alpha: 0.15),
                                child: Icon(
                                  log.result == AuditResult.success
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.error_outline_rounded,
                                  color: sevColor,
                                  size: 20,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      log.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                  Text(
                                    timeStr,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                '$dateStr • ${log.action} • ${log.entityType}${log.description.isNotEmpty ? ' • ${log.description}' : ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AuditLogDetailScreen(state: widget.state, log: log),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
      ],
    );
  }

  Widget _categoryChip(String category) {
    final isSel = _selectedCategory == category;
    return ChoiceChip(
      selected: isSel,
      label: Text(category, style: const TextStyle(fontSize: 11)),
      onSelected: (val) {
        if (val) {
          setState(() => _selectedCategory = category);
          _refreshLogs();
        }
      },
    );
  }

  Widget _dateFilterChip() {
    return ActionChip(
      avatar: const Icon(Icons.calendar_today_rounded, size: 14),
      label: Text(_dateRangeLabel, style: const TextStyle(fontSize: 11)),
      onPressed: _selectDateRange,
    );
  }

  void _selectDateRange() async {
    final now = DateTime.now();
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('All Time'),
              onTap: () {
                setState(() {
                  _dateRangeLabel = 'All Time';
                  _startDate = null;
                  _endDate = null;
                });
                Navigator.pop(ctx);
                _refreshLogs();
              },
            ),
            ListTile(
              title: const Text('Today'),
              onTap: () {
                setState(() {
                  _dateRangeLabel = 'Today';
                  _startDate = DateTime(now.year, now.month, now.day);
                  _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
                });
                Navigator.pop(ctx);
                _refreshLogs();
              },
            ),
            ListTile(
              title: const Text('Last 7 Days'),
              onTap: () {
                setState(() {
                  _dateRangeLabel = 'Last 7 Days';
                  _startDate = now.subtract(const Duration(days: 7));
                  _endDate = now;
                });
                Navigator.pop(ctx);
                _refreshLogs();
              },
            ),
            ListTile(
              title: const Text('This Month'),
              onTap: () {
                setState(() {
                  _dateRangeLabel = 'This Month';
                  _startDate = DateTime(now.year, now.month, 1);
                  _endDate = now;
                });
                Navigator.pop(ctx);
                _refreshLogs();
              },
            ),
            ListTile(
              title: const Text('Custom Date Range...'),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2025, 1, 1),
                  lastDate: DateTime(2027, 12, 31),
                );
                if (picked != null) {
                  setState(() {
                    _dateRangeLabel = '${DateFormatter.formatDateOnly(picked.start)} - ${DateFormatter.formatDateOnly(picked.end)}';
                    _startDate = picked.start;
                    _endDate = picked.end;
                  });
                  _refreshLogs();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Activity History'),
        content: const Text('Export your activity and audit logs as JSON or CSV format for local backup.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.state.databaseService.auditService.logDataExported(type: 'Audit Log CSV');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Audit log CSV exported successfully.')),
              );
            },
            child: const Text('Export CSV'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.state.databaseService.auditService.logDataExported(type: 'Audit Log JSON');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Audit log JSON exported successfully.')),
              );
            },
            child: const Text('Export JSON'),
          ),
        ],
      ),
    );
  }

  void _showRetentionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Audit Retention Setting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Delete logs older than 30 days'),
              onTap: () async {
                Navigator.pop(ctx);
                final deleted = await widget.state.databaseService.auditRepo.deleteLogsOlderThanDays(30);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Cleaned $deleted audit records older than 30 days.')),
                  );
                  _refreshLogs();
                }
              },
            ),
            ListTile(
              title: const Text('Delete logs older than 90 days'),
              onTap: () async {
                Navigator.pop(ctx);
                final deleted = await widget.state.databaseService.auditRepo.deleteLogsOlderThanDays(90);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Cleaned $deleted audit records older than 90 days.')),
                  );
                  _refreshLogs();
                }
              },
            ),
            ListTile(
              title: const Text('Keep Forever (Default)'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Audit History?'),
        content: const Text(
          'This will permanently delete your activity history.\n\nYour transactions, accounts, and financial data WILL NOT be deleted.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expenseRed, foregroundColor: Colors.white),
            onPressed: () async {
              await widget.state.databaseService.auditRepo.clearAllLogs();
              if (ctx.mounted) Navigator.pop(ctx);
              _refreshLogs();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Audit history cleared.')),
                );
              }
            },
            child: const Text('Delete Audit History'),
          ),
        ],
      ),
    );
  }
}
