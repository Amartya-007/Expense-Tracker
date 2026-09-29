import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/services/sms_capture_service.dart';
import 'package:expensetracker/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  final AppState state;
  const SettingsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = state.profile.isDarkMode;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _sectionHeader('APPEARANCE & PRIVACY', isDark),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(
                    Icons.dark_mode_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Dark Mode',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: const Text('Switch between light and dark theme'),
                  value: state.profile.isDarkMode,
                  onChanged: (val) => state.toggleDarkMode(),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(
                    Icons.visibility_off_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Privacy Mode (Mask Balances)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Mask currency values as ₹•••••• in public',
                  ),
                  value: state.profile.isPrivacyModeEnabled,
                  onChanged: (val) => state.togglePrivacyMode(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _sectionHeader('AUTOMATION', isDark),
          FutureBuilder<bool>(
            future: SmsCaptureService.hasPermission(),
            builder: (context, snapshot) {
              final enabled = snapshot.data == true;
              return Card(
                child: ListTile(
                  leading: Icon(
                    enabled ? Icons.sms_rounded : Icons.sms_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Automatic SMS capture',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    enabled ? 'Recognized bank alerts are added automatically' : 'Allow access to add recognized bank alerts automatically',
                  ),
                  trailing: enabled
                      ? const Icon(
                          Icons.check_circle,
                          color: AppColors.incomeGreen,
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: enabled
                      ? null
                      : () async {
                          final granted =
                              await SmsCaptureService.requestPermission();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                granted
                                    ? 'Automatic SMS capture enabled.'
                                    : 'SMS access was not enabled.',
                              ),
                            ),
                          );
                        },
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          _sectionHeader('DATA MANAGEMENT', isDark),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.download_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Export Backup (JSON)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: const Text('Download complete financial history'),
                  onTap: () => _exportBackup(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.restore_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text('Restore Backup (JSON)'),
                  subtitle: const Text(
                    'Paste a backup JSON file to restore your data',
                  ),
                  onTap: () => _showRestoreBackupDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.table_view_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text('Export Transactions (CSV)'),
                  subtitle: const Text(
                    'Save a spreadsheet-friendly transaction file',
                  ),
                  onTap: () => _exportCsv(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.upload_file_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text('Import Transactions (CSV)'),
                  subtitle: const Text(
                    'Paste CSV rows; duplicates are skipped',
                  ),
                  onTap: () => _showImportCsvDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.delete_sweep_rounded,
                    color: AppColors.expenseRed,
                  ),
                  title: const Text(
                    'Clear All Data (Clean Slate)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.expenseRed,
                    ),
                  ),
                  subtitle: const Text(
                    'Wipe all accounts & transactions to start 100% fresh',
                  ),
                  onTap: () => _confirmReset(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _sectionHeader('ABOUT & HELP', isDark),
          Card(
            child: const Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'RupeeCommand Version',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text('v1.0.0 • Personal Money Command Center'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Clear All Data?'),
          content: const Text(
            'This will permanently remove all accounts, transactions, budgets, goals, and recurring items so you can start completely fresh with your own finances.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expenseRed,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await state.clearAllData();
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'All data cleared. Welcome to your clean slate!',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File('${directory.path}/rupeecommand-backup-$stamp.json');
      await file.writeAsString(state.exportBackupJson(), flush: true);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup saved to ${file.path}'),
          action: SnackBarAction(
            label: 'Copy path',
            onPressed: () => Clipboard.setData(ClipboardData(text: file.path)),
          ),
          duration: const Duration(seconds: 8),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save backup: $error')));
    }
  }

  Future<void> _exportCsv(BuildContext context) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File(
        '${directory.path}/rupeecommand-transactions-$stamp.csv',
      );
      await file.writeAsString(state.exportTransactionsCsv(), flush: true);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV saved to ${file.path}'),
          action: SnackBarAction(
            label: 'Copy path',
            onPressed: () => Clipboard.setData(ClipboardData(text: file.path)),
          ),
          duration: const Duration(seconds: 8),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not export CSV: $error')));
    }
  }

  void _showRestoreBackupDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: const Text('Restore JSON Backup'),
        content: TextField(
          controller: controller,
          minLines: 8,
          maxLines: 12,
          decoration: const InputDecoration(
            hintText: 'Paste the contents of your backup JSON file',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await state.restoreBackupJson(controller.text);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Backup restored. Current app data was replaced.',
                      ),
                    ),
                  );
                }
              } catch (error) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Backup could not be restored: $error'),
                    ),
                  );
                }
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  void _showImportCsvDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: const Text('Import Transaction CSV'),
        content: TextField(
          controller: controller,
          minLines: 8,
          maxLines: 12,
          decoration: const InputDecoration(
            hintText: 'Paste CSV with the exported transaction columns',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final result = await state.importTransactionsCsv(
                  controller.text,
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Imported ${result.imported}; skipped ${result.skipped} invalid or duplicate rows.',
                      ),
                    ),
                  );
                }
              } catch (error) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('CSV could not be imported: $error'),
                    ),
                  );
                }
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }
}
