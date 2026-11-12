import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import '../../services/cart_service.dart';
import '../services/cart_helper_service.dart';
import '../../models/product.dart';
import '../../models/recommended_product.dart';
import '../../theme/sipora_theme.dart';
import '../../utils/screen_utils.dart';

enum ProductType { product, recommended }

class UnifiedAddToCartButton extends StatelessWidget {
  final String productId;
  final String productName;
  final String imageUrl;
  final String weight;
  final double price;
  final double mrp;
  final String discount;
  final bool isFreeCupEligible;
  final String itemType;
  final ProductType productType;
  final VoidCallback? onCartUpdated;
  final double? customWidth;
  final double? customHeight;
  final double? iconSize;
  final BorderRadius? borderRadius;
  final bool showIconOnly;
  final String? buttonText;

  const UnifiedAddToCartButton({
    super.key,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.weight,
    required this.price,
    required this.mrp,
    this.discount = '',
    required this.isFreeCupEligible,
    this.itemType = 'product',
    required this.productType,
    this.onCartUpdated,
    this.customWidth,
    this.customHeight,
    this.iconSize,
    this.borderRadius,
    this.showIconOnly = true,
    this.buttonText,
  });

  /// Factory constructor for Product
  factory UnifiedAddToCartButton.fromProduct(
    Product product, {
    VoidCallback? onCartUpdated,
    double? customWidth,
    double? customHeight,
    bool showIconOnly = true,
    String? buttonText,
  }) {
    return UnifiedAddToCartButton(
      productId: product.id,
      productName: product.name,
      imageUrl: product.image,
      weight: product.weight,
      price: product.price,
      mrp: product.mrp,
      discount: product.discount,
      isFreeCupEligible: product.isFreeCupEligible,
      itemType: product.isWarehouseProduct ? 'warehouse' : 'product',
      productType: ProductType.product,
      onCartUpdated: onCartUpdated,
      customWidth: customWidth,
      customHeight: customHeight,
      showIconOnly: showIconOnly,
      buttonText: buttonText,
    );
  }

  /// Factory constructor for RecommendedProduct
  factory UnifiedAddToCartButton.fromRecommendedProduct(
    RecommendedProduct product, {
    VoidCallback? onCartUpdated,
    double? customWidth,
    double? customHeight,
    bool showIconOnly = true,
    String? buttonText,
  }) {
    final discountPercent = product.mrp > product.sellingPrice
        ? ((product.mrp - product.sellingPrice) / product.mrp * 100).round()
        : 0;

    return UnifiedAddToCartButton(
      productId: product.id,
      productName: product.productName,
      imageUrl: product.firstImage,
      weight: product.weightDescription,
      price: product.sellingPrice,
      mrp: product.mrp,
      discount: discountPercent > 0 ? discountPercent.toString() : '',
      isFreeCupEligible: product.freeCupEligibility,
      itemType: product.franchiseId.isEmpty ? 'warehouse' : 'product',
      productType: ProductType.recommended,
      onCartUpdated: onCartUpdated,
      customWidth: customWidth,
      customHeight: customHeight,
      showIconOnly: showIconOnly,
      buttonText: buttonText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final isInCart = CartService.isInCart(productName);
    final quantity = CartService.getQuantity(productName);

    if (isInCart) {
      return _buildQuantitySelector(context, theme, quantity);
    }

    return _buildAddButton(context, theme);
  }

  Widget _buildAddButton(BuildContext context, SiporaThemeExtension theme) {
    final isTablet = context.isTablet;
    final width = customWidth ?? (isTablet ? context.w(36) : context.w(32));
    final height = customHeight ?? (isTablet ? context.w(36) : context.w(32));
    final iconSizeVal = iconSize ?? (isTablet ? context.w(18) : context.w(16));
    final radius =
        borderRadius ??
        BorderRadius.circular(isTablet ? context.r(10) : context.r(8));

    return GestureDetector(
      onTap: () => _addToCart(context),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [SiporaTheme.greenDark, SiporaTheme.greenMid],
          ),
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: SiporaTheme.greenDark.withValues(alpha: 0.3),
              blurRadius: 6.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: showIconOnly
            ? Icon(Icons.add, color: Colors.white, size: iconSizeVal)
            : Center(
                child: Text(
                  buttonText ?? 'Add',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.sp(12),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildQuantitySelector(
    BuildContext context,
    SiporaThemeExtension theme,
    int quantity,
  ) {
    final isTablet = context.isTablet;
    final selectorHeight =
        customHeight ?? (isTablet ? context.h(36) : context.h(32));
    final buttonSize = isTablet ? context.w(30) : context.w(26);
    final iconSizeVal = iconSize ?? (isTablet ? context.w(16) : context.w(14));
    final fontSize = isTablet ? context.sp(15) : context.sp(13);

    return Container(
      height: selectorHeight,
      decoration: BoxDecoration(
        color: SiporaTheme.greenBg,
        borderRadius: BorderRadius.circular(
          isTablet ? context.r(10) : context.r(8),
        ),
        border: Border.all(
          color: SiporaTheme.greenLight.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              if (quantity > 1) {
                CartService.updateQuantity(productName, quantity - 1);
              } else {
                CartService.removeItem(productName);
              }
              onCartUpdated?.call();
            },
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: quantity == 1
                    ? SiporaTheme.greenBg
                    : SiporaTheme.greenDark,
                borderRadius: BorderRadius.circular(
                  isTablet ? context.r(8) : context.r(6),
                ),
              ),
              child: Icon(
                Icons.remove,
                color: quantity == 1 ? SiporaTheme.greenDark : Colors.white,
                size: iconSizeVal,
              ),
            ),
          ),
          Container(
            width: buttonSize,
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: theme.textDark,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              CartService.updateQuantity(productName, quantity + 1);
              onCartUpdated?.call();
            },
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: SiporaTheme.greenDark,
                borderRadius: BorderRadius.circular(
                  isTablet ? context.r(8) : context.r(6),
                ),
              ),
              child: Icon(Icons.add, color: Colors.white, size: iconSizeVal),
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(BuildContext context) {
    CartHelperService.addProductToCart(
      productId: productId,
      productName: productName,
      imageUrl: imageUrl,
      weight: weight,
      price: price,
      mrp: mrp,
      discount: discount,
      isFreeCupEligible: isFreeCupEligible,
      itemType: itemType,
      quantity: 1,
      onCartUpdated: onCartUpdated,
      onSuccess: () {
        SiporaTheme.showSnackBar(
          context,
          'Added $productName to cart',
          isError: false,
        );
      },
    );
  }
}
