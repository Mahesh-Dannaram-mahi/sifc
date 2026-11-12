import '../models/active_discount_models.dart';

/// Discount applied at checkout — sent to customer-invoice after payment.
class CheckoutDiscountInfo {
  final double discountAmount;
  final double discountPercentage;
  final String? cupId;
  final String? discountProductId;
  final CartDiscountType? discountType;
  final Map<String, double>? productDiscounts; // productId -> discount amount

  const CheckoutDiscountInfo({
    required this.discountAmount,
    required this.discountPercentage,
    this.cupId,
    this.discountProductId,
    this.discountType,
    this.productDiscounts,
  });

  Map<String, dynamic> toJson() => {
        'discount': discountAmount,
        'discount_percentage': discountPercentage,
        'cup_id': cupId ?? '',
        if (discountProductId != null && discountProductId!.isNotEmpty)
          'discount_product_id': discountProductId,
        if (discountType != null) 'discount_type': discountType!.name,
        if (productDiscounts != null && productDiscounts!.isNotEmpty)
          'product_discounts': productDiscounts,
      };

  factory CheckoutDiscountInfo.fromJson(Map<String, dynamic> json) {
    CartDiscountType? type;
    final typeStr = json['discount_type']?.toString();
    if (typeStr == 'freeCup') {
      type = CartDiscountType.freeCup;
    } else if (typeStr == 'event') {
      type = CartDiscountType.event;
    } else if (typeStr == 'cupDiscount') {
      type = CartDiscountType.cupDiscount;
    }

    Map<String, double>? productDiscounts;
    if (json['product_discounts'] != null) {
      final Map<String, dynamic> raw = json['product_discounts'];
      productDiscounts = raw.map((key, value) => MapEntry(key, (value as num).toDouble()));
    }

    return CheckoutDiscountInfo(
      discountAmount: (json['discount'] as num?)?.toDouble() ?? 0,
      discountPercentage: (json['discount_percentage'] as num?)?.toDouble() ?? 0,
      cupId: json['cup_id']?.toString(),
      discountProductId: json['discount_product_id']?.toString(),
      discountType: type,
      productDiscounts: productDiscounts,
    );
  }

  CheckoutDiscountInfo copyWith({
    String? discountProductId,
    CartDiscountType? discountType,
    Map<String, double>? productDiscounts,
  }) {
    return CheckoutDiscountInfo(
      discountAmount: discountAmount,
      discountPercentage: discountPercentage,
      cupId: cupId,
      discountProductId: discountProductId ?? this.discountProductId,
      discountType: discountType ?? this.discountType,
      productDiscounts: productDiscounts ?? this.productDiscounts,
    );
  }
}