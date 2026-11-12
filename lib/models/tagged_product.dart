class TaggedProduct {
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
  final String? tags;
  final DateTime? createdAt;

  TaggedProduct({
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
    this.tags,
    this.createdAt,
  });

  factory TaggedProduct.fromJson(Map<String, dynamic> json) {
    return TaggedProduct(
      id: json['id'] as String,
      franchiseId: json['franchise_id'] as String,
      productName: json['product_name'] as String,
      category: json['category'] as String,
      brand: json['brand'] as String,
      weightKg: (json['weight_kg'] as num).toDouble(),
      gramsG: (json['grams_g'] as num).toInt(),
      lengthCm: (json['length_cm'] as num).toInt(),
      widthCm: (json['width_cm'] as num).toInt(),
      productsImages: json['products_images'] as String,
      shortDescription: json['short_description'] as String,
      longDescription: json['long_description'] as String,
      gstRate: (json['GST_Rate'] as num).toInt(),
      amount: (json['Amount'] as num).toDouble(),
      cgst: (json['CGST'] as num).toDouble(),
      sgst: (json['SGST'] as num).toDouble(),
      total: (json['Total'] as num).toDouble(),
      freeCupEligibility: json['free_cup_eligibility'] as bool,
      showGst: json['show_gst'] as bool,
      tags: json['tags'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  // Get the first image from the comma-separated images string
  String get firstImage {
    return productsImages.split(',').first.trim();
  }

  // Get formatted price
  String get formattedPrice {
    return '₹${total.toStringAsFixed(2)}';
  }
}

class ProductTag {
  final String tagName;
  final List<TaggedProduct> products;
  final String assignedImage;

  ProductTag({
    required this.tagName,
    required this.products,
    this.assignedImage = '',
  });

  factory ProductTag.fromJson(Map<String, dynamic> json) {
    final List<dynamic> productsJson = json['products'] as List;
    return ProductTag(
      tagName: json['tag_name'] as String,
      products: productsJson
          .map((productJson) => TaggedProduct.fromJson(productJson))
          .toList(),
    );
  }
}

class ProductsByTagsResponse {
  final List<ProductTag> data;

  ProductsByTagsResponse({required this.data});

  factory ProductsByTagsResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> dataJson = json['data'] as List;
    return ProductsByTagsResponse(
      data: dataJson
          .map((tagJson) => ProductTag.fromJson(tagJson))
          .toList(),
    );
  }

  // Get only the first 6 tags
  List<ProductTag> get firstSixTags {
    return data.take(6).toList();
  }
}
