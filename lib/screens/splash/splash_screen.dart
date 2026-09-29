import 'package:flutter/material.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/screens/onboarding/onboarding_screen.dart';
import 'package:expensetracker/screens/main_navigation_screen.dart';
import 'package:expensetracker/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final AppState state;
  const SplashScreen({super.key, required this.state});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkNavigation();
  }

  Future<void> _checkNavigation() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    if (!widget.state.profile.isOnboarded) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OnboardingScreen(state: widget.state),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainNavigationScreen(state: widget.state),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.profile.isDarkMode;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 96,
                height: 96,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'RupeeCommand',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Personal Money Command Center',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
