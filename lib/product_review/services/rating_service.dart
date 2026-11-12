// lib/services/rating_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../models/product_rating_data.dart';

class RatingService {
  // Rating endpoints
  static const String _ratingCreateEndpoint = '/api/rating/customer-rating-create';
  static const String _ratingUpdateEndpoint = '/api/rating/customer-rating-update';
  static const String _ratingFetchEndpoint = '/api/rating/customer-rating';
  
  static String _getFullUrl(String endpoint) => '${ApiConfig.baseUrl}$endpoint';
  
  /// Create or update rating for a product (automatically handles both)
  static Future<bool> rateProduct({
    required String userId,
    required String productId,
    required double rating,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('tea_app_token');
      
      // First try POST (create new rating)
      var response = await http.post(
        Uri.parse(_getFullUrl(_ratingCreateEndpoint)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'user_id': userId,
          'product_id': productId,
          'rating': rating,
        }),
      );
      
      // If rating already exists (409 Conflict), try PUT (update existing rating)
      if (response.statusCode == 409) {
        response = await http.put(
          Uri.parse(_getFullUrl(_ratingUpdateEndpoint)),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'user_id': userId,
            'product_id': productId,
            'rating': rating,
          }),
        );
      }
      


      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Update existing rating (explicit update method)
  static Future<bool> updateRating({
    required String userId,
    required String productId,
    required double rating,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('tea_app_token');
      
      final response = await http.put(
        Uri.parse(_getFullUrl(_ratingUpdateEndpoint)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'user_id': userId,
          'product_id': productId,
          'rating': rating,
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

  /// Get complete rating data for a product
  static Future<ProductRatingData?> getProductRatingData({
    required String userId,
    required String productId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('tea_app_token');
      
      final url = '${_getFullUrl(_ratingFetchEndpoint)}/$userId/$productId';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ProductRatingData.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Check if user has already rated a product
  static Future<bool> hasUserRated({
    required String userId,
    required String productId,
  }) async {
    final ratingData = await getProductRatingData(
      userId: userId,
      productId: productId,
    );
    return ratingData != null && ratingData.rating != null;
  }
}