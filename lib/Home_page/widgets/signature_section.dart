import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:sipora/theme/sipora_theme.dart';
import 'package:sipora/utils/image_utils.dart';
import 'package:sipora/services/cart_service.dart';
import 'package:sipora/models/product.dart';
import 'package:sipora/Shop_page/widgets/infinite_carousel.dart';
import 'package:sipora/Shop_page/widgets/products_details_page.dart';
import 'package:sipora/models/recommended_product.dart';
import '../../Cart_page/services/cart_helper_service.dart';
import '../../utils/screen_utils.dart';

class SignatureSection extends StatefulWidget {
  final List<Map<String, String>> signatureProducts;
  final List<RecommendedProduct> recommendedProducts;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onCartUpdated;
  final VoidCallback? onCupQuestRefresh;

  const SignatureSection({
    super.key,
    required this.signatureProducts,
    required this.recommendedProducts,
    this.isLoading = false,
    this.errorMessage,
    this.onCartUpdated,
    this.onCupQuestRefresh,
  });

  @override
  State<SignatureSection> createState() => _SignatureSectionState();
}

class _SignatureSectionState extends State<SignatureSection> {
  final ScrollController _scrollController = ScrollController();
  double _savedScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_saveScrollOffset);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_saveScrollOffset);
    _scrollController.dispose();
    super.dispose();
  }

  void _saveScrollOffset() {
    if (_scrollController.hasClients) {
      _savedScrollOffset = _scrollController.offset;
    }
  }

  void _restoreScrollPosition() {
    if (_scrollController.hasClients && _savedScrollOffset > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients &&
            _savedScrollOffset <= _scrollController.position.maxScrollExtent) {
          _scrollController.jumpTo(_savedScrollOffset);
        }
      });
    }
  }

  List<Product> _getCarouselProducts(int index) {
    final recommendedProduct = widget.recommendedProducts[index];
    final List<Product> carouselProducts = [];

    final allImages = recommendedProduct.allImages;

    if (allImages.isNotEmpty) {
      for (int i = 0; i < allImages.length; i++) {
        final imageUrl = allImages[i];
        if (imageUrl.isNotEmpty && imageUrl != 'null') {
          carouselProducts.add(
            Product(
              id: recommendedProduct.id,
              name: recommendedProduct.productName,
              image: ImageUtils.getValidImageUrl(imageUrl),
              productsImages: allImages.join(','),
              weight: '${recommendedProduct.weightKg} kg',
              price: recommendedProduct.total,
              mrp: recommendedProduct.total,
              discount: '',
              brand: recommendedProduct.brand,
              isFreeCupEligible: recommendedProduct.freeCupEligibility,
            ),
          );
        }
      }
    }

    if (carouselProducts.isEmpty && recommendedProduct.firstImage.isNotEmpty) {
      carouselProducts.add(
        Product(
          id: recommendedProduct.id,
          name: recommendedProduct.productName,
          image: ImageUtils.getValidImageUrl(recommendedProduct.firstImage),
          productsImages: recommendedProduct.firstImage,
          weight: '${recommendedProduct.weightKg} kg',
          price: recommendedProduct.total,
          mrp: recommendedProduct.total,
          discount: '',
          brand: recommendedProduct.brand,
          isFreeCupEligible: recommendedProduct.freeCupEligibility,
        ),
      );
    }

    if (carouselProducts.isEmpty) {
      carouselProducts.add(
        Product(
          id: recommendedProduct.id,
          name: recommendedProduct.productName,
          image: ImageUtils.fallbackImagePath,
          productsImages: '',
          weight: '${recommendedProduct.weightKg} kg',
          price: recommendedProduct.total,
          mrp: recommendedProduct.total,
          discount: '',
          brand: recommendedProduct.brand,
          isFreeCupEligible: recommendedProduct.freeCupEligibility,
        ),
      );
    }

    return carouselProducts;
  }

  Widget _buildFreeCupBadge() {
    final isTablet = context.isTablet;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(6),
        vertical: context.h(3),
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [SiporaTheme.gold, SiporaTheme.greenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(context.r(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: context.r(4),
            offset: Offset(0, 1.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_cafe_rounded,
            color: Colors.white,
            size: isTablet ? context.w(12) : context.w(10),
          ),
          SizedBox(width: context.w(3)),
          Text(
            'Free Cup Eligible',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? context.sp(9) : context.sp(8),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;

    // Auto-adjust dimensions based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    double cardWidth;

    if (isTablet) {
      cardWidth = screenWidth * 0.32;
    } else {
      if (screenWidth < 360) {
        cardWidth = screenWidth * 0.38;
      } else if (screenWidth < 400) {
        cardWidth = screenWidth * 0.40;
      } else {
        cardWidth = screenWidth * 0.42;
      }
    }

    // Clamp card width
    final minCardWidth = isTablet ? context.w(170) : context.w(130);
    final maxCardWidth = isTablet ? context.w(230) : context.w(180);
    final adjustedCardWidth = cardWidth.clamp(minCardWidth, maxCardWidth);

    // Calculate carousel height based on card width
    final carouselHeight = adjustedCardWidth * 0.75;
    final carouselWidth = adjustedCardWidth - context.w(16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.w(16)),
          child: Text(
            'Sipora Signature',
            style: TextStyle(
              fontSize: isTablet ? context.sp(24) : context.sp(20),
              fontWeight: FontWeight.w800,
              color: theme.textDark,
            ),
          ),
        ),
        SizedBox(height: context.h(8)),
        widget.isLoading
            ? const Center(child: CircularProgressIndicator())
            : widget.errorMessage != null
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(context.w(16)),
                  child: Text(
                    widget.errorMessage!,
                    style: TextStyle(
                      fontSize: context.sp(14),
                      color: theme.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : widget.signatureProducts.isEmpty
            ? Center(
                child: Text(
                  'No products available',
                  style: TextStyle(
                    fontSize: context.sp(14),
                    color: theme.textMuted,
                  ),
                ),
              )
            : SizedBox(
                height:
                    carouselHeight +
                    context.h(100), // Approximate height for content
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: context.w(16)),
                  itemCount: widget.signatureProducts.length,
                  itemBuilder: (context, index) {
                    final product = widget.signatureProducts[index];
                    final productName = product['name']!;
                    final productPrice = product['price']!;
                    final productBrand = product['brand'] ?? '';

                    // Get free cup eligibility from recommended product directly
                    final recommendedProduct =
                        widget.recommendedProducts[index];
                    final isFreeCupEligible =
                        recommendedProduct.freeCupEligibility;

                    final carouselProducts = _getCarouselProducts(index);
                    final hasMultipleImages = carouselProducts.length > 1;

                    final isInCart = CartService.isInCart(productName);
                    final quantity = CartService.getQuantity(productName);

                    return GestureDetector(
                      onTap: () => _showProductDetails(context, index),
                      child: Container(
                        width: adjustedCardWidth,
                        margin: EdgeInsets.only(right: context.w(12)),
                        decoration: BoxDecoration(
                          color: theme.white,
                          borderRadius: BorderRadius.circular(context.r(16)),
                          boxShadow: [
                            BoxShadow(
                              color: SiporaTheme.shadowLight.withValues(
                                alpha: 0.1,
                              ),
                              blurRadius: 15.r,
                              offset: Offset(0, 4.h),
                            ),
                          ],
                          border: Border.all(
                            color: theme.goldBg.withValues(alpha: 0.2),
                            width: 1.w,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(context.r(16)),
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: carouselHeight,
                                    child: InfiniteCarousel(
                                      products: carouselProducts,
                                      type: CarouselType.card,
                                      height: carouselHeight,
                                      width: carouselWidth,
                                      borderRadius: context.r(12),
                                      showDots: hasMultipleImages,
                                      showCounter: hasMultipleImages,
                                      showOverlay: false,
                                      autoSlideDuration: const Duration(
                                        seconds: 3,
                                      ),
                                      animationDuration: const Duration(
                                        milliseconds: 500,
                                      ),
                                      onTap: () =>
                                          _showProductDetails(context, index),
                                    ),
                                  ),
                                ),
                                // Free Cup Eligibility Badge - Top Left
                                if (isFreeCupEligible)
                                  Positioned(
                                    top: context.h(8),
                                    left: context.w(8),
                                    child: _buildFreeCupBadge(),
                                  ),
                                Positioned(
                                  bottom: context.h(6),
                                  right: context.w(6),
                                  child: isInCart
                                      ? _buildQuantitySelector(
                                          context,
                                          productName,
                                          quantity,
                                          carouselProducts.first,
                                          isTablet,
                                          adjustedCardWidth,
                                        )
                                      : _buildAddButton(
                                          context,
                                          productName,
                                          carouselProducts.first,
                                          isTablet,
                                          adjustedCardWidth,
                                        ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.w(8),
                                vertical: context.h(6),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (productBrand.isNotEmpty)
                                    Text(
                                      productBrand,
                                      style: TextStyle(
                                        fontSize: isTablet
                                            ? context.sp(12)
                                            : context.sp(10),
                                        color: theme.greenPill,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (productBrand.isNotEmpty)
                                    SizedBox(height: context.h(2)),
                                  Text(
                                    productName,
                                    style: TextStyle(
                                      fontSize: isTablet
                                          ? context.sp(14)
                                          : context.sp(12),
                                      fontWeight: FontWeight.w600,
                                      height: 1.2,
                                      color: theme.textDark,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: context.h(4)),
                                  Row(
                                    children: [
                                      Text(
                                        productPrice,
                                        style: TextStyle(
                                          fontSize: isTablet
                                              ? context.sp(16)
                                              : context.sp(14),
                                          fontWeight: FontWeight.w700,
                                          color: theme.textDark,
                                        ),
                                      ),
                                      if (isFreeCupEligible) ...[
                                        SizedBox(width: context.w(4)),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: context.w(4),
                                            vertical: context.h(1),
                                          ),
                                          decoration: BoxDecoration(
                                            color: SiporaTheme.gold.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              context.r(4),
                                            ),
                                            border: Border.all(
                                              color: SiporaTheme.gold
                                                  .withValues(alpha: 0.3),
                                              width: 0.5.w,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildAddButton(
    BuildContext context,
    String productName,
    Product product,
    bool isTablet,
    double cardWidth,
  ) {
    final theme = context.siporaTheme;
    final buttonSize = cardWidth * 0.22;

    return GestureDetector(
      onTap: () {
        CartHelperService.addProductToCart(
          productId: product.id,
          productName: product.name,
          imageUrl: ImageUtils.getValidImageUrl(product.image),
          weight: product.weight,
          price: product.price,
          mrp: product.mrp,
          discount: product.discount,
          isFreeCupEligible: product.isFreeCupEligible,
          itemType: product.isWarehouseProduct ? 'warehouse' : 'product',
          quantity: 1,
          onCartUpdated: () {
            widget.onCartUpdated?.call();
            widget.onCupQuestRefresh?.call();
          },
          onSuccess: () {
            if (context.mounted) {
              SiporaTheme.showSnackBar(
                context,
                'Added ${product.name} to cart',
                isError: false,
              );
            }
          },
        );
      },
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [theme.greenDark, theme.greenMid]),
          borderRadius: BorderRadius.circular(context.r(10)),
          boxShadow: [
            BoxShadow(
              color: theme.greenDark.withValues(alpha: 0.3),
              blurRadius: 8.r,
              offset: Offset(0, 3.h),
            ),
          ],
        ),
        child: Icon(Icons.add, color: Colors.white, size: buttonSize * 0.55),
      ),
    );
  }

  Widget _buildQuantitySelector(
    BuildContext context,
    String productName,
    int quantity,
    Product product,
    bool isTablet,
    double cardWidth,
  ) {
    final theme = context.siporaTheme;
    final buttonSize = cardWidth * 0.20;
    final iconSize = buttonSize * 0.5;

    return Container(
      height: buttonSize * 1.3,
      decoration: BoxDecoration(
        color: theme.greenBg,
        borderRadius: BorderRadius.circular(context.r(10)),
        border: Border.all(color: theme.greenLight.withValues(alpha: 0.3)),
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
              widget.onCartUpdated?.call();
              widget.onCupQuestRefresh?.call();
            },
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: quantity == 1 ? theme.greenBg : theme.greenDark,
                borderRadius: BorderRadius.circular(context.r(8)),
              ),
              child: Icon(
                Icons.remove,
                color: quantity == 1 ? theme.greenDark : Colors.white,
                size: iconSize,
              ),
            ),
          ),
          Container(
            width: buttonSize * 0.9,
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: TextStyle(
                fontSize: isTablet ? context.sp(12) : context.sp(11),
                fontWeight: FontWeight.w600,
                color: theme.textDark,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              CartService.updateQuantity(productName, quantity + 1);
              widget.onCartUpdated?.call();
              widget.onCupQuestRefresh?.call();
            },
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: theme.greenDark,
                borderRadius: BorderRadius.circular(context.r(8)),
              ),
              child: Icon(Icons.add, color: Colors.white, size: iconSize),
            ),
          ),
        ],
      ),
    );
  }

  void _showProductDetails(BuildContext context, int productIndex) {
    final recommendedProduct = widget.recommendedProducts[productIndex];
    _saveScrollOffset();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailsPage(
        product: recommendedProduct,
        onCartUpdated: () {
          widget.onCartUpdated?.call();
          widget.onCupQuestRefresh?.call();
          _restoreScrollPosition();
        },
      ),
    ).then((_) {
      _restoreScrollPosition();
    });
  }
}
