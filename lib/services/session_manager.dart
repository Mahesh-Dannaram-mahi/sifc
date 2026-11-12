// services/session_manager.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'storage_service.dart';
import '../Login_page/widgets/login.dart';

class SessionManager {
  static Timer? _sessionTimer;
  static bool _isMonitoring = false;
  static final List<VoidCallback> _listeners = [];

  // Start monitoring session validity
  static void startMonitoring(BuildContext context) {
    if (_isMonitoring) return;
    _isMonitoring = true;

    // print('🔄 Starting session monitoring...');

    // Check immediately
    _checkAndValidateSession(context);

    // Then check every 2 minutes
    _sessionTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _checkAndValidateSession(context);
    });
  }

  static void stopMonitoring() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _isMonitoring = false;
    // print('⏹️ Session monitoring stopped');
  }

  static Future<void> _checkAndValidateSession(BuildContext context) async {
    try {
      // First check local token validity
      final isValid = await StorageService.isTokenValid();

      if (!isValid) {
        // print('❌ Token invalid locally, redirecting to login');
        _redirectToLogin(context);
        return;
      }

      // Then validate with backend
      final isBackendValid = await StorageService.validateSessionWithBackend();

      if (!isBackendValid) {
        // print('❌ Session invalid on backend, redirecting to login');
        _redirectToLogin(context);
        return;
      }

      // Get token expiry info for logging
      final expiry = await StorageService.getTokenExpiry();
      if (expiry != null) {
        final remaining = expiry.difference(DateTime.now().toUtc());
        // print('⏱️ Session valid. Remaining: ${remaining.inMinutes} minutes');

        // If less than 1 day remaining, show warning
        if (remaining.inDays < 1) {
          _notifyListeners();
        }
      }
    } catch (e) {
      // print('⚠️ Session check error: $e');
    }
  }

  static void _redirectToLogin(BuildContext context) {
    // Clear all auth data
    StorageService.clearAuthData();

    // Stop monitoring
    stopMonitoring();

    // Navigate to login
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  // Add listener for session expiry warnings
  static void addListener(VoidCallback listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  static void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  // Check if session is valid without redirecting
  static Future<bool> isSessionValid() async {
    final isValid = await StorageService.isTokenValid();
    if (!isValid) return false;
    return await StorageService.validateSessionWithBackend();
  }
}
