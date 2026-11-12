import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import '../../theme/sipora_theme.dart';
import '../../models/product.dart';
import '../../utils/image_utils.dart';
import '../../utils/screen_utils.dart';

/// A reusable infinite carousel widget that supports both hero banner and circular card modes
enum CarouselType {
  hero, // Full-width banner with overlay text
  card, // Square/Rectangular/Circular card without overlay
}

class InfiniteCarousel extends StatefulWidget {
  final List<Product> products;
  final CarouselType type;
  final double? height;
  final double? width;
  final double borderRadius;
  final Duration autoSlideDuration;
  final Duration animationDuration;
  final bool showDots;
  final bool showCounter;
  final bool showOverlay;
  final VoidCallback? onTap;

  const InfiniteCarousel({
    super.key,
    required this.products,
    this.type = CarouselType.hero,
    this.height,
    this.width,
    this.borderRadius = 20,
    this.autoSlideDuration = const Duration(seconds: 3),
    this.animationDuration = const Duration(milliseconds: 800),
    this.showDots = true,
    this.showCounter = false,
    this.showOverlay = true,
    this.onTap,
  });

  @override
  State<InfiniteCarousel> createState() => _InfiniteCarouselState();
}

class _InfiniteCarouselState extends State<InfiniteCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;
  int _totalItems = 0;

  @override
  void initState() {
    super.initState();
    _totalItems = widget.products.length;

    if (_totalItems > 0) {
      if (_totalItems == 1) {
        // For single item, use a simple page controller
        _pageController = PageController(initialPage: 0);
        _currentPage = 0;
        _startAutoSlideForSingleItem();
      } else {
        // For multiple items, use infinite scrolling
        _pageController = PageController(initialPage: 1000);
        _currentPage = 1000;
        _startAutoSlide();
      }
    }
  }

  void _startAutoSlide() {
    _timer?.cancel();
    if (_totalItems > 1) {
      _timer = Timer.periodic(widget.autoSlideDuration, (timer) {
        if (mounted && widget.products.isNotEmpty && _totalItems > 1) {
          final nextPage = _currentPage + 1;
          _pageController.animateToPage(
            nextPage,
            duration: widget.animationDuration,
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _startAutoSlideForSingleItem() {
    _timer?.cancel();
    if (_totalItems == 1) {
      _timer = Timer.periodic(widget.autoSlideDuration, (timer) {
        if (mounted && widget.products.isNotEmpty && _totalItems == 1) {
          // For single item, just go to page 0 again with a bounce effect
          _pageController.animateToPage(
            0,
            duration: widget.animationDuration,
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_totalItems == 0) {
      return _buildEmptyState();
    }

    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius.r),
        boxShadow: widget.type == CarouselType.hero
            ? [
                BoxShadow(
                  color: SiporaTheme.shadowLight,
                  blurRadius: 20.r,
                  offset: Offset(0, 8.h),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius.r),
        child: _totalItems == 1
            ? _buildSingleItem()
            : PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  // Safe index access
                  final actualIndex = index % _totalItems;
                  final product = widget.products[actualIndex];

                  return GestureDetector(
                    onTap: () => widget.onTap?.call(),
                    child: widget.type == CarouselType.hero
                        ? _buildHeroItem(product, actualIndex)
                        : _buildCardItem(product),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildSingleItem() {
    final product = widget.products[0];

    return GestureDetector(
      onTap: () => widget.onTap?.call(),
      child: widget.type == CarouselType.hero
          ? _buildHeroItem(product, 0)
          : _buildCardItem(product),
    );
  }

  Widget _buildEmptyState() {
    final isTablet = context.isTablet;

    return Container(
      height: widget.height ?? context.h(200),
      width: widget.width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SiporaTheme.greenBg,
            SiporaTheme.greenBg.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(widget.borderRadius.r),
      ),
      child: Center(
        child: ImageUtils.assetImage(
          path: '/assets/images/sipora_logo.png',
          width: isTablet ? context.w(80) : context.w(60),
          height: isTablet ? context.w(80) : context.w(60),
        ),
      ),
    );
  }

  Widget _buildHeroItem(Product product, int actualIndex) {
    final isTablet = context.isTablet;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Image
        ImageUtils.networkImage(
          url: product.image,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        ),
        // Dark Overlay for better text visibility
        if (widget.showOverlay)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
        // Content
        Padding(
          padding: EdgeInsets.all(context.w(20)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showCounter && _totalItems > 1)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(12),
                    vertical: context.h(4),
                  ),
                  decoration: BoxDecoration(
                    color: SiporaTheme.greenPill,
                    borderRadius: BorderRadius.circular(context.r(20)),
                  ),
                  child: Text(
                    '${actualIndex + 1}/$_totalItems',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? context.sp(14) : context.sp(12),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (widget.showCounter && _totalItems > 1)
                SizedBox(height: context.h(12)),
              Text(
                product.name,
                style: TextStyle(
                  fontSize: isTablet ? context.sp(28) : context.sp(24),
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: context.h(8)),
              Text(
                product.brand,
                style: TextStyle(
                  fontSize: isTablet ? context.sp(16) : context.sp(14),
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              SizedBox(height: context.h(12)),
              Row(
                children: [
                  Text(
                    '₹${product.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: isTablet ? context.sp(20) : context.sp(18),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (product.mrp > product.price) ...[
                    SizedBox(width: context.w(8)),
                    Text(
                      '₹${product.mrp.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: isTablet ? context.sp(16) : context.sp(14),
                        color: Colors.white.withValues(alpha: 0.6),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    SizedBox(width: context.w(8)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(8),
                        vertical: context.h(2),
                      ),
                      decoration: BoxDecoration(
                        color: SiporaTheme.greenPill,
                        borderRadius: BorderRadius.circular(context.r(12)),
                      ),
                      child: Text(
                        '${((product.mrp - product.price) / product.mrp * 100).round()}% OFF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? context.sp(12) : context.sp(10),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        // Dots Indicator - Only show if there's more than 1 item and showDots is true
        if (widget.showDots && _totalItems > 1)
          Positioned(
            bottom: context.h(16),
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _totalItems > 8 ? 8 : _totalItems,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: context.w(4)),
                  width: (_currentPage % _totalItems) == index
                      ? context.w(24)
                      : context.w(8),
                  height: context.h(8),
                  decoration: BoxDecoration(
                    color: (_currentPage % _totalItems) == index
                        ? SiporaTheme.greenPill
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(context.r(4)),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCardItem(Product product) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius.r),
      child: ImageUtils.networkImage(
        url: product.image,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}
