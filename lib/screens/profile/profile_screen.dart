import 'package:flutter/material.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/utils/currency_formatter.dart';
import 'package:expensetracker/screens/settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final AppState state;
  const ProfileScreen({super.key, required this.state});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _editNameDialog() {
    final controller = TextEditingController(text: widget.state.profile.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Your Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                widget.state.updateProfileName(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editCurrencyDialog() {
    final currencies = ['₹', r'$', '€', '£', '¥', 'AED', 'CAD', 'AUD'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Preferred Currency'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: currencies.length,
            itemBuilder: (ctx, i) {
              final c = currencies[i];
              final isSelected = widget.state.profile.currencySymbol == c;
              return ListTile(
                leading: Text(
                  c,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                title: Text(c == '₹' ? 'Indian Rupee (INR)' : c),
                trailing: isSelected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                      )
                    : null,
                onTap: () {
                  widget.state.updateCurrencySymbol(c);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.profile.isDarkMode;
    final isPrivacy = widget.state.profile.isPrivacyModeEnabled;
    final symbol = widget.state.profile.currencySymbol;
    final profile = widget.state.profile;

    final totalMoney = widget.state.totalAvailableMoney;
    final monthIncome = widget.state.thisMonthIncome;
    final monthExpense = widget.state.thisMonthExpense;
    final monthSaved = (monthIncome - monthExpense).clamp(0.0, double.infinity);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Financial Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'App Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(state: widget.state),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // PROFILE HEADER CARD
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      profile.name.isNotEmpty
                          ? profile.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: _editNameDialog,
                        tooltip: 'Edit Name',
                      ),
                    ],
                  ),
                  Text(
                    '100% Local & Offline Financial Identity',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // COMPACT PERSONAL SUMMARY (Exact as specified)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL MONEY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(
                      totalMoney,
                      symbol: symbol,
                      isPrivacyMode: isPrivacy,
                    ),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 24),
                  Text(
                    'THIS MONTH SUMMARY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _summaryCol(
                        'Income',
                        monthIncome,
                        AppColors.incomeGreen,
                        symbol,
                        isPrivacy,
                      ),
                      _summaryCol(
                        'Spent',
                        monthExpense,
                        AppColors.expenseRed,
                        symbol,
                        isPrivacy,
                      ),
                      _summaryCol(
                        'Saved',
                        monthSaved,
                        AppColors.infoBlue,
                        symbol,
                        isPrivacy,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // PREFERENCES & PRIVACY CONTROLS
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.currency_rupee_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Preferred Currency',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text('${profile.currencySymbol} (Tap to change)'),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                  ),
                  onTap: _editCurrencyDialog,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(
                    Icons.visibility_off_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'One-Tap Privacy Mode',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Mask financial values across all screens',
                  ),
                  value: profile.isPrivacyModeEnabled,
                  onChanged: (val) => widget.state.togglePrivacyMode(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _summaryCol(
    String label,
    double amount,
    Color color,
    String symbol,
    bool isPrivacy,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.format(
            amount,
            symbol: symbol,
            isPrivacyMode: isPrivacy,
          ),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
