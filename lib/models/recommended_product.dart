// lib/models/recommended_product.dart
import 'dart:convert';
import '../../product_review/models/product_rating_data.dart';

class RecommendedProduct {
  final String id;
  final String franchiseId;
  final String productName;
  final String category;
  final String brand;
  final double weightKg;
  final int gramsG;
  final int lengthCm;
  final int widthCm;
  final String productsImages;
  final String shortDescription;
  final String longDescription;
  final int gstRate;
  final double amount;
  final double cgst;
  final double sgst;
  final double total;
  final bool freeCupEligibility;
  final bool showGst;
  final String tags;
  final DateTime createdAt;
  final int purchaseCount;
  
  // Rating and Like fields
  double? userRating;
  bool isLiked;
  double averageRating;
  int totalRatings;
  int totalLikes;

  RecommendedProduct({
    required this.id,
    required this.franchiseId,
    required this.productName,
    required this.category,
    required this.brand,
    required this.weightKg,
    required this.gramsG,
    required this.lengthCm,
    required this.widthCm,
    required this.productsImages,
    required this.shortDescription,
    required this.longDescription,
    required this.gstRate,
    required this.amount,
    required this.cgst,
    required this.sgst,
    required this.total,
    required this.freeCupEligibility,
    required this.showGst,
    required this.tags,
    required this.createdAt,
    required this.purchaseCount,
    this.userRating,
    this.isLiked = false,
    this.averageRating = 0,
    this.totalRatings = 0,
    this.totalLikes = 0,
  });

