import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import '../../models/product.dart';
import '../../models/recommended_product.dart';
import '../../theme/sipora_theme.dart';
import '../../utils/screen_utils.dart';
import '../../Shop_page/widgets/infinite_carousel.dart';
import '../../product_review/widgets/rating_stars.dart';
import '../../product_review/widgets/like_button.dart';
import 'unified_add_to_cart_button.dart';

enum CardType { product, recommended }

class UnifiedProductCard extends StatelessWidget {
  final String id;
  final String name;
  final String brand;
  final String imageUrl;
  final String productsImages;
  final String weight;
  final double price;
  final double mrp;
  final String discount;
  final bool isFreeCupEligible;
  final String itemType;
  final CardType cardType;
  final VoidCallback? onTap;
  final VoidCallback? onCartUpdated;
  final double? cardWidth;
  final double? imageHeight;
  final double? borderRadius;

  final double? averageRating;
  final int? totalRatings;
  final bool? isLiked;
  final int? totalLikes;
  final String? userId;
  final Function(String, bool)? onLikeToggled;

  const UnifiedProductCard({
    super.key,
    required this.id,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.productsImages,
    required this.weight,
    required this.price,
    required this.mrp,
    required this.discount,
    required this.isFreeCupEligible,
    this.itemType = 'product',
    required this.cardType,
    this.onTap,
    this.onCartUpdated,
    this.cardWidth,
    this.imageHeight,
    this.borderRadius,
    this.averageRating,
    this.totalRatings,
    this.isLiked,
    this.totalLikes,
    this.userId,
    this.onLikeToggled,
  });

  factory UnifiedProductCard.fromProduct(
    Product product, {
    VoidCallback? onTap,
    VoidCallback? onCartUpdated,
    double? cardWidth,
    double? imageHeight,
    double? averageRating,
    int? totalRatings,
    bool? isLiked,
    int? totalLikes,
    String? userId,
    Function(String, bool)? onLikeToggled,
  }) {
    return UnifiedProductCard(
      id: product.id,
      name: product.name,
      brand: product.brand,
      imageUrl: product.image,
      productsImages: product.productsImages,
      weight: product.weight,
      price: product.price,
      mrp: product.mrp,
      discount: product.discount,
      isFreeCupEligible: product.isFreeCupEligible,
      itemType: product.isWarehouseProduct ? 'warehouse' : 'product',
      cardType: CardType.product,
      onTap: onTap,
      onCartUpdated: onCartUpdated,
      cardWidth: cardWidth,
      imageHeight: imageHeight,
      averageRating: averageRating,
      totalRatings: totalRatings,
      isLiked: isLiked,
      totalLikes: totalLikes,
      userId: userId,
      onLikeToggled: onLikeToggled,
    );
  }

