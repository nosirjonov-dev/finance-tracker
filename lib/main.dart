// ============================================================
// main.dart
// Entry point for the Finance Tracker Flutter app.
// Sets up the app theme and root widget.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/app_theme.dart';
import 'screens/home_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized before using plugins
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation for consistent layout
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set the system status bar to transparent / dark icons
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.primaryDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const FinanceTrackerApp());
}

/// Root widget of the application.
class FinanceTrackerApp extends StatelessWidget {
  const FinanceTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Tracker',
      debugShowCheckedModeBanner: false,
      // Apply the custom dark theme defined in AppTheme
      theme: AppTheme.darkTheme,
      // Start on the Home screen
      home: const HomeScreen(),
    );
  }
}
