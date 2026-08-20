import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isGuestMode = false;
  bool _isInitialized = false;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? const LocalAuthService() {
    checkSession();
  }

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isGuestMode => _isGuestMode;
  bool get isInitialized => _isInitialized;

  /// Check active user session or guest mode on app start
  Future<void> checkSession() async {
    try {
      _currentUser = await _authService.checkActiveSession();
      _isAuthenticated = _currentUser != null;

      final prefs = await SharedPreferences.getInstance();
      _isGuestMode = prefs.getBool('is_guest_mode') ?? false;
    } catch (e) {
      debugPrint('Error checking active session: $e');
      _currentUser = null;
      _isAuthenticated = false;
      _isGuestMode = false;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Enable or disable optional guest mode
  Future<void> setGuestMode(bool value) async {
    _isGuestMode = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value) {
        await prefs.setBool('is_guest_mode', true);
      } else {
        await prefs.remove('is_guest_mode');
      }
    } catch (e) {
      debugPrint('Error saving guest mode: $e');
    }
    notifyListeners();
  }

  /// Login with username and password
  Future<void> login(String username, String password) async {
    try {
      _currentUser = await _authService.login(username, password);
      _isAuthenticated = true;
      _isGuestMode = false;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_guest_mode');
      notifyListeners();
    } catch (e) {
      _currentUser = null;
      _isAuthenticated = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Register a new user profile
  Future<void> register(
    String username,
    String displayName,
    String password,
    String avatarEmoji,
  ) async {
    try {
      _currentUser = await _authService.register(
        username,
        displayName,
        password,
        avatarEmoji,
      );
      _isAuthenticated = true;
      _isGuestMode = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_guest_mode');
      notifyListeners();
    } catch (e) {
      _currentUser = null;
      _isAuthenticated = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Log out from the current profile session
  Future<void> logout() async {
    try {
      await _authService.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_guest_mode');
    } catch (e) {
      debugPrint('Error logging out: $e');
    } finally {
      _currentUser = null;
      _isAuthenticated = false;
      _isGuestMode = false;
      notifyListeners();
    }
  }
}
