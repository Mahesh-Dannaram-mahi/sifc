import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';

class StorageService {
  static const String _tokenKey = 'tea_app_token';
  static const String _userIdKey = 'user_id';
  static const String _pendingFcmTokenKey = 'pending_fcm_token';
  static const String _userPhoneKey = 'user_phone';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _rememberMeKey = 'remember_me';
  static const String _userRoleKey = 'user_role';
  static const String _tokenExpiryKey = 'token_expiry';

  // ===== Token Methods =====

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);

    final expiry = _extractTokenExpiry(token);
    if (expiry != null) {
      await prefs.setString(_tokenExpiryKey, expiry.toIso8601String());
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_tokenExpiryKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_tokenExpiryKey);
  }

  static DateTime? _extractTokenExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      String payload = parts[1];
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      final bytes = base64.decode(payload);
      final jsonString = utf8.decode(bytes);
      final Map<String, dynamic> data = json.decode(jsonString);

      final expiry = data['exp'];
      if (expiry == null) return null;

      int expirySeconds;
      if (expiry is int) {
        expirySeconds = expiry;
      } else if (expiry is double) {
        expirySeconds = expiry.toInt();
      } else if (expiry is String) {
        expirySeconds = int.parse(expiry);
      } else {
        return null;
      }

      return DateTime.fromMillisecondsSinceEpoch(
        expirySeconds * 1000,
        isUtc: true,
      );
    } catch (e) {
      return null;
    }
  }

  static Future<bool> isTokenValid() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token == null) {
      return false;
    }

    // Check stored expiry first
    final expiryStr = prefs.getString(_tokenExpiryKey);
    if (expiryStr != null) {
      try {
        final expiry = DateTime.parse(expiryStr);
        final nowUtc = DateTime.now().toUtc();

        if (nowUtc.isAfter(expiry)) {
          return false;
        }
      } catch (e) {
        // Ignore parse error
      }
    }

    // Also check token expiry directly
    final expiry = _extractTokenExpiry(token);
    if (expiry != null) {
      final nowUtc = DateTime.now().toUtc();
      if (nowUtc.isAfter(expiry)) {
        return false;
      }
      return true;
    }

    return true;
  }

  static Future<DateTime?> getTokenExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryStr = prefs.getString(_tokenExpiryKey);
    if (expiryStr != null) {
      try {
        return DateTime.parse(expiryStr);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // ===== User ID Methods =====

  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<void> removeUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
  }

  static Future<void> clearUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
  }

  // ===== User Info Methods =====

  static Future<void> saveUserPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userPhoneKey, phone);
  }

  static Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userPhoneKey);
  }

  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<void> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  static Future<void> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, role);
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  // ===== Login State Methods =====

  static Future<void> saveIsLoggedIn(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
  }

  static Future<bool> getIsLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<void> saveRememberMe(bool rememberMe) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, rememberMe);
  }

  static Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  // ===== Pending FCM Token Methods =====

  static Future<void> setPendingFcmToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingFcmTokenKey, token);
  }

  static Future<String?> getPendingFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pendingFcmTokenKey);
  }

  static Future<void> clearPendingFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingFcmTokenKey);
  }

  // ===== Session Validation with Backend =====

  static Future<bool> validateSessionWithBackend() async {
    try {
      final token = await getToken();
      if (token == null) {
        return false;
      }

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/validate-session'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final isValid = data['valid'] == true;

        if (isValid && data['expires_at'] != null) {
          try {
            final expiry = DateTime.parse(data['expires_at']).toUtc();
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_tokenExpiryKey, expiry.toIso8601String());
          } catch (_) {}
        }

        return isValid;
      } else if (response.statusCode == 401) {
        return false;
      } else {
        return await isTokenValid();
      }
    } on TimeoutException {
      return await isTokenValid();
    } catch (e) {
      return await isTokenValid();
    }
  }

  // ===== Authentication Status =====

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userId = prefs.getString(_userIdKey);
    final isLoggedInFlag = prefs.getBool(_isLoggedInKey) ?? false;

    if (token != null && userId != null && isLoggedInFlag) {
      return await isTokenValid();
    }

    return false;
  }

  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userPhoneKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_tokenExpiryKey);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<void> clearUserDataOnly() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userPhoneKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_tokenExpiryKey);
  }

  // ===== Helper/Utility Methods =====

  static Future<void> saveUserData({
    required String userId,
    required String token,
    String? phone,
    String? name,
    String? email,
    String? role,
    bool rememberMe = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userIdKey, userId);
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setBool(_rememberMeKey, rememberMe);

    final expiry = _extractTokenExpiry(token);
    if (expiry != null) {
      await prefs.setString(_tokenExpiryKey, expiry.toIso8601String());
    }

    if (phone != null) await prefs.setString(_userPhoneKey, phone);
    if (name != null) await prefs.setString(_userNameKey, name);
    if (email != null) await prefs.setString(_userEmailKey, email);
    if (role != null) await prefs.setString(_userRoleKey, role);
  }

  static Future<Map<String, dynamic>> getAllUserData() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString(_tokenKey);
    final isValid = token != null ? await isTokenValid() : false;

    return {
      'hasToken': token != null,
      'hasUserId': prefs.getString(_userIdKey) != null,
      'userId': prefs.getString(_userIdKey),
      'userPhone': prefs.getString(_userPhoneKey),
      'userName': prefs.getString(_userNameKey),
      'userEmail': prefs.getString(_userEmailKey),
      'userRole': prefs.getString(_userRoleKey),
      'isLoggedIn': prefs.getBool(_isLoggedInKey) ?? false,
      'rememberMe': prefs.getBool(_rememberMeKey) ?? false,
      'hasPendingFcmToken': prefs.getString(_pendingFcmTokenKey) != null,
      'tokenValid': isValid,
      'tokenExpiry': prefs.getString(_tokenExpiryKey),
    };
  }

  static Future<void> updateToken(String newToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, newToken);

    final expiry = _extractTokenExpiry(newToken);
    if (expiry != null) {
      await prefs.setString(_tokenExpiryKey, expiry.toIso8601String());
    }
  }

  static Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey) != null;
  }
}
