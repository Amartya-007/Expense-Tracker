class UserProfile {
  String name;
  String currencySymbol;
  double monthlyIncomeGoal;
  bool isPrivacyModeEnabled;
  bool hideBalances;
  bool isDarkMode;
  List<String> homeSectionOrder;
  bool isOnboarded;
  int onboardingVersion;

  UserProfile({
    this.name = '',
    this.currencySymbol = '₹',
    this.monthlyIncomeGoal = 0.0,
    this.isPrivacyModeEnabled = false,
    this.hideBalances = false,
    this.isDarkMode = false,
    this.homeSectionOrder = const [
      'balance',
      'cash_flow',
      'spending_snapshot',
      'budget_snapshot',
      'recent_transactions',
      'upcoming_bills',
      'goals',
      'financial_insights',
    ],
    this.isOnboarded = false,
    this.onboardingVersion = 0,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'currencySymbol': currencySymbol,
    'monthlyIncomeGoal': monthlyIncomeGoal,
    'isPrivacyModeEnabled': isPrivacyModeEnabled,
    'hideBalances': hideBalances,
    'isDarkMode': isDarkMode,
    'homeSectionOrder': homeSectionOrder,
    'isOnboarded': isOnboarded,
    'onboardingVersion': onboardingVersion,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final onboardingVersion = (json['onboardingVersion'] as num?)?.toInt() ?? 0;
    return UserProfile(
      name: json['name'] ?? '',
      currencySymbol: json['currencySymbol'] ?? '₹',
      monthlyIncomeGoal:
          (json['monthlyIncomeGoal'] as num?)?.toDouble() ?? 0.0,
      isPrivacyModeEnabled: json['isPrivacyModeEnabled'] ?? false,
      hideBalances: json['hideBalances'] ?? false,
      isDarkMode: json['isDarkMode'] ?? false,
      homeSectionOrder: List<String>.from(
        json['homeSectionOrder'] ??
            [
              'balance',
              'cash_flow',
              'spending_snapshot',
              'budget_snapshot',
              'recent_transactions',
              'upcoming_bills',
              'goals',
              'financial_insights',
            ],
      ),
      isOnboarded: json['isOnboarded'] == true && onboardingVersion >= 1,
      onboardingVersion: onboardingVersion,
    );
  }
}