  factory RecommendedProduct.fromJson(Map<String, dynamic> json) {
    final totalValue = _parseDouble(json['Total']);
    final amountValue = _parseDouble(json['Amount']);
    
    final freeCupValue = _parseBool(json['free_cup_eligibility']);

    return RecommendedProduct(
      id: json['id']?.toString() ?? '',
      franchiseId: json['franchise_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      weightKg: _parseDouble(json['weight_kg']),
      gramsG: _parseInt(json['grams_g']),
      lengthCm: _parseInt(json['length_cm']),
      widthCm: _parseInt(json['width_cm']),
      productsImages: json['products_images']?.toString() ?? '',
      shortDescription: json['short_description']?.toString() ?? '',
      longDescription: json['long_description']?.toString() ?? '',
      gstRate: _parseInt(json['GST_Rate']),
      amount: amountValue,
      cgst: _parseDouble(json['CGST']),
      sgst: _parseDouble(json['SGST']),
      total: totalValue,
      freeCupEligibility: freeCupValue,
      showGst: _parseBool(json['show_gst']),
      tags: json['tags']?.toString() ?? '',
      createdAt: _parseDateTime(json['created_at']),
      purchaseCount: _parseInt(json['purchase_count']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' ||
          value == '1' ||
          value.toLowerCase() == 'yes';
    }
    return false;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  void updateRatingData(ProductRatingData data) {
    userRating = data.rating;
    isLiked = data.liked;
    averageRating = data.averageRating;
    totalRatings = data.totalRatings;
    totalLikes = data.totalLikes;
  }

  String get formattedAverageRating {
    if (averageRating == 0) return 'New';
    return averageRating.toStringAsFixed(1);
  }

  String get ratingDisplay {
    if (totalRatings == 0) return 'No ratings yet';
    return '★ $formattedAverageRating ($totalRatings)';
  }

  String get formattedLikeCount {
    if (totalLikes >= 1000) {
      return '${(totalLikes / 1000).toStringAsFixed(1)}K';
    }
    return totalLikes.toString();
  }

  List<String> get allImages {
    if (productsImages.isEmpty) {
      return [];
    }

    if (productsImages.trim().startsWith('[') &&
        productsImages.trim().endsWith(']')) {
      try {
        final List<dynamic> parsed = jsonDecode(productsImages);
        return parsed
            .map((url) => url.toString().trim())
            .where((url) => url.isNotEmpty && url != 'null')
            .toList();
      } catch (e) {
        // If JSON parsing fails, fall through to other method
      }
    }

    List<String> images = productsImages
        .split(',')
        .map((image) => image.trim())
        .where(
          (image) =>
              image.isNotEmpty &&
              image != 'null' &&
              image != '""' &&
              image != "''",
        )
        .toList();

    images = images.map((image) {
      if ((image.startsWith('"') && image.endsWith('"')) ||
          (image.startsWith("'") && image.endsWith("'"))) {
        return image.substring(1, image.length - 1);
      }
      return image;
    }).toList();

    return images;
  }

  String get firstImage {
    final images = allImages;
    return images.isNotEmpty ? images.first : '';
  }

  String getImage(int index) {
    final images = allImages;
    if (index >= 0 && index < images.length) {
      return images[index];
    }
    return firstImage;
  }

  bool get hasMultipleImages => allImages.length > 1;

  int get imageCount => allImages.length;

  String get formattedPrice {
    return '₹${sellingPrice.toStringAsFixed(0)}';
  }

  String get formattedMrp {
    return '₹${mrp.toStringAsFixed(0)}';
  }

  String get formattedAmount {
    return '₹${amount.toStringAsFixed(2)}';
  }

  double get discountPercent {
    if (hasDiscount && mrp > 0) {
      return ((mrp - sellingPrice) / mrp * 100);
    }
    return 0.0;
  }

  String get discountPercentage {
    if (hasDiscount && mrp > 0) {
      final discount = ((mrp - sellingPrice) / mrp * 100);
      return '${discount.toStringAsFixed(0)}%';
    }
    return '0%';
  }

  String get discountDisplay {
    if (hasDiscount && mrp > 0) {
      final discount = ((mrp - sellingPrice) / mrp * 100);
      return '${discount.toStringAsFixed(0)}% OFF';
    }
    return '';
  }

  bool get hasDiscount {
    if (mrp > sellingPrice && sellingPrice > 0) {
      return true;
    }
    return total > amount && amount > 0;
  }

  double get discountAmount {
    if (hasDiscount && mrp > sellingPrice) {
      return mrp - sellingPrice;
    }
    return total - amount;
  }

  String get formattedDiscountAmount {
    return '₹${discountAmount.toStringAsFixed(2)}';
  }

  double get sellingPrice {
    if (total > 0) return total;
    if (amount > 0) return amount;
    return 0.0;
  }

  double get mrp {
    if (total > amount) return total;
    if (amount > total) return amount;
    return total;
  }

  double get totalGst => cgst + sgst;

  String get formattedTotalGst {
    return '₹${totalGst.toStringAsFixed(2)}';
  }

  List<String> get tagList {
    if (tags.isEmpty) return [];
    return tags
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  bool get hasTags => tagList.isNotEmpty;

  String get weightDescription {
    if (weightKg >= 1) {
      return '${weightKg.toStringAsFixed(weightKg == weightKg.roundToDouble() ? 0 : 1)} kg';
    }
    return '$gramsG g';
  }

  String get dimensionsDescription {
    return '${lengthCm}cm × ${widthCm}cm';
  }

  String get gstDetails {
    if (showGst && totalGst > 0) {
      return 'Incl. GST: $formattedTotalGst ($gstRate%)';
    }
    return '';
  }

  Map<String, String> toSignatureProductFormat() {
    return {
      'name': productName,
      'price': formattedPrice,
      'mrp': formattedMrp,
      'discount': discountDisplay,
      'image': firstImage,
      'description': shortDescription,
      'brand': brand,
      'free_cup_eligibility': freeCupEligibility.toString(),
      'tags': tags,
    };
  }

  Map<String, dynamic> toCartItemFormat({required int quantity}) {
    return {
      'productId': id,
      'name': productName,
      'image': firstImage,
      'weight': weightDescription,
      'price': sellingPrice,
      'mrp': mrp,
      'discount': discountDisplay,
      'quantity': quantity,
      'gst': totalGst,
      'gstRate': gstRate,
      'category': category,
      'brand': brand,
      'totalAmount': sellingPrice * quantity,
    };
  }

  String get summary {
    return '$productName - $category by $brand';
  }

  String get displayDescription {
    return shortDescription.isNotEmpty ? shortDescription : longDescription;
  }

  bool get isValid {
    return id.isNotEmpty && productName.isNotEmpty && sellingPrice > 0;
  }

  @override
  String toString() {
    return 'RecommendedProduct(id: $id, name: $productName, '
        'category: $category, brand: $brand, '
        'sellingPrice: ₹$sellingPrice, MRP: ₹$mrp, '
        'discount: $discountDisplay, images: $imageCount, '
        'rating: $averageRating ($totalRatings), likes: $totalLikes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecommendedProduct && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  RecommendedProduct copyWith({
    String? id,
    String? franchiseId,
    String? productName,
    String? category,
    String? brand,
    double? weightKg,
    int? gramsG,
    int? lengthCm,
    int? widthCm,
    String? productsImages,
    String? shortDescription,
    String? longDescription,
    int? gstRate,
    double? amount,
    double? cgst,
    double? sgst,
    double? total,
    bool? freeCupEligibility,
    bool? showGst,
    String? tags,
    DateTime? createdAt,
    int? purchaseCount,
    double? userRating,
    bool? isLiked,
    double? averageRating,
    int? totalRatings,
    int? totalLikes,
  }) {
    return RecommendedProduct(
      id: id ?? this.id,
      franchiseId: franchiseId ?? this.franchiseId,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      weightKg: weightKg ?? this.weightKg,
      gramsG: gramsG ?? this.gramsG,
      lengthCm: lengthCm ?? this.lengthCm,
      widthCm: widthCm ?? this.widthCm,
      productsImages: productsImages ?? this.productsImages,
      shortDescription: shortDescription ?? this.shortDescription,
      longDescription: longDescription ?? this.longDescription,
      gstRate: gstRate ?? this.gstRate,
      amount: amount ?? this.amount,
      cgst: cgst ?? this.cgst,
      sgst: sgst ?? this.sgst,
      total: total ?? this.total,
      freeCupEligibility: freeCupEligibility ?? this.freeCupEligibility,
      showGst: showGst ?? this.showGst,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      purchaseCount: purchaseCount ?? this.purchaseCount,
      userRating: userRating ?? this.userRating,
      isLiked: isLiked ?? this.isLiked,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      totalLikes: totalLikes ?? this.totalLikes,
    );
  }
}