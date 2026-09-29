import 'package:flutter/material.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/utils/currency_formatter.dart';
import 'package:expensetracker/screens/profile/profile_screen.dart';
import 'package:expensetracker/screens/accounts/accounts_screen.dart';
import 'package:expensetracker/screens/recurring_bills/recurring_bills_screen.dart';
import 'package:expensetracker/screens/goals/goals_screen.dart';
import 'package:expensetracker/screens/calendar/calendar_screen.dart';
import 'package:expensetracker/screens/available_to_spend/available_to_spend_screen.dart';
import 'package:expensetracker/screens/to_review/to_review_screen.dart';
import 'package:expensetracker/screens/shared/shared_expenses_screen.dart';
import 'package:expensetracker/screens/categories/categories_screen.dart';
import 'package:expensetracker/screens/receipts/receipts_screen.dart';
import 'package:expensetracker/screens/settings/settings_screen.dart';
import 'package:expensetracker/screens/ai_assistant/ai_assistant_screen.dart';
import 'package:expensetracker/screens/tags/tags_screen.dart';
import 'package:expensetracker/features/audit/presentation/audit_log_screen.dart';

class MoreScreen extends StatelessWidget {
  final AppState state;
  const MoreScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = state.profile.isDarkMode;
    final isPrivacy = state.profile.isPrivacyModeEnabled;
    final symbol = state.profile.currencySymbol;
    final profile = state.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('More Hub')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. VISUALLY PROMINENT PROFILE CARD AT TOP
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen(state: state)),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.15,
                      ),
                      child: Text(
                        profile.name.isNotEmpty
                            ? profile.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                profile.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Available: ${CurrencyFormatter.format(state.totalAvailableMoney, symbol: symbol, isPrivacyMode: isPrivacy)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap to view your financial profile',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white38 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // LOCAL AI ASSISTANT BANNER
          Card(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.smart_toy_rounded,
                color: AppColors.primary,
                size: 28,
              ),
              title: const Text(
                'AI Money Assistant',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: const Text(
                '100% offline natural language financial queries',
                style: TextStyle(fontSize: 11),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.primary,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AIAssistantScreen(state: state),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          Card(
            color: AppColors.infoBlue.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.history_rounded,
                color: AppColors.infoBlue,
                size: 28,
              ),
              title: const Text(
                'Activity & Audit Log',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: const Text(
                'Detailed history of all actions and state changes',
                style: TextStyle(fontSize: 11),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.infoBlue,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AuditLogScreen(state: state),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // 2. MONEY MANAGEMENT
          _sectionTitle('MONEY & BUDGET PLANNING', isDark),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _menuTile(
                  Icons.account_balance_rounded,
                  'Accounts & Cards',
                  '${state.accounts.length} tracked accounts & credit cards',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AccountsScreen(state: state),
                    ),
                  ),
                ),
                const Divider(height: 1),
                _menuTile(
                  Icons.savings_rounded,
                  'Available to Spend',
                  'Dedicated safe-to-spend allowance formula',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AvailableToSpendScreen(state: state),
                    ),
                  ),
                ),
                const Divider(height: 1),
                _menuTile(
                  Icons.flag_rounded,
                  'Savings Goals',
                  '${state.goals.length} active financial targets',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GoalsScreen(state: state),
                    ),
                  ),
                ),
                const Divider(height: 1),
                _menuTile(
                  Icons.repeat_rounded,
                  'Bills & Recurring Payments',
                  '${state.recurringBills.length} active bills & subscriptions',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecurringBillsScreen(state: state),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. AUTOMATION & TIMELINE
          _sectionTitle('AUTOMATION & TIMELINE', isDark),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _menuTile(
                  Icons.sms_failed_rounded,
                  'SMS Review Queue',
                  '${state.reviewQueue.length} transactions waiting for review',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ToReviewScreen(state: state),
                    ),
                  ),
                  badge: state.reviewQueue.isNotEmpty
                      ? '${state.reviewQueue.length}'
                      : null,
                ),
                const Divider(height: 1),
                _menuTile(
                  Icons.calendar_month_rounded,
                  'Financial Calendar',
                  'Monthly spending & daily net activity',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CalendarScreen(state: state),
                    ),
                  ),
                ),
                const Divider(height: 1),
                _menuTile(
                  Icons.receipt_long_rounded,
                  'Receipts Gallery',
                  'Zoom & manage all stored receipt photos',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReceiptsScreen(state: state),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. SHARING
          _sectionTitle('SHARED EXPENSES', isDark),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _menuTile(
                  Icons.group_rounded,
                  'Shared Expenses',
                  'Bill splitting with friends & unsettled debts',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SharedExpensesScreen(state: state),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. SYSTEM SETTINGS
          _sectionTitle('SYSTEM & SETTINGS', isDark),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _menuTile(
                  Icons.category_rounded,
                  'Categories',
                  '${state.categories.length} custom income & expense categories',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoriesScreen(state: state),
                    ),
                  ),
                ),
                const Divider(height: 1),
                _menuTile(
                  Icons.tag_rounded,
                  'Tags & Labels',
                  '${state.allAvailableTags.length} tags for classifying transactions',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TagsScreen(state: state)),
                  ),
                ),
                const Divider(height: 1),
                _menuTile(
                  Icons.settings_rounded,
                  'Settings',
                  'Privacy, Backup & Restore, Clean Slate',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SettingsScreen(state: state),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 96),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
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

  Widget _menuTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    String? badge,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.expenseRed,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        ],
      ),
      onTap: onTap,
    );
  }
}
