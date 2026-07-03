import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

/// Exposes authentication state to the widget tree.
class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String _userEmail = '';
  String? _errorMessage;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String get userEmail => _userEmail;
  String? get errorMessage => _errorMessage;

  // ── Initialisation ─────────────────────────────────────────────────────────

  /// Called once at startup to restore persisted session.
  Future<void> checkLoginStatus() async {
    _isLoggedIn = await AuthService.instance.isLoggedIn();
    _userEmail = await AuthService.instance.getUserEmail();
    notifyListeners();
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    final success = await AuthService.instance.login(email, password);
    if (success) {
      _isLoggedIn = true;
      _userEmail = email.trim();
    } else {
      _errorMessage = 'Invalid email or password. Please try again.';
    }

    _setLoading(false);
    return success;
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    _setLoading(true);
    await AuthService.instance.logout();
    _isLoggedIn = false;
    _userEmail = '';
    _setLoading(false);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
