import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sipora/Cart_page/services/cart_helper_service.dart';
import 'package:sipora/map/map_page.dart';
import 'package:provider/provider.dart';

// IMPORTANT: Fix imports - use explicit imports with 'as' to avoid conflicts
import 'widgets/app_header.dart';
import 'widgets/bottom_nav_text_row.dart';
import 'widgets/signature_section.dart' as signature;
import 'widgets/shops_section.dart';

import '../config/api_config.dart';
import '../providers/user_provider.dart';
import '../services/jwt_service.dart';

import '../theme/sipora_theme.dart';

import '../utils/memory_optimizer.dart';
import '../utils/memory_monitor.dart';
import '../utils/image_utils.dart';
import '../utils/screen_utils.dart';

import '../Shop_page/widgets/product_list_page.dart';
import '../Shop_page/widgets/infinite_carousel.dart';
import '../Shop_page/widgets/products_details_page.dart';

import '../models/product.dart';
import '../models/tagged_product.dart';
import '../models/recommended_product.dart';

import '../services/api_service.dart';
import '../services/shop_service.dart';
import '../services/discount_service.dart';
import '../services/storage_service.dart';
import '../services/cart_service.dart';

import '../Login_page/widgets/login.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  List<RecommendedProduct> recommendedProducts = [];
  List<Map<String, String>> signatureProducts = [];
  List<ProductTag> productTags = [];
  bool _isLoadingProducts = true;
  bool _isLoadingTags = true;
  String? _errorMessage;
  bool _isLoadingAllData = true;
  bool _dataLoaded = false;
  bool _isLoadingStarted = false;
  bool _isRefreshingAfterSettings = false;

  static bool _userHasDismissedLocationChange = false;

  Map<String, List<Product>> _productsByCategory = {};
  Map<String, List<Product>> _filteredProductsByCategory = {};
  final Map<String, String> _subcategoryToCategoryMap = {};

  bool _cupQuestLoading = false;

  // Session monitoring timer
  Timer? _sessionCheckTimer;
  bool _isSessionMonitoring = false;
  bool _isSessionValid = true;

  // Warehouse Products with Pagination
  List<Product> _warehouseProducts = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalWarehouseProducts = 0;
  bool _isLoadingWarehouseProducts = true;
  bool _isLoadingMoreWarehouseProducts = false;
  bool _hasMoreWarehouseProducts = true;
  static const int _warehousePageSize = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    CartService.addListener(_onCartChanged);

    ShopService.setOnSettingsClosed(() {
      _refreshAfterSettings();
    });

    MemoryOptimizer.limitImageCacheSize();
    MemoryMonitor.startMonitoring();
    MemoryMonitor.logMemoryEvent('HomePage initialized');

    // Start session monitoring
    _startSessionMonitoring();

    _loadAllData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    CartService.removeListener(_onCartChanged);
    MemoryMonitor.stopMonitoring();
    MemoryMonitor.logMemoryEvent('HomePage disposed');

    // Stop session monitoring
    _stopSessionMonitoring();

    super.dispose();
  }

  void _onCartChanged() {
    _fetchActiveDiscounts(force: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _checkLocationAfterResume();
      // Check session when app resumes
      _checkSessionAfterResume();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndReloadData();
      _refreshCupQuestIfNeeded();
    });
  }

  // ==================== Session Monitoring Methods ====================

  void _startSessionMonitoring() {
    if (_isSessionMonitoring) return;
    _isSessionMonitoring = true;

    debugPrint('🔄 Starting session monitoring on HomePage...');

    // Check immediately
    _checkSessionValidity();

    // Then check every 5 minutes
    _sessionCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (timer) => _checkSessionValidity(),
    );
  }

  void _stopSessionMonitoring() {
    _sessionCheckTimer?.cancel();
    _sessionCheckTimer = null;
    _isSessionMonitoring = false;
    debugPrint('⏹️ Session monitoring stopped on HomePage');
  }

  Future<void> _checkSessionValidity() async {
    try {
      // ✅ Get token directly from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('tea_app_token');

      debugPrint(
        '🔍 Checking token: ${token != null ? "Token exists" : "No token"}',
      );

      if (token == null || token.isEmpty) {
        // Guest users are allowed to browse. There is no session to validate.
        return;
      }

      // Check local token validity
      final isValid = await StorageService.isTokenValid();

      if (!isValid) {
        debugPrint('❌ Token invalid locally, redirecting to login');
        _handleSessionExpired();
        return;
      }

      // ✅ Only validate with backend if token is still valid locally
      try {
        final isBackendValid =
            await StorageService.validateSessionWithBackend();
        if (!isBackendValid) {
          debugPrint('❌ Session invalid on backend, redirecting to login');
          _handleSessionExpired();
          return;
        }
      } catch (e) {
        // ✅ If backend validation fails (network error), don't clear the token
        debugPrint('⚠️ Backend validation error: $e, keeping session valid');
        // Continue with local validation only
      }

      // Check if token is about to expire (within 1 day)
      final expiry = await StorageService.getTokenExpiry();
      if (expiry != null) {
        final nowUtc = DateTime.now().toUtc();
        final remaining = expiry.difference(nowUtc);
        final remainingDays = remaining.inDays;

        debugPrint(
          '⏱️ Session valid. Remaining: ${remaining.inDays} days, ${remaining.inHours % 24} hours',
        );

        if (remainingDays < 1 && remaining.inMilliseconds > 0) {
          _showSessionExpiryWarning(remaining);
        }

        if (remaining.inMilliseconds < 0) {
          debugPrint('❌ Session expired, redirecting to login');
          _handleSessionExpired();
        }
      }

      // Update session valid state
      if (!_isSessionValid) {
        setState(() {
          _isSessionValid = true;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Session check error: $e');
      // ✅ Don't clear token on error
    }
  }

  Future<void> _checkSessionAfterResume() async {
    debugPrint('🔄 Checking session after app resume...');
    await _checkSessionValidity();
  }

  Future<void> _handleSessionExpired() async {
    if (!_isSessionValid) return;
    _isSessionValid = false;

    debugPrint('🔄 Session expired; continuing in guest mode.');
    await StorageService.clearAuthData();
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.clearUser();
    } catch (e) {
      debugPrint('⚠️ Error clearing user provider: $e');
    }
    _stopSessionMonitoring();

    if (mounted) {
      setState(() => _isSessionValid = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your session expired. You can continue browsing as a guest.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSessionExpiryWarning(Duration remaining) {
    // Only show warning if not already shown recently
    final hoursRemaining = remaining.inHours;
    final message = hoursRemaining < 1
        ? 'Session expires in ${remaining.inMinutes} minutes. Please save your work.'
        : 'Session expires in $hoursRemaining hours. Please save your work.';

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade300),
              SizedBox(width: 12.w),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // ==================== Warehouse Products Methods ====================

  Future<void> _fetchWarehouseProducts({bool loadMore = false}) async {
    if (!ShopService.hasSelectedShop()) {
      setState(() {
        _isLoadingWarehouseProducts = false;
        _warehouseProducts = [];
      });
      return;
    }

    if (_isLoadingMoreWarehouseProducts) return;

    // If not loading more, reset
    if (!loadMore) {
      setState(() {
        _currentPage = 1;
        _warehouseProducts = [];
        _hasMoreWarehouseProducts = true;
        _isLoadingWarehouseProducts = true;
      });
    }

    if (!_hasMoreWarehouseProducts && loadMore) {
      setState(() => _isLoadingWarehouseProducts = false);
      return;
    }

    try {
      setState(() => _isLoadingMoreWarehouseProducts = true);

      ShopService.selectedShopId!;

      String? userId;
      final token = await SharedPreferences.getInstance().then(
        (prefs) => prefs.getString('tea_app_token'),
      );
      if (token != null) {
        userId = JwtService.extractUserId(token);
      }

      userId ??= await SharedPreferences.getInstance().then(
        (prefs) => prefs.getString('user_id'),
      );

      if (userId == null) {
        setState(() {
          _isLoadingWarehouseProducts = false;
          _isLoadingMoreWarehouseProducts = false;
        });
        return;
      }

      final url =
          '${ApiConfig.baseUrl}/api/product/fetch-by-warehouse-products';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'page': loadMore ? _currentPage + 1 : 1,
          'page_size': _warehousePageSize,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          final products = data['warehouse_products'] as List? ?? [];
          final pagination = data['pagination'] as Map<String, dynamic>?;

          if (pagination != null) {
            final totalRecords = pagination['total_records'] as int? ?? 0;
            final totalPages = pagination['total_pages'] as int? ?? 1;
            final currentPage = pagination['page'] as int? ?? 1;

            setState(() {
              _totalPages = totalPages;
              _totalWarehouseProducts = totalRecords;
              _currentPage = currentPage;
              _hasMoreWarehouseProducts = currentPage < totalPages;
            });
          } else {
            setState(() {
              _totalWarehouseProducts = products.length;
              _totalPages = 1;
              _currentPage = 1;
              _hasMoreWarehouseProducts = false;
            });
          }

          final List<Product> newProducts = [];
          for (var product in products) {
            final mappedProduct = _mapApiProductToProduct(
              product,
              isWarehouseProduct: true,
            );
            newProducts.add(mappedProduct);
          }

          setState(() {
            if (loadMore) {
              _warehouseProducts.addAll(newProducts);
            } else {
              _warehouseProducts = newProducts;
            }
            _isLoadingWarehouseProducts = false;
            _isLoadingMoreWarehouseProducts = false;
          });
        } else {
          setState(() {
            _isLoadingWarehouseProducts = false;
            _isLoadingMoreWarehouseProducts = false;
          });
        }
      } else {
        setState(() {
          _isLoadingWarehouseProducts = false;
          _isLoadingMoreWarehouseProducts = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching warehouse products: $e');
      setState(() {
        _isLoadingWarehouseProducts = false;
        _isLoadingMoreWarehouseProducts = false;
      });
    }
  }

  Future<void> _loadMoreWarehouseProducts() async {
    if (_hasMoreWarehouseProducts && !_isLoadingMoreWarehouseProducts) {
      await _fetchWarehouseProducts(loadMore: true);
    }
  }

  // ==================== Existing Methods ====================

  Future<void> _refreshCupQuestIfNeeded() async {
    if (ShopService.hasSelectedShop() && !_isLoadingAllData && mounted) {
      await _fetchActiveDiscounts(force: true);
    }
  }

  Future<void> _checkAndReloadData() async {
    if (ShopService.hasSelectedShop() &&
        (signatureProducts.isEmpty || productTags.isEmpty) &&
        !_isLoadingAllData &&
        !_isLoadingProducts) {
      await _reloadProducts();
    }
  }

  Future<void> _reloadProducts() async {
    if (!mounted) return;

    setState(() {
      _isLoadingProducts = true;
      _isLoadingTags = true;
    });

    try {
      await Future.wait([
        _fetchProductsForCategories(),
        _fetchProductsByTags(),
        _fetchRecommendedProducts(),
        _fetchActiveDiscounts(force: true),
        _fetchWarehouseProducts(),
      ]);

      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
          _isLoadingTags = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
          _isLoadingTags = false;
        });
      }
    }
  }

  Future<void> _refreshAfterSettings() async {
    if (_isRefreshingAfterSettings) return;
    _isRefreshingAfterSettings = true;

    setState(() {
      _isLoadingAllData = true;
    });

    try {
      await ShopService.getCurrentLocation(forceRefresh: true);
      await ShopService.fetchAllShops(forceRefresh: true);

      final nearestShop = ShopService.getNearestShop();
      if (nearestShop != null && ShopService.hasSelectedShop()) {
        if (ShopService.selectedShopId != nearestShop.id &&
            !_userHasDismissedLocationChange) {
          _showShopChoiceDialog(nearestShop);
          _isRefreshingAfterSettings = false;
          return;
        }
      }

      if (!ShopService.hasSelectedShop() && nearestShop != null) {
        await ShopService.selectShop(nearestShop);
      }

      await _reloadProducts();

      if (mounted) {
        setState(() {
          _isLoadingAllData = false;
          _isLoadingProducts = false;
          _isLoadingTags = false;
          _dataLoaded = true;
        });

        SiporaTheme.showSnackBar(
          context,
          'Location enabled! Shops updated.',
          isError: false,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAllData = false;
        });
      }
    }

    _isRefreshingAfterSettings = false;
  }

  Future<void> _checkLocationAfterResume() async {
    if (_isRefreshingAfterSettings) return;

    await Future.delayed(const Duration(milliseconds: 300));

    if (ShopService.hasUserLocation()) {
      return;
    }

    if (!mounted) return;
    final hasLocation = await ShopService.requestLocationOnce(context);
    if (hasLocation && mounted) {
      await _refreshAfterSettings();
    }
  }

  Future<void> _loadAllData() async {
    if (_isLoadingStarted) return;
    _isLoadingStarted = true;

    try {
      await ShopService.loadSelectedShop();

      if (!mounted) return;
      final hasLocation = await ShopService.requestLocationOnce(context);

      if (hasLocation) {
        await ShopService.fetchAllShops(forceRefresh: true);

        final nearestShop = ShopService.getNearestShop();
        if (nearestShop != null && ShopService.hasSelectedShop()) {
          if (ShopService.selectedShopId != nearestShop.id &&
              !_userHasDismissedLocationChange) {
            _showShopChoiceDialog(nearestShop);
            return;
          }
        }

        if (!ShopService.hasSelectedShop() && nearestShop != null) {
          await ShopService.selectShop(nearestShop);
        }

        if (mounted) {
          setState(() {});
        }
      }

      if (ShopService.hasSelectedShop()) {
        await _reloadProducts();
      } else {
        if (mounted) {
          setState(() {
            _isLoadingProducts = false;
            _isLoadingTags = false;
            _isLoadingWarehouseProducts = false;
          });
        }
      }

      if (mounted) {
        setState(() {
          _isLoadingAllData = false;
          _dataLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAllData = false;
          _errorMessage = 'Failed to load data. Pull down to refresh.';
        });
      }
    }
  }

  void _showShopChoiceDialog(Shop nearestShop) {
    final theme = context.siporaTheme;
    final isSmallScreen = context.isSmallScreen;
    final isTablet = context.isTablet;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [SiporaTheme.gold, SiporaTheme.greenMid],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on,
                color: Colors.white,
                size: isTablet ? 24.w : 20.w,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Shop Location Changed',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14.sp : (isTablet ? 18.sp : 16.sp),
                  fontWeight: FontWeight.w700,
                  color: theme.textDark,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'You are in a new area. Do you want to continue with your previous shop '
          '(${ShopService.selectedShopDisplayName}) or switch to the nearest shop '
          '(${nearestShop.name})?',
          style: TextStyle(
            fontSize: isSmallScreen ? 11.sp : (isTablet ? 14.sp : 12.sp),
            color: theme.textDark,
            height: 1.4,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    setState(() {
                      _userHasDismissedLocationChange = true;
                    });
                    await _reloadProducts();
                    if (mounted) {
                      setState(() {
                        _isLoadingAllData = false;
                        _dataLoaded = true;
                      });
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.textDark,
                    side: BorderSide(color: theme.border, width: 1.5.w),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Keep Old Shop',
                    style: TextStyle(
                      fontSize: isSmallScreen
                          ? 10.sp
                          : (isTablet ? 12.sp : 11.sp),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await ShopService.selectShop(nearestShop);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      if (mounted) {
                        setState(() {
                          _userHasDismissedLocationChange = false;
                        });
                        await _reloadProducts();
                        if (mounted) {
                          setState(() {
                            _isLoadingAllData = false;
                            _dataLoaded = true;
                          });
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SiporaTheme.gold,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Switch',
                    style: TextStyle(
                      fontSize: isSmallScreen
                          ? 10.sp
                          : (isTablet ? 12.sp : 11.sp),
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _fetchProductsForCategories() async {
    if (!ShopService.hasSelectedShop()) {
      if (mounted) {
        setState(() {
          _productsByCategory = {};
          _filteredProductsByCategory = {};
        });
      }
      return;
    }

    try {
      final franchiseId = ShopService.selectedShopId!;

      String? userId;
      final token = await SharedPreferences.getInstance().then(
        (prefs) => prefs.getString('tea_app_token'),
      );
      if (token != null) {
        userId = JwtService.extractUserId(token);
      }

      userId ??= await SharedPreferences.getInstance().then(
        (prefs) => prefs.getString('user_id'),
      );

      final queryParameters = <String, String>{'franchise_id': franchiseId};
      if (userId != null && userId.isNotEmpty) {
        queryParameters['user_id'] = userId;
      }
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/product/get-products-for-mobile',
      ).replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          final Map<String, dynamic> groupedProducts =
              data['grouped_products'] ?? {};
          final Map<String, dynamic> groupedWarehouseProducts =
              data['grouped_warehouse_products'] ?? {};

          final Map<String, List<Product>> productsBySubcategory = {};

          groupedProducts.forEach((category, subcategories) {
            if (subcategories is Map<String, dynamic>) {
              subcategories.forEach((subCategory, products) {
                if (products is List) {
                  for (var product in products) {
                    final mappedProduct = _mapApiProductToProduct(product);
                    productsBySubcategory
                        .putIfAbsent(subCategory, () => [])
                        .add(mappedProduct);
                  }
                  _subcategoryToCategoryMap[subCategory] = category;
                }
              });
            }
          });

          groupedWarehouseProducts.forEach((category, subcategories) {
            if (subcategories is Map<String, dynamic>) {
              subcategories.forEach((subCategory, products) {
                if (products is List) {
                  for (var product in products) {
                    final mappedProduct = _mapApiProductToProduct(
                      product,
                      isWarehouseProduct: true,
                    );
                    productsBySubcategory
                        .putIfAbsent(subCategory, () => [])
                        .add(mappedProduct);
                  }
                  _subcategoryToCategoryMap[subCategory] = category;
                }
              });
            }
          });

          if (mounted) {
            setState(() {
              _productsByCategory = productsBySubcategory;
              _filteredProductsByCategory = Map.from(productsBySubcategory);
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  Product _mapApiProductToProduct(
    Map<String, dynamic> apiProduct, {
    bool isWarehouseProduct = false,
  }) {
    String imageUrl = '';
    String productsImages = '';
    if (apiProduct['Products_Images'] != null &&
        apiProduct['Products_Images'].toString().isNotEmpty) {
      productsImages = apiProduct['Products_Images'].toString();
      final images = productsImages.split(',');
      imageUrl = images[0].trim();
    }

    // Use ImageUtils to validate and fix image URL
    imageUrl = ImageUtils.getValidImageUrl(imageUrl);

    String weightStr = '';
    if (apiProduct['Weight_kg'] != null && apiProduct['Weight_kg'] != 0) {
      weightStr = '${apiProduct['Weight_kg']} kg';
    } else if (apiProduct['Grams_g'] != null && apiProduct['Grams_g'] != 0) {
      weightStr = '${apiProduct['Grams_g']} g';
    }

    double price = 0.0;
    double mrp = 0.0;
    String discount = '';

    if (apiProduct['Total'] != null) {
      price = apiProduct['Total'].toDouble();
    } else if (apiProduct['Amount'] != null) {
      price = apiProduct['Amount'].toDouble();
    } else if (apiProduct['Price'] != null) {
      price = apiProduct['Price'].toDouble();
    } else if (apiProduct['price'] != null) {
      price = apiProduct['price'].toDouble();
    } else {
      price = 99.0;
    }

    if (apiProduct['MRP'] != null) {
      mrp = apiProduct['MRP'].toDouble();
    } else if (apiProduct['mrp'] != null) {
      mrp = apiProduct['mrp'].toDouble();
    } else {
      mrp = price;
    }

    if (mrp > price) {
      final discountPercentage = ((mrp - price) / mrp * 100).round();
      discount = '$discountPercentage% OFF';
    }

    bool freeCupEligibility = false;
    if (apiProduct['free_cup_eligibility'] != null) {
      final value = apiProduct['free_cup_eligibility'];
      if (value is bool) {
        freeCupEligibility = value;
      } else if (value is int) {
        freeCupEligibility = value == 1;
      } else if (value is String) {
        freeCupEligibility = value.toLowerCase() == 'true' || value == '1';
      }
    }

    return Product(
      id:
          (apiProduct['id'] ??
                  apiProduct['product_id'] ??
                  apiProduct['products_id'] ??
                  apiProduct['Product_ID'] ??
                  apiProduct['Products_ID'] ??
                  '')
              .toString(),
      name: apiProduct['Product_Name'] ?? 'Unknown Product',
      image: imageUrl,
      productsImages: productsImages,
      weight: weightStr.isNotEmpty ? weightStr : '1 unit',
      price: price,
      mrp: mrp,
      discount: discount,
      brand: apiProduct['Brand'] ?? 'Unknown Brand',
      isFreeCupEligible: freeCupEligibility,
      isWarehouseProduct: isWarehouseProduct,
    );
  }

  Set<String> _getAvailableSubcategories() {
    return _productsByCategory.keys.toSet();
  }

  Future<void> _fetchRecommendedProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('tea_app_token');

      if (token == null || !ShopService.hasSelectedShop()) return;

      final franchiseId = ShopService.selectedShopId!;
      final products = await ApiService.getRecommendedProducts(
        token,
        franchiseId,
      );

      if (mounted) {
        setState(() {
          recommendedProducts = products;
          signatureProducts = products
              .map((product) => product.toSignatureProductFormat())
              .toList();
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Error fetching recommended products: $e');
    }
  }

  Future<void> _fetchProductsByTags() async {
    try {
      if (!ShopService.hasSelectedShop()) {
        if (mounted) setState(() => productTags = []);
        return;
      }

      final franchiseId = ShopService.selectedShopId!;
      final response = await ApiService.getProductsByTags(franchiseId);

      if (mounted) {
        final tagsWithUniqueImages = _assignUniqueImagesToTags(
          response.firstSixTags,
        );
        setState(() => productTags = tagsWithUniqueImages);
      }
    } catch (e) {
      if (_productsByCategory.isNotEmpty) {
        await _extractTagsFromProducts();
      }
    }
  }

  Future<void> _fetchActiveDiscounts({bool force = false}) async {
    if (!ShopService.hasSelectedShop()) return;
    if (_cupQuestLoading && !force) return;

    if (mounted) setState(() => _cupQuestLoading = true);

    try {
      final franchiseId = ShopService.selectedShopId!;
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('tea_app_token');

      // ✅ Fixed: Using null-aware assignment
      String? userId =
          await StorageService.getUserId() ?? prefs.getString('user_id');

      if (userId == null && token != null) {
        userId = JwtService.extractUserId(token);
      }

      if (userId == null) {
        if (mounted) setState(() => _cupQuestLoading = false);
        return;
      }

      await DiscountService.fetchCupQuestProgressWithCart(
        userId: userId,
        franchiseId: franchiseId,
        authToken: token,
      );

      if (mounted) {
        setState(() {
          _cupQuestLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cupQuestLoading = false);
    }
  }

  Future<void> _extractTagsFromProducts() async {
    try {
      if (_productsByCategory.isEmpty) {
        if (mounted) setState(() => productTags = []);
        return;
      }

      final Set<String> allTags = {};
      final Map<String, List<TaggedProduct>> tagProducts = {};

      _productsByCategory.forEach((category, products) {
        for (final product in products) {
          final tags = [
            product.name.toLowerCase(),
            product.brand.toLowerCase(),
            category.toLowerCase(),
            if (product.discount.isNotEmpty) 'discount' else '',
            'popular',
          ];
          for (final tag in tags) {
            final cleanTag = tag.trim();
            if (cleanTag.isNotEmpty) {
              allTags.add(cleanTag);
              tagProducts.putIfAbsent(cleanTag, () => []);
            }
          }
        }
      });

      final List<ProductTag> tagsList = allTags.map((tagName) {
        return ProductTag(
          tagName: tagName,
          products: tagProducts[tagName] ?? [],
        );
      }).toList();

      tagsList.sort((a, b) => a.tagName.compareTo(b.tagName));
      final firstSixTags = tagsList.take(6).toList();

      if (mounted) setState(() => productTags = firstSixTags);
    } catch (e) {
      debugPrint('Error extracting tags from products: $e');
    }
  }

  List<ProductTag> _assignUniqueImagesToTags(List<ProductTag> tags) {
    final Set<String> usedImages = {};
    final List<ProductTag> processedTags = [];

    for (final tag in tags) {
      String assignedImage = '';
      for (final product in tag.products) {
        final imageUrl = ImageUtils.getValidImageUrl(product.firstImage);
        if (imageUrl.isNotEmpty &&
            imageUrl != ImageUtils.fallbackImagePath &&
            !usedImages.contains(imageUrl)) {
          assignedImage = imageUrl;
          usedImages.add(imageUrl);
          break;
        }
      }
      if (assignedImage.isEmpty && tag.products.isNotEmpty) {
        assignedImage = ImageUtils.getValidImageUrl(
          tag.products.first.firstImage,
        );
      }
      if (assignedImage.isEmpty) {
        assignedImage = ImageUtils.fallbackImagePath;
      }
      processedTags.add(
        ProductTag(
          tagName: tag.tagName,
          products: tag.products,
          assignedImage: assignedImage,
        ),
      );
    }
    return processedTags;
  }

  String _formatTagName(String tagName) {
    return tagName
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  // ==================== Build Methods ====================

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;

    if (_errorMessage != null && !_dataLoaded && !_isLoadingAllData) {
      return Scaffold(
        backgroundColor: theme.cream,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64.w, color: theme.red),
              SizedBox(height: 16.h),
              Text(
                _errorMessage!,
                style: SiporaTheme.bodyMedium(
                  context,
                ).copyWith(color: theme.textDark),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoadingAllData = true;
                    _errorMessage = null;
                  });
                  _loadAllData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.greenDark,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.cream,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(bottom: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── SHOPS SECTION ──────────────────────────────────────
                    ShopsSection(onRefresh: () {}, dataLoaded: _dataLoaded),

                    // ─── SIGNATURE SECTION ──────────────────────────────────
                    signature.SignatureSection(
                      key: ValueKey(
                        'signature_${signatureProducts.length}_${recommendedProducts.length}',
                      ),
                      signatureProducts: signatureProducts,
                      recommendedProducts: recommendedProducts,
                      isLoading: _isLoadingProducts,
                      errorMessage: _errorMessage,
                      onCartUpdated: () {
                        setState(() {});
                      },
                      onCupQuestRefresh: () {
                        _fetchActiveDiscounts(force: true);
                      },
                    ),
                    SizedBox(height: 32.h),

                    // ─── EXPLORE BY TASTE ──────────────────────────────────
                    _buildExploreByTaste(),
                    SizedBox(height: 16.h),

                    // ─── WAREHOUSE PRODUCTS ────────────────────────────────
                    _buildWarehouseProducts(),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavTextRow(currentPage: 'home'),
    );
  }

  Widget _buildExploreByTaste() {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;
    final isSmall = context.isSmallScreen;
    final crossAxisCount = isSmall ? 2 : (isTablet ? 4 : 3);
    final double carouselHeight = isTablet ? 160.h : 120.h;
    final double carouselWidth = double.infinity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPremiumCategories(),
        SizedBox(height: 32.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'Explore by Tags',
            style: SiporaTheme.titleLarge(context).copyWith(
              fontWeight: FontWeight.w800,
              fontSize: isTablet ? 22.sp : 18.sp,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: _isLoadingTags
              ? SizedBox(
                  height: 120.h,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.greenDark,
                      ),
                    ),
                  ),
                )
              : productTags.isEmpty
              ? SizedBox(
                  height: 120.h,
                  child: Center(
                    child: Text(
                      'No tags available',
                      style: SiporaTheme.bodyMedium(
                        context,
                      ).copyWith(color: theme.textMuted),
                    ),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 12.h,
                    childAspectRatio: isTablet ? 1.0 : 0.85,
                  ),
                  itemCount: productTags.length,
                  itemBuilder: (context, index) {
                    final tag = productTags[index];
                    return _buildCategoryGridCard(
                      tag,
                      carouselHeight,
                      carouselWidth,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryGridCard(
    ProductTag tag,
    double carouselHeight,
    double carouselWidth,
  ) {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;
    final carouselProducts = tag.products.map((taggedProduct) {
      return Product(
        id: taggedProduct.id,
        name: taggedProduct.productName,
        image: ImageUtils.getValidImageUrl(taggedProduct.firstImage),
        productsImages: taggedProduct.firstImage,
        weight: '1 unit',
        price: 0,
        mrp: 0,
        discount: '',
        brand: '',
        isFreeCupEligible: taggedProduct.freeCupEligibility,
      );
    }).toList();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductListPage(
              category: tag.tagName,
              tagProducts: tag.products,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: theme.goldBg.withValues(alpha: 0.3),
            width: 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: SiporaTheme.shadowLight.withValues(alpha: 0.05),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                child: carouselProducts.isNotEmpty
                    ? InfiniteCarousel(
                        products: carouselProducts,
                        type: CarouselType.card,
                        height: carouselHeight,
                        width: carouselWidth,
                        borderRadius: 8.r,
                        showDots: false,
                        showCounter: false,
                        showOverlay: false,
                        autoSlideDuration: carouselProducts.length > 1
                            ? const Duration(seconds: 3)
                            : Duration.zero,
                        animationDuration: const Duration(milliseconds: 500),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductListPage(
                                category: tag.tagName,
                                tagProducts: tag.products,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: theme.cream,
                        child: Center(
                          child: ImageUtils.assetImage(
                            path: ImageUtils.fallbackImagePath,
                            width: 60.w,
                            height: 60.w,
                          ),
                        ),
                      ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(8.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatTagName(tag.tagName),
                      style: SiporaTheme.titleSmall(context).copyWith(
                        fontSize: isTablet ? 14.sp : 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${tag.products.length} items',
                      style: SiporaTheme.caption(
                        context,
                      ).copyWith(fontSize: isTablet ? 11.sp : 9.sp),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCategories() {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;
    final categories = _filteredProductsByCategory.entries.map((entry) {
      final products = entry.value;
      return {
        'products': products,
        'label': entry.key,
        'count': '${entry.value.length} items',
      };
    }).toList();

    if (categories.isEmpty) return const SizedBox.shrink();

    final double cardWidth = isTablet ? 200.w : 160.w;
    final double carouselHeight = isTablet ? 120.h : 100.h;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'Browse By Categories',
            style: SiporaTheme.titleLarge(context).copyWith(
              fontWeight: FontWeight.w800,
              fontSize: isTablet ? 22.sp : 18.sp,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: isTablet ? 240.h : 200.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final products = category['products'] as List<Product>;
              final categoryName = category['label'] as String;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductListPage(
                        category: categoryName,
                        allProductsByCategory: _filteredProductsByCategory,
                        subcategoryToCategoryMap: _subcategoryToCategoryMap,
                        availableSubcategories: _getAvailableSubcategories(),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: cardWidth,
                  margin: EdgeInsets.only(right: 16.w),
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: theme.white,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: SiporaTheme.shadowLight.withValues(alpha: 0.08),
                        blurRadius: 16.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                    border: Border.all(
                      color: theme.goldBg.withValues(alpha: 0.3),
                      width: 1.w,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: carouselHeight,
                        child: InfiniteCarousel(
                          products: products,
                          type: CarouselType.card,
                          height: carouselHeight,
                          width: cardWidth,
                          borderRadius: 8.r,
                          showDots: false,
                          showCounter: false,
                          showOverlay: false,
                          autoSlideDuration: products.length > 1
                              ? const Duration(seconds: 3)
                              : Duration.zero,
                          animationDuration: const Duration(milliseconds: 500),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductListPage(
                                  category: categoryName,
                                  allProductsByCategory:
                                      _filteredProductsByCategory,
                                  subcategoryToCategoryMap:
                                      _subcategoryToCategoryMap,
                                  availableSubcategories:
                                      _getAvailableSubcategories(),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        categoryName,
                        style: SiporaTheme.titleSmall(context).copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: isTablet ? 16.sp : 14.sp,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        category['count'] as String,
                        style: SiporaTheme.captionBold(
                          context,
                        ).copyWith(color: theme.greenMid),
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

  // ==================== Warehouse Products Section ====================

  Widget _buildWarehouseProducts() {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;
    final crossAxisCount = isTablet ? 3 : 2;

    // Show loading state
    if (_isLoadingWarehouseProducts) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Warehouse Products',
                    style: SiporaTheme.titleLarge(context).copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: isTablet ? 22.sp : 18.sp,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 200.h,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(theme.greenDark),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Show empty state
    if (_warehouseProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Warehouse Products',
                style: SiporaTheme.titleLarge(context).copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: isTablet ? 22.sp : 18.sp,
                ),
              ),
              if (_totalWarehouseProducts > 0)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.goldBg,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '$_totalWarehouseProducts items',
                    style: SiporaTheme.caption(context).copyWith(
                      color: theme.greenDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            addRepaintBoundaries: true,
            addAutomaticKeepAlives: false,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 20.w,
              mainAxisSpacing: 20.h,
              childAspectRatio: isTablet ? 0.9 : 0.75,
            ),
            itemCount: _warehouseProducts.length,
            itemBuilder: (context, index) {
              final product = _warehouseProducts[index];
              return Container(
                margin: EdgeInsets.all(4.w),
                child: KeyedSubtree(
                  key: ValueKey('warehouse_${product.id}_$index'),
                  child: _buildWarehouseProductCard(product),
                ),
              );
            },
          ),
        ),
        // Modern Load More Button
        if (_hasMoreWarehouseProducts && _totalPages > 1)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
            child: Center(
              child: _isLoadingMoreWarehouseProducts
                  ? Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 32.w,
                        vertical: 14.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.greenDark.withValues(alpha: 0.1),
                            theme.gold.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30.r),
                        border: Border.all(
                          color: theme.gold.withValues(alpha: 0.3),
                          width: 1.w,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.greenDark,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'Loading...',
                            style: SiporaTheme.bodyMedium(context).copyWith(
                              color: theme.greenDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GestureDetector(
                      onTap: _loadMoreWarehouseProducts,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 40.w,
                          vertical: 16.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [theme.greenDark, theme.greenMid],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30.r),
                          boxShadow: [
                            BoxShadow(
                              color: theme.greenDark.withValues(alpha: 0.3),
                              blurRadius: 12.r,
                              offset: Offset(0, 4.h),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Load More',
                              style: SiporaTheme.bodyLarge(context).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Icon(
                              Icons.arrow_downward_rounded,
                              color: Colors.white,
                              size: 20.w,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        // Page Info
        if (_totalPages > 1 && !_isLoadingWarehouseProducts)
          Padding(
            padding: EdgeInsets.only(top: 4.h, bottom: 4.h),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: theme.cream,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: theme.goldBg.withValues(alpha: 0.3),
                    width: 1.w,
                  ),
                ),
                child: Text(
                  'Showing $_currentPage of $_totalPages pages',
                  style: SiporaTheme.caption(context).copyWith(
                    color: theme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildWarehouseProductCard(Product product) {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;

    // Check if product is in cart using productId for warehouse products
    final isInCart = CartService.isInCartById(product.id);
    final quantity = CartService.getQuantityById(product.id);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // Navigate to product detail page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProductDetailsPage(product: product.toRecommendedProduct()),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: theme.goldBg.withValues(alpha: 0.3),
            width: 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: SiporaTheme.shadowLight.withValues(alpha: 0.05),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(12.r),
                  ),
                  child: Stack(
                    children: [
                      product.image.isNotEmpty
                          ? Image.network(
                              product.image,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              theme.greenDark,
                                            ),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return ImageUtils.assetImage(
                                  path: ImageUtils.fallbackImagePath,
                                  fit: BoxFit.cover,
                                );
                              },
                            )
                          : ImageUtils.assetImage(
                              path: ImageUtils.fallbackImagePath,
                              fit: BoxFit.cover,
                            ),
                      // Warehouse badge
                      Positioned(
                        top: 6.h,
                        left: 6.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: theme.greenDark.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'Warehouse',
                            style: SiporaTheme.caption(context).copyWith(
                              color: Colors.white,
                              fontSize: 7.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      // Discount badge
                      if (product.discount.isNotEmpty)
                        Positioned(
                          top: 6.h,
                          right: 6.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: theme.gold,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              product.discount,
                              style: SiporaTheme.caption(context).copyWith(
                                color: Colors.white,
                                fontSize: 7.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      // Add to Cart / Quantity Selector
                      Positioned(
                        bottom: 6.h,
                        right: 6.w,
                        child: GestureDetector(
                          onTap: () {}, // Prevent tap propagation to parent
                          child: isInCart
                              ? _buildQuantitySelector(
                                  context,
                                  product.name,
                                  quantity,
                                  product,
                                )
                              : _buildAddButton(context, product.name, product),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Product Info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(6.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (product.brand.isNotEmpty)
                        Text(
                          product.brand,
                          style: TextStyle(
                            fontSize: isTablet ? 12.sp : 10.sp,
                            color: theme.greenPill,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      SizedBox(height: 2.h),
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: isTablet ? 14.sp : 12.sp,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                          color: theme.textDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: isTablet ? 16.sp : 14.sp,
                          fontWeight: FontWeight.w700,
                          color: theme.textDark,
                        ),
                      ),
                      if (product.mrp > product.price) ...[
                        SizedBox(height: 1.h),
                        Text(
                          '₹${product.mrp.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: isTablet ? 11.sp : 9.sp,
                            decoration: TextDecoration.lineThrough,
                            color: theme.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(
    BuildContext context,
    String productName,
    Product product,
  ) {
    final theme = context.siporaTheme;

    return GestureDetector(
      onTap: () {
        // Use CartHelperService for unified cart addition
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
            setState(() {});
            _onCartChanged();
          },
          onSuccess: () {
            if (mounted) {
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
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [theme.greenDark, theme.greenMid]),
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: theme.greenDark.withValues(alpha: 0.3),
              blurRadius: 8.r,
              offset: Offset(0, 3.h),
            ),
          ],
        ),
        child: Icon(Icons.add, color: Colors.white, size: 20.w),
      ),
    );
  }

  Widget _buildQuantitySelector(
    BuildContext context,
    String productName,
    int quantity,
    Product product,
  ) {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;

    return Container(
      height: 36.h,
      decoration: BoxDecoration(
        color: theme.greenBg,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: theme.greenLight.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              if (quantity > 1) {
                CartService.updateQuantityById(product.id, quantity - 1);
              } else {
                CartService.removeItemById(product.id);
              }
              setState(() {});
              _onCartChanged();
            },
            child: Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                color: quantity == 1 ? theme.greenBg : theme.greenDark,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.remove,
                color: quantity == 1 ? theme.greenDark : Colors.white,
                size: 16.w,
              ),
            ),
          ),
          Container(
            width: 28.w,
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: TextStyle(
                fontSize: isTablet ? 12.sp : 11.sp,
                fontWeight: FontWeight.w600,
                color: theme.textDark,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              CartService.updateQuantityById(product.id, quantity + 1);
              setState(() {});
              _onCartChanged();
            },
            child: Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                color: theme.greenDark,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.add, color: Colors.white, size: 16.w),
            ),
          ),
        ],
      ),
    );
  }
}
