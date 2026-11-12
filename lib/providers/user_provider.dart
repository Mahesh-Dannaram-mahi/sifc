import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../services/jwt_service.dart';
import '../services/storage_service.dart';

class UserProvider extends ChangeNotifier {
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  /// Callback for when authentication fails (to be set by main app)
  VoidCallback? onAuthFailure;

  /// Load user data from API using stored token
  Future<bool> loadUser() async {
    if (_isLoading) return _isAuthenticated;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // ✅ Get token
      String? token = await StorageService.getToken();
      if (token == null) {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('tea_app_token');
        if (token != null) await StorageService.saveToken(token);
      }

      if (token == null) {
        // debugPrint('❌ No token found in loadUser');
        _isAuthenticated = false;
        _userData = null;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // ✅ Check if token is expired
      if (JwtService.isTokenExpired(token)) {
        debugPrint('❌ Token expired in loadUser');
        _handleAuthFailure();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final userId = JwtService.extractUserId(token);
      if (userId == null) {
        debugPrint('❌ No userId in token');
        _handleAuthFailure();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // ✅ Make API call with timeout
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/user/fetch-user-data/$userId'),
            headers: {
              'accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      // Handle 404 - User not found
      if (response.statusCode == 404) {
        debugPrint('❌ User not found (404)');
        _handleAuthFailure();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Handle 401 - Unauthorized
      if (response.statusCode == 401) {
        debugPrint('❌ Unauthorized (401)');
        _handleAuthFailure();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['user'] != null) {
          _userData = data['user'];
          _isAuthenticated = true;
          _isLoading = false;
          notifyListeners();
          debugPrint('✅ User loaded successfully');
          return true;
        } else {
          debugPrint('❌ User data not found in response');
          _handleAuthFailure();
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        // ✅ For other status codes, don't trigger auth failure
        // Just return false with error
        _error = 'Server error: ${response.statusCode}';
        _isAuthenticated = false;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on http.ClientException catch (e) {
      // ✅ Network errors - don't trigger auth failure
      _error = 'Network error: ${e.message}';
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      // ✅ Handle all other errors including TimeoutException
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('timeout')) {
        // ✅ Timeout errors - don't trigger auth failure
        _error = 'Request timeout. Please try again.';
        _isAuthenticated = false;
        _isLoading = false;
        notifyListeners();
        return false;
      } else if (errorStr.contains('401') ||
          errorStr.contains('403') ||
          errorStr.contains('unauthorized') ||
          errorStr.contains('forbidden')) {
        // ✅ Auth errors - trigger auth failure
        _handleAuthFailure();
        _isLoading = false;
        notifyListeners();
        return false;
      } else {
        // ✅ Other errors
        _error = e.toString();
        _isAuthenticated = false;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Handle authentication failure - clear all data and trigger logout
  void _handleAuthFailure() {
    debugPrint('🔄 Handling auth failure in UserProvider');
    _userData = null;
    _isAuthenticated = false;

    // Clear data asynchronously
    clearUserData();

    // Trigger callback if set
    if (onAuthFailure != null) {
      // Use addPostFrameCallback to avoid issues with setState
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onAuthFailure!();
      });
    }
  }

  /// Clear all user data from storage
  Future<void> clearUserData() async {
    _userData = null;
    _isAuthenticated = false;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tea_app_token');
    await prefs.remove('user_id');
    await prefs.remove('user_phone');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('is_logged_in');
    await prefs.remove('remember_me');
    await prefs.remove('user_role');
    await prefs.remove('user_avatar');
    await prefs.remove('tea_token_expiry');
    await prefs.remove('tea_token_expiry_days');
    await prefs.remove('tea_login_time');

    await StorageService.clearToken();
    await StorageService.clearUserId();
    await StorageService.clearAuthData();

    notifyListeners();
  }

  /// Update user data (e.g., after profile edit)
  void updateUser(Map<String, dynamic> updatedUser) {
    _userData = updatedUser;
    _isAuthenticated = true;
    notifyListeners();
  }

  /// Clear user data on logout
  void clearUser() {
    _userData = null;
    _isAuthenticated = false;
    _error = null;
    notifyListeners();
  }

  /// Refresh user data from API
  Future<bool> refreshUser() async {
    // Don't trigger auth failure on refresh
    final originalCallback = onAuthFailure;
    onAuthFailure = null;
    final result = await loadUser();
    onAuthFailure = originalCallback;
    return result;
  }

  /// Check authentication status
  Future<bool> checkAuthentication() async {
    return await loadUser();
  }
}