  factory UnifiedProductCard.fromRecommendedProduct(
    RecommendedProduct product, {
    VoidCallback? onTap,
    VoidCallback? onCartUpdated,
    double? cardWidth,
    double? imageHeight,
    String? userId,
    Function(String, bool)? onLikeToggled,
  }) {
    final discountPercent = product.mrp > product.sellingPrice
        ? ((product.mrp - product.sellingPrice) / product.mrp * 100).round()
        : 0;

    return UnifiedProductCard(
      id: product.id,
      name: product.productName,
      brand: product.brand,
      imageUrl: product.firstImage,
      productsImages: product.productsImages,
      weight: product.weightDescription,
      price: product.sellingPrice,
      mrp: product.mrp,
      discount: discountPercent > 0 ? discountPercent.toString() : '',
      isFreeCupEligible: product.freeCupEligibility,
      itemType: product.franchiseId.isEmpty ? 'warehouse' : 'product',
      cardType: CardType.recommended,
      onTap: onTap,
      onCartUpdated: onCartUpdated,
      cardWidth: cardWidth,
      imageHeight: imageHeight,
      averageRating: product.averageRating,
      totalRatings: product.totalRatings,
      isLiked: product.isLiked,
      totalLikes: product.totalLikes,
      userId: userId,
      onLikeToggled: onLikeToggled,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;
    final width = cardWidth ?? (isTablet ? context.w(200) : context.w(160));
    final height = imageHeight ?? (isTablet ? context.h(120) : context.h(100));
    final radius = borderRadius ?? context.r(16);

    final carouselProducts = _getCarouselProducts();
    final hasMultipleImages = carouselProducts.length > 1;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: EdgeInsets.only(right: context.w(16)),
        decoration: BoxDecoration(
          color: theme.white,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: SiporaTheme.shadowLight.withValues(alpha: 0.1),
              blurRadius: 15.r,
              offset: Offset(0, 4.h),
            ),
          ],
          border: Border.all(
            color: SiporaTheme.goldBg.withValues(alpha: 0.2),
            width: 1.w,
          ),
        ),
        child: ClipRect(
          // Add ClipRect to prevent overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(radius),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: height,
                      child: InfiniteCarousel(
                        products: carouselProducts,
                        type: CarouselType.card,
                        height: height,
                        width: width,
                        borderRadius: radius - 4.r,
                        showDots: hasMultipleImages,
                        showCounter: hasMultipleImages,
                        showOverlay: false,
                        autoSlideDuration: const Duration(seconds: 3),
                        animationDuration: const Duration(milliseconds: 500),
                        onTap: onTap,
                      ),
                    ),
                  ),
                  // Discount Badge
                  if (discount.isNotEmpty)
                    Positioned(
                      top: context.h(8),
                      left: context.w(8),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.w(8),
                          vertical: context.h(3),
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              SiporaTheme.greenDark,
                              SiporaTheme.greenMid,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(context.r(16)),
                        ),
                        child: Text(
                          '$discount% OFF',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.sp(10),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  // FREE CUP ELIGIBLE BADGE - Full width label at bottom of image
                  if (isFreeCupEligible)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: context.h(3)),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              SiporaTheme.gold.withValues(alpha: 0.9),
                              SiporaTheme.greenDark.withValues(alpha: 0.9),
                            ],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_cafe_rounded,
                              color: Colors.white,
                              size: context.w(12),
                            ),
                            SizedBox(width: context.w(4)),
                            Text(
                              'FREE CUP ELIGIBLE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: context.sp(8),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Like Button
                  Positioned(
                    top: context.h(8),
                    right: context.w(8),
                    child: LikeButton(
                      isLiked: isLiked ?? false,
                      likeCount: totalLikes ?? 0,
                      onLikeToggled: () {
                        if (userId != null && onLikeToggled != null) {
                          onLikeToggled!(id, isLiked ?? false);
                        }
                      },
                      size: isTablet ? context.w(18) : context.w(16),
                      showCount: false,
                    ),
                  ),
                  // Add to Cart Button
                  Positioned(
                    bottom: context.h(8),
                    right: context.w(8),
                    child: UnifiedAddToCartButton(
                      productId: id,
                      productName: name,
                      imageUrl: imageUrl,
                      weight: weight,
                      price: price,
                      mrp: mrp,
                      discount: discount,
                      isFreeCupEligible: isFreeCupEligible,
                      itemType: itemType,
                      productType: cardType == CardType.product
                          ? ProductType.product
                          : ProductType.recommended,
                      onCartUpdated: onCartUpdated,
                      customWidth: isTablet ? context.w(32) : context.w(28),
                      customHeight: isTablet ? context.w(32) : context.w(28),
                      iconSize: isTablet ? context.w(16) : context.w(14),
                    ),
                  ),
                ],
              ),
              // Reduced padding from 8 to 6
              Padding(
                padding: EdgeInsets.all(context.w(6)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (brand.isNotEmpty) ...[
                      Text(
                        brand,
                        style: TextStyle(
                          fontSize: context.sp(10), // Reduced from 11
                          fontWeight: FontWeight.w500,
                          color: SiporaTheme.greenPill,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: context.h(2)),
                    ],
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: context.sp(12), // Reduced from 13
                        fontWeight: FontWeight.w600,
                        color: theme.textDark,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((totalRatings ?? 0) > 0) ...[
                      SizedBox(height: context.h(3)), // Reduced from 4
                      Row(
                        children: [
                          RatingStars(
                            rating: averageRating ?? 0,
                            size: context.w(9), // Reduced from 10
                          ),
                          SizedBox(width: context.w(3)), // Reduced from 4
                          Text(
                            '(${totalRatings ?? 0})',
                            style: TextStyle(
                              fontSize: context.sp(9), // Reduced from 10
                              color: theme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: context.h(4)), // Reduced from 6
                    // Price
                    Text(
                      '₹${price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: context.sp(14), // Reduced from 15
                        fontWeight: FontWeight.w700,
                        color: theme.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Product> _getCarouselProducts() {
    final List<Product> carouselProducts = [];

    if (productsImages.isNotEmpty) {
      final images = productsImages.contains(',')
          ? productsImages.split(',').map((img) => img.trim()).toList()
          : [imageUrl];

      for (final imageUrl in images) {
        if (imageUrl.isNotEmpty && imageUrl != 'null') {
          carouselProducts.add(
            Product(
              id: id,
              name: name,
              image: imageUrl,
              productsImages: productsImages,
              weight: weight,
              price: price,
              mrp: mrp,
              discount: discount,
              brand: brand,
              isFreeCupEligible: isFreeCupEligible,
            ),
          );
        }
      }
    }

    if (carouselProducts.isEmpty &&
        imageUrl.isNotEmpty &&
        imageUrl != 'null' &&
        !imageUrl.startsWith('/assets/')) {
      carouselProducts.add(
        Product(
          id: id,
          name: name,
          image: imageUrl,
          productsImages: productsImages,
          weight: weight,
          price: price,
          mrp: mrp,
          discount: discount,
          brand: brand,
          isFreeCupEligible: isFreeCupEligible,
        ),
      );
    }

    // Add fallback product with logo if no images
    if (carouselProducts.isEmpty) {
      carouselProducts.add(
        Product(
          id: id,
          name: name,
          image: '/assets/images/sipora_logo.png',
          productsImages: '',
          weight: weight,
          price: price,
          mrp: mrp,
          discount: discount,
          brand: brand,
          isFreeCupEligible: isFreeCupEligible,
        ),
      );
    }

    return carouselProducts;
  }
}
