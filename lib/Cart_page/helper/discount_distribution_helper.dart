import '../../models/cart_item.dart';

class DiscountDistributionHelper {
  /// Distribute discount proportionally based on item prices
  /// Items with higher prices get more discount
  static Map<String, double> distributeDiscountProportionally(
    List<CartItem> cartItems,
    double totalDiscount,
  ) {
    if (cartItems.isEmpty || totalDiscount <= 0) return {};

    // Calculate total price of all items
    final totalPrice = cartItems.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );

    if (totalPrice <= 0) return {};

    final Map<String, double> productDiscounts = {};
    double distributedSum = 0;

    for (int i = 0; i < cartItems.length; i++) {
      final item = cartItems[i];
      final itemTotal = item.price * item.quantity;
      // Distribute discount proportionally based on item price
      final discountShare = (itemTotal / totalPrice) * totalDiscount;

      // For the last item, adjust to avoid floating point issues
      if (i == cartItems.length - 1) {
        final remaining = totalDiscount - distributedSum;
        productDiscounts[item.productId] = double.parse(
          remaining.toStringAsFixed(2),
        );
      } else {
        productDiscounts[item.productId] = double.parse(
          discountShare.toStringAsFixed(2),
        );
        distributedSum += discountShare;
      }
    }

    return productDiscounts;
  }

  /// Distribute discount equally per unit
  /// Each product gets the same discount per unit
  static Map<String, double> distributeDiscountPerUnit(
    List<CartItem> cartItems,
    double totalDiscount,
  ) {
    if (cartItems.isEmpty || totalDiscount <= 0) return {};

    // Calculate total quantity
    final totalQuantity = cartItems.fold(0, (sum, item) => sum + item.quantity);
    if (totalQuantity <= 0) return {};

    // Distribute discount equally per unit
    final discountPerUnit = totalDiscount / totalQuantity;
    final Map<String, double> productDiscounts = {};
    double distributedSum = 0;

    for (int i = 0; i < cartItems.length; i++) {
      final item = cartItems[i];
      final itemDiscount = discountPerUnit * item.quantity;

      // For the last item, adjust to avoid floating point issues
      if (i == cartItems.length - 1) {
        final remaining = totalDiscount - distributedSum;
        productDiscounts[item.productId] = double.parse(
          remaining.toStringAsFixed(2),
        );
      } else {
        productDiscounts[item.productId] = double.parse(
          itemDiscount.toStringAsFixed(2),
        );
        distributedSum += itemDiscount;
      }
    }

    return productDiscounts;
  }

  /// Distribute discount evenly across all products (same amount per product)
  static Map<String, double> distributeDiscountEvenly(
    List<CartItem> cartItems,
    double totalDiscount,
  ) {
    if (cartItems.isEmpty || totalDiscount <= 0) return {};

    final discountPerProduct = totalDiscount / cartItems.length;
    final Map<String, double> productDiscounts = {};
    double distributedSum = 0;

    for (int i = 0; i < cartItems.length; i++) {
      final item = cartItems[i];

      // For the last item, adjust to avoid floating point issues
      if (i == cartItems.length - 1) {
        final remaining = totalDiscount - distributedSum;
        productDiscounts[item.productId] = double.parse(
          remaining.toStringAsFixed(2),
        );
      } else {
        productDiscounts[item.productId] = double.parse(
          discountPerProduct.toStringAsFixed(2),
        );
        distributedSum += discountPerProduct;
      }
    }

    return productDiscounts;
  }

  /// Validate that distributed discounts sum to total discount
  static bool validateDistribution(
    Map<String, double> distribution,
    double expectedTotal,
  ) {
    final sum = distribution.values.fold(0.0, (a, b) => a + b);
    return (sum - expectedTotal).abs() <
        0.01; // Allow small floating point differences
  }

  /// Get the discount for a specific product
  static double getDiscountForProduct(
    Map<String, double>? productDiscounts,
    String productId,
  ) {
    if (productDiscounts == null) return 0;
    return productDiscounts[productId] ?? 0;
  }

  /// Format discount distribution for display
  static String formatDistribution(Map<String, double> productDiscounts) {
    final entries = productDiscounts.entries
        .map((e) => '${e.key}: ₹${e.value.toStringAsFixed(2)}')
        .join(', ');
    return '{$entries}';
  }
}
