import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import '../../Setting_page/setting_page.dart';
import '../../Shop_page/shop_page.dart';
import '../../Cart_page/products_cart.dart';
import '../../Search_page/search_page.dart';
import '../../Home_page/home_page.dart';
import '../../services/cart_service.dart';
import '../../theme/sipora_theme.dart';

class BottomNavTextRow extends StatefulWidget {
  final String currentPage;

  const BottomNavTextRow({super.key, this.currentPage = 'home'});

  @override
  State<BottomNavTextRow> createState() => BottomNavTextRowState();
}

class BottomNavTextRowState extends State<BottomNavTextRow> {
  late int _selectedIndex;

  int get _cartItemCount =>
      CartService.items.fold(0, (sum, item) => sum + item.quantity);

  int _pageToIndex(String page) {
    if (page == 'setting') return 4;
    if (page == 'shop') return 2;
    if (page == 'cart') return 3;
    if (page == 'search') return 1;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = _pageToIndex(widget.currentPage);
    CartService.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    CartService.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(BottomNavTextRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage) {
      setState(() => _selectedIndex = _pageToIndex(widget.currentPage));
    }
  }

  void _onItemTapped(int index) {
    // If already on this page, do nothing
    if (_selectedIndex == index && _pageToIndex(widget.currentPage) == index) {
      return;
    }

    // Update the selected index immediately
    setState(() {
      _selectedIndex = index;
    });

    Widget page;
    String pageName;
    switch (index) {
      case 0:
        page = const HomePage();
        pageName = 'home';
        break;
      case 1:
        page = const SearchPage();
        pageName = 'search';
        break;
      case 2:
        page = const ShopPage();
        pageName = 'shop';
        break;
      case 3:
        page = const ProductsCart();
        pageName = 'cart';
        break;
      case 4:
        page = const SettingPage();
        pageName = 'setting';
        break;
      default:
        return;
    }

    // ✅ FIXED: Use push and pass the current page name to the new page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => page,
        settings: RouteSettings(
          name: pageName,
          arguments: {'currentPage': pageName},
        ),
      ),
    ).then((_) {
      // When coming back to this page, update the selected index
      // based on the current page (which is the page we're returning to)
      if (mounted) {
        setState(() {
          _selectedIndex = _pageToIndex(widget.currentPage);
        });
      }
    });
  }

  // ─── Safe responsive value getters with protection ─────────────────────

  double _safeW(double value) {
    final result = context.w(value);
    return result > 0 ? result : value; // Fallback to raw value if negative
  }

  double _safeH(double value) {
    final result = context.h(value);
    return result > 0 ? result : value;
  }

  double _safeSp(double value) {
    final result = context.sp(value);
    return result > 0 ? result : value;
  }

  double _getIconSize() => _safeW(24);
  double _getFontSize() => _safeSp(10);
  double _getBadgeSize() => _safeW(18);
  double _getBadgeFontSize() => _safeSp(9);
  double _getCircleSize() => _safeW(56);
  double _getOrderNowIconSize() => _safeW(18);
  double _getOrderNowFontSize() => _safeSp(9);
  double _getBorderWidth() => _safeW(1.5);
  double _getBarHeight() => _safeH(60);
  double _getHorizontalPadding() => _safeW(12);
  double _getPillWidth() => _safeW(48);
  double _getPillHeight() => _safeH(30);
  double _getSpacerWidth() => _safeW(52);

  double _getPillLeftOffset(double totalWidth) {
    int logicalIndex;
    switch (_selectedIndex) {
      case 0:
        logicalIndex = 0;
        break;
      case 1:
        logicalIndex = 1;
        break;
      case 3:
        logicalIndex = 2;
        break;
      case 4:
        logicalIndex = 3;
        break;
      default:
        return 0;
    }

    final spacerWidth = _getSpacerWidth();
    final double availableWidth = totalWidth - spacerWidth;
    final double itemWidth = availableWidth / 4;

    final List<double> itemCenters = [
      itemWidth / 2,
      itemWidth + (itemWidth / 2),
      (itemWidth * 2) + spacerWidth + (itemWidth / 2),
      (itemWidth * 3) + spacerWidth + (itemWidth / 2),
    ];

    final double centerX = itemCenters[logicalIndex];
    final double pillWidth = _getPillWidth();
    double leftOffset = centerX - (pillWidth / 2);

    leftOffset = leftOffset.clamp(4.0, totalWidth - pillWidth - 4.0);
    return leftOffset;
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final bool isActive = _selectedIndex == index;
    final iconSize = _getIconSize();
    final fontSize = _getFontSize();

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            size: iconSize,
            color: isActive ? SiporaTheme.gold : Colors.white,
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              color: isActive ? SiporaTheme.gold : Colors.white,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem() {
    final bool isActive = _selectedIndex == 3;
    final iconSize = _getIconSize();
    final fontSize = _getFontSize();
    final badgeSize = _getBadgeSize();
    final badgeFontSize = _getBadgeFontSize();

    return GestureDetector(
      onTap: () => _onItemTapped(3),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                isActive ? Icons.shopping_cart : Icons.shopping_cart_outlined,
                size: iconSize,
                color: isActive ? SiporaTheme.gold : Colors.white,
              ),
              if (_cartItemCount > 0)
                Positioned(
                  right: -5.w,
                  top: -5.h,
                  child: Container(
                    padding: EdgeInsets.all(2.r),
                    decoration: BoxDecoration(
                      color: SiporaTheme.gold,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: SiporaTheme.greenDark,
                        width: 1.5.w,
                      ),
                    ),
                    constraints: BoxConstraints(
                      minWidth: badgeSize,
                      minHeight: badgeSize,
                    ),
                    child: Text(
                      _cartItemCount > 99 ? '99+' : '$_cartItemCount',
                      style: TextStyle(
                        color: SiporaTheme.greenDark,
                        fontSize: badgeFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Cart',
            style: TextStyle(
              fontSize: fontSize,
              color: isActive ? SiporaTheme.gold : Colors.white,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderNowButton() {
    final bool isActive = _selectedIndex == 2;
    final circleSize = _getCircleSize();
    final iconSize = _getOrderNowIconSize();
    final fontSize = _getOrderNowFontSize();
    final borderWidth = _getBorderWidth();

    return GestureDetector(
      onTap: () => _onItemTapped(2),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: circleSize,
        height: circleSize,
        decoration: BoxDecoration(
          color: SiporaTheme.greenDark,
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive
                ? SiporaTheme.gold
                : Colors.white.withValues(alpha: 0.5),
            width: isActive ? borderWidth + 0.5.w : borderWidth,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.coffee,
              size: iconSize,
              color: isActive ? SiporaTheme.gold : Colors.white,
            ),
            SizedBox(height: 3.h),
            Text(
              'Order Now',
              style: TextStyle(
                fontSize: fontSize,
                color: isActive ? SiporaTheme.gold : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final circleSize = _getCircleSize();
    final barHeight = _getBarHeight();
    final overflow = (circleSize - barHeight) / 2;
    final horizontalPadding = _getHorizontalPadding();

    // Ensure padding is never negative
    final safeBottomPadding = bottomPadding > 0 ? bottomPadding : 0.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding.clamp(0.0, double.infinity),
        overflow.clamp(0.0, double.infinity),
        horizontalPadding.clamp(0.0, double.infinity),
        (safeBottomPadding + 8.h).clamp(0.0, double.infinity),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double totalWidth = constraints.maxWidth;
          final pillWidth = _getPillWidth();
          final pillHeight = _getPillHeight();
          final spacerWidth = _getSpacerWidth();

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              if (_selectedIndex != 2)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  left: _getPillLeftOffset(totalWidth),
                  bottom: 0,
                  top: (barHeight - pillHeight) / 2,
                  child: Container(
                    width: pillWidth,
                    height: pillHeight,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                  ),
                ),
              Container(
                height: barHeight.clamp(40.0, double.infinity),
                decoration: BoxDecoration(
                  color: SiporaTheme.greenDark,
                  borderRadius: BorderRadius.circular(32.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                    _buildNavItem(
                      1,
                      Icons.search_outlined,
                      Icons.search,
                      'Search',
                    ),
                    SizedBox(width: spacerWidth.clamp(0.0, double.infinity)),
                    _buildCartItem(),
                    _buildNavItem(
                      4,
                      Icons.settings_outlined,
                      Icons.settings,
                      'Settings',
                    ),
                  ],
                ),
              ),
              Positioned(bottom: 0, child: _buildOrderNowButton()),
            ],
          );
        },
      ),
    );
  }
}
