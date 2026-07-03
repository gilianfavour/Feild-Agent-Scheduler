import 'package:flutter/material.dart';

/// Application-wide constants for colors, strings, and configuration.
class AppConstants {
  AppConstants._();

  // ── App Info ──────────────────────────────────────────────────────────────
  static const String appName = 'Field Agent Scheduler';
  static const String appVersion = '1.0.0';

  // ── Demo Credentials ──────────────────────────────────────────────────────
  static const String demoEmail = 'agent@test.com';
  static const String demoPassword = '123456';

  // ── SharedPreferences Keys ────────────────────────────────────────────────
  static const String prefIsLoggedIn = 'is_logged_in';
  static const String prefUserEmail = 'user_email';
  static const String prefSchedules = 'schedules';

  // ── Location ──────────────────────────────────────────────────────────────
  /// Maximum allowed distance (in metres) for a valid check-in.
  static const double checkInRadiusMeters = 100.0;

  // ── Color Palette (Field Operations) ──────────────────────────────────────
  static const Color seedColor = Color(0xFF2563EB); // cobalt blue
  static const Color primaryAccent = Color(0xFF2563EB); // cobalt
  static const Color successColor = Color(0xFF16A34A); // slate-green
  static const Color warningColor = Color(0xFFF59E0B); // amber
  static const Color errorColor = Color(0xFFC62828);

  // Neutrals
  static const Color deepNavy = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate50 = Color(0xFFF8FAFC);

  // ── Status Labels ─────────────────────────────────────────────────────────
  static const String statusPending = 'pending';
  static const String statusCheckedIn = 'checkedIn';
  static const String statusCompleted = 'completed';

  // ── UI Spacing ────────────────────────────────────────────────────────────
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;

  // ── Status chip colors ────────────────────────────────────────────────────
  static Color statusColor(String status) {
    switch (status) {
      case statusCheckedIn:
        return primaryAccent; // cobalt – active/in-progress
      case statusCompleted:
        return successColor; // quiet green
      default:
        return warningColor; // amber – needs attention
    }
  }

  static String statusLabel(String status) {
    switch (status) {
      case statusCheckedIn:
        return 'Checked In';
      case statusCompleted:
        return 'Completed';
      default:
        return 'Pending';
    }
  }

  static IconData statusIcon(String status) {
    switch (status) {
      case statusCheckedIn:
        return Icons.login_rounded;
      case statusCompleted:
        return Icons.check_circle_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }
}
