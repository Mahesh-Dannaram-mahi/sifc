import 'package:flutter/foundation.dart';
import '../../models/cart_item.dart';
import '../../models/recommended_product.dart';
import '../../models/product.dart';
import '../../services/cart_service.dart';

class CartHelperService {
  /// Unified method to add a product to cart from any source
  static void addProductToCart({
    required String productId,
    required String productName,
    required String imageUrl,
    required String weight,
    required double price,
    required double mrp,
    String discount = '',
    required bool isFreeCupEligible,
    String itemType = 'product',
    int quantity = 1,
    VoidCallback? onSuccess,
    VoidCallback? onCartUpdated,
  }) {
    // debugPrint(
    //   '🛒 CartHelperService adding: $productName, price: $price, mrp: $mrp, itemType: $itemType',
    // );

    final cartItem = CartItem(
      productId: productId,
      name: productName,
      image: imageUrl,
      weight: weight,
      price: price,
      mrp: mrp,
      discount: discount,
      isFreeCupEligible: isFreeCupEligible,
      itemType: itemType,
      quantity: quantity,
    );

    debugPrint(
      '🛒 CartItem created: price=${cartItem.price}, mrp=${cartItem.mrp}',
    );

    CartService.addItem(cartItem);
    onCartUpdated?.call();
    onSuccess?.call();
  }

  /// Add RecommendedProduct to cart
  static void addRecommendedProduct(
    RecommendedProduct product, {
    VoidCallback? onCartUpdated,
  }) {
    final discountPercent = product.mrp > product.sellingPrice
        ? ((product.mrp - product.sellingPrice) / product.mrp * 100).round()
        : 0;

    addProductToCart(
      productId: product.id,
      productName: product.productName,
      imageUrl: product.firstImage,
      weight: product.weightDescription,
      price: product.sellingPrice,
      mrp: product.mrp,
      discount: discountPercent > 0 ? discountPercent.toString() : '',
      isFreeCupEligible: product.freeCupEligibility,
      itemType: product.franchiseId.isEmpty ? 'warehouse' : 'product',
      quantity: 1,
      onCartUpdated: onCartUpdated,
    );
  }

  /// Add Product to cart
  static void addProduct(Product product, {VoidCallback? onCartUpdated}) {
    addProductToCart(
      productId: product.id,
      productName: product.name,
      imageUrl: product.image,
      weight: product.weight,
      price: product.price,
      mrp: product.mrp,
      discount: product.discount,
      isFreeCupEligible: product.isFreeCupEligible,
      itemType: product.isWarehouseProduct ? 'warehouse' : 'product',
      quantity: 1,
      onCartUpdated: onCartUpdated,
    );
  }
}
