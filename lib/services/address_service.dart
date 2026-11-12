// lib/services/address_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_address.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddressService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('tea_app_token');
  }

  static Map<String, String> _authHeaders(String token) => {
    'accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// Fetch all addresses for the logged-in user
  static Future<List<UserAddress>> fetchAddresses() async {
    final token = await _getToken();
    if (token == null) return [];
    try {
      final resp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/user/addresses'),
        headers: _authHeaders(token),
      );
      if (resp.statusCode != 200) return [];
      final data = jsonDecode(resp.body);
      final List raw = data['addresses'] ?? [];
      return raw.map((e) => UserAddress.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Create a new address
  static Future<({bool success, String? addressId, String? error})>
  createAddress(Map<String, dynamic> payload) async {
    final token = await _getToken();
    if (token == null) {
      return (success: false, addressId: null, error: 'Not authenticated');
    }
    try {
      final resp = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/user/addresses'),
        headers: _authHeaders(token),
        body: jsonEncode(payload),
      );
      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 && data['success'] == true) {
        return (
          success: true,
          addressId: data['address_id']?.toString(),
          error: null,
        );
      }
      return (
        success: false,
        addressId: null,
        error: data['detail']?.toString() ?? 'Failed',
      );
    } catch (e) {
      return (success: false, addressId: null, error: e.toString());
    }
  }

  /// Delete an address
  static Future<bool> deleteAddress(String addressId) async {
    final token = await _getToken();
    if (token == null) return false;
    try {
      final resp = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/user/addresses/$addressId'),
        headers: _authHeaders(token),
      );
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Get Shiprocket delivery fee estimate
  static Future<double> getDeliveryFee({
    required String pickupPincode,
    required String deliveryPincode,
    double weight = 0.5,
  }) async {
    try {
      final resp = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/warehouse-orders/shipping-fee'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pickup_pincode': pickupPincode,
          'delivery_pincode': deliveryPincode,
          'weight': weight,
        }),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return (data['delivery_fee'] as num?)?.toDouble() ?? 60.0;
      }
    } catch (_) {}
    return 60.0;
  }
}
