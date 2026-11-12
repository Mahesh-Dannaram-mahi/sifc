import 'recommended_product.dart';

class Product {
  final String id;
  final String name;
  final String image;
  final String productsImages;
  final String weight;
  final double price;
  final double mrp;
  final String discount;
  final String brand;
  final String category;
  final String subcategory;
  final bool isFreeCupEligible;
  final bool isWarehouseProduct;

  Product({
    this.id = '',
    required this.name,
    required this.image,
    required this.productsImages,
    required this.weight,
    required this.price,
    required this.mrp,
    required this.discount,
    required this.brand,
    this.category = '',
    this.subcategory = '',
    this.isFreeCupEligible = false,
    this.isWarehouseProduct = false,
  });

  factory Product.fromRecommendedProduct(
    RecommendedProduct recommendedProduct,
  ) {
    return Product(
      id: recommendedProduct.id,
      name: recommendedProduct.productName,
      image: recommendedProduct.firstImage,
      productsImages: recommendedProduct.productsImages,
      weight: '${recommendedProduct.gramsG}g',
      price: recommendedProduct.total,
      mrp: recommendedProduct.total * 1.1,
      discount: '',
      brand: recommendedProduct.brand,
      category: recommendedProduct.category,
      subcategory: '',
      isFreeCupEligible: recommendedProduct.freeCupEligibility,
      isWarehouseProduct: recommendedProduct.franchiseId.isEmpty,
    );
  }

  factory Product.fromApiMap(Map<String, dynamic> map) {
    final String id =
        (map['id'] ??
                map['product_id'] ??
                map['products_id'] ??
                map['Product_ID'] ??
                map['Products_ID'] ??
                '')
            .toString();
    final String productName = map['product_name'] ?? map['Product_Name'] ?? '';
    final String brand = map['brand'] ?? map['Brand'] ?? '';
    final String category = map['category'] ?? map['Category'] ?? '';
    final String subcategory = map['sub_category'] ?? map['sub_category'] ?? '';
    final double grams = (map['grams_g'] ?? map['Grams_g'] ?? 0).toDouble();
    final String productsImages =
        map['products_images'] ?? map['Products_Images'] ?? '';
    final String sourceTable = (map['source_table'] ?? map['item_type'] ?? '')
        .toString()
        .toLowerCase();

    bool freeCupEligibility = false;
    if (map['free_cup_eligibility'] != null) {
      final value = map['free_cup_eligibility'];
      if (value is bool) {
        freeCupEligibility = value;
      } else if (value is int) {
        freeCupEligibility = value == 1;
      } else if (value is String) {
        freeCupEligibility = value.toLowerCase() == 'true' || value == '1';
      }
    }

    String firstImage = '';
    if (productsImages.isNotEmpty) {
      final imageList = productsImages.split(',');
      firstImage = imageList.first.trim();
    }

    double price = 0.0;
    if (map['Total'] != null) {
      price = map['Total'].toDouble();
    } else if (map['Amount'] != null) {
      price = map['Amount'].toDouble();
    } else if (map['Price'] != null) {
      price = map['Price'].toDouble();
    } else if (map['price'] != null) {
      price = map['price'].toDouble();
    } else {
      price = 99.0;
    }

    double mrp = 0.0;
    if (map['MRP'] != null) {
      mrp = map['MRP'].toDouble();
    } else if (map['mrp'] != null) {
      mrp = map['mrp'].toDouble();
    } else {
      mrp = price;
    }

    String discount = '';
    if (mrp > price) {
      final discountPercentage = ((mrp - price) / mrp * 100).round();
      discount = '$discountPercentage% OFF';
    }

    return Product(
      id: id,
      name: productName,
      image: firstImage,
      productsImages: productsImages,
      weight: '${grams}g',
      price: price,
      mrp: mrp,
      discount: discount,
      brand: brand,
      category: category,
      subcategory: subcategory,
      isFreeCupEligible: freeCupEligibility,
      isWarehouseProduct: sourceTable.contains('warehouse'),
    );
  }

  String get formattedPrice {
    return '₹${price.toStringAsFixed(2)}';
  }

  String get formattedMrp {
    return '₹${mrp.toStringAsFixed(2)}';
  }

  String get discountPercentage {
    if (discount.isNotEmpty) return discount;
    if (mrp > price) {
      final discountPercent = ((mrp - price) / mrp * 100).round();
      return '$discountPercent% OFF';
    }
    return '';
  }

  RecommendedProduct toRecommendedProduct() {
    // Parse weight to extract grams
    int grams = 0;
    if (weight.contains('g')) {
      grams = int.tryParse(weight.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    } else if (weight.contains('kg')) {
      final kg = double.tryParse(weight.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      grams = (kg * 1000).round();
    }

    return RecommendedProduct(
      id: id,
      franchiseId: isWarehouseProduct ? '' : 'default',
      productName: name,
      category: category,
      brand: brand,
      weightKg: grams / 1000,
      gramsG: grams,
      lengthCm: 0,
      widthCm: 0,
      productsImages: productsImages,
      shortDescription: '',
      longDescription: '',
      gstRate: 18,
      amount: price,
      cgst: 0,
      sgst: 0,
      total: price,
      freeCupEligibility: isFreeCupEligible,
      showGst: false,
      tags: '',
      createdAt: DateTime.now(),
      purchaseCount: 0,
    );
  }
}
