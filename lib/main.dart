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
import 'screens/map_picker_screen.dart';
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
        '/map-picker': (_) => const MapPickerScreen(),
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // ── Hand-crafted ColorScheme anchored to #2563EB cobalt ──────────────────
    // We start from seed to get all the Material 3 roles, then override the
    // primary family so every widget that reads colorScheme.primary uses the
    // exact cobalt — not the pale tone the seed algorithm derives.
    final base = ColorScheme.fromSeed(
      seedColor: AppConstants.primaryAccent,
      brightness: brightness,
    );

    final colorScheme = base.copyWith(
      primary: AppConstants.primaryAccent, // #2563EB  — buttons, FAB, active
      onPrimary: Colors.white,
      primaryContainer: AppConstants.primaryAccent.withValues(
        alpha: isDark ? 0.25 : 0.12,
      ), // tinted container
      onPrimaryContainer: isDark ? Colors.white : AppConstants.deepNavy,
      secondary: AppConstants.primaryAccent,
      onSecondary: Colors.white,
      surface: isDark ? AppConstants.slate800 : Colors.white,
      onSurface: isDark ? Colors.white : AppConstants.deepNavy,
      surfaceContainerHighest: isDark
          ? const Color(0xFF1E293B)
          : const Color(0xFFEFF2F7),
      outline: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
      outlineVariant: isDark
          ? const Color(0xFF1E293B)
          : const Color(0xFFE2E8F0),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Roboto',

      // ── Scaffold ────────────────────────────────────────────────────────────
      scaffoldBackgroundColor: isDark
          ? AppConstants.deepNavy
          : AppConstants.slate50,

      // ── AppBar ──────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 2,
        elevation: 0,
        backgroundColor: isDark ? AppConstants.deepNavy : Colors.white,
        foregroundColor: isDark ? Colors.white : AppConstants.deepNavy,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : AppConstants.deepNavy,
        ),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
              ),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppConstants.deepNavy,
          fontFamily: 'Roboto',
        ),
      ),

      // ── Cards ────────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 1,
        color: isDark ? AppConstants.slate800 : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Bottom Navigation Bar ─────────────────────────────────────────────
      // No pill indicator — active = cobalt icon + label only.
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
            fontFamily: 'Roboto',
            color: selected
                ? AppConstants.primaryAccent
                : (isDark ? AppConstants.slate200 : AppConstants.slate600),
          );
        }),
      ),

      // ── Filled Button ─────────────────────────────────────────────────────
      // Uses colorScheme.primary so it automatically picks up cobalt.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppConstants.primaryAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            fontFamily: 'Roboto',
          ),
        ),
      ),

      // ── Outlined Button ───────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.primaryAccent,
          side: BorderSide(
            color: AppConstants.primaryAccent.withValues(alpha: 0.5),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            fontFamily: 'Roboto',
          ),
        ),
      ),

      // ── Text Button ───────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppConstants.primaryAccent,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
          ),
        ),
      ),

      // ── FloatingActionButton ──────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppConstants.primaryAccent,
        foregroundColor: Colors.white,
        elevation: 3,
      ),

      // ── FilterChip / Chips ────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        selectedColor: AppConstants.primaryAccent.withValues(alpha: 0.15),
        checkmarkColor: AppConstants.primaryAccent,
        labelStyle: const TextStyle(fontSize: 13, fontFamily: 'Roboto'),
        side: BorderSide(
          color: AppConstants.primaryAccent.withValues(alpha: 0.3),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),

      // ── Switch ────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppConstants.primaryAccent
              : null,
        ),
      ),

      // ── Progress Indicator ────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppConstants.primaryAccent,
      ),

      // ── Input Decoration ──────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppConstants.slate800 : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : AppConstants.slate200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppConstants.primaryAccent,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppConstants.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppConstants.errorColor,
            width: 2,
          ),
        ),
        labelStyle: TextStyle(
          color: AppConstants.slate600,
          fontSize: 14,
          fontFamily: 'Roboto',
        ),
        hintStyle: TextStyle(
          color: AppConstants.slate600.withValues(alpha: 0.5),
          fontSize: 14,
          fontFamily: 'Roboto',
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),

      // ── Snack Bar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppConstants.slate800 : AppConstants.deepNavy,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontFamily: 'Roboto',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      // ── Dialog ────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppConstants.slate800 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppConstants.deepNavy,
          fontFamily: 'Roboto',
        ),
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: isDark ? const Color(0xFF1E293B) : AppConstants.slate200,
        thickness: 1,
        space: 1,
      ),

      // ── ListTile ─────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        iconColor: AppConstants.slate600,
        subtitleTextStyle: TextStyle(
          fontSize: 12,
          color: AppConstants.slate600,
          fontFamily: 'Roboto',
        ),
      ),
    );
  }
}
