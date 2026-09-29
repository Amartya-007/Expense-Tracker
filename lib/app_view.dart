import 'package:flutter/material.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/services/database_service.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/screens/splash/splash_screen.dart';

class MyAppView extends StatefulWidget {
  const MyAppView({super.key});

  @override
  State<MyAppView> createState() => _MyAppViewState();
}

class _MyAppViewState extends State<MyAppView> {
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    final db = await DatabaseService.init();
    await _appState.init(db);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appState,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'RupeeCommand',
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: _appState.profile.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: !_appState.isInitialized
              ? Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text('Initializing Personal Money Command Center...'),
                      ],
                    ),
                  ),
                )
              : SplashScreen(state: _appState),
        );
      },
    );
  }
}
