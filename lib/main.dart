import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/create_schedule_screen.dart';
import 'screens/schedule_details_screen.dart';
import 'screens/checkout_screen.dart';
import 'utils/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Load theme preference before first frame.
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
      ],
      child: const FieldAgentSchedulerApp(),
    ),
  );
}

class FieldAgentSchedulerApp extends StatelessWidget {
  const FieldAgentSchedulerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,

      // ── Light Theme (Material 3) ───────────────────────────────────────────
      theme: _buildTheme(Brightness.light),

      // ── Dark Theme (Material 3) ────────────────────────────────────────────
      darkTheme: _buildTheme(Brightness.dark),

      // ── Routes ────────────────────────────────────────────────────────────
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        // Main bottom-nav shell (tabs: Dashboard / Schedules / Reports / Profile)
        '/shell': (_) => const MainShell(),
        // Legacy named route kept so any pushNamed('/dashboard') still lands correctly
        '/dashboard': (_) => const MainShell(initialIndex: 0),
        '/schedules': (_) => const MainShell(initialIndex: 1),
        '/reports': (_) => const MainShell(initialIndex: 2),
        // Detail screens pushed on top of the shell
        '/create-schedule': (_) => const CreateScheduleScreen(),
        '/schedule-details': (_) => const ScheduleDetailsScreen(),
        '/checkout': (_) => const CheckoutScreen(),
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.seedColor,
        brightness: brightness,
      ),
      fontFamily: 'Roboto',

      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 2,
        backgroundColor: isDark ? AppConstants.deepNavy : Colors.white,
        foregroundColor: isDark ? Colors.white : AppConstants.deepNavy,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppConstants.deepNavy,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: AppConstants.cardElevation,
        color: isDark ? AppConstants.slate800 : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        margin: EdgeInsets.zero,
      ),

      // Scaffold
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0F172A)
          : AppConstants.slate50,

      // Navigation bar — cobalt active icon/label, transparent indicator (no pill)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppConstants.slate800 : Colors.white,
        elevation: 8,
        indicatorColor: Colors.transparent,
        indicatorShape: const RoundedRectangleBorder(),
        overlayColor: WidgetStateProperty.all(
          AppConstants.primaryAccent.withValues(alpha: 0.06),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected
                ? AppConstants.primaryAccent
                : (isDark ? AppConstants.slate200 : AppConstants.slate600),
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? AppConstants.primaryAccent
                : (isDark ? AppConstants.slate200 : AppConstants.slate600),
          );
        }),
      ),

      // Snack bar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),

      // Filled button
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
      ),
    );
  }
}
