import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/recommended_product.dart';
import '../services/storage_service.dart';
import '../services/jwt_service.dart';
import '../services/shop_service.dart';

class RecommendedProductsService {
  static const String _endpoint =
      '/api/razorpay-payments/customer_recommended_Perchance';

  static Future<List<RecommendedProduct>> fetchCustomerRecommendedProducts({
    required String userId,
    required String franchiseId,
    String? authToken,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$_endpoint');

      final headers = {
        'accept': 'application/json',
        'Content-Type': 'application/json',
      };

      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final body = jsonEncode({'user_id': userId, 'franchise_id': franchiseId});

      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['recommended_products'] != null) {
          final List<dynamic> productsJson = data['recommended_products'];

          if (productsJson.isEmpty) {
            return [];
          }

          final products = productsJson
              .map((json) => RecommendedProduct.fromJson(json))
              .toList();

          return products;
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (_) {
      return [];
    }
  }

  // Convenience method that auto-fetches userId and franchiseId
  static Future<List<RecommendedProduct>>
  fetchRecommendedProductsForCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('tea_app_token');

      String? userId = await StorageService.getUserId();
      userId ??= prefs.getString('user_id');

      if (userId == null && token != null) {
        userId = JwtService.extractUserId(token);
      }

      if (userId == null) {
        return [];
      }

      if (!ShopService.hasSelectedShop()) {
        return [];
      }

      final franchiseId = ShopService.selectedShopId!;

      return await fetchCustomerRecommendedProducts(
        userId: userId,
        franchiseId: franchiseId,
        authToken: token,
      );
    } catch (_) {
      return [];
    }
  }
}
