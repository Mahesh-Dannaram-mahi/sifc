import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recommended_product.dart';
import '../models/tagged_product.dart';
import '../services/jwt_service.dart';
import '../config/api_config.dart';

class ApiService {
  static Map<String, dynamic> _normalizeProductJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    normalized['id'] =
        normalized['id'] ?? normalized['product_id'] ?? normalized['item_id'];
    final sourceTable = normalized['source_table']?.toString().toLowerCase();
    final warehouseId = normalized['warehouse_id']?.toString();
    if (normalized['franchise_id'] == null &&
        sourceTable != 'warehouse_products' &&
        (warehouseId == null || warehouseId.isEmpty)) {
      normalized['franchise_id'] = 'franchise';
    }
    normalized['Amount'] = normalized['Amount'] ?? normalized['amount'];
    normalized['Total'] = normalized['Total'] ?? normalized['total'];
    normalized['products_images'] =
        normalized['products_images'] ?? normalized['product_image'];
    normalized['weight_kg'] =
        normalized['weight_kg'] ?? normalized['Weight_kg'];
    normalized['grams_g'] = normalized['grams_g'] ?? normalized['Grams_g'];
    normalized['GST_Rate'] = normalized['GST_Rate'] ?? normalized['gst_rate'];
    normalized['CGST'] = normalized['CGST'] ?? normalized['cgst'];
    normalized['SGST'] = normalized['SGST'] ?? normalized['sgst'];
    normalized['show_gst'] = normalized['show_gst'] ?? false;
    normalized['tags'] = normalized['tags'] ?? '';
    normalized['created_at'] =
        normalized['created_at'] ?? DateTime.now().toIso8601String();
    normalized['purchase_count'] =
        normalized['purchase_count'] ?? normalized['search_count'] ?? 0;
    return normalized;
  }

  static Future<List<RecommendedProduct>> getRecommendedProducts(
    String token,
    String franchiseId,
  ) async {
    try {
      // Extract user_id from JWT token
      final userId = JwtService.extractUserId(token);
      if (userId == null) {
        throw Exception('Failed to extract user ID from token');
      }

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/razorpay-payments/customer_recommended_Perchance',
      );

      final response = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'user_id': userId, 'franchise_id': franchiseId}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> recommendedProductsJson =
            data['recommended_products'];

        return recommendedProductsJson
            .map((json) => RecommendedProduct.fromJson(json))
            .toList();
      } else {
        final errorMessage =
            'Failed to load recommended products: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Re-throw with the original error for ErrorHandlerService to handle
      rethrow;
    }
  }

  static Future<ProductsByTagsResponse> getProductsByTags(
    String franchiseId,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/product/products-by-tags',
      );

      final response = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'franchise_id': franchiseId}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return ProductsByTagsResponse.fromJson(data);
      } else {
        final errorMessage =
            'Failed to load products by tags: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Re-throw with the original error for ErrorHandlerService to handle
      rethrow;
    }
  }

  static Future<List<RecommendedProduct>> searchProducts(
    String query, {
    String? franchiseId,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/search/search_products');

      final Map<String, dynamic> requestBody = {};
      if (query.isNotEmpty) {
        requestBody['query'] = query;
      }
      if (franchiseId != null && franchiseId.isNotEmpty) {
        requestBody['franchise_id'] = franchiseId;
      }

      final response = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {}
        return data
            .map(
              (json) =>
                  RecommendedProduct.fromJson(_normalizeProductJson(json)),
            )
            .toList();
      } else {
        final errorMessage =
            'Failed to search products: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Re-throw with the original error for ErrorHandlerService to handle
      rethrow;
    }
  }

  static Future<List<RecommendedProduct>> fetchRecentSearches(
    String userId,
  ) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/search/recent-search/$userId'),
      headers: {'accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load recent searches: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final List<dynamic> products = data['products'] ?? [];
    return products
        .map((json) => RecommendedProduct.fromJson(_normalizeProductJson(json)))
        .toList();
  }

  static Future<List<RecommendedProduct>> fetchPopularSearches() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/search/popular-searches'),
      headers: {'accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load popular searches: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);
    final List<dynamic> products = data['products'] ?? [];
    return products
        .map((json) => RecommendedProduct.fromJson(_normalizeProductJson(json)))
        .toList();
  }

  static Future<void> updateRecentSearch({
    required String userId,
    required String productId,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/search/recent-search'),
      headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'user_id': userId, 'product_id': productId}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to update recent search: ${response.statusCode}');
    }
  }
}
