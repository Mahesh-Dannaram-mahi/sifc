import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'dart:async';
import '../Shop_page/widgets/products_details_page.dart';
import '../models/recommended_product.dart';
import '../services/api_service.dart';
import '../services/shop_service.dart';
import '../services/storage_service.dart';
import '../services/jwt_service.dart';
import '../services/recommended_products_service.dart';
import '../config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Shop_page/widgets/infinite_carousel.dart';
import '../models/product.dart';
import '../theme/sipora_theme.dart';
import '../utils/screen_utils.dart';
import '../Shop_page/shop_page.dart';
import '../Home_page/home_page.dart';
import '../Home_page/widgets/bottom_nav_text_row.dart';
import 'widgets/recent_popular_searches.dart';
import '../Shop_page/widgets/product_list_page.dart';
import '../Cart_page/widgets/unified_product_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<RecommendedProduct> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _currentSearchQuery;
  Timer? _debounceTimer;

  Map<String, List<Product>> _productsByCategory = {};
  final Map<String, String> _subcategoryToCategoryMap = {};
  bool _isCategoriesLoading = true;
  String? _categoriesError;

  List<RecommendedProduct> _recommendedProducts = [];
  bool _recommendedLoading = false;

  String _currentSortOption = 'default';

  List<String> _popularSearches = [
    'Cold Coffee',
    'Cappuccino',
    'Mocha',
    'Green Tea',
    'Vanilla Shake',
    'Caramel Latte',
    'Espresso',
    'Masala Chai',
    'Iced Tea',
    'Hot Chocolate',
    'Frappuccino',
    'Matcha Latte',
  ];

  List<String> _recentSearches = [
    'Vanilla Cold Coffee',
    'Green Tea',
    'Hazelnut Latte',
    'Americano',
    'Chocolate Shake',
    'Blueberry Smoothie',
    'Caramel Macchiato',
    'Flat White',
  ];
  final Map<String, RecommendedProduct> _recentSearchProducts = {};
  final Map<String, RecommendedProduct> _popularSearchProducts = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
    _fetchCategoriesData();
    _loadRecommendedProducts();
    _loadRecentAndPopularSearches();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchCategoriesData() async {
    setState(() {
      _isCategoriesLoading = true;
      _categoriesError = null;
    });

    try {
      final franchiseId = ShopService.selectedShopId;
      if (franchiseId == null) {
        throw Exception('No shop selected');
      }

      String? userId;
      final token = await StorageService.getToken();
      if (token != null) {
        userId = JwtService.extractUserId(token);
      }

      userId ??= await StorageService.getUserId();

      if (userId == null) {
        throw Exception('User ID not found');
      }

      final url =
          '${ApiConfig.baseUrl}/api/product/get-products-for-mobile?user_id=$userId&franchise_id=$franchiseId';

      final response = await http.get(
        Uri.parse(url),
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
                    if (!productsBySubcategory.containsKey(subCategory)) {
                      productsBySubcategory[subCategory] = [];
                    }
                    productsBySubcategory[subCategory]!.add(mappedProduct);
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
                    if (!productsBySubcategory.containsKey(subCategory)) {
                      productsBySubcategory[subCategory] = [];
                    }
                    productsBySubcategory[subCategory]!.add(mappedProduct);
                  }
                  _subcategoryToCategoryMap[subCategory] = category;
                }
              });
            }
          });

          if (mounted) {
            setState(() {
              _productsByCategory = productsBySubcategory;
              _isCategoriesLoading = false;
            });
          }
        } else {
          setState(() {
            _isCategoriesLoading = false;
            _categoriesError = 'Failed to load categories';
          });
        }
      } else {
        setState(() {
          _isCategoriesLoading = false;
          _categoriesError = 'Failed to load categories';
        });
      }
    } catch (e) {
      setState(() {
        _isCategoriesLoading = false;
        _categoriesError = e.toString();
      });
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
      image: imageUrl.isNotEmpty ? imageUrl : ApiConfig.placeholderImageUrl,
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

  Future<void> _loadRecommendedProducts() async {
    if (!ShopService.hasSelectedShop()) return;

    setState(() {
      _recommendedLoading = true;
    });

    try {
      final products =
          await RecommendedProductsService.fetchRecommendedProductsForCurrentUser();

      if (mounted) {
        setState(() {
          _recommendedProducts = products;
          _recommendedLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _recommendedLoading = false;
          _recommendedProducts = [];
        });
      }
    }
  }

  void _showProductDetails(RecommendedProduct product) {
    _trackRecentProduct(product);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailsPage(
        product: product,
        onCartUpdated: () {
          setState(() {});
        },
      ),
    );
  }

  void _navigateToShopPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ShopPage()),
    );
  }

  void _onSearchChanged(String query) {
    setState(() {});
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _hasSearched = false;
        _searchResults = [];
        _currentSearchQuery = null;
        _currentSortOption = 'default';
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _currentSearchQuery = query;
      _currentSortOption = 'default';
    });

    try {
      final results = await ApiService.searchProducts(
        query,
        franchiseId: ShopService.selectedShopId,
      );
      setState(() {
        _searchResults = _rankSearchResults(query, results);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: SiporaTheme.greenDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.r(12)),
            ),
          ),
        );
      }
    }
  }

  Future<String?> _getCurrentUserId() async {
    final token = await StorageService.getToken();
    if (token != null) {
      final tokenUserId = JwtService.extractUserId(token);
      if (tokenUserId != null && tokenUserId.isNotEmpty) return tokenUserId;
    }
    return StorageService.getUserId();
  }

  Future<void> _loadRecentAndPopularSearches() async {
    try {
      final userId = await _getCurrentUserId();
      final futures = await Future.wait([
        if (userId != null)
          ApiService.fetchRecentSearches(userId)
        else
          Future.value(<RecommendedProduct>[]),
        ApiService.fetchPopularSearches(),
      ]);

      final recentProducts = futures[0];
      final popularProducts = futures[1];

      if (!mounted) return;
      setState(() {
        if (recentProducts.isNotEmpty) {
          _recentSearchProducts
            ..clear()
            ..addEntries(recentProducts.map((p) => MapEntry(p.productName, p)));
          _recentSearches = recentProducts.map((p) => p.productName).toList();
        }

        if (popularProducts.isNotEmpty) {
          _popularSearchProducts
            ..clear()
            ..addEntries(
              popularProducts.map((p) => MapEntry(p.productName, p)),
            );
          _popularSearches = popularProducts.map((p) => p.productName).toList();
        }
      });
    } catch (_) {}
  }

  Future<void> _trackRecentProduct(RecommendedProduct product) async {
    if (product.id.isEmpty) return;
    final userId = await _getCurrentUserId();
    if (userId == null || userId.isEmpty) return;

    try {
      await ApiService.updateRecentSearch(
        userId: userId,
        productId: product.id,
      );
      await _loadRecentAndPopularSearches();
    } catch (_) {}
  }

  List<RecommendedProduct> _rankSearchResults(
    String query,
    List<RecommendedProduct> products,
  ) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return products;

    int score(RecommendedProduct product) {
      final name = product.productName.toLowerCase();
      final category = product.category.toLowerCase();
      final brand = product.brand.toLowerCase();
      final tags = product.tags.toLowerCase();
      final description = product.displayDescription.toLowerCase();

      if (name == normalizedQuery) return 0;
      if (name.startsWith(normalizedQuery)) return 1;
      if (name.contains(normalizedQuery)) return 2;
      if (category.startsWith(normalizedQuery)) return 3;
      if (category.contains(normalizedQuery)) return 4;
      if (brand.contains(normalizedQuery)) return 5;
      if (tags.contains(normalizedQuery)) return 6;
      if (description.contains(normalizedQuery)) return 7;
      return 999;
    }

    final ranked = products.toList();
    ranked.sort((a, b) {
      final scoreCompare = score(a).compareTo(score(b));
      if (scoreCompare != 0) return scoreCompare;
      return a.productName.compareTo(b.productName);
    });
    return ranked;
  }

  void _applySort(String sortOption) {
    setState(() {
      _currentSortOption = sortOption;
      switch (sortOption) {
        case 'price_asc':
          _searchResults.sort(
            (a, b) => a.sellingPrice.compareTo(b.sellingPrice),
          );
          break;
        case 'price_desc':
          _searchResults.sort(
            (a, b) => b.sellingPrice.compareTo(a.sellingPrice),
          );
          break;
        case 'name_asc':
          _searchResults.sort((a, b) => a.productName.compareTo(b.productName));
          break;
        case 'name_desc':
          _searchResults.sort((a, b) => b.productName.compareTo(a.productName));
          break;
        default:
          break;
      }
    });
  }

  void _showFilterOptions() {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(context.r(24)),
          ),
          boxShadow: [
            BoxShadow(
              color: SiporaTheme.shadowLight,
              blurRadius: 20.r,
              offset: Offset(0, -4.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: context.h(12)),
              width: context.w(40),
              height: context.h(4),
              decoration: BoxDecoration(
                color: theme.border,
                borderRadius: BorderRadius.circular(context.r(2)),
              ),
            ),
            SizedBox(height: context.h(20)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(20)),
              child: Row(
                children: [
                  Icon(
                    Icons.sort_rounded,
                    color: SiporaTheme.greenDark,
                    size: isTablet ? context.w(26) : context.w(22),
                  ),
                  SizedBox(width: context.w(12)),
                  Text(
                    'Sort by',
                    style: TextStyle(
                      fontSize: isTablet ? context.sp(20) : context.sp(18),
                      fontWeight: FontWeight.w700,
                      color: theme.textDark,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.h(12)),
            _buildSortOptionTile(
              'Price: Low to High',
              'price_asc',
              Icons.arrow_upward_rounded,
            ),
            _buildSortOptionTile(
              'Price: High to Low',
              'price_desc',
              Icons.arrow_downward_rounded,
            ),
            _buildSortOptionTile(
              'Name: A to Z',
              'name_asc',
              Icons.sort_by_alpha_rounded,
            ),
            _buildSortOptionTile(
              'Name: Z to A',
              'name_desc',
              Icons.sort_by_alpha_rounded,
              reversed: true,
            ),
            if (_currentSortOption != 'default') ...[
              Divider(
                height: context.h(24),
                thickness: 1.w,
                color: theme.border,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.w(20)),
                child: TextButton(
                  onPressed: () {
                    _applySort('default');
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Sort order reset to default'),
                        backgroundColor: SiporaTheme.greenPill,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: SiporaTheme.greenDark,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restart_alt_rounded, size: context.w(18)),
                      SizedBox(width: context.w(8)),
                      Text('Reset to Default'),
                    ],
                  ),
                ),
              ),
            ],
            SizedBox(height: context.h(20)),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOptionTile(
    String title,
    String value,
    IconData icon, {
    bool reversed = false,
  }) {
    final theme = context.siporaTheme;
    final isSelected = _currentSortOption == value;
    final isTablet = context.isTablet;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? SiporaTheme.greenDark : theme.textMuted,
        size: isTablet ? context.w(24) : context.w(20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: isTablet ? context.sp(16) : context.sp(15),
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? SiporaTheme.greenDark : theme.textDark,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle_rounded,
              color: SiporaTheme.greenDark,
              size: isTablet ? context.w(24) : context.w(20),
            )
          : null,
      onTap: () {
        _applySort(value);
        Navigator.pop(context);
      },
    );
  }

  void _removeRecentSearch(String item) {
    setState(() => _recentSearches.remove(item));
  }

  void _clearAllRecentSearches() {
    setState(() => _recentSearches.clear());
  }

  void _applyQuickSearch(String term) {
    _searchController.text = term;
    final product = _recentSearchProducts[term] ?? _popularSearchProducts[term];
    if (product != null) {
      _trackRecentProduct(product);
    }
    _performSearch(term);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;

    return Scaffold(
      backgroundColor: theme.cream,
      appBar: _buildPremiumAppBar(),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                strokeWidth: 3.w,
                color: SiporaTheme.greenDark,
              ),
            )
          : _hasSearched
          ? _buildSearchResultsView()
          : _buildDefaultView(),
      bottomNavigationBar: const BottomNavTextRow(currentPage: 'search'),
    );
  }

  PreferredSizeWidget _buildPremiumAppBar() {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;
    final iconSize = isTablet ? context.w(28) : context.w(24);
    final fontSize = isTablet ? context.sp(16) : context.sp(14);

    return AppBar(
      backgroundColor: theme.cream,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      leadingWidth: isTablet ? context.w(56) : context.w(48),
      leading: GestureDetector(
        onTap: () {
          // FIXED: Check if can pop, otherwise navigate to home
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            // If no previous page, go to HomePage
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        },
        child: Container(
          margin: EdgeInsets.all(context.w(8)),
          padding: EdgeInsets.all(context.w(8)),
          decoration: BoxDecoration(
            color: theme.white,
            border: Border.all(color: theme.border, width: 1.5.w),
            borderRadius: BorderRadius.circular(context.r(12)),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.textDark,
            size: iconSize - 4,
          ),
        ),
      ),
      title: Container(
        height: isTablet ? context.h(50) : context.h(44),
        decoration: BoxDecoration(
          color: theme.white,
          borderRadius: BorderRadius.circular(context.r(12)),
          border: Border.all(color: theme.border, width: 1.5.w),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            primaryColor: SiporaTheme.greenDark,
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: SiporaTheme.greenDark,
              secondary: SiporaTheme.greenMid,
            ),
            textSelectionTheme: const TextSelectionThemeData(
              cursorColor: SiporaTheme.greenDark,
              selectionColor: SiporaTheme.greenBg,
              selectionHandleColor: SiporaTheme.greenDark,
            ),
            inputDecorationTheme: const InputDecorationTheme(
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: SiporaTheme.greenDark),
              ),
            ),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            cursorColor: SiporaTheme.greenDark,
            decoration: InputDecoration(
              hintText: 'Search products, brands & categories...',
              hintStyle: TextStyle(fontSize: fontSize, color: theme.textMuted),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: theme.textMuted,
                size: iconSize - 2,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        color: theme.textMuted,
                        size: iconSize - 4,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.w(12),
                vertical: context.h(10),
              ),
            ),
            style: TextStyle(fontSize: fontSize, color: theme.textDark),
            onChanged: _onSearchChanged,
            onSubmitted: (v) {
              if (v.trim().isNotEmpty) _performSearch(v.trim());
            },
          ),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: _showFilterOptions,
          child: Container(
            margin: EdgeInsets.only(right: context.w(16)),
            padding: EdgeInsets.all(context.w(8)),
            decoration: BoxDecoration(
              color: theme.white,
              border: Border.all(color: theme.border, width: 1.5.w),
              borderRadius: BorderRadius.circular(context.r(12)),
            ),
            child: Icon(
              Icons.tune_rounded,
              color: theme.textDark,
              size: iconSize - 4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultView() {
    return ListView(
      clipBehavior: Clip.none,
      padding: EdgeInsets.only(bottom: context.h(0)),
      children: [
        SizedBox(height: context.h(28)),
        RecentPopularSearches(
          recentSearches: _recentSearches,
          popularSearches: _popularSearches,
          onSearchTap: _applyQuickSearch,
          onRemoveRecent: _removeRecentSearch,
          onClearAllRecent: _clearAllRecentSearches,
        ),
        SizedBox(height: context.h(24)),
        _buildPremiumBrowseByCategories(),
        SizedBox(height: context.h(24)),
        _buildYouMightLikeSection(),
        SizedBox(height: context.h(24)),
        _buildPremiumBottomBanner(),
        SizedBox(height: context.h(16)),
      ],
    );
  }

  Widget _buildPremiumBrowseByCategories() {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;
    final screenPadding = context.w(16);
    final gridSpacing = context.h(12);
    final cardRadius = context.r(16);
    final cardPadding = context.w(16);

    if (_isCategoriesLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Browse by Categories',
                  style: TextStyle(
                    fontSize: isTablet ? context.sp(18) : context.sp(16),
                    fontWeight: FontWeight.w700,
                    color: theme.textDark,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'View all',
                        style: TextStyle(
                          color: SiporaTheme.greenPill,
                          fontSize: context.sp(14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: context.w(16),
                        color: SiporaTheme.greenPill,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: gridSpacing * 2),
            SizedBox(
              height: isTablet ? context.h(240) : context.h(200),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: screenPadding),
                itemCount: 4,
                itemBuilder: (context, index) {
                  return Container(
                    width: isTablet ? context.w(200) : context.w(160),
                    margin: EdgeInsets.only(right: gridSpacing * 2),
                    padding: EdgeInsets.all(cardPadding),
                    decoration: BoxDecoration(
                      color: theme.white,
                      borderRadius: BorderRadius.circular(cardRadius),
                      boxShadow: [
                        BoxShadow(
                          color: SiporaTheme.shadowLight.withValues(
                            alpha: 0.08,
                          ),
                          blurRadius: 16.r,
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
                      children: [
                        Container(
                          width: double.infinity,
                          height: isTablet ? context.h(120) : context.h(100),
                          decoration: BoxDecoration(
                            color: SiporaTheme.greenBg,
                            borderRadius: BorderRadius.circular(context.r(12)),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.w,
                              color: SiporaTheme.greenDark,
                            ),
                          ),
                        ),
                        SizedBox(height: context.h(8)),
                        Container(
                          width: context.w(100),
                          height: context.sp(14),
                          color: SiporaTheme.greenBg,
                        ),
                        SizedBox(height: gridSpacing * 0.5),
                        Container(
                          width: context.w(60),
                          height: context.sp(12),
                          color: SiporaTheme.greenBg,
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

    if (_categoriesError != null || _productsByCategory.isEmpty) {
      return const SizedBox.shrink();
    }

    final categories = _productsByCategory.entries.map((entry) {
      final products = entry.value;
      return {
        'products': products,
        'label': entry.key,
        'count': '${entry.value.length} items',
      };
    }).toList();

    if (categories.isEmpty) return const SizedBox.shrink();

    final double cardWidth = isTablet ? context.w(200) : context.w(160);
    final double carouselHeight = isTablet ? context.h(120) : context.h(100);
    final double carouselWidth = isTablet ? context.w(180) : context.w(140);

    final double categoryFontSize = isTablet
        ? context.sp(16)
        : (context.isSmallScreen ? context.sp(11) : context.sp(13));
    final double countFontSize = isTablet
        ? context.sp(12)
        : (context.isSmallScreen ? context.sp(9) : context.sp(10));

    Set<String> getAvailableSubcategories() {
      return _productsByCategory.keys.toSet();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Browse by Categories',
                style: TextStyle(
                  fontSize: isTablet ? context.sp(18) : context.sp(16),
                  fontWeight: FontWeight.w700,
                  color: theme.textDark,
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                        color: SiporaTheme.greenPill,
                        fontSize: context.sp(14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: context.w(16),
                      color: SiporaTheme.greenPill,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: gridSpacing * 2),
          SizedBox(
            height: isTablet ? context.h(240) : context.h(200),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
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
                          allProductsByCategory: _productsByCategory,
                          subcategoryToCategoryMap: _subcategoryToCategoryMap,
                          availableSubcategories: getAvailableSubcategories(),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: cardWidth,
                    margin: EdgeInsets.only(right: gridSpacing * 2),
                    padding: EdgeInsets.all(cardPadding),
                    decoration: BoxDecoration(
                      color: theme.white,
                      borderRadius: BorderRadius.circular(cardRadius),
                      boxShadow: [
                        BoxShadow(
                          color: SiporaTheme.shadowLight.withValues(
                            alpha: 0.08,
                          ),
                          blurRadius: 16.r,
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
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: carouselHeight,
                          child: InfiniteCarousel(
                            products: products,
                            type: CarouselType.card,
                            height: carouselHeight,
                            width: carouselWidth,
                            borderRadius: cardRadius - 4.r,
                            showDots: false,
                            showCounter: false,
                            showOverlay: false,
                            autoSlideDuration: const Duration(seconds: 3),
                            animationDuration: const Duration(
                              milliseconds: 500,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductListPage(
                                    category: categoryName,
                                    allProductsByCategory: _productsByCategory,
                                    subcategoryToCategoryMap:
                                        _subcategoryToCategoryMap,
                                    availableSubcategories:
                                        getAvailableSubcategories(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: context.h(8)),
                        Text(
                          categoryName,
                          style: TextStyle(
                            fontSize: categoryFontSize,
                            fontWeight: FontWeight.w600,
                            color: theme.textDark,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: gridSpacing * 0.5),
                        Text(
                          category['count'] as String,
                          style: TextStyle(
                            fontSize: countFontSize,
                            fontWeight: FontWeight.w500,
                            color: theme.greenMid,
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
      ),
    );
  }

  Widget _buildYouMightLikeSection() {
    final theme = context.siporaTheme;
    final screenPadding = context.w(16);
    final gridSpacing = context.h(12);
    final isTablet = context.isTablet;

    if (_recommendedLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenPadding),
            child: Text(
              'You might like',
              style: TextStyle(
                fontSize: isTablet ? context.sp(18) : context.sp(16),
                fontWeight: FontWeight.w700,
                color: theme.textDark,
              ),
            ),
          ),
          SizedBox(height: gridSpacing),
          SizedBox(
            height: isTablet ? context.h(240) : context.h(200),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: screenPadding),
              itemCount: 3,
              itemBuilder: (context, index) =>
                  _buildRecommendedProductSkeleton(),
            ),
          ),
        ],
      );
    }

    if (_recommendedProducts.isEmpty && !_recommendedLoading) {
      return const SizedBox.shrink();
    }

    final double cardWidth = isTablet ? context.w(200) : context.w(160);
    final double carouselHeight = isTablet ? context.h(120) : context.h(100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenPadding),
          child: Text(
            'You might like',
            style: TextStyle(
              fontSize: isTablet ? context.sp(18) : context.sp(16),
              fontWeight: FontWeight.w700,
              color: theme.textDark,
            ),
          ),
        ),
        SizedBox(height: gridSpacing * 2),
        SizedBox(
          height: isTablet ? context.h(240) : context.h(200),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: screenPadding),
            itemCount: _recommendedProducts.length,
            itemBuilder: (context, index) {
              final product = _recommendedProducts[index];
              return UnifiedProductCard.fromRecommendedProduct(
                product,
                onTap: () => _showProductDetails(product),
                onCartUpdated: () => setState(() {}),
                cardWidth: cardWidth,
                imageHeight: carouselHeight,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedProductSkeleton() {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;
    final double cardWidth = isTablet ? context.w(200) : context.w(160);
    final double carouselHeight = isTablet ? context.h(120) : context.h(100);

    return Container(
      width: cardWidth,
      margin: EdgeInsets.only(right: context.w(16)),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(context.r(16)),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: carouselHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: SiporaTheme.greenBg,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(context.r(20)),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.coffee,
                size: context.w(40),
                color: SiporaTheme.greenLight.withValues(alpha: 0.5),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(context.w(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: context.w(50),
                  height: context.h(8),
                  decoration: BoxDecoration(
                    color: theme.border.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(context.r(4)),
                  ),
                ),
                SizedBox(height: context.h(6)),
                Container(
                  width: context.w(100),
                  height: context.h(10),
                  decoration: BoxDecoration(
                    color: theme.border.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(context.r(4)),
                  ),
                ),
                SizedBox(height: context.h(8)),
                Container(
                  width: context.w(50),
                  height: context.h(12),
                  decoration: BoxDecoration(
                    color: theme.border.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(context.r(4)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBottomBanner() {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;
    final fontSize = isTablet ? context.sp(16) : context.sp(14);
    final smallFontSize = isTablet ? context.sp(12) : context.sp(12);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(20)),
      child: SizedBox(
        height: isTablet ? context.h(140) : context.h(110),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [SiporaTheme.greenBg, theme.white],
                  ),
                  borderRadius: BorderRadius.circular(context.r(20)),
                  boxShadow: [
                    BoxShadow(
                      color: SiporaTheme.shadowLight,
                      blurRadius: 20.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                  border: Border.all(color: theme.border, width: 1.w),
                ),
              ),
            ),
            Positioned(
              right: -4.w,
              top: -30.h,
              bottom: -20.h,
              child: Image.network(
                'https://siporaimagescollection.blob.core.windows.net/websiteimages/MobileApp/Tea_Cup_for_shop-removebg.png',
                width: isTablet ? context.w(200) : context.w(160),
                fit: BoxFit.contain,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.coffee_rounded,
                  size: isTablet ? context.w(80) : context.w(70),
                  color: SiporaTheme.greenDark,
                ),
              ),
            ),
            Positioned(
              left: context.w(20),
              top: 0,
              bottom: 0,
              right: isTablet ? context.w(160) : context.w(120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Can't find what you're looking for?",
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                      color: theme.textDark,
                      letterSpacing: -0.3,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: context.h(4)),
                  Text(
                    'Browse all products and find your perfect cup!',
                    style: TextStyle(
                      fontSize: smallFontSize,
                      color: theme.textMuted,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: context.h(8)),
                  ElevatedButton(
                    onPressed: _navigateToShopPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SiporaTheme.greenDark,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(12),
                        vertical: context.h(6),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.r(30)),
                      ),
                      elevation: 0,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Browse All Products',
                      style: TextStyle(
                        fontSize: isTablet ? context.sp(13) : context.sp(12),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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

  Widget _buildSearchResultsView() {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = context.w(20) * 2;
    final spacing = context.w(16);
    final availableWidth = screenWidth - horizontalPadding - spacing;
    final double cardWidth = availableWidth / 2;
    final double carouselHeight = isTablet ? context.h(200) : context.h(160);

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(context.w(24)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [SiporaTheme.greenBg, SiporaTheme.greenBg],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: isTablet ? context.w(70) : context.w(50),
                color: SiporaTheme.greenDark,
              ),
            ),
            SizedBox(height: context.h(20)),
            Text(
              'No products found for "$_currentSearchQuery"',
              style: TextStyle(
                fontSize: isTablet ? context.sp(22) : context.sp(18),
                fontWeight: FontWeight.w700,
                color: theme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.h(8)),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
                fontSize: isTablet ? context.sp(16) : context.sp(14),
                color: theme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(context.w(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(12),
                  vertical: context.h(6),
                ),
                decoration: BoxDecoration(
                  color: SiporaTheme.greenBg,
                  borderRadius: BorderRadius.circular(context.r(20)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: isTablet ? context.w(20) : context.w(16),
                      color: SiporaTheme.greenPill,
                    ),
                    SizedBox(width: context.w(6)),
                    Text(
                      '${_searchResults.length} results',
                      style: TextStyle(
                        fontSize: isTablet ? context.sp(15) : context.sp(14),
                        fontWeight: FontWeight.w600,
                        color: SiporaTheme.greenPill,
                      ),
                    ),
                  ],
                ),
              ),
              if (_currentSortOption != 'default')
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(10),
                    vertical: context.h(4),
                  ),
                  decoration: BoxDecoration(
                    color: SiporaTheme.greenDark.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(context.r(16)),
                    border: Border.all(
                      color: SiporaTheme.greenDark.withValues(alpha: 0.3),
                      width: 1.w,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sort_rounded,
                        size: isTablet ? context.w(20) : context.w(16),
                        color: SiporaTheme.greenDark,
                      ),
                      SizedBox(width: context.w(4)),
                      Text(
                        _getSortLabel(_currentSortOption),
                        style: TextStyle(
                          fontSize: isTablet ? context.sp(13) : context.sp(12),
                          color: theme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.w(16)),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: cardWidth / (carouselHeight + context.h(90)),
                crossAxisSpacing: context.w(12),
                mainAxisSpacing: context.h(12),
              ),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final product = _searchResults[index];
                return UnifiedProductCard.fromRecommendedProduct(
                  product,
                  onTap: () => _showProductDetails(product),
                  onCartUpdated: () => setState(() {}),
                  cardWidth: cardWidth,
                  imageHeight: carouselHeight,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  String _getSortLabel(String option) {
    switch (option) {
      case 'price_asc':
        return 'Price ↑';
      case 'price_desc':
        return 'Price ↓';
      case 'name_asc':
        return 'Name A–Z';
      case 'name_desc':
        return 'Name Z–A';
      default:
        return '';
    }
  }
}
