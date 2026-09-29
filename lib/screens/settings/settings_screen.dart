import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/services/sms_capture_service.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/services/haptic_service.dart';
import 'package:expensetracker/screens/settings/parser_rules_screen.dart';

class SettingsScreen extends StatefulWidget {
  final AppState state;
  const SettingsScreen({super.key, required this.state});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hapticsEnabled = HapticService.isEnabled;

  void _showAccentColorPicker(BuildContext context) {
    HapticService.selection();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Accent Color'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AppColors.accentOptions.map((color) {
            return InkWell(
              onTap: () async {
                HapticService.success();
                widget.state.profile.accentColorValue = color.toARGB32();
                await widget.state.databaseService.profileRepo.saveProfile(widget.state.profile);
                widget.state.notifyStateChanged();
                if (context.mounted) {
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: widget.state.profile.accentColorValue == color.toARGB32()
                    ? const Icon(Icons.check_rounded, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.profile.isDarkMode;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _sectionHeader('APPEARANCE & THEME', isDark),
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
                  value: widget.state.profile.isDarkMode,
                  onChanged: (val) {
                    HapticService.selection();
                    widget.state.toggleDarkMode();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.color_lens_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Custom Accent Color',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: const Text('Personalize primary theme color'),
                  trailing: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Color(widget.state.profile.accentColorValue),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey, width: 1),
                    ),
                  ),
                  onTap: () => _showAccentColorPicker(context),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(
                    Icons.vibration_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Haptic Micro-Interactions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: const Text('Subtle tactile feedback for actions'),
                  value: _hapticsEnabled,
                  onChanged: (val) async {
                    await HapticService.setEnabled(val);
                    setState(() {
                      _hapticsEnabled = val;
                    });
                    if (val) HapticService.success();
                  },
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
                  value: widget.state.profile.isPrivacyModeEnabled,
                  onChanged: (val) {
                    HapticService.selection();
                    widget.state.togglePrivacyMode();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _sectionHeader('AUTOMATION & RULES', isDark),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.rule_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Transaction Parsing Rules',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: const Text('Custom regex and keyword rules for SMS parsing'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    HapticService.selection();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ParserRulesScreen(state: widget.state)),
                    );
                  },
                ),
                const Divider(height: 1),
                FutureBuilder<bool>(
                  future: SmsCaptureService.hasPermission(),
                  builder: (context, snapshot) {
                    final enabled = snapshot.data == true;
                    return ListTile(
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
                              HapticService.selection();
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
                    );
                  },
                ),
              ],
            ),
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
                  onTap: () => _exportJson(context),
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
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      ),
    );
  }

  Future<void> _exportJson(BuildContext context) async {
    HapticService.selection();
    try {
      final map = {
        'profile': widget.state.profile.toJson(),
        'transactions': widget.state.transactions.map((t) => t.toJson()).toList(),
        'accounts': widget.state.accounts.map((a) => a.toJson()).toList(),
      };
      final jsonStr = jsonEncode(map);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/rupeecommand_backup.json');
      await file.writeAsString(jsonStr);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup exported to ${file.path}'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }
}
