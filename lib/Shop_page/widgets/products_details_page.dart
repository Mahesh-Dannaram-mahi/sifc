// lib/Shop_page/widgets/products_details_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/sipora_theme.dart';
import '../../utils/screen_utils.dart';
import '../../utils/image_utils.dart';

import '../../Cart_page/services/cart_helper_service.dart';
import '../../Cart_page/products_cart.dart';
import '../../services/cart_service.dart';
import '../../product_review/services/like_service.dart';
import '../../services/storage_service.dart';
import '../../product_review/services/batch_rating_service.dart';
import '../../product_review/widgets/rating_stars.dart';
import '../../models/recommended_product.dart';

class ProductDetailsPage extends StatefulWidget {
  final RecommendedProduct product;
  final VoidCallback? onCartUpdated;

  const ProductDetailsPage({
    super.key,
    required this.product,
    this.onCartUpdated,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage>
    with SingleTickerProviderStateMixin {
  int _quantity = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late PageController _pageController;
  int _currentImageIndex = 0;

  // Rating and Like state variables
  String? _userId;
  bool _isLoadingRating = true;

  @override
  void initState() {
    super.initState();
    _quantity = CartService.getQuantity(widget.product.productName);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _pageController = PageController();

    _animationController.forward();

    _loadUserIdAndRating();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserIdAndRating() async {
    try {
      String? userId = await StorageService.getUserId();

      if (userId == null || userId.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        userId = prefs.getString('user_id');
      }

      await StorageService.getToken();

      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      if (userId != null && userId.isNotEmpty && isLoggedIn) {
        setState(() {
          _userId = userId;
        });
        await _loadRatingData();
      } else {
        setState(() {
          _isLoadingRating = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingRating = false;
      });
    }
  }

  Future<void> _loadRatingData() async {
    if (_userId == null || _userId!.isEmpty) {
      setState(() {
        _isLoadingRating = false;
      });
      return;
    }

    setState(() {
      _isLoadingRating = true;
    });

    try {
      await BatchRatingService.loadRatingForProduct(widget.product);
    } catch (e) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRating = false;
        });
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_userId == null || _userId!.isEmpty) {
      _showLoginRequiredDialog();
      return;
    }

    final previouslyLiked = widget.product.isLiked;

    setState(() {
      widget.product.isLiked = !previouslyLiked;
      widget.product.totalLikes += previouslyLiked ? -1 : 1;
    });

    final success = await LikeService.toggleLike(
      userId: _userId!,
      productId: widget.product.id,
      currentlyLiked: previouslyLiked,
    );

    if (!success && mounted) {
      setState(() {
        widget.product.isLiked = previouslyLiked;
        widget.product.totalLikes += previouslyLiked ? 1 : -1;
      });
      SiporaTheme.showSnackBar(
        context,
        'Failed to update like status. Please try again.',
        isError: true,
      );
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.r(16)),
        ),
        title: Text(
          'Login Required',
          style: TextStyle(fontSize: context.sp(16)),
        ),
        content: Text(
          'Please login to like products.',
          style: TextStyle(fontSize: context.sp(14)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(fontSize: context.sp(14))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SiporaTheme.greenDark,
            ),
            child: Text('Login', style: TextStyle(fontSize: context.sp(14))),
          ),
        ],
      ),
    );
  }

  void _increment() {
    setState(() {
      _quantity++;
      CartService.updateQuantity(widget.product.productName, _quantity);
    });
    widget.onCartUpdated?.call();
  }

  void _decrement() {
    setState(() {
      if (_quantity > 0) {
        _quantity--;
        CartService.updateQuantity(widget.product.productName, _quantity);
      }
    });
    widget.onCartUpdated?.call();
  }

  void _goToPreviousImage() {
    final totalImages = widget.product.allImages.length;
    if (totalImages <= 1) return;

    if (_currentImageIndex == 0) {
      _pageController.animateToPage(
        totalImages - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNextImage() {
    final totalImages = widget.product.allImages.length;
    if (totalImages <= 1) return;

    if (_currentImageIndex == totalImages - 1) {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _addToCart() {
    if (_quantity == 0) {
      setState(() {
        _quantity = 1;
      });
    }

    CartHelperService.addProductToCart(
      productId: widget.product.id,
      productName: widget.product.productName,
      imageUrl: widget.product.firstImage,
      weight: '${widget.product.weightKg}kg',
      price: widget.product.total,
      mrp: widget.product.total,
      discount: '',
      isFreeCupEligible: widget.product.freeCupEligibility,
      itemType: widget.product.franchiseId.isEmpty ? 'warehouse' : 'product',
      quantity: _quantity,
      onCartUpdated: widget.onCartUpdated,
      onSuccess: () {
        SiporaTheme.showSnackBar(
          context,
          '${widget.product.productName} added to cart',
          isError: false,
        );
      },
    );
  }

  void _navigateToCart() {
    if (CartService.isNotEmpty) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const ProductsCart()));
    } else {
      SiporaTheme.showSnackBar(
        context,
        'Your cart is empty. Add some products first!',
        isError: true,
      );
    }
  }

  Widget _buildImageItem(String imageUrl, int index) {
    final isTablet = context.isTablet;
    final imageHeight = isTablet ? context.h(400) : context.h(280);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SiporaTheme.greenBg,
            SiporaTheme.greenBg.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: ImageUtils.networkImage(
        url: imageUrl,
        width: double.infinity,
        height: imageHeight,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildThumbnailImage(String imageUrl) {
    final isTablet = context.isTablet;
    final thumbnailSize = isTablet ? context.w(60) : context.w(44);

    return ClipRRect(
      borderRadius: BorderRadius.circular(context.r(4)),
      child: ImageUtils.networkImage(
        url: imageUrl,
        width: thumbnailSize,
        height: thumbnailSize,
        fit: BoxFit.cover,
        borderRadius: 4,
      ),
    );
  }

  Widget _buildFreeCupLabel() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(12),
        vertical: context.h(6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final totalImages = widget.product.allImages.length;
    final isTablet = context.isTablet;
    final imageHeight = isTablet ? context.h(400) : context.h(280);
    final thumbnailSize = isTablet ? context.w(60) : context.w(44);
    final arrowSize = isTablet ? context.w(44) : context.w(36);
    final arrowIconSize = isTablet ? context.w(28) : context.w(24);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [theme.cream, theme.white],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(context.r(28)),
                topRight: Radius.circular(context.r(28)),
              ),
              boxShadow: [
                BoxShadow(
                  color: SiporaTheme.shadowLight,
                  blurRadius: context.r(30),
                  offset: Offset(0, -4.h),
                ),
              ],
            ),
            child: Column(
              children: [
                // Handle Bar
                Container(
                  margin: EdgeInsets.only(top: context.h(12)),
                  width: context.w(50),
                  height: context.h(5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [SiporaTheme.greenDark, SiporaTheme.greenPill],
                    ),
                    borderRadius: BorderRadius.circular(context.r(3)),
                  ),
                ),

                // Header with Free Cup Label
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.w(16),
                    context.h(16),
                    context.w(16),
                    context.h(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Free Cup Eligibility Label - Left side
                      if (widget.product.freeCupEligibility)
                        _buildFreeCupLabel()
                      else
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.w(18),
                            vertical: context.h(12),
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                SiporaTheme.greenDark.withValues(alpha: 0.1),
                                SiporaTheme.greenLight.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(context.r(20)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: isTablet ? context.w(22) : context.w(18),
                                color: SiporaTheme.greenDark,
                              ),
                              SizedBox(width: context.w(8)),
                              Text(
                                'Details',
                                style: TextStyle(
                                  fontSize: isTablet
                                      ? context.sp(14)
                                      : context.sp(13),
                                  fontWeight: FontWeight.w600,
                                  color: SiporaTheme.greenDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Close Button - Right side
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: EdgeInsets.all(context.w(8)),
                          decoration: BoxDecoration(
                            color: theme.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: SiporaTheme.shadowLight,
                                blurRadius: context.r(8),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: theme.textMuted,
                            size: isTablet ? context.w(26) : context.w(22),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: context.w(16),
                      right: context.w(16),
                      bottom: context.w(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Images
                        Container(
                          margin: EdgeInsets.only(top: context.h(8)),
                          height:
                              imageHeight +
                              (totalImages > 1 ? context.h(70) : 0),
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    context.r(20),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: SiporaTheme.shadowLight,
                                      blurRadius: context.r(20),
                                      offset: Offset(0, 8.h),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    context.r(20),
                                  ),
                                  child: totalImages == 0
                                      ? ImageUtils.assetImage(
                                          path:
                                              '/assets/images/sipora_logo.png',
                                          width: double.infinity,
                                          height: imageHeight,
                                        )
                                      : totalImages == 1
                                      ? _buildImageItem(
                                          widget.product.allImages[0],
                                          0,
                                        )
                                      : PageView.builder(
                                          controller: _pageController,
                                          onPageChanged: (index) {
                                            setState(() {
                                              _currentImageIndex = index;
                                            });
                                          },
                                          itemCount: totalImages,
                                          itemBuilder: (context, index) {
                                            return _buildImageItem(
                                              widget.product.allImages[index],
                                              index,
                                            );
                                          },
                                        ),
                                ),
                              ),
                              if (totalImages > 1) ...[
                                Positioned(
                                  left: context.w(8),
                                  top: 0,
                                  bottom: context.h(70),
                                  child: Center(
                                    child: GestureDetector(
                                      onTap: _goToPreviousImage,
                                      child: Container(
                                        width: arrowSize,
                                        height: arrowSize,
                                        decoration: BoxDecoration(
                                          color: theme.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.chevron_left_rounded,
                                          color: theme.textDark,
                                          size: arrowIconSize,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: context.w(8),
                                  top: 0,
                                  bottom: context.h(70),
                                  child: Center(
                                    child: GestureDetector(
                                      onTap: _goToNextImage,
                                      child: Container(
                                        width: arrowSize,
                                        height: arrowSize,
                                        decoration: BoxDecoration(
                                          color: theme.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.chevron_right_rounded,
                                          color: theme.textDark,
                                          size: arrowIconSize,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: context.h(78),
                                  right: context.w(16),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: context.w(6),
                                      vertical: context.h(2),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.6,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        context.r(8),
                                      ),
                                    ),
                                    child: Text(
                                      '${_currentImageIndex + 1}/$totalImages',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: context.sp(9),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              if (totalImages > 1)
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: thumbnailSize + context.h(16),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: context.w(8),
                                    ),
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: totalImages,
                                      itemBuilder: (context, index) {
                                        return GestureDetector(
                                          onTap: () {
                                            _pageController.animateToPage(
                                              index,
                                              duration: const Duration(
                                                milliseconds: 300,
                                              ),
                                              curve: Curves.easeInOut,
                                            );
                                          },
                                          child: Container(
                                            margin: EdgeInsets.symmetric(
                                              horizontal: context.w(4),
                                            ),
                                            width: thumbnailSize,
                                            height: thumbnailSize,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    context.r(6),
                                                  ),
                                              border: Border.all(
                                                color:
                                                    _currentImageIndex == index
                                                    ? SiporaTheme.greenDark
                                                    : theme.border,
                                                width:
                                                    _currentImageIndex == index
                                                    ? 2.w
                                                    : 1.w,
                                              ),
                                            ),
                                            child: _buildThumbnailImage(
                                              widget.product.allImages[index],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              // Free Cup Eligibility Badge on Image - Top Left
                              if (widget.product.freeCupEligibility)
                                Positioned(
                                  top: context.h(16),
                                  left: context.w(16),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: context.w(12),
                                      vertical: context.h(8),
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          SiporaTheme.gold,
                                          SiporaTheme.greenDark,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        context.r(20),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.2,
                                          ),
                                          blurRadius: context.r(8),
                                          offset: Offset(0, 2.h),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.local_cafe_rounded,
                                          color: Colors.white,
                                          size: isTablet
                                              ? context.w(16)
                                              : context.w(12),
                                        ),
                                        SizedBox(width: context.w(6)),
                                        Text(
                                          'Free Cup Eligible',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isTablet
                                                ? context.sp(12)
                                                : context.sp(10),
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              // Category Badge - Top Right
                              Positioned(
                                right: context.w(16),
                                top: context.h(16),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.w(10),
                                    vertical: context.h(5),
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(
                                      context.r(30),
                                    ),
                                  ),
                                  child: Text(
                                    widget.product.category,
                                    style: TextStyle(
                                      color: SiporaTheme.greenDark,
                                      fontSize: isTablet
                                          ? context.sp(13)
                                          : context.sp(12),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: context.h(16)),

                        // Product Name
                        Text(
                          widget.product.productName,
                          style: TextStyle(
                            fontSize: isTablet
                                ? context.sp(22)
                                : context.sp(18),
                            fontWeight: FontWeight.w700,
                            color: theme.textDark,
                          ),
                        ),

                        SizedBox(height: context.h(16)),

                        // PRICE SECTION
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        widget.product.formattedPrice,
                                        style: TextStyle(
                                          fontSize: isTablet
                                              ? context.sp(24)
                                              : context.sp(20),
                                          fontWeight: FontWeight.w800,
                                          color: theme.textDark,
                                        ),
                                      ),
                                      if (widget.product.hasDiscount) ...[
                                        SizedBox(width: context.w(10)),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: context.w(8),
                                            vertical: context.h(4),
                                          ),
                                          decoration: BoxDecoration(
                                            color: SiporaTheme.greenDark
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              context.r(6),
                                            ),
                                          ),
                                          child: Text(
                                            '${widget.product.discountPercentage} OFF',
                                            style: TextStyle(
                                              fontSize: isTablet
                                                  ? context.sp(13)
                                                  : context.sp(12),
                                              fontWeight: FontWeight.w700,
                                              color: SiporaTheme.greenDark,
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

                        SizedBox(height: context.h(16)),

                        // RATING & LIKE SECTION
                        if (_isLoadingRating)
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: context.h(8),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: context.w(20),
                                  height: context.w(20),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.w,
                                    color: SiporaTheme.greenDark,
                                  ),
                                ),
                                SizedBox(width: context.w(12)),
                                Text(
                                  'Loading ratings...',
                                  style: TextStyle(
                                    fontSize: context.sp(14),
                                    color: theme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Overall rating
                              Row(
                                children: [
                                  RatingStars(
                                    rating: widget.product.averageRating,
                                    size: context.w(16),
                                  ),
                                  SizedBox(width: context.w(8)),
                                  Text(
                                    '${widget.product.averageRating.toStringAsFixed(1)} (${widget.product.totalRatings} ratings)',
                                    style: TextStyle(
                                      fontSize: isTablet
                                          ? context.sp(14)
                                          : context.sp(13),
                                      color: theme.textMuted,
                                    ),
                                  ),
                                ],
                              ),

                              // Like button
                              if (_userId != null && _userId!.isNotEmpty)
                                GestureDetector(
                                  onTap: _toggleLike,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        padding: EdgeInsets.all(context.w(2)),
                                        decoration: BoxDecoration(
                                          color: widget.product.isLiked
                                              ? Colors.red.withValues(
                                                  alpha: 0.1,
                                                )
                                              : theme.greenBg,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: widget.product.isLiked
                                                ? Colors.red.withValues(
                                                    alpha: 0.3,
                                                  )
                                                : theme.border,
                                            width: 0.5.w,
                                          ),
                                        ),
                                        child: Icon(
                                          widget.product.isLiked
                                              ? Icons.favorite_rounded
                                              : Icons.favorite_border_rounded,
                                          size: isTablet
                                              ? context.w(16)
                                              : context.w(14),
                                          color: widget.product.isLiked
                                              ? Colors.red
                                              : theme.textMuted,
                                        ),
                                      ),
                                      SizedBox(height: context.h(2)),
                                      Text(
                                        _formatLikeCount(
                                          widget.product.totalLikes,
                                        ),
                                        style: TextStyle(
                                          fontSize: isTablet
                                              ? context.sp(12)
                                              : context.sp(10),
                                          fontWeight: FontWeight.w600,
                                          color: widget.product.isLiked
                                              ? Colors.red
                                              : theme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                GestureDetector(
                                  onTap: _showLoginRequiredDialog,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(context.w(2)),
                                        decoration: BoxDecoration(
                                          color: theme.greenBg,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: theme.border,
                                            width: 0.5.w,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.favorite_border_rounded,
                                          size: isTablet
                                              ? context.w(16)
                                              : context.w(14),
                                          color: theme.textMuted,
                                        ),
                                      ),
                                      SizedBox(height: context.h(2)),
                                      Text(
                                        _formatLikeCount(
                                          widget.product.totalLikes,
                                        ),
                                        style: TextStyle(
                                          fontSize: isTablet
                                              ? context.sp(12)
                                              : context.sp(10),
                                          color: theme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),

                        SizedBox(height: context.h(20)),

                        // Description
                        Container(
                          padding: EdgeInsets.all(context.w(16)),
                          decoration: BoxDecoration(
                            color: theme.white,
                            borderRadius: BorderRadius.circular(context.r(12)),
                            border: Border.all(color: theme.border, width: 1.w),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Description',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: isTablet
                                      ? context.sp(16)
                                      : context.sp(14),
                                  color: theme.textDark,
                                ),
                              ),
                              SizedBox(height: context.h(8)),
                              Text(
                                widget.product.longDescription.isNotEmpty
                                    ? widget.product.longDescription
                                    : widget.product.shortDescription,
                                style: TextStyle(
                                  fontSize: isTablet
                                      ? context.sp(14)
                                      : context.sp(13),
                                  color: theme.textMuted,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: context.h(20)),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Bar
                SafeArea(
                  top: false,
                  child: Container(
                    padding: EdgeInsets.all(context.w(16)),
                    decoration: BoxDecoration(
                      color: theme.white,
                      boxShadow: [
                        BoxShadow(
                          color: SiporaTheme.shadowLight,
                          blurRadius: context.r(20),
                          offset: Offset(0, -4.h),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _navigateToCart,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: context.h(12),
                              ),
                              decoration: BoxDecoration(
                                color: CartService.isNotEmpty
                                    ? theme.white
                                    : theme.cream.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(
                                  context.r(30),
                                ),
                                border: Border.all(
                                  color: CartService.isNotEmpty
                                      ? SiporaTheme.greenDark.withValues(
                                          alpha: 0.3,
                                        )
                                      : theme.textMuted.withValues(alpha: 0.2),
                                  width: 1.w,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_cart_outlined,
                                    size: isTablet
                                        ? context.w(24)
                                        : context.w(20),
                                    color: CartService.isNotEmpty
                                        ? SiporaTheme.greenDark
                                        : theme.textMuted,
                                  ),
                                  SizedBox(width: context.w(8)),
                                  Text(
                                    CartService.isNotEmpty
                                        ? 'Go to Cart'
                                        : 'Add Products',
                                    style: TextStyle(
                                      fontSize: isTablet
                                          ? context.sp(15)
                                          : context.sp(14),
                                      color: CartService.isNotEmpty
                                          ? SiporaTheme.greenDark
                                          : theme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: context.w(12)),
                        Expanded(
                          child: _quantity == 0
                              ? GestureDetector(
                                  onTap: _addToCart,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: context.h(12),
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          SiporaTheme.greenDark,
                                          SiporaTheme.greenMid,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        context.r(30),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Add to Cart',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: isTablet
                                              ? context.sp(16)
                                              : context.sp(14),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : _buildPremiumQuantitySelector(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumQuantitySelector() {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;
    final selectorHeight = isTablet ? context.h(48) : context.h(42);
    final buttonWidth = isTablet ? context.w(50) : context.w(40);
    final iconSize = isTablet ? context.w(20) : context.w(18);
    final fontSize = isTablet ? context.sp(16) : context.sp(14);

    return Container(
      height: selectorHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SiporaTheme.greenBg,
            SiporaTheme.greenBg.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(context.r(30)),
        border: Border.all(
          color: SiporaTheme.greenDark.withValues(alpha: 0.2),
          width: 1.w,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _decrement,
            child: Container(
              width: buttonWidth,
              height: selectorHeight,
              decoration: BoxDecoration(
                gradient: _quantity == 1
                    ? null
                    : const LinearGradient(
                        colors: [SiporaTheme.greenDark, SiporaTheme.greenMid],
                      ),
                color: _quantity == 1 ? SiporaTheme.greenBg : null,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(context.r(30)),
                ),
              ),
              child: Icon(
                Icons.remove_rounded,
                color: _quantity == 1 ? SiporaTheme.greenDark : Colors.white,
                size: iconSize,
              ),
            ),
          ),
          Text(
            '$_quantity',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: theme.textDark,
            ),
          ),
          GestureDetector(
            onTap: _increment,
            child: Container(
              width: buttonWidth,
              height: selectorHeight,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [SiporaTheme.greenDark, SiporaTheme.greenMid],
                ),
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(30),
                ),
              ),
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: iconSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLikeCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
