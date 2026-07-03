import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_constants.dart';

/// Handles authentication logic using demo credentials and SharedPreferences.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns [true] if credentials match the demo account.
  Future<bool> login(String email, String password) async {
    final valid =
        email.trim() == AppConstants.demoEmail &&
        password == AppConstants.demoPassword;
    if (valid) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.prefIsLoggedIn, true);
      await prefs.setString(AppConstants.prefUserEmail, email.trim());
    }
    return valid;
  }

  /// Clears the persisted login state.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefIsLoggedIn);
    await prefs.remove(AppConstants.prefUserEmail);
  }

  /// Checks whether the user is currently logged in.
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.prefIsLoggedIn) ?? false;
  }

  /// Returns the saved user email or an empty string.
  Future<String> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefUserEmail) ?? '';
  }
}
