// lib/services/rating_cache_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_rating_data.dart';

class RatingCacheService {
  static const String _ratingCacheKey = 'product_ratings_cache';
  static const Duration cacheDuration = Duration(hours: 1);

  /// Cache rating data for a product
  static Future<void> cacheRatingData(ProductRatingData data) async {
    final prefs = await SharedPreferences.getInstance();
    final cache = await _getCache();
    
    cache[data.productId] = {
      'data': data.toJson(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    await prefs.setString(_ratingCacheKey, json.encode(cache));
  }

  /// Get cached rating data for a product
  static Future<ProductRatingData?> getCachedRatingData(String productId) async {
    final cache = await _getCache();
    final entry = cache[productId];
    
    if (entry != null) {
      final timestamp = entry['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Check if cache is still valid
      if (now - timestamp < cacheDuration.inMilliseconds) {
        return ProductRatingData.fromJson(entry['data'] as Map<String, dynamic>);
      }
    }
    return null;
  }

  /// Clear all cached rating data
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ratingCacheKey);
  }

  static Future<Map<String, dynamic>> _getCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheString = prefs.getString(_ratingCacheKey);
    
    if (cacheString != null && cacheString.isNotEmpty) {
      return Map<String, dynamic>.from(json.decode(cacheString));
    }
    
    return {};
  }
}
