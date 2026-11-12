import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:sipora/widgets/shop_products_page.dart';
import '../../theme/sipora_theme.dart';
import '../../services/shop_service.dart';
import '../../map/map_page.dart';
import '../../models/product.dart';
import '../../utils/screen_utils.dart';

class ShopsSection extends StatelessWidget {
  final VoidCallback onRefresh;
  final bool dataLoaded;

  const ShopsSection({
    super.key,
    required this.onRefresh,
    this.dataLoaded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final allShops = ShopService.getAllShops();
    final isTablet = context.isTablet;
    final double shopCardWidth = isTablet ? context.w(160) : context.w(130);

    // Check if user has location
    final hasLocation = ShopService.hasUserLocation();

    // Filter shops under 20KM only if user has location
    final List<Shop> filteredShops = allShops.where((shop) {
      // If no location, show all shops
      if (!hasLocation) return true;

      // Get distance in meters
      final distance = ShopService.calculateDistanceToShop(shop);

      // If distance is null, include the shop
      if (distance == null) return true;

      // Only include shops under 20KM (20,000 meters)
      return distance <= 20000.0;
    }).toList();

    // Sort shops by distance (nearest first) if user has location
    if (hasLocation) {
      filteredShops.sort((a, b) {
        final distanceA = ShopService.calculateDistanceToShop(a);
        final distanceB = ShopService.calculateDistanceToShop(b);

        if (distanceA == null && distanceB == null) return 0;
        if (distanceA == null) return 1;
        if (distanceB == null) return -1;

        return distanceA.compareTo(distanceB);
      });
    }

    if (filteredShops.isEmpty) {
      return _buildEmptyState(context, hasLocation);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.w(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hasLocation ? 'Shops Near You' : 'All Shops',
                style: TextStyle(
                  fontSize: isTablet ? context.sp(22) : context.sp(18),
                  fontWeight: FontWeight.w800,
                  color: theme.textDark,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MapPage()),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: theme.gold),
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: isTablet ? context.sp(14) : context.sp(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.h(8)),
        // INCREASED HEIGHT from 140 to 180 on phones, and 170 to 210 on tablets
        SizedBox(
          height: isTablet ? context.h(210) : context.h(180),
          child: ListView.builder(
            key: ValueKey('shops_${filteredShops.length}_$dataLoaded'),
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: context.w(16)),
            itemCount: filteredShops.length,
            itemBuilder: (context, index) {
              final shop = filteredShops[index];
              return _ShopCard(
                key: ValueKey('shop_card_${shop.id}'),
                shop: shop,
                shopCardWidth: shopCardWidth,
                isTablet: isTablet,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool hasLocation) {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.w(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hasLocation ? 'Shops Near You' : 'All Shops',
                style: TextStyle(
                  fontSize: isTablet ? context.sp(22) : context.sp(18),
                  fontWeight: FontWeight.w800,
                  color: theme.textDark,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MapPage()),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: theme.gold),
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: isTablet ? context.sp(14) : context.sp(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.h(16)),
        Container(
          margin: EdgeInsets.symmetric(horizontal: context.w(16)),
          padding: EdgeInsets.all(context.w(16)),
          decoration: BoxDecoration(
            color: theme.cream,
            borderRadius: BorderRadius.circular(context.r(12)),
            border: Border.all(color: theme.border, width: 0.5.w),
          ),
          child: Row(
            children: [
              Icon(
                hasLocation
                    ? Icons.storefront_outlined
                    : Icons.location_off_rounded,
                color: theme.textMuted,
                size: context.w(32),
              ),
              SizedBox(width: context.w(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasLocation ? 'No Shops Within 20KM' : 'Enable Location',
                      style: TextStyle(
                        fontSize: isTablet ? context.sp(16) : context.sp(14),
                        fontWeight: FontWeight.w600,
                        color: theme.textDark,
                      ),
                    ),
                    SizedBox(height: context.h(4)),
                    Text(
                      hasLocation
                          ? 'There are no shops available within 20KM of your location. Try expanding your search.'
                          : 'Please enable location to find nearby shops.',
                      style: TextStyle(
                        fontSize: isTablet ? context.sp(13) : context.sp(12),
                        color: theme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShopCard extends StatelessWidget {
  final Shop shop;
  final double shopCardWidth;
  final bool isTablet;

  const _ShopCard({
    super.key,
    required this.shop,
    required this.shopCardWidth,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final isOpen = shop.status == 'Open';
    // Slightly reduced circle size to fit better
    final double circleSize = isTablet ? context.w(75) : context.w(60);
    final double iconSizeVal = isTablet ? context.w(40) : context.w(32);
    final double infoIconSize = isTablet ? context.w(14) : context.w(12);
    final double infoFontSize = isTablet ? context.sp(10) : context.sp(9);

    return GestureDetector(
      onTap: () => _showShopProducts(context, shop),
      child: Container(
        width: shopCardWidth,
        margin: EdgeInsets.only(right: context.w(8)),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Added to prevent overflow
          children: [
            // Shop Avatar or Store Icon - Clean, no badges
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOpen ? theme.goldBg : theme.cream,
                border: Border.all(
                  color: isOpen
                      ? theme.gold.withValues(alpha: 0.3)
                      : theme.border,
                  width: 1.5.w,
                ),
              ),
              child: shop.avatarIcons != null && shop.avatarIcons!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        shop.avatarIcons!,
                        fit: BoxFit.cover,
                        width: circleSize,
                        height: circleSize,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildAvatarFallback(
                            context,
                            shop,
                            theme,
                            isOpen,
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: context.w(24),
                              height: context.w(24),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isOpen ? theme.gold : theme.textMuted,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.store_rounded,
                      color: isOpen ? theme.gold : theme.textMuted,
                      size: iconSizeVal,
                    ),
            ),
            SizedBox(height: context.h(4)), // Reduced from 6 to 4
            // Shop Name
            Text(
              shop.name,
              style: TextStyle(
                fontSize: isTablet ? context.sp(16) : context.sp(13),
                fontWeight: FontWeight.w700,
                color: theme.textDark,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: context.h(2)), // Reduced from 3 to 2
            // Distance and Time Info
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: infoIconSize,
                        color: theme.gold,
                      ),
                      SizedBox(width: context.w(2)),
                      Text(
                        ShopService.getDistanceString(shop),
                        style: TextStyle(
                          fontSize: infoFontSize,
                          fontWeight: FontWeight.w500,
                          color: theme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: context.w(4)),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: infoIconSize,
                        color: theme.gold,
                      ),
                      SizedBox(width: context.w(2)),
                      Text(
                        ShopService.getTravelTimeString(shop),
                        style: TextStyle(
                          fontSize: infoFontSize,
                          fontWeight: FontWeight.w500,
                          color: theme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Avatar fallback with shop initials
  Widget _buildAvatarFallback(
    BuildContext context,
    Shop shop,
    SiporaThemeExtension theme,
    bool isOpen,
  ) {
    final isTablet = context.isTablet;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOpen
              ? [theme.gold, theme.greenMid]
              : [theme.textMuted, theme.border],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          shop.initials,
          style: TextStyle(
            fontSize: isTablet ? context.sp(24) : context.sp(20),
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _showShopProducts(BuildContext context, Shop shop) async {
    // ✅ Get theme inside the method
    final theme = context.siporaTheme;

    try {
      final productsData = await ShopService.fetchProductsByFranchise(shop.id);

      // ✅ Check if products fetch was successful
      if (productsData['success'] == false) {
        if (context.mounted) {
          SiporaTheme.showSnackBar(
            context,
            productsData['error'] ?? 'Failed to load products',
            isError: true,
          );
        }
        return;
      }

      // ✅ Check if there are any products
      final List<dynamic> productsList =
          productsData['product_information'] ?? [];

      if (productsList.isEmpty) {
        // ✅ Show "No products available" message
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (dialogContext) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.r(16)),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: SiporaTheme.gold,
                    size: context.w(28),
                  ),
                  SizedBox(width: context.w(12)),
                  Text(
                    'No Products Available',
                    style: TextStyle(
                      fontSize: context.sp(18),
                      fontWeight: FontWeight.w700,
                      color: theme.textDark,
                    ),
                  ),
                ],
              ),
              content: Text(
                'This shop currently has no products added. Please explore other shops.',
                style: TextStyle(
                  fontSize: context.sp(14),
                  color: theme.textMuted,
                  height: 1.4,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      fontSize: context.sp(14),
                      fontWeight: FontWeight.w600,
                      color: SiporaTheme.gold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    // Navigate to map page to explore other shops
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MapPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SiporaTheme.greenDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.r(10)),
                    ),
                  ),
                  child: const Text('Explore Other Shops'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // ✅ Process products
      final Map<String, List<Product>> productsByCategory = {};

      for (var productData in productsList) {
        try {
          final product = Product.fromApiMap(productData);
          final category = product.subcategory.isNotEmpty
              ? product.subcategory
              : product.category;
          productsByCategory.putIfAbsent(category, () => []).add(product);
        } catch (e) {
          // debugPrint('Error parsing product in shops_section: $e');
        }
      }

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShopProductsPage(
              shopName: shop.name,
              shopId: shop.id,
              productsByCategory: productsByCategory,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        SiporaTheme.showSnackBar(
          context,
          'Error loading products: $e',
          isError: true,
        );
      }
    }
  }
}
