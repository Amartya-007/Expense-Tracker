import 'dart:convert';
import 'package:expensetracker/models/user_profile.dart';
import 'package:expensetracker/core/database/app_database.dart';

class UserProfileRepository {
  final AppDatabase db;

  UserProfileRepository(this.db);

  static const _selectColumns = '''
    id, name, currency_symbol, monthly_income_goal, is_privacy_mode_enabled,
    hide_balances, is_dark_mode, home_section_order, is_onboarded, onboarding_version
  ''';

  Future<UserProfile> getProfile() async {
    final resultSet = db.rawDb.select(
      'SELECT $_selectColumns FROM user_profiles ORDER BY id DESC LIMIT 1',
    );
    if (resultSet.isEmpty) return UserProfile();

    final row = resultSet.first;
    List<String> order;
    try {
      order = List<String>.from(jsonDecode(row['home_section_order'] as String));
    } catch (_) {
      order = UserProfile().homeSectionOrder;
    }

    return UserProfile(
      name: row['name'] as String? ?? '',
      currencySymbol: row['currency_symbol'] as String? ?? '₹',
      monthlyIncomeGoal: (row['monthly_income_goal'] as num?)?.toDouble() ?? 0.0,
      isPrivacyModeEnabled: (row['is_privacy_mode_enabled'] as int?) == 1,
      hideBalances: (row['hide_balances'] as int?) == 1,
      isDarkMode: (row['is_dark_mode'] as int?) == 1,
      homeSectionOrder: order,
      isOnboarded: (row['is_onboarded'] as int?) == 1,
      onboardingVersion: (row['onboarding_version'] as int?) ?? 0,
    );
  }

  Future<void> saveProfile(UserProfile profile) async {
    db.rawDb.execute('BEGIN TRANSACTION');
    try {
      final stmt = db.rawDb.prepare('''
        INSERT OR REPLACE INTO user_profiles (
          id, name, currency_symbol, monthly_income_goal,
          is_privacy_mode_enabled, hide_balances, is_dark_mode,
          home_section_order, is_onboarded, onboarding_version
        ) VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''');
      stmt.execute([
        profile.name,
        profile.currencySymbol,
        profile.monthlyIncomeGoal,
        profile.isPrivacyModeEnabled ? 1 : 0,
        profile.hideBalances ? 1 : 0,
        profile.isDarkMode ? 1 : 0,
        jsonEncode(profile.homeSectionOrder),
        profile.isOnboarded ? 1 : 0,
        profile.onboardingVersion,
      ]);
      stmt.dispose();
      db.rawDb.execute('COMMIT');
    } catch (_) {
      db.rawDb.execute('ROLLBACK');
      rethrow;
    }
  }
}
