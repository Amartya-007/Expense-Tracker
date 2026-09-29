import 'package:flutter/material.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/screens/home/home_screen.dart';
import 'package:expensetracker/screens/transactions/transactions_screen.dart';
import 'package:expensetracker/screens/budgets/budgets_screen.dart';
import 'package:expensetracker/screens/insights/insights_screen.dart';
import 'package:expensetracker/screens/more/more_screen.dart';
import 'package:expensetracker/screens/add_transaction/add_transaction_sheet.dart';

class MainNavigationScreen extends StatefulWidget {
  final AppState state;
  const MainNavigationScreen({super.key, required this.state});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.state.processPendingSms();
    }
  }

  void _openAddTransaction() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionSheet(state: widget.state),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final isDark = widget.state.profile.isDarkMode;

        final List<Widget> pages = [
          HomeScreen(
            state: widget.state,
            onNavigateToTab: (index) => setState(() => _currentIndex = index),
          ),
          TransactionsScreen(state: widget.state),
          BudgetsScreen(state: widget.state),
          InsightsScreen(state: widget.state),
          MoreScreen(state: widget.state),
        ];

        return Scaffold(
          body: IndexedStack(index: _currentIndex, children: pages),
          floatingActionButton: _currentIndex == 0
              ? FloatingActionButton(
                  onPressed: _openAddTransaction,
                  backgroundColor: AppColors.primary,
                  elevation: 6,
                  shape: const CircleBorder(),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
                )
              : null,
          bottomNavigationBar: NavigationBarTheme(
            data: NavigationBarThemeData(
              indicatorColor: AppColors.primary.withValues(alpha: 0.12),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.primaryDark : AppColors.primary,
                  );
                }
                return TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.normal,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return IconThemeData(
                    size: 22,
                    color: isDark ? AppColors.primaryDark : AppColors.primary,
                  );
                }
                return IconThemeData(
                  size: 22,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                );
              }),
            ),
            child: NavigationBar(
              height: 68,
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) =>
                  setState(() => _currentIndex = index),
              backgroundColor: isDark
                  ? AppColors.darkSurface
                  : AppColors.lightSurface,
              surfaceTintColor: Colors.transparent,
              elevation: 8,
              animationDuration: const Duration(milliseconds: 300),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: 'Transactions',
                ),
                NavigationDestination(
                  icon: Icon(Icons.pie_chart_outline_rounded),
                  selectedIcon: Icon(Icons.pie_chart_rounded),
                  label: 'Budgets',
                ),
                NavigationDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon: Icon(Icons.insights_rounded),
                  label: 'Insights',
                ),
                NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view_rounded),
                  label: 'More',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
