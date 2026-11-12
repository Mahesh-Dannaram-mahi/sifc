// lib/services/like_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';

class LikeService {
  // Like endpoints
  static const String _likeEndpoint = '/api/like/customer-like';
  static const String _unlikeEndpoint = '/api/like/customer-unlike';
  
  static String _getFullUrl(String endpoint) => '${ApiConfig.baseUrl}$endpoint';
  
  /// Like a product
  static Future<bool> likeProduct({
    required String userId,
    required String productId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('tea_app_token');
      
      final response = await http.post(
        Uri.parse(_getFullUrl(_likeEndpoint)),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'user_id': userId,
          'product_id': productId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Unlike a product
  static Future<bool> unlikeProduct({
    required String userId,
    required String productId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('tea_app_token');
      
      final response = await http.put(
        Uri.parse(_getFullUrl(_unlikeEndpoint)),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'user_id': userId,
          'product_id': productId,
        }),
      );
      

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Toggle like status
  static Future<bool> toggleLike({
    required String userId,
    required String productId,
    required bool currentlyLiked,
  }) async {
    if (currentlyLiked) {
      return await unlikeProduct(userId: userId, productId: productId);
    } else {
      return await likeProduct(userId: userId, productId: productId);
    }
  }
}