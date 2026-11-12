import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../Home_page/widgets/bottom_nav_text_row.dart';
import 'widgets/products_details_page.dart';
import '../models/recommended_product.dart';
import '../models/product.dart';
import 'widgets/product_list_page.dart';
import '../services/shop_service.dart';
import '../services/storage_service.dart';
import '../services/jwt_service.dart';
import '../map/map_page.dart';
import '../theme/sipora_theme.dart';
import '../utils/screen_utils.dart';
import '../utils/image_utils.dart';
import './widgets/infinite_carousel.dart';
import '../Cart_page/widgets/unified_product_card.dart';
import '../Search_page/search_page.dart';

class PremiumShimmerEffect extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const PremiumShimmerEffect({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<PremiumShimmerEffect> createState() => _PremiumShimmerEffectState();
}

class _PremiumShimmerEffectState extends State<PremiumShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();

    _animation = Tween<Alignment>(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: _animation.value,
              end: _animation.value == Alignment.topLeft
                  ? Alignment.bottomRight
                  : Alignment.topLeft,
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.6),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  bool _isLoading = true;
  Map<String, List<Product>> _productsByCategory = {};
  final Map<String, String> _subcategoryToCategoryMap = {};
  Set<String> _teaCoffeeCategories = {};
  String? _selectedTeaCoffeeCategory;

  bool _isInitialized = false;

  // DEBUG: Add a debug flag
  final bool _debugMode = true;

  Set<String> _getAvailableSubcategories() {
    return _productsByCategory.keys.toSet();
  }

  // DEBUG: Method to log debug information
  void _logDebug(String message, {Map<String, dynamic>? data}) {
    if (_debugMode) {
      // ignore: avoid_print
      // print('🔍 [ShopPage Debug] $message');
      if (data != null) {
        // ignore: avoid_print
        // print('🔍 Data: ${json.encode(data)}');
      }
    }
  }

  // DEBUG: Method to log layout information
  void _logLayoutInfo() {
    _logDebug('=== LAYOUT DEBUG INFO ===');
    _logDebug('Total subcategories: ${_productsByCategory.keys.length}');
    _logDebug('Subcategory keys: ${_productsByCategory.keys.toList()}');
    _logDebug('Subcategory to category map: $_subcategoryToCategoryMap');
    _logDebug('Tea coffee categories: $_teaCoffeeCategories');
    _logDebug('Selected category: $_selectedTeaCoffeeCategory');
    _logDebug('Is loading: $_isLoading');
    _logDebug('=== END LAYOUT DEBUG INFO ===');

    // Log each subcategory's products count
    _productsByCategory.forEach((subcategory, products) {
      _logDebug('Subcategory "$subcategory" has ${products.length} products');
      for (var i = 0; i < products.length; i++) {
        _logDebug('  Product $i: ${products[i].name} - ${products[i].image}');
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _logDebug('🚀 ShopPage initialized');
    _initializeAndFetchProducts();
  }

  @override
  void dispose() {
    _logDebug('🗑️ ShopPage disposed');
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ShopPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _logDebug('🔄 didUpdateWidget called');
    _logLayoutInfo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _logDebug('📱 didChangeDependencies called');
    // Log screen size info
    final size = MediaQuery.of(context).size;
    _logDebug('Screen size: ${size.width}x${size.height}');
    _logDebug('Screen aspect ratio: ${size.aspectRatio}');
    _logDebug('Device pixel ratio: ${MediaQuery.of(context).devicePixelRatio}');
  }

  Future<void> _initializeAndFetchProducts() async {
    _logDebug('🔄 Starting _initializeAndFetchProducts');
    if (_isInitialized) {
      _logDebug('⚠️ Already initialized, skipping');
      return;
    }

    try {
      _logDebug('📦 Loading selected shop...');
      await ShopService.loadSelectedShop();
      _logDebug('✅ Selected shop loaded');

      _logDebug('🏪 Fetching all shops and location...');
      await Future.wait([
        ShopService.fetchAllShops(),
        ShopService.getCurrentLocation(),
      ]);
      _logDebug('✅ Shops and location fetched');

      final nearestShop = ShopService.getNearestShop();
      _logDebug('📍 Nearest shop: ${nearestShop?.name ?? 'None'}');

      if (!ShopService.hasSelectedShop() && nearestShop != null) {
        _logDebug('🔄 Selecting nearest shop: ${nearestShop.name}');
        await ShopService.selectShop(nearestShop);
        _logDebug('✅ Nearest shop selected');
      }

      _logDebug('📦 Fetching products by franchise...');
      await _fetchProductsByFranchise();

      setState(() {
        _isInitialized = true;
        _logDebug('✅ Initialization complete');
        _logLayoutInfo();
      });
    } catch (e, stackTrace) {
      _logDebug('❌ Error in _initializeAndFetchProducts: $e');
      _logDebug('StackTrace: $stackTrace');
    }
  }

  Future<void> _fetchProductsByFranchise() async {
    _logDebug('🔄 Starting _fetchProductsByFranchise');

    if (!ShopService.hasSelectedShop()) {
      _logDebug('⚠️ No shop selected');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _productsByCategory = {};
          _teaCoffeeCategories = {};
        });
      }
      if (mounted) {
        SiporaTheme.showSnackBar(
          context,
          'Please select a shop first',
          isError: true,
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _productsByCategory = {};
        _logDebug('🔄 Set loading state to true, cleared products');
      });
    }

    try {
      final franchiseId = ShopService.selectedShopId!;
      _logDebug('🏪 Franchise ID: $franchiseId');

      String? userId;
      final token = await StorageService.getToken();
      _logDebug('🔑 Token present: ${token != null}');

      if (token != null) {
        userId = JwtService.extractUserId(token);
        _logDebug('👤 User ID from JWT: $userId');
      }

      userId ??= await StorageService.getUserId();
      _logDebug('👤 Final User ID: $userId');

      final queryParameters = <String, String>{'franchise_id': franchiseId};
      if (userId != null && userId.isNotEmpty) {
        queryParameters['user_id'] = userId;
      }
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/product/get-products-for-mobile',
      ).replace(queryParameters: queryParameters);
      _logDebug('🌐 Product API URI: $uri');

      final response = await http.get(
        uri,
        headers: {'accept': 'application/json'},
      );

      _logDebug('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        _logDebug('📊 Response data keys: ${data.keys}');
        _logDebug('📊 Success: ${data['success']}');

        if (data['success'] == true) {
          final Map<String, dynamic> groupedProducts =
              data['grouped_products'] ?? {};
          final Map<String, dynamic> groupedWarehouseProducts =
              data['grouped_warehouse_products'] ?? {};

          _logDebug('📦 Grouped products keys: ${groupedProducts.keys}');
          _logDebug(
            '📦 Grouped warehouse products keys: ${groupedWarehouseProducts.keys}',
          );

          final Map<String, List<Product>> productsBySubcategory = {};

          groupedProducts.forEach((category, subcategories) {
            _logDebug('📂 Processing category: $category');
            if (subcategories is Map<String, dynamic>) {
              subcategories.forEach((subCategory, products) {
                _logDebug('  📁 Processing subcategory: $subCategory');
                if (products is List) {
                  _logDebug(
                    '    📄 Found ${products.length} products in $subCategory',
                  );
                  for (var product in products) {
                    try {
                      final mappedProduct = _mapApiProductToProduct(product);
                      if (mappedProduct != null) {
                        if (!productsBySubcategory.containsKey(subCategory)) {
                          productsBySubcategory[subCategory] = [];
                        }
                        productsBySubcategory[subCategory]!.add(mappedProduct);
                        _logDebug(
                          '      ✅ Added product: ${mappedProduct.name}',
                        );
                      } else {
                        _logDebug('      ⚠️ Failed to map product: $product');
                      }
                    } catch (e) {
                      _logDebug('      ❌ Error mapping product: $e');
                    }
                  }
                  _subcategoryToCategoryMap[subCategory] = category;
                  _logDebug(
                    '    📌 Mapped subcategory "$subCategory" to category "$category"',
                  );
                } else {
                  _logDebug(
                    '    ⚠️ Products is not a List: ${products.runtimeType}',
                  );
                }
              });
            } else {
              _logDebug(
                '  ⚠️ Subcategories is not a Map: ${subcategories.runtimeType}',
              );
            }
          });

          groupedWarehouseProducts.forEach((category, subcategories) {
            _logDebug('🏭 Processing warehouse category: $category');
            if (subcategories is Map<String, dynamic>) {
              subcategories.forEach((subCategory, products) {
                _logDebug(
                  '  🏭 Processing warehouse subcategory: $subCategory',
                );
                if (products is List) {
                  _logDebug(
                    '    📄 Found ${products.length} warehouse products in $subCategory',
                  );
                  for (var product in products) {
                    try {
                      final mappedProduct = _mapApiProductToProduct(
                        product,
                        isWarehouseProduct: true,
                      );
                      if (mappedProduct != null) {
                        if (!productsBySubcategory.containsKey(subCategory)) {
                          productsBySubcategory[subCategory] = [];
                        }
                        productsBySubcategory[subCategory]!.add(mappedProduct);
                        _logDebug(
                          '      ✅ Added warehouse product: ${mappedProduct.name}',
                        );
                      } else {
                        _logDebug(
                          '      ⚠️ Failed to map warehouse product: $product',
                        );
                      }
                    } catch (e) {
                      _logDebug('      ❌ Error mapping warehouse product: $e');
                    }
                  }
                  _subcategoryToCategoryMap[subCategory] = category;
                  _logDebug(
                    '    📌 Mapped warehouse subcategory "$subCategory" to category "$category"',
                  );
                } else {
                  _logDebug(
                    '    ⚠️ Warehouse products is not a List: ${products.runtimeType}',
                  );
                }
              });
            } else {
              _logDebug(
                '  ⚠️ Warehouse subcategories is not a Map: ${subcategories.runtimeType}',
              );
            }
          });

          _logDebug(
            '📊 Total subcategories: ${productsBySubcategory.keys.length}',
          );
          _logDebug('📊 Subcategory keys: ${productsBySubcategory.keys}');

          final Set<String> teaCoffeeCategories = {};
          groupedProducts.forEach((category, subcategories) {
            if (subcategories is Map<String, dynamic>) {
              subcategories.forEach((subCategory, products) {
                if (products is List && products.isNotEmpty) {
                  final hasTeaCoffeeProducts = products.any((product) {
                    if (product is Map<String, dynamic>) {
                      final sub =
                          product['sub_category']?.toString().toLowerCase() ??
                          '';
                      final hasTea = sub.contains('tea');
                      final hasCoffee = sub.contains('coffee');
                      final hasPowder = sub.contains('powder');
                      final hasGreen = sub.contains('green');
                      final hasInstant = sub.contains('instant');
                      final result =
                          hasTea ||
                          hasCoffee ||
                          hasPowder ||
                          hasGreen ||
                          hasInstant;
                      if (result) {
                        _logDebug(
                          '☕ Found tea/coffee product in category "$category", subcategory "$subCategory": $sub',
                        );
                      }
                      return result;
                    }
                    return false;
                  });
                  if (hasTeaCoffeeProducts) {
                    teaCoffeeCategories.add(category);
                    _logDebug(
                      '☕ Added category "$category" to tea/coffee categories',
                    );
                  }
                }
              });
            }
          });

          groupedWarehouseProducts.forEach((category, subcategories) {
            if (subcategories is Map<String, dynamic>) {
              subcategories.forEach((subCategory, products) {
                if (products is List && products.isNotEmpty) {
                  final hasTeaCoffeeProducts = products.any((product) {
                    if (product is Map<String, dynamic>) {
                      final sub =
                          product['sub_category']?.toString().toLowerCase() ??
                          '';
                      final hasTea = sub.contains('tea');
                      final hasCoffee = sub.contains('coffee');
                      final hasPowder = sub.contains('powder');
                      final hasGreen = sub.contains('green');
                      final hasInstant = sub.contains('instant');
                      final result =
                          hasTea ||
                          hasCoffee ||
                          hasPowder ||
                          hasGreen ||
                          hasInstant;
                      if (result) {
                        _logDebug(
                          '☕ Found warehouse tea/coffee product in category "$category", subcategory "$subCategory": $sub',
                        );
                      }
                      return result;
                    }
                    return false;
                  });
                  if (hasTeaCoffeeProducts) {
                    teaCoffeeCategories.add(category);
                    _logDebug(
                      '☕ Added warehouse category "$category" to tea/coffee categories',
                    );
                  }
                }
              });
            }
          });

          _logDebug('☕ Tea/Coffee categories: $teaCoffeeCategories');

          if (mounted) {
            setState(() {
              _productsByCategory = productsBySubcategory;
              _teaCoffeeCategories = teaCoffeeCategories;
              if (teaCoffeeCategories.isNotEmpty &&
                  _selectedTeaCoffeeCategory == null) {
                _selectedTeaCoffeeCategory = teaCoffeeCategories.first;
                _logDebug(
                  '🔍 Selected first tea/coffee category: $_selectedTeaCoffeeCategory',
                );
              }
              _isLoading = false;
              _logDebug('✅ Products loaded successfully');
              _logLayoutInfo();
            });
          }
        } else {
          _logDebug('❌ API returned success: false');
          if (mounted) {
            setState(() {
              _isLoading = false;
              _productsByCategory = {};
              _teaCoffeeCategories = {};
            });
          }
        }
      } else {
        _logDebug('❌ API returned status: ${response.statusCode}');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _productsByCategory = {};
          });
        }
      }
    } catch (e, stackTrace) {
      _logDebug('❌ Error in _fetchProductsByFranchise: $e');
      _logDebug('StackTrace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _productsByCategory = {};
          _teaCoffeeCategories = {};
        });
      }
    }
  }

  Product? _mapApiProductToProduct(
    Map<String, dynamic> apiProduct, {
    bool isWarehouseProduct = false,
  }) {
    try {
      _logDebug(
        '🔄 Mapping API product: ${apiProduct['Product_Name'] ?? 'Unknown'}',
      );

      String imageUrl = '';
      String productsImages = '';
      if (apiProduct['Products_Images'] != null &&
          apiProduct['Products_Images'].toString().isNotEmpty) {
        productsImages = apiProduct['Products_Images'].toString();
        final images = productsImages.split(',');
        imageUrl = images[0].trim();
        _logDebug('  🖼️ Image URL: $imageUrl');
      }

      imageUrl = ImageUtils.getValidImageUrl(imageUrl);

      String weightStr = '';
      if (apiProduct['Weight_kg'] != null && apiProduct['Weight_kg'] != 0) {
        weightStr = '${apiProduct['Weight_kg']} kg';
      } else if (apiProduct['Grams_g'] != null && apiProduct['Grams_g'] != 0) {
        weightStr = '${apiProduct['Grams_g']} g';
      }
      _logDebug('  ⚖️ Weight: $weightStr');

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
        _logDebug('  ⚠️ No price found, using default: $price');
      }
      _logDebug('  💰 Price: $price');

      if (apiProduct['MRP'] != null) {
        mrp = apiProduct['MRP'].toDouble();
      } else if (apiProduct['mrp'] != null) {
        mrp = apiProduct['mrp'].toDouble();
      } else {
        mrp = price;
      }
      _logDebug('  💰 MRP: $mrp');

      if (mrp > price) {
        final discountPercentage = ((mrp - price) / mrp * 100).round();
        discount = '$discountPercentage% OFF';
        _logDebug('  🏷️ Discount: $discount');
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
        _logDebug('  🎯 Free cup eligibility: $freeCupEligibility');
      }

      final product = Product(
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

      _logDebug('  ✅ Successfully mapped product: ${product.name}');
      return product;
    } catch (e, stackTrace) {
      _logDebug('  ❌ Error mapping product: $e');
      _logDebug('  StackTrace: $stackTrace');
      return null;
    }
  }

  void _refreshBuyAgainCards() {
    _logDebug('🔄 Refreshing buy again cards');
    setState(() {});
  }

  void _navigateToSearchPage() {
    _logDebug('🔍 Navigating to search page');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;

    // DEBUG: Log build information
    _logDebug('🏗️ Building ShopPage');
    _logDebug('  Is loading: $_isLoading');
    _logDebug(
      '  Products by category count: ${_productsByCategory.keys.length}',
    );
    _logDebug('  Tea coffee categories count: ${_teaCoffeeCategories.length}');

    if (!_isLoading) {
      _logDebug('  Displaying product data');
      _logLayoutInfo();
    }

    return Scaffold(
      backgroundColor: theme.cream,
      appBar: _buildPremiumAppBar(),
      body: _isLoading
          ? _buildPremiumLoadingSkeleton()
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(bottom: context.h(32)),
                    child: Column(
                      children: [
                        _buildPremiumHeader(),
                        SizedBox(height: context.h(24)),
                        _buildPremiumTeaCoffeeEssentials(),
                        SizedBox(height: context.h(32)),
                        _buildPremiumCategories(),
                        SizedBox(height: context.h(32)),
                        _buildPremiumAllProducts(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const BottomNavTextRow(currentPage: 'shop'),
    );
  }

  PreferredSizeWidget _buildPremiumAppBar() {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;
    final fontSize = isTablet ? context.sp(14) : context.sp(12);
    final titleFontSize = isTablet ? context.sp(18) : context.sp(16);

    _logDebug('🏷️ Building app bar - Tablet: $isTablet');

    return AppBar(
      backgroundColor: theme.cream,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      toolbarHeight: isTablet ? context.h(100) : context.h(90),
      leading: GestureDetector(
        onTap: () {
          _logDebug('📍 Shop icon tapped, navigating to map');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MapPage()),
          ).then((_) {
            _logDebug('🔄 Returning from map, refreshing products');
            _fetchProductsByFranchise();
          });
        },
        child: Container(
          margin: EdgeInsets.only(left: context.w(16)),
          padding: EdgeInsets.all(context.w(6)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                SiporaTheme.greenDark.withValues(alpha: 0.1),
                SiporaTheme.greenLight.withValues(alpha: 0.1),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.store_outlined,
            color: SiporaTheme.greenDark,
            size: isTablet ? context.w(24) : context.w(20),
          ),
        ),
      ),
      title: GestureDetector(
        onTap: () {
          _logDebug('📍 Shop title tapped, navigating to map');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MapPage()),
          ).then((_) {
            _logDebug('🔄 Returning from map, refreshing products');
            _fetchProductsByFranchise();
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Try another shop',
                  style: TextStyle(
                    fontSize: fontSize,
                    color: SiporaTheme.greenDark,
                  ),
                ),
                SizedBox(width: context.w(2)),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: isTablet ? context.w(16) : context.w(14),
                  color: SiporaTheme.greenDark,
                ),
              ],
            ),
            Text(
              ShopService.hasSelectedShop()
                  ? ShopService.selectedShopDisplayName
                  : 'Select a shop',
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w600,
                color: theme.textDark,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: context.w(16)),
          decoration: BoxDecoration(
            color: theme.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: SiporaTheme.shadowLight,
                blurRadius: context.r(10),
              ),
            ],
          ),
          child: IconButton(
            onPressed: _navigateToSearchPage,
            icon: Icon(
              Icons.search_rounded,
              color: SiporaTheme.greenDark,
              size: isTablet ? context.w(28) : context.w(24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumHeader() {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;
    final fontSize = isTablet ? context.sp(16) : context.sp(14);

    _logDebug('📋 Building premium header');

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!ShopService.hasSelectedShop())
            Container(
              padding: EdgeInsets.all(context.w(16)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.greenBg, theme.greenBg],
                ),
                borderRadius: BorderRadius.circular(context.r(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(context.w(8)),
                    decoration: BoxDecoration(
                      color: theme.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.store_outlined,
                      color: SiporaTheme.greenDark,
                      size: isTablet ? context.w(24) : context.w(20),
                    ),
                  ),
                  SizedBox(width: context.w(12)),
                  Expanded(
                    child: Text(
                      'Select a shop to see available products',
                      style: TextStyle(
                        fontSize: fontSize,
                        color: theme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumTeaCoffeeEssentials() {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;
    final fontSize = isTablet ? context.sp(18) : context.sp(16);

    _logDebug('☕ Building tea/coffee essentials section');
    _logDebug('  Tea coffee categories: $_teaCoffeeCategories');
    _logDebug('  Selected category: $_selectedTeaCoffeeCategory');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.w(20)),
          child: Text(
            'Sipora Products',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: theme.textDark,
              letterSpacing: -0.3,
            ),
          ),
        ),
        SizedBox(height: context.h(16)),

        if (_teaCoffeeCategories.isNotEmpty)
          SizedBox(
            height: context.h(48),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: context.w(20)),
              itemCount: _teaCoffeeCategories.length,
              itemBuilder: (context, index) {
                final category = _teaCoffeeCategories.elementAt(index);
                final isSelected = category == _selectedTeaCoffeeCategory;

                _logDebug(
                  '  Category $index: $category, Selected: $isSelected',
                );

                return GestureDetector(
                  onTap: () {
                    _logDebug('🔄 Selected tea/coffee category: $category');
                    setState(() {
                      _selectedTeaCoffeeCategory = category;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: context.w(10)),
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(20),
                      vertical: context.h(12),
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                SiporaTheme.greenDark,
                                SiporaTheme.greenMid,
                              ],
                            )
                          : null,
                      color: isSelected ? null : theme.white,
                      borderRadius: BorderRadius.circular(context.r(30)),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: SiporaTheme.greenDark.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: context.r(12),
                                offset: Offset(0, 4.h),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: context.r(8),
                                offset: Offset(0, 2.h),
                              ),
                            ],
                      border: isSelected
                          ? null
                          : Border.all(color: theme.border, width: 1.w),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: isTablet ? context.sp(16) : context.sp(14),
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : theme.textDark,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        SizedBox(height: context.h(20)),

        if (_selectedTeaCoffeeCategory != null)
          _buildPremiumSubcategories(_selectedTeaCoffeeCategory!)
        else if (_teaCoffeeCategories.isEmpty && !_isLoading) ...[
          Container(
            margin: EdgeInsets.symmetric(horizontal: context.w(20)),
            padding: EdgeInsets.all(context.w(32)),
            decoration: BoxDecoration(
              color: theme.white,
              borderRadius: BorderRadius.circular(context.r(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: context.r(20),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.coffee_outlined,
                  size: isTablet ? context.w(56) : context.w(48),
                  color: SiporaTheme.greenDark.withValues(alpha: 0.3),
                ),
                SizedBox(height: context.h(16)),
                Text(
                  'No products available',
                  style: TextStyle(
                    fontSize: isTablet ? context.sp(16) : context.sp(14),
                    color: theme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPremiumSubcategories(String selectedCategory) {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;
    final fontSize = isTablet ? context.sp(10) : context.sp(9);
    final titleFontSize = isTablet ? context.sp(12) : context.sp(11);

    _logDebug('📂 Building subcategories for: $selectedCategory');

    final Set<String> subcategories = {};

    _subcategoryToCategoryMap.forEach((subCategory, category) {
      if (category == selectedCategory) {
        subcategories.add(subCategory);
        _logDebug('  Found subcategory: $subCategory -> $category');
      }
    });

    _logDebug('  Total subcategories found: ${subcategories.length}');

    if (subcategories.isEmpty) {
      _logDebug('⚠️ No subcategories found for: $selectedCategory');
      return Container(
        margin: EdgeInsets.symmetric(horizontal: context.w(20)),
        padding: EdgeInsets.all(context.w(32)),
        decoration: BoxDecoration(
          color: theme.white,
          borderRadius: BorderRadius.circular(context.r(20)),
        ),
        child: Center(
          child: Text(
            'No subcategories available',
            style: TextStyle(fontSize: fontSize, color: theme.textMuted),
          ),
        ),
      );
    }

    final imageSize = context.w(70);
    final spacing = context.h(4);
    final textHeight = context.h(28);
    final itemsCountHeight = context.h(14);
    final totalItemHeight = imageSize + spacing + textHeight + itemsCountHeight;
    final containerHeight = totalItemHeight + context.h(8);

    _logDebug('📐 Container height: $containerHeight');
    _logDebug('📐 Image size: $imageSize');
    _logDebug('📐 Total item height: $totalItemHeight');

    return Container(
      margin: EdgeInsets.only(bottom: context.h(12)),
      child: SizedBox(
        height: containerHeight,
        child: ClipRect(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: context.w(12)),
            itemCount: subcategories.length,
            itemBuilder: (context, index) {
              final subcategory = subcategories.elementAt(index);
              final products = _productsByCategory[subcategory] ?? [];

              _logDebug('  🏗️ Building subcategory $index: $subcategory');
              _logDebug('    Products: ${products.length}');

              return GestureDetector(
                onTap: () {
                  _logDebug('👆 Tapped subcategory: $subcategory');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductListPage(
                        category: subcategory,
                        allProductsByCategory: _productsByCategory,
                        subcategoryToCategoryMap: _subcategoryToCategoryMap,
                        availableSubcategories: _getAvailableSubcategories(),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: context.w(90),
                  margin: EdgeInsets.only(right: context.w(10)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: context.w(70),
                        height: context.w(70),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(context.r(35)),
                        ),
                        child: products.isNotEmpty && products.length > 1
                            ? InfiniteCarousel(
                                products: products,
                                type: CarouselType.card,
                                width: context.w(70),
                                height: context.w(70),
                                borderRadius: context.r(35),
                                showDots: false,
                                showCounter: false,
                                showOverlay: false,
                                autoSlideDuration: const Duration(seconds: 3),
                                animationDuration: const Duration(
                                  milliseconds: 500,
                                ),
                                onTap: () {
                                  _logDebug(
                                    '👆 Tapped carousel for: $subcategory',
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductListPage(
                                        category: subcategory,
                                        allProductsByCategory:
                                            _productsByCategory,
                                        subcategoryToCategoryMap:
                                            _subcategoryToCategoryMap,
                                        availableSubcategories:
                                            _getAvailableSubcategories(),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : products.isNotEmpty && products.length == 1
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  context.r(35),
                                ),
                                child: Image.network(
                                  products.first.image,
                                  width: context.w(70),
                                  height: context.w(70),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        width: context.w(70),
                                        height: context.w(70),
                                        decoration: BoxDecoration(
                                          color: theme.greenBg,
                                          borderRadius: BorderRadius.circular(
                                            context.r(35),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.coffee_outlined,
                                          size: context.w(28),
                                          color: SiporaTheme.greenDark
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                ),
                              )
                            : Container(
                                width: context.w(70),
                                height: context.w(70),
                                decoration: BoxDecoration(
                                  color: theme.greenBg,
                                  borderRadius: BorderRadius.circular(
                                    context.r(35),
                                  ),
                                ),
                                child: Icon(
                                  Icons.coffee_outlined,
                                  size: context.w(28),
                                  color: SiporaTheme.greenDark.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                      ),
                      SizedBox(height: context.h(4)),
                      SizedBox(
                        height: textHeight,
                        child: Center(
                          child: Text(
                            subcategory,
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w600,
                              color: theme.textDark,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (products.isNotEmpty)
                        SizedBox(
                          height: itemsCountHeight,
                          child: Center(
                            child: Text(
                              '${products.length} items',
                              style: TextStyle(
                                fontSize: fontSize,
                                color: theme.textMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumCategories() {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;

    _logDebug('🏷️ Building categories section');

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

    final minCardWidth = isTablet ? context.w(170) : context.w(130);
    final maxCardWidth = isTablet ? context.w(230) : context.w(180);
    final adjustedCardWidth = cardWidth.clamp(minCardWidth, maxCardWidth);

    final carouselHeight = adjustedCardWidth * 0.65;
    final carouselWidth = adjustedCardWidth - context.w(24);

    final categories = _productsByCategory.entries.map((entry) {
      return {
        'products': entry.value,
        'label': entry.key,
        'count': '${entry.value.length} items',
      };
    }).toList();

    _logDebug('  Categories found: ${categories.length}');
    for (var cat in categories) {
      _logDebug('    Category: ${cat['label']} - ${cat['count']}');
    }

    if (categories.isEmpty) {
      _logDebug('⚠️ No categories found');
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.w(20)),
          child: Text(
            'Browse By Categories',
            style: TextStyle(
              fontSize: isTablet ? context.sp(22) : context.sp(18),
              fontWeight: FontWeight.w800,
              color: theme.textDark,
            ),
          ),
        ),
        SizedBox(height: context.h(16)),
        SizedBox(
          // FIX: Increased from 70 to 90 to safely accommodate 2-line category names
          height: carouselHeight + context.h(90),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: context.w(20)),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final products = category['products'] as List<Product>;
              final categoryName = category['label'] as String;

              _logDebug('  Building category $index: $categoryName');

              return GestureDetector(
                onTap: () {
                  _logDebug('👆 Tapped category: $categoryName');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductListPage(
                        category: categoryName,
                        allProductsByCategory: _productsByCategory,
                        subcategoryToCategoryMap: _subcategoryToCategoryMap,
                        availableSubcategories: _getAvailableSubcategories(),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: adjustedCardWidth,
                  margin: EdgeInsets.only(right: context.w(16)),
                  padding: EdgeInsets.all(context.w(12)),
                  decoration: BoxDecoration(
                    color: theme.white,
                    borderRadius: BorderRadius.circular(context.r(16)),
                    boxShadow: [
                      BoxShadow(
                        color: SiporaTheme.shadowLight.withValues(alpha: 0.08),
                        blurRadius: context.r(16),
                        offset: Offset(0, 4.h),
                      ),
                    ],
                    border: Border.all(
                      color: SiporaTheme.goldBg.withValues(alpha: 0.3),
                      width: 1.w,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: carouselHeight,
                        child: products.isNotEmpty && products.length > 1
                            ? InfiniteCarousel(
                                products: products,
                                type: CarouselType.card,
                                height: carouselHeight,
                                width: carouselWidth,
                                borderRadius: context.r(12),
                                showDots: false,
                                showCounter: false,
                                showOverlay: false,
                                autoSlideDuration: const Duration(seconds: 3),
                                animationDuration: const Duration(
                                  milliseconds: 500,
                                ),
                                onTap: () {
                                  _logDebug(
                                    '👆 Tapped carousel for category: $categoryName',
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductListPage(
                                        category: categoryName,
                                        allProductsByCategory:
                                            _productsByCategory,
                                        subcategoryToCategoryMap:
                                            _subcategoryToCategoryMap,
                                        availableSubcategories:
                                            _getAvailableSubcategories(),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : products.isNotEmpty && products.length == 1
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  context.r(12),
                                ),
                                child: Image.network(
                                  products.first.image,
                                  width: double.infinity,
                                  height: carouselHeight,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        width: double.infinity,
                                        height: carouselHeight,
                                        decoration: BoxDecoration(
                                          color: theme.greenBg,
                                          borderRadius: BorderRadius.circular(
                                            context.r(12),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.coffee_outlined,
                                          size: context.w(40),
                                          color: SiporaTheme.greenDark
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                ),
                              )
                            : Container(
                                width: double.infinity,
                                height: carouselHeight,
                                decoration: BoxDecoration(
                                  color: theme.greenBg,
                                  borderRadius: BorderRadius.circular(
                                    context.r(12),
                                  ),
                                ),
                                child: Icon(
                                  Icons.coffee_outlined,
                                  size: context.w(40),
                                  color: SiporaTheme.greenDark.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                      ),
                      SizedBox(height: context.h(8)),
                      Text(
                        categoryName,
                        style: TextStyle(
                          fontSize: isTablet ? context.sp(16) : context.sp(14),
                          fontWeight: FontWeight.w600,
                          color: theme.textDark,
                        ),
                        // FIX: Changed to 1 line to prevent variable height issues
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: context.h(4)),
                      Text(
                        category['count'] as String,
                        style: TextStyle(
                          fontSize: isTablet ? context.sp(13) : context.sp(11),
                          fontWeight: FontWeight.w500,
                          color: SiporaTheme.greenMid,
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

  Widget _buildPremiumAllProducts() {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;

    _logDebug('📦 Building all products section');

    if (_productsByCategory.isEmpty) {
      _logDebug('⚠️ No products available');
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(20),
          vertical: context.h(32),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.inbox_outlined,
                size: isTablet ? context.w(72) : context.w(64),
                color: theme.textMuted.withValues(alpha: 0.5),
              ),
              SizedBox(height: context.h(16)),
              Text(
                'No products available',
                style: TextStyle(
                  fontSize: isTablet ? context.sp(20) : context.sp(18),
                  fontWeight: FontWeight.w600,
                  color: theme.textDark,
                ),
              ),
              SizedBox(height: context.h(8)),
              Text(
                'Check back later for new products',
                style: TextStyle(
                  fontSize: isTablet ? context.sp(16) : context.sp(14),
                  color: theme.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

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

    final minCardWidth = isTablet ? context.w(170) : context.w(130);
    final maxCardWidth = isTablet ? context.w(230) : context.w(180);
    final adjustedCardWidth = cardWidth.clamp(minCardWidth, maxCardWidth);

    final carouselHeight = adjustedCardWidth * 0.65;

    final double brandHeight = context.h(18);
    final double brandSpacing = context.h(2);
    final double nameHeight = context.h(32);
    final double nameSpacing = context.h(4);
    final double priceHeight = context.h(22);
    final double paddingVertical = context.h(12);

    final double totalCardHeight =
        carouselHeight +
        brandHeight +
        brandSpacing +
        nameHeight +
        nameSpacing +
        priceHeight +
        paddingVertical;

    _logDebug('  Card width: $adjustedCardWidth');
    _logDebug('  Carousel height: $carouselHeight');
    _logDebug('  Total card height: $totalCardHeight');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.w(20)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Products',
                style: TextStyle(
                  fontSize: isTablet ? context.sp(22) : context.sp(20),
                  fontWeight: FontWeight.w800,
                  color: theme.textDark,
                  letterSpacing: -0.3,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(10),
                  vertical: context.h(6),
                ),
                decoration: BoxDecoration(
                  color: theme.greenBg,
                  borderRadius: BorderRadius.circular(context.r(20)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: isTablet ? context.w(16) : context.w(14),
                      color: SiporaTheme.greenPill,
                    ),
                    SizedBox(width: context.w(4)),
                    Text(
                      '${_productsByCategory.values.fold<int>(0, (sum, list) => sum + list.length)} items',
                      style: TextStyle(
                        fontSize: isTablet ? context.sp(14) : context.sp(12),
                        fontWeight: FontWeight.w600,
                        color: SiporaTheme.greenPill,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.h(16)),
        for (var entry in _productsByCategory.entries) ...[
          if (entry.value.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.only(bottom: context.h(20)),
              child: _buildPremiumCategorySection(
                entry.key,
                entry.value,
                adjustedCardWidth,
                carouselHeight,
                totalCardHeight,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildPremiumCategorySection(
    String title,
    List<Product> products,
    double cardWidth,
    double carouselHeight,
    double totalCardHeight,
  ) {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;
    final fontSize = isTablet ? context.sp(13) : context.sp(11);

    _logDebug('  Building category: $title with ${products.length} products');

    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(20),
            vertical: context.h(8),
          ),
          child: Row(
            children: [
              Container(
                width: context.w(3),
                height: context.h(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [SiporaTheme.greenDark, SiporaTheme.greenPill],
                  ),
                  borderRadius: BorderRadius.circular(context.r(2)),
                ),
              ),
              SizedBox(width: context.w(8)),
              Text(
                title,
                style: TextStyle(
                  fontSize: isTablet ? context.sp(18) : context.sp(16),
                  fontWeight: FontWeight.w600,
                  color: theme.textDark,
                ),
              ),
              SizedBox(width: context.w(6)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(6),
                  vertical: context.h(2),
                ),
                decoration: BoxDecoration(
                  color: theme.greenBg,
                  borderRadius: BorderRadius.circular(context.r(10)),
                ),
                child: Text(
                  '${products.length}',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: SiporaTheme.greenDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: totalCardHeight,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: context.w(20)),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final validProduct =
                  product.image.isEmpty || product.image == 'null'
                  ? Product(
                      id: product.id,
                      name: product.name,
                      image: ImageUtils.fallbackImagePath,
                      productsImages: product.productsImages,
                      weight: product.weight,
                      price: product.price,
                      mrp: product.mrp,
                      discount: product.discount,
                      brand: product.brand,
                      isFreeCupEligible: product.isFreeCupEligible,
                    )
                  : Product(
                      id: product.id,
                      name: product.name,
                      image: ImageUtils.getValidImageUrl(product.image),
                      productsImages: product.productsImages,
                      weight: product.weight,
                      price: product.price,
                      mrp: product.mrp,
                      discount: product.discount,
                      brand: product.brand,
                      isFreeCupEligible: product.isFreeCupEligible,
                    );

              return Container(
                width: cardWidth,
                margin: EdgeInsets.only(right: context.w(12)),
                child: UnifiedProductCard.fromProduct(
                  validProduct,
                  onTap: () => _showProductDetailsFromProduct(validProduct),
                  onCartUpdated: _refreshBuyAgainCards,
                  cardWidth: cardWidth,
                  imageHeight: carouselHeight,
                  // The Free Cup badge is already shown on the image via InfiniteCarousel
                  // No need to pass showFreeCupBadge here
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showProductDetailsFromProduct(Product product) {
    _logDebug('📱 Showing product details for: ${product.name}');

    final recommendedProduct = RecommendedProduct(
      id: product.id,
      franchiseId: product.isWarehouseProduct
          ? ''
          : (ShopService.selectedShopId ?? ''),
      productName: product.name,
      category: product.category,
      brand: product.brand,
      weightKg: 0,
      gramsG: 0,
      lengthCm: 0,
      widthCm: 0,
      productsImages: product.productsImages,
      shortDescription: '',
      longDescription: product.name,
      gstRate: 18,
      amount: product.price,
      cgst: 0,
      sgst: 0,
      total: product.price,
      freeCupEligibility: product.isFreeCupEligible,
      showGst: true,
      tags: '',
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
          _logDebug('🔄 Cart updated, refreshing');
          setState(() {});
          _refreshBuyAgainCards();
        },
      ),
    );
  }

  Widget _buildPremiumLoadingSkeleton() {
    _logDebug('⏳ Building loading skeleton');

    return ListView(
      padding: EdgeInsets.only(bottom: context.h(32)),
      children: [
        _buildPremiumHeader(),
        SizedBox(height: context.h(24)),
        for (var i = 0; i < 4; i++) ...[_buildPremiumSectionSkeleton()],
      ],
    );
  }

  Widget _buildPremiumSectionSkeleton() {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.w(20)),
          child: Container(
            width: context.w(150),
            height: context.h(24),
            decoration: BoxDecoration(
              color: theme.white,
              borderRadius: BorderRadius.circular(context.r(6)),
            ),
          ),
        ),
        SizedBox(height: context.h(16)),
        SizedBox(
          height: context.h(290),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: context.w(20)),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                width: isTablet ? context.w(200) : context.w(160),
                margin: EdgeInsets.only(right: context.w(16)),
                decoration: BoxDecoration(
                  color: theme.white,
                  borderRadius: BorderRadius.circular(context.r(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: context.r(16),
                    ),
                  ],
                ),
                child: PremiumShimmerEffect(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: isTablet ? context.h(180) : context.h(160),
                        decoration: BoxDecoration(
                          color: theme.greenBg,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(context.r(20)),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(context.w(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: context.w(60),
                              height: context.h(12),
                              decoration: BoxDecoration(
                                color: theme.white,
                                borderRadius: BorderRadius.circular(
                                  context.r(6),
                                ),
                              ),
                            ),
                            SizedBox(height: context.h(8)),
                            Container(
                              width: context.w(120),
                              height: context.h(16),
                              decoration: BoxDecoration(
                                color: theme.white,
                                borderRadius: BorderRadius.circular(
                                  context.r(6),
                                ),
                              ),
                            ),
                            SizedBox(height: context.h(12)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: context.w(60),
                                  height: context.h(20),
                                  decoration: BoxDecoration(
                                    color: theme.white,
                                    borderRadius: BorderRadius.circular(
                                      context.r(6),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: context.w(40),
                                  height: context.w(40),
                                  decoration: BoxDecoration(
                                    color: theme.white,
                                    borderRadius: BorderRadius.circular(
                                      context.r(12),
                                    ),
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
            },
          ),
        ),
        SizedBox(height: context.h(32)),
      ],
    );
  }
}
