// lib/Setting_page/widgets/favorites_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/sipora_theme.dart';
import '../../utils/responsive_constants.dart';
import '../../services/storage_service.dart';
import '../../product_review/services/like_service.dart';
import '../../config/api_config.dart';
import '../../models/recommended_product.dart';
import '../../services/shop_service.dart';
import '../../Shop_page/widgets/products_details_page.dart';
import '../../Shop_page/widgets/infinite_carousel.dart';
import '../../models/product.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with SingleTickerProviderStateMixin {
  List<LikedProduct> _likedProducts = [];
  bool _isLoading = true;
  String? _userId;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _loadLikedProducts();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadLikedProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? userId = await StorageService.getUserId();
      if (userId == null || userId.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        userId = prefs.getString('user_id');
      }

      if (userId == null || userId.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _userId = userId;
        });
      }

      await _fetchLikedProducts(userId);
      _animationController.forward();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchLikedProducts(String userId) async {
    try {
      final token = await StorageService.getToken();
      final prefs = await SharedPreferences.getInstance();
      final authToken = token ?? prefs.getString('tea_app_token');

      final url = '${ApiConfig.baseUrl}/api/like/liked-products/$userId';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> products = data['products'] ?? [];
          setState(() {
            _likedProducts = products
                .map((json) => LikedProduct.fromJson(json))
                .toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeFromFavorites(String productId) async {
    if (_userId == null) return;

    final previouslyLiked = true;
    
    setState(() {
      _likedProducts.removeWhere((p) => p.productId == productId);
    });

    final success = await LikeService.toggleLike(
      userId: _userId!,
      productId: productId,
      currentlyLiked: previouslyLiked,
    );

    if (!success && mounted) {
      await _loadLikedProducts();
      if (mounted) {
        SiporaTheme.showSnackBar(
          context,
          'Failed to remove from favorites. Please try again.',
          isError: true,
        );
      }
    } else if (mounted) {
      SiporaTheme.showSnackBar(
        context,
        'Removed from favorites',
        isError: false,
      );
    }
  }

  void _showProductDetails(LikedProduct product) {
    // Get all images properly parsed
    final allImagesList = product.getAllImages();
    
    // Create a comma-separated string of all images (same format as API returns)
    final imagesString = allImagesList.join(',');
    
    // Calculate GST - use int for gstRate
    final int gstRate = 18;
    final cgstAmount = (product.amount * (gstRate / 2) / 100).roundToDouble();
    final sgstAmount = (product.amount * (gstRate / 2) / 100).roundToDouble();
    final totalAmount = product.amount + cgstAmount + sgstAmount;
    
    final recommendedProduct = RecommendedProduct(
      id: product.productId,
      franchiseId: ShopService.selectedShopId ?? '',
      productName: product.productName,
      category: product.category,
      brand: product.brand,
      weightKg: 0.5,
      gramsG: 500,
      lengthCm: 10,
      widthCm: 10,
      productsImages: imagesString,
      shortDescription: product.productName,
      longDescription: 'Experience the authentic taste of ${product.productName}. '
          'Made with premium quality ingredients, this ${product.category.toLowerCase()} '
          'product from ${product.brand} delivers exceptional flavor and aroma.',
      gstRate: gstRate,
      amount: product.amount,
      cgst: cgstAmount,
      sgst: sgstAmount,
      total: totalAmount,
      freeCupEligibility: false,
      showGst: true,
      tags: product.category,
      createdAt: DateTime.now(),
      purchaseCount: 0,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailsPage(
        product: recommendedProduct,
        onCartUpdated: () {
          setState(() {});
        },
      ),
    ).then((_) => _loadLikedProducts());
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;

    return Scaffold(
      backgroundColor: theme.cream,
      appBar: AppBar(
        backgroundColor: theme.cream,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                SiporaTheme.greenDark.withValues(alpha: 0.1),
                SiporaTheme.greenLight.withValues(alpha: 0.1),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: SiporaTheme.greenDark,
              size: ResponsiveConstants.getIconSize(context) - 2,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'My Favorites',
          style: TextStyle(
            fontSize: ResponsiveConstants.getTitleFontSize(context),
            fontWeight: FontWeight.w600,
            color: theme.textDark,
          ),
        ),
        actions: [
          if (_likedProducts.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.greenBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.favorite_rounded,
                    size: 16,
                    color: SiporaTheme.greenPill,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_likedProducts.length}',
                    style: TextStyle(
                      fontSize: ResponsiveConstants.getFontSize(context),
                      fontWeight: FontWeight.w600,
                      color: SiporaTheme.greenPill,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: _isLoading ? _buildLoadingSkeleton() : _buildBody(),
    );
  }

  Widget _buildBody() {
    final theme = context.siporaTheme;
    final isTablet = ResponsiveConstants.isTablet(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = 20.0 * 2;
    final spacing = 16.0;
    final availableWidth = screenWidth - horizontalPadding - spacing;
    final double cardWidth = availableWidth / 2;
    final double imageHeight = isTablet ? 200.0 : 160.0;
    final double totalCardHeight = imageHeight + 85;

    if (_userId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [SiporaTheme.greenBg, SiporaTheme.greenBg],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: ResponsiveConstants.getIconSize(context) * 2.5,
                color: SiporaTheme.greenDark,
              ),
            ),
            SizedBox(height: ResponsiveConstants.getGridSpacing(context) * 2.5),
            Text(
              'Login to see your favorites',
              style: TextStyle(
                fontSize: ResponsiveConstants.getTitleFontSize(context),
                fontWeight: FontWeight.w700,
                color: theme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveConstants.getGridSpacing(context)),
            Text(
              'Items you like will appear here',
              style: TextStyle(
                fontSize: ResponsiveConstants.getFontSize(context),
                color: theme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveConstants.getGridSpacing(context) * 2.5),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login').then((_) {
                  _loadLikedProducts();
                });
              },
              style: SiporaTheme.primaryButtonStyle(
                radius: 30,
                height: ResponsiveConstants.getButtonHeight(context) - 8,
              ),
              child: Text(
                'Login',
                style: TextStyle(
                  fontSize: ResponsiveConstants.getButtonFontSize(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_likedProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [SiporaTheme.greenBg, SiporaTheme.greenBg],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: ResponsiveConstants.getIconSize(context) * 3,
                color: SiporaTheme.greenDark,
              ),
            ),
            SizedBox(height: ResponsiveConstants.getGridSpacing(context) * 2.5),
            Text(
              'No favorites yet',
              style: TextStyle(
                fontSize: ResponsiveConstants.getTitleFontSize(context),
                fontWeight: FontWeight.w700,
                color: theme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveConstants.getGridSpacing(context)),
            Text(
              'Start liking products to see them here',
              style: TextStyle(
                fontSize: ResponsiveConstants.getFontSize(context),
                color: theme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: cardWidth / totalCardHeight,
                ),
                itemCount: _likedProducts.length,
                itemBuilder: (context, index) {
                  final product = _likedProducts[index];
                  return _buildFavoriteProductCard(
                    product: product,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildFavoriteProductCard({
  required LikedProduct product,
}) {
  final theme = context.siporaTheme;
  final isTablet = ResponsiveConstants.isTablet(context);
  final imageHeight = isTablet ? 200.0 : 160.0;
  
  // Convert LikedProduct to Product for the carousel
  final tempProducts = product.getAllImages().map((imageUrl) {
    return Product(
      id: product.productId,
      name: product.productName,
      image: imageUrl,
      productsImages: product.productsImages,
      weight: '${product.amount > 100 ? 500 : 250}g',
      price: product.amount,
      mrp: product.total,
      discount: product.hasDiscount 
          ? '${((product.total - product.amount) / product.total * 100).round()}% OFF'
          : '',
      brand: product.brand,
      isFreeCupEligible: false,
      // Remove subCategory and rating as they don't exist in Product model
    );
  }).toList();

  return GestureDetector(
    onTap: () => _showProductDetails(product),
    child: Container(
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.goldBg.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: SiporaTheme.shadowLight.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Product Image with Infinite Carousel
          Stack(
            children: [
              SizedBox(
                height: imageHeight,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: tempProducts.isNotEmpty
                      ? InfiniteCarousel(
                          products: tempProducts,
                          type: CarouselType.card,
                          height: imageHeight,
                          width: double.infinity,
                          borderRadius: 20,
                          showDots: tempProducts.length > 1,
                          showCounter: false,
                          showOverlay: false,
                          autoSlideDuration: const Duration(seconds: 3),
                          animationDuration: const Duration(milliseconds: 500),
                        )
                      : Container(
                          color: theme.greenBg,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.local_cafe_outlined,
                                  color: theme.textMuted.withValues(alpha: 0.5),
                                  size: 48,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No Image',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.textMuted.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
              // Remove button
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _removeFromFavorites(product.productId),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: theme.textMuted,
                    ),
                  ),
                ),
              ),
              // Heart icon
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          // Product Details
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Brand
                if (product.brand.isNotEmpty)
                  Text(
                    product.brand,
                    style: TextStyle(
                      fontSize: ResponsiveConstants.getFontSize(context) - 5,
                      color: theme.greenPill,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                // Product Name
                Text(
                  product.productName,
                  style: TextStyle(
                    fontSize: ResponsiveConstants.getFontSize(context) - 3,
                    fontWeight: FontWeight.w600,
                    color: theme.textDark,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Price
                Text(
                  product.formattedAmount,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    fontWeight: FontWeight.w700,
                    color: theme.greenDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildLoadingSkeleton() {
    final theme = context.siporaTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = 20.0 * 2;
    final spacing = 16.0;
    final availableWidth = screenWidth - horizontalPadding - spacing;
    final double cardWidth = availableWidth / 2;
    final double imageHeight = 160.0;
    final double totalCardHeight = imageHeight + 85;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: cardWidth / totalCardHeight,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: theme.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: imageHeight,
                        decoration: BoxDecoration(
                          color: theme.greenBg,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 50,
                              height: 10,
                              decoration: BoxDecoration(
                                color: theme.greenBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 90,
                              height: 14,
                              decoration: BoxDecoration(
                                color: theme.greenBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 45,
                              height: 12,
                              decoration: BoxDecoration(
                                color: theme.greenBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Model for Liked Product
class LikedProduct {
  final String productId;
  final String productName;
  final double amount;
  final double total;
  final String brand;
  final String category;
  final String subCategory;
  final String source;
  final double rating;
  final bool liked;
  final String productsImages;

  LikedProduct({
    required this.productId,
    required this.productName,
    required this.amount,
    required this.total,
    required this.brand,
    required this.category,
    required this.subCategory,
    required this.source,
    required this.rating,
    required this.liked,
    required this.productsImages,
  });

  factory LikedProduct.fromJson(Map<String, dynamic> json) {
    double ratingValue = 0.0;
    if (json['rating'] != null) {
      if (json['rating'] is int) {
        ratingValue = (json['rating'] as int).toDouble();
      } else if (json['rating'] is double) {
        ratingValue = json['rating'] as double;
      } else if (json['rating'] is String) {
        ratingValue = double.tryParse(json['rating']) ?? 0.0;
      }
    }

    double amountValue = 0.0;
    if (json['amount'] != null) {
      if (json['amount'] is int) {
        amountValue = (json['amount'] as int).toDouble();
      } else if (json['amount'] is double) {
        amountValue = json['amount'] as double;
      } else if (json['amount'] is String) {
        amountValue = double.tryParse(json['amount']) ?? 0.0;
      }
    }

    double totalValue = 0.0;
    if (json['total'] != null) {
      if (json['total'] is int) {
        totalValue = (json['total'] as int).toDouble();
      } else if (json['total'] is double) {
        totalValue = json['total'] as double;
      } else if (json['total'] is String) {
        totalValue = double.tryParse(json['total']) ?? 0.0;
      }
    }

    return LikedProduct(
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name'] ?? '',
      amount: amountValue,
      total: totalValue,
      brand: json['brand'] ?? '',
      category: json['category'] ?? '',
      subCategory: json['sub_category'] ?? '',
      source: json['source'] ?? '',
      rating: ratingValue,
      liked: json['liked'] ?? false,
      productsImages: json['products_images'] ?? '',
    );
  }

  List<String> getAllImages() {
    if (productsImages.isEmpty) return [];
    return productsImages.split(',').map((url) => url.trim()).toList();
  }

  String getFirstImage() {
    final images = getAllImages();
    return images.isNotEmpty ? images.first : '';
  }

  bool get hasDiscount => total > amount;
  
  String get formattedAmount => '₹${amount.toStringAsFixed(0)}';
  String get formattedTotal => '₹${total.toStringAsFixed(0)}';
}