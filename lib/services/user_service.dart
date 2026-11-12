import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'jwt_service.dart';
import 'storage_service.dart';

class UserService {
  static Future<Map<String, dynamic>?> fetchUserData() async {
    try {
      // Get JWT token from storage
      String? token = await StorageService.getToken();

      if (token == null) {
        // Try fallback method - check SharedPreferences directly
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('tea_app_token');

        if (token != null) {
          // Save the fallback token using StorageService for future use
          await StorageService.saveToken(token);
        } else {
          return null;
        }
      }

      // Check if token is expired
      if (JwtService.isTokenExpired(token)) {
        await _clearAuthData();
        return null;
      }

      // Extract userId from JWT token
      final userId = JwtService.extractUserId(token);

      if (userId == null) {
        await _clearAuthData();
        return null;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/user/fetch-user-data/$userId'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Handle 404 - User not found
      if (response.statusCode == 404) {
        // print('User not found (404) - clearing auth data');
        await _clearAuthData();
        return null;
      }

      // Handle 401 - Unauthorized
      if (response.statusCode == 401) {
        // print('Unauthorized (401) - clearing auth data');
        await _clearAuthData();
        return null;
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['user'] != null) {
          return data['user'];
        } else {
          await _clearAuthData();
          return null;
        }
      } else {
        await _clearAuthData();
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  static Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tea_app_token');
    await prefs.remove('user_id');
    await prefs.remove('user_phone');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('is_logged_in');
    await prefs.remove('remember_me');

    await StorageService.clearToken();
    await StorageService.clearUserId();
  }

  static Future<String?> getUserName() async {
    final userData = await fetchUserData();
    if (userData != null) {
      final firstName = userData['first_name'] ?? '';
      final lastName = userData['last_name'] ?? '';
      return '$firstName $lastName'.trim();
    }
    return null;
  }

  static Future<String?> getUserEmail() async {
    final userData = await fetchUserData();
    return userData?['email'];
  }

  static Future<String?> getUserPhone() async {
    final userData = await fetchUserData();
    return userData?['phone_number'];
  }

  static Future<Map<String, String>?> getUserBasicInfo() async {
    final userData = await fetchUserData();
    if (userData != null) {
      return {
        'name': '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'
            .trim(),
        'email': userData['email'] ?? '',
        'phone': userData['phone_number'] ?? '',
      };
    }
    return null;
  }

  static Future<bool> isAuthenticated() async {
    final userData = await fetchUserData();
    return userData != null;
  }
}
