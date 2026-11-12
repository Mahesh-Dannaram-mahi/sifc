import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/recommended_product.dart';
import '../theme/sipora_theme.dart';
import '../utils/responsive_constants.dart';
import '../utils/image_utils.dart';
import '../Shop_page/widgets/products_details_page.dart';
import '../Cart_page/widgets/unified_product_card.dart';

class ShopProductsPage extends StatefulWidget {
  final String shopName;
  final String shopId;
  final Map<String, List<Product>> productsByCategory;

  const ShopProductsPage({
    super.key,
    required this.shopName,
    required this.shopId,
    required this.productsByCategory,
  });

  @override
  State<ShopProductsPage> createState() => _ShopProductsPageState();
}

class _ShopProductsPageState extends State<ShopProductsPage> {
  late Map<String, List<Product>> _filteredProductsByCategory;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _filteredProductsByCategory = Map.from(widget.productsByCategory);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase().trim();
      _filterProducts();
    });
  }

  void _filterProducts() {
    if (_searchQuery.isEmpty) {
      _filteredProductsByCategory = Map.from(widget.productsByCategory);
      return;
    }

    final Map<String, List<Product>> filtered = {};

    widget.productsByCategory.forEach((category, products) {
      final matchingProducts = products
          .where(
            (product) =>
                product.name.toLowerCase().contains(_searchQuery) ||
                product.brand.toLowerCase().contains(_searchQuery) ||
                category.toLowerCase().contains(_searchQuery),
          )
          .toList();

      if (matchingProducts.isNotEmpty) {
        filtered[category] = matchingProducts;
      }
    });

    _filteredProductsByCategory = filtered;
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _filteredProductsByCategory = Map.from(widget.productsByCategory);
      _isSearchVisible = false;
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        _searchQuery = '';
        _filteredProductsByCategory = Map.from(widget.productsByCategory);
      }
    });
  }

  void _refreshBuyAgainCards() {
    setState(() {});
  }

  RecommendedProduct _convertToRecommendedProduct(Product product) {
    List<String> allImages = [];

    if (product.productsImages.isNotEmpty) {
      if (product.productsImages.contains(',')) {
        allImages = product.productsImages
            .split(',')
            .map((img) => img.trim())
            .toList();
      } else {
        allImages = [product.productsImages];
      }
    } else if (product.image.isNotEmpty) {
      allImages = [product.image];
    }

    // Use placeholder from ImageUtils if no images
    if (allImages.isEmpty) {
      allImages = [ImageUtils.fallbackImagePath];
    }

    // Validate all images
    allImages = allImages.map((url) => ImageUtils.getValidImageUrl(url)).toList();

    return RecommendedProduct(
      id: product.id,
      franchiseId: widget.shopId,
      productName: product.name,
      category: _getCategoryForProduct(product),
      brand: product.brand,
      weightKg: _extractWeightKg(product.weight),
      gramsG: _extractGramsG(product.weight),
      lengthCm: 0,
      widthCm: 0,
      productsImages: allImages.join(','),
      shortDescription: product.brand,
      longDescription: product.name,
      gstRate: 18,
      amount: product.price,
      cgst: 0,
      sgst: 0,
      total: product.price,
      freeCupEligibility: product.isFreeCupEligible,
      showGst: true,
      tags: product.brand,
      createdAt: DateTime.now(),
      purchaseCount: 0,
    );
  }

  double _extractWeightKg(String weightStr) {
    if (weightStr.contains('kg')) {
      final value = weightStr.replaceAll('kg', '').trim();
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  int _extractGramsG(String weightStr) {
    if (weightStr.contains('g') && !weightStr.contains('kg')) {
      final value = weightStr.replaceAll('g', '').trim();
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  String _getCategoryForProduct(Product product) {
    for (final category in widget.productsByCategory.keys) {
      if (product.name.toLowerCase().contains(category.toLowerCase()) ||
          product.brand.toLowerCase().contains(category.toLowerCase())) {
        return category;
      }
    }
    return 'Products';
  }

  void _showProductDetails(Product product) {
    final recommendedProduct = _convertToRecommendedProduct(product);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailsPage(
        product: recommendedProduct,
        onCartUpdated: () {
          _refreshBuyAgainCards();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<SiporaThemeExtension>()!;
    final screenPadding = ResponsiveConstants.getScreenPadding(context);
    final gridSpacing = ResponsiveConstants.getGridSpacing(context);
    final isTablet = ResponsiveConstants.isTablet(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenPadding * 2;
    final spacing = gridSpacing * 2;
    final availableWidth = screenWidth - horizontalPadding - spacing;
    final double cardWidth = isTablet
        ? 200.0
        : (availableWidth / 2).clamp(140.0, 180.0);
    final double imageHeight = isTablet ? 160.0 : 140.0;
    final double cardHeight = imageHeight + (isTablet ? 110 : 95);

    return Scaffold(
      backgroundColor: theme.cream,
      appBar: AppBar(
        backgroundColor: theme.cream,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.shopName,
              style: TextStyle(
                fontSize: ResponsiveConstants.getTitleFontSize(context),
                fontWeight: FontWeight.w700,
                color: theme.textDark,
              ),
            ),
            Text(
              '${_getTotalProducts()} products',
              style: TextStyle(
                fontSize: ResponsiveConstants.getFontSize(context) - 2,
                color: theme.textMuted,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: theme.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: screenPadding),
            child: IconButton(
              onPressed: _toggleSearch,
              icon: Icon(
                _isSearchVisible ? Icons.close_rounded : Icons.search_rounded,
                color: SiporaTheme.greenDark,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearchVisible)
            _buildSearchBar(theme, screenPadding, gridSpacing),
          Expanded(
            child: _filteredProductsByCategory.isEmpty
                ? _buildEmptyState(theme, screenPadding, gridSpacing)
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_searchQuery.isNotEmpty && _isSearchVisible)
                          _buildSearchResultsHeader(
                            theme,
                            screenPadding,
                            gridSpacing,
                          ),
                        ..._filteredProductsByCategory.entries.map((entry) {
                          return _buildPremiumCategorySection(
                            entry.key,
                            entry.value,
                            cardWidth,
                            imageHeight,
                            cardHeight,
                            isTablet,
                          );
                        }),
                        SizedBox(height: gridSpacing * 4),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
    SiporaThemeExtension theme,
    double screenPadding,
    double gridSpacing,
  ) {
    return Padding(
      padding: EdgeInsets.all(screenPadding),
      child: Container(
        decoration: BoxDecoration(
          color: theme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: SiporaTheme.shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          cursorColor: SiporaTheme.greenDark,
          decoration: InputDecoration(
            hintText: 'Search products in ${widget.shopName}...',
            hintStyle: TextStyle(
              fontSize: ResponsiveConstants.getFontSize(context) - 2,
              color: theme.textMuted,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: SiporaTheme.greenDark,
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      size: 20,
                      color: theme.textMuted,
                    ),
                    onPressed: _clearSearch,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: gridSpacing * 2,
              vertical: gridSpacing * 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultsHeader(
    SiporaThemeExtension theme,
    double screenPadding,
    double gridSpacing,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenPadding,
        vertical: gridSpacing,
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20, color: SiporaTheme.greenDark),
          SizedBox(width: gridSpacing),
          Expanded(
            child: Text(
              'Search results for "$_searchQuery"',
              style: TextStyle(
                fontSize: ResponsiveConstants.getFontSize(context) - 1,
                fontWeight: FontWeight.w500,
                color: theme.textDark,
              ),
            ),
          ),
          TextButton(
            onPressed: _clearSearch,
            child: Text(
              'Clear',
              style: TextStyle(
                fontSize: ResponsiveConstants.getFontSize(context) - 2,
                color: SiporaTheme.greenDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    SiporaThemeExtension theme,
    double screenPadding,
    double gridSpacing,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: ResponsiveConstants.getIconSize(context) * 2.5,
            color: theme.textMuted.withValues(alpha: 0.3),
          ),
          SizedBox(height: gridSpacing * 2),
          Text(
            _searchQuery.isEmpty
                ? 'No products available'
                : 'No products found',
            style: TextStyle(
              fontSize: ResponsiveConstants.getTitleFontSize(context),
              fontWeight: FontWeight.w600,
              color: theme.textDark,
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            SizedBox(height: gridSpacing),
            Text(
              'Try a different search term',
              style: TextStyle(
                fontSize: ResponsiveConstants.getFontSize(context) - 1,
                color: theme.textMuted,
              ),
            ),
            SizedBox(height: gridSpacing * 2),
            TextButton(
              onPressed: _clearSearch,
              child: Text(
                'Clear search',
                style: TextStyle(color: SiporaTheme.greenDark),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPremiumCategorySection(
    String title,
    List<Product> products,
    double cardWidth,
    double imageHeight,
    double cardHeight,
    bool isTablet,
  ) {
    final theme = Theme.of(context).extension<SiporaThemeExtension>()!;
    final fontSize = ResponsiveConstants.getFontSize(context);
    final titleFontSize = ResponsiveConstants.getTitleFontSize(context);
    final gridSpacing = ResponsiveConstants.getGridSpacing(context);
    final screenPadding = ResponsiveConstants.getScreenPadding(context);

    // Create validated products with proper image URLs
    final validatedProducts = products.map((product) {
      if (product.image.isEmpty || product.image == 'null') {
        return Product(
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
        );
      }
      return product;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenPadding,
            vertical: gridSpacing * 1.5,
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: titleFontSize - 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [SiporaTheme.greenDark, SiporaTheme.greenPill],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: gridSpacing),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: theme.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: gridSpacing),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: SiporaTheme.greenBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${validatedProducts.length}',
                  style: TextStyle(
                    fontSize: fontSize - 2,
                    fontWeight: FontWeight.w600,
                    color: SiporaTheme.greenDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: cardHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: screenPadding),
            itemCount: validatedProducts.length,
            itemBuilder: (context, index) {
              final product = validatedProducts[index];
              // Use the unified product card
              return UnifiedProductCard.fromProduct(
                product,
                onTap: () => _showProductDetails(product),
                onCartUpdated: _refreshBuyAgainCards,
                cardWidth: cardWidth,
                imageHeight: imageHeight,
              );
            },
          ),
        ),
        SizedBox(height: gridSpacing * 2),
      ],
    );
  }

  int _getTotalProducts() {
    return widget.productsByCategory.values.fold(
      0,
      (sum, list) => sum + list.length,
    );
  }
}