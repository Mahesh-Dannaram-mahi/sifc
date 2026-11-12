import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/storage_service.dart';

// ---------- Models ----------
class ProductSalesResponse {
  final bool success;
  final String? franchiseId;
  final String? view;
  final String? startDate;
  final String? endDate;
  final OverallAnalytics overall;
  final List<ProductSummary> products;

  ProductSalesResponse({
    required this.success,
    this.franchiseId,
    this.view,
    this.startDate,
    this.endDate,
    required this.overall,
    required this.products,
  });

  factory ProductSalesResponse.fromJson(Map<String, dynamic> json) {
    return ProductSalesResponse(
      success: json['success'] ?? false,
      franchiseId: json['franchise_id']?.toString(),
      view: json['view']?.toString(),
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      overall: OverallAnalytics.fromJson(json['overall'] ?? {}),
      products: (json['products'] as List? ?? [])
          .map((e) => ProductSummary.fromJson(e))
          .toList(),
    );
  }
}

class ProductSummary {
  final String productId;
  final String productName;
  final ProductSummaryData summary;
  final List<PeriodAnalyticsPoint> breakdown;

  ProductSummary({
    required this.productId,
    required this.productName,
    required this.summary,
    required this.breakdown,
  });

  factory ProductSummary.fromJson(Map<String, dynamic> json) {
    return ProductSummary(
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      summary: ProductSummaryData.fromJson(json['summary'] ?? {}),
      breakdown: (json['breakdown'] as List? ?? [])
          .map((e) => PeriodAnalyticsPoint.fromJson(e))
          .toList(),
    );
  }
}

class ProductSummaryData {
  final int quantity;
  final double unitAmount;
  final double unitCgst;
  final double unitSgst;
  final double unitGstRate;
  final double totalAmount;
  final double totalCgst;
  final double totalSgst;
  final double itemTotal;
  final double discount;

  ProductSummaryData({
    required this.quantity,
    required this.unitAmount,
    required this.unitCgst,
    required this.unitSgst,
    required this.unitGstRate,
    required this.totalAmount,
    required this.totalCgst,
    required this.totalSgst,
    required this.itemTotal,
    required this.discount,
  });

  factory ProductSummaryData.fromJson(Map<String, dynamic> json) {
    return ProductSummaryData(
      quantity: (json['quantity'] ?? 0).toInt(),
      unitAmount: (json['unit_amount'] ?? 0).toDouble(),
      unitCgst: (json['unit_cgst'] ?? 0).toDouble(),
      unitSgst: (json['unit_sgst'] ?? 0).toDouble(),
      unitGstRate: (json['unit_gst_rate'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      totalCgst: (json['total_cgst'] ?? 0).toDouble(),
      totalSgst: (json['total_sgst'] ?? 0).toDouble(),
      itemTotal: (json['item_total'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
    );
  }

  double get gst => totalCgst + totalSgst;
}

class OverallAnalytics {
  final int quantity;
  final double unitAmount;
  final double unitCgst;
  final double unitSgst;
  final double unitGstRate;
  final double totalAmount;
  final double totalCgst;
  final double totalSgst;
  final double itemTotal;
  final double discount;

  OverallAnalytics({
    required this.quantity,
    required this.unitAmount,
    required this.unitCgst,
    required this.unitSgst,
    required this.unitGstRate,
    required this.totalAmount,
    required this.totalCgst,
    required this.totalSgst,
    required this.itemTotal,
    required this.discount,
  });

  factory OverallAnalytics.fromJson(Map<String, dynamic> json) {
    return OverallAnalytics(
      quantity: (json['quantity'] ?? 0).toInt(),
      unitAmount: (json['unit_amount'] ?? 0).toDouble(),
      unitCgst: (json['unit_cgst'] ?? 0).toDouble(),
      unitSgst: (json['unit_sgst'] ?? 0).toDouble(),
      unitGstRate: (json['unit_gst_rate'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      totalCgst: (json['total_cgst'] ?? 0).toDouble(),
      totalSgst: (json['total_sgst'] ?? 0).toDouble(),
      itemTotal: (json['item_total'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
    );
  }

  double get gst => totalCgst + totalSgst;
}

class PeriodAnalyticsPoint {
  final String period;
  final int quantity;
  final double unitAmount;
  final double unitCgst;
  final double unitSgst;
  final double unitGstRate;
  final double totalAmount;
  final double totalCgst;
  final double totalSgst;
  final double itemTotal;
  final double discount;

  PeriodAnalyticsPoint({
    required this.period,
    required this.quantity,
    required this.unitAmount,
    required this.unitCgst,
    required this.unitSgst,
    required this.unitGstRate,
    required this.totalAmount,
    required this.totalCgst,
    required this.totalSgst,
    required this.itemTotal,
    required this.discount,
  });

  factory PeriodAnalyticsPoint.fromJson(Map<String, dynamic> json) {
    return PeriodAnalyticsPoint(
      period: json['period']?.toString() ?? '',
      quantity: (json['quantity'] ?? 0).toInt(),
      unitAmount: (json['unit_amount'] ?? 0).toDouble(),
      unitCgst: (json['unit_cgst'] ?? 0).toDouble(),
      unitSgst: (json['unit_sgst'] ?? 0).toDouble(),
      unitGstRate: (json['unit_gst_rate'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      totalCgst: (json['total_cgst'] ?? 0).toDouble(),
      totalSgst: (json['total_sgst'] ?? 0).toDouble(),
      itemTotal: (json['item_total'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
    );
  }

  double get gst => totalCgst + totalSgst;
}

// ---------- API Call ----------
class ProductSalesApi {
  static Future<ProductSalesResponse> fetchProductSales({
    required String franchiseId,
    required DateTime startDate,
    required DateTime endDate,
    required String view, // 'daily', 'weekly', 'monthly', 'yearly', 'custom'
  }) async {
    final token = await StorageService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    // Map 'daily' to 'custom' for backend compatibility
    final apiView = view == 'daily' ? 'custom' : view;

    final start = _formatDate(startDate);
    final end = _formatDate(endDate);

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/franchise-invoices/franchise-product-sales/$franchiseId'
      '?start_date=$start'
      '&end_date=$end'
      '&view=$apiView',
    );

    final response = await http.get(
      url,
      headers: {'accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      return ProductSalesResponse.fromJson(json);
    } else {
      throw Exception('Failed to load product sales: ${response.statusCode}');
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
