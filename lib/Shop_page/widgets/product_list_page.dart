import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'products_details_page.dart';
import 'infinite_carousel.dart';

import '../../config/api_config.dart';

import '../../utils/screen_utils.dart';
import '../../utils/image_utils.dart';

import '../../theme/sipora_theme.dart';

import '../../Home_page/widgets/bottom_nav_text_row.dart';

import '../../models/product.dart';
import '../../models/recommended_product.dart';
import '../../models/tagged_product.dart';

import '../../services/storage_service.dart';
import '../../services/shop_service.dart';
import '../../services/jwt_service.dart';
import '../../services/error_handler_service.dart';

import '../../Cart_page/services/cart_helper_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Card layout constants
// ─────────────────────────────────────────────────────────────────────────────
class _Card {
  static const double mobileImage = 130.0;
  static const double tabletImage = 170.0;
  static const double mobileContent = 88.0;
  static const double tabletContent = 96.0;
  static const double borderRadius = 12.0;

  static bool _tab(BuildContext c) => c.isTablet;

  static double imageH(BuildContext c) =>
      _tab(c) ? c.h(tabletImage) : c.h(mobileImage);
  static double contentH(BuildContext c) =>
      _tab(c) ? c.h(tabletContent) : c.h(mobileContent);
  static double cardH(BuildContext c) => imageH(c) + contentH(c);
  static double brandSz(BuildContext c) => c.sp(12);
  static double nameSz(BuildContext c) => c.sp(14);
  static double priceSz(BuildContext c) => c.sp(16);
  static double gs(BuildContext c) => c.h(12);
  static double brandGap(BuildContext c) => gs(c) * 0.3;
}

// ─────────────────────────────────────────────────────────────────────────────

class ProductListPage extends StatefulWidget {
  final String category;
  final List<TaggedProduct>? tagProducts;
  final Map<String, List<Product>>? allProductsByCategory;
  final Map<String, String>? subcategoryToCategoryMap;
  final Set<String>? availableSubcategories;

  const ProductListPage({
    super.key,
    required this.category,
    this.tagProducts,
    this.allProductsByCategory,
    this.subcategoryToCategoryMap,
    this.availableSubcategories,
  });

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage>
    with SingleTickerProviderStateMixin {
  List<Product> filteredProducts = [];
  List<Product> allProducts = [];
  List<String> availableCategories = [];
  String selectedCategory = 'All Products';
  bool _isLoading = true;
  String? _errorMessage;

  late AnimationController _anim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.category;
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _loadProducts();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  // ── Data ─────────────────────────────────────────────────────────────────────

  Future<void> _loadProducts() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      if (widget.tagProducts?.isNotEmpty == true) {
        allProducts = widget.tagProducts!
            .map(
              (tp) => Product(
                id: tp.id,
                name: tp.productName,
                image: ImageUtils.getValidImageUrl(tp.firstImage),
                productsImages: tp.productsImages,
                weight: '${tp.gramsG}g',
                price: tp.total.roundToDouble(),
                mrp: (tp.total * 1.1).roundToDouble(),
                discount: '',
                brand: tp.brand,
                category: widget.category,
                isFreeCupEligible: tp.freeCupEligibility,
              ),
            )
            .toList();
        filteredProducts = List.from(allProducts);
        _setupCategories();
        _anim.forward();
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      if (widget.allProductsByCategory?.isNotEmpty == true) {
        _setupCategories();
        _filterByCategory();
        _anim.forward();
        if (mounted) setState(() => _isLoading = false);
      } else {
        await _fetchFromAPI();
        _anim.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = ErrorHandlerService.getErrorMessage(e);
          filteredProducts = [];
          _isLoading = false;
        });
        ErrorHandlerService.showErrorDialog(
          context,
          e,
          operationContext: 'loadProducts',
        );
      }
    }
  }

  void _setupCategories() {
    availableCategories = ['All Products'];
    if (widget.category != 'All Products') {
      availableCategories.add(widget.category);
    }
    if (widget.availableSubcategories?.isNotEmpty == true) {
      availableCategories.addAll(widget.availableSubcategories!);
    } else if (widget.allProductsByCategory != null) {
      availableCategories.addAll(widget.allProductsByCategory!.keys);
    }
    availableCategories = availableCategories.toSet().toList()
      ..sort(
        (a, b) => a == 'All Products'
            ? -1
            : b == 'All Products'
            ? 1
            : a.compareTo(b),
      );
  }

  void _filterByCategory() {
    setState(() {
      allProducts =
          widget.allProductsByCategory?.values.expand((e) => e).toList() ?? [];
      filteredProducts = selectedCategory == 'All Products'
          ? List.from(allProducts)
          : widget.allProductsByCategory?[selectedCategory] ?? [];
    });
  }

  Future<void> _fetchFromAPI() async {
    final franchiseId =
        ShopService.selectedShopId ?? (throw Exception('No franchise ID'));
    String? userId;
    final token = await StorageService.getToken();
    if (token != null) userId = JwtService.extractUserId(token);
    userId ??= await StorageService.getUserId();

    final queryParameters = <String, String>{'franchise_id': franchiseId};
    if (userId != null && userId.isNotEmpty) {
      queryParameters['user_id'] = userId;
    }
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/product/get-products-for-mobile',
    ).replace(queryParameters: queryParameters);
    final res = await http
        .get(uri, headers: {'accept': 'application/json'})
        .timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) {
      throw Exception('Failed to load products: ${res.statusCode}');
    }

    final data = json.decode(res.body);
    final Map<String, List<Product>> bySubcat = {};

    (data['grouped_franchise_products'] as Map? ?? {}).forEach((_, subs) {
      if (subs is Map<String, dynamic>) {
        subs.forEach((subCat, products) {
          if (products is List) {
            for (final p in products) {
              try {
                final mp = Product.fromApiMap(p);
                bySubcat
                    .putIfAbsent(subCat, () => [])
                    .add(
                      Product(
                        id: mp.id,
                        name: mp.name,
                        image: ImageUtils.getValidImageUrl(mp.image),
                        productsImages: mp.productsImages,
                        weight: mp.weight,
                        price: mp.price,
                        mrp: mp.mrp,
                        discount: mp.discount,
                        brand: mp.brand,
                        category: subCat,
                        isFreeCupEligible: mp.isFreeCupEligible,
                        isWarehouseProduct: mp.isWarehouseProduct,
                      ),
                    );
              } catch (_) {}
            }
          }
        });
      }
    });

    availableCategories = ['All Products', ...bySubcat.keys];
    allProducts = bySubcat.values.expand((e) => e).toList();
    filteredProducts = selectedCategory == 'All Products'
        ? List.from(allProducts)
        : bySubcat[selectedCategory] ?? [];

    if (mounted) setState(() => _isLoading = false);
  }

  // ── AppBar ───────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;

    return AppBar(
      backgroundColor: theme.cream,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: Container(
        margin: EdgeInsets.all(context.w(8)),
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
            size: isTablet ? context.w(26) : context.w(22),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Text(
        widget.category,
        style: TextStyle(
          fontSize: isTablet ? context.sp(20) : context.sp(18),
          fontWeight: FontWeight.w600,
          color: theme.textDark,
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: context.w(16)),
          padding: EdgeInsets.symmetric(
            horizontal: context.w(12),
            vertical: context.h(8),
          ),
          decoration: BoxDecoration(
            color: theme.greenBg,
            borderRadius: BorderRadius.circular(context.r(20)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: isTablet ? context.w(18) : context.w(16),
                color: SiporaTheme.greenPill,
              ),
              SizedBox(width: context.w(6)),
              Text(
                '${filteredProducts.length}',
                style: TextStyle(
                  fontSize: isTablet ? context.sp(15) : context.sp(14),
                  fontWeight: FontWeight.w600,
                  color: SiporaTheme.greenPill,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Root build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    return Scaffold(
      backgroundColor: theme.cream,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildSkeleton() : _buildBody(),
      bottomNavigationBar: const BottomNavTextRow(currentPage: 'shop'),
    );
  }

  // ── Body ─────────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(context.w(24)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: isTablet ? context.w(72) : context.w(56),
                color: SiporaTheme.greenDark,
              ),
              SizedBox(height: context.h(24)),
              Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: isTablet ? context.sp(16) : context.sp(14),
                  color: theme.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.h(24)),
              ElevatedButton(
                onPressed: _loadProducts,
                style: SiporaTheme.primaryButtonStyle(
                  radius: 30,
                  height: isTablet ? context.h(48) : context.h(40),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: isTablet ? context.sp(15) : context.sp(14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: isTablet ? context.w(80) : context.w(64),
              color: SiporaTheme.greenDark,
            ),
            SizedBox(height: context.h(24)),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: isTablet ? context.sp(20) : context.sp(18),
                fontWeight: FontWeight.w700,
                color: theme.textDark,
              ),
            ),
            SizedBox(height: context.h(12)),
            Text(
              'Check back later for new products',
              style: TextStyle(
                fontSize: isTablet ? context.sp(16) : context.sp(14),
                color: theme.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fade,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: context.h(32)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Category chips ────────────────────────────────────────────────
            if (availableCategories.length > 1) ...[
              SizedBox(height: context.h(16)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.w(20)),
                child: SizedBox(
                  height: context.h(40),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: availableCategories.length,
                    itemBuilder: (ctx, i) {
                      final cat = availableCategories[i];
                      final isSelected = cat == selectedCategory;
                      return Padding(
                        padding: EdgeInsets.only(right: context.w(8)),
                        child: FilterChip(
                          label: Text(
                            cat,
                            style: TextStyle(
                              fontSize: isTablet
                                  ? context.sp(13)
                                  : context.sp(11),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected ? Colors.white : theme.textDark,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (v) {
                            if (v) {
                              setState(() {
                                selectedCategory = cat;
                                _filterByCategory();
                              });
                            }
                          },
                          backgroundColor: theme.white,
                          selectedColor: SiporaTheme.greenPill,
                          checkmarkColor: Colors.white,
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.transparent
                                  : theme.goldBg,
                              width: 1.w,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            SizedBox(height: context.h(20)),

            // ── Grid ─────────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(20)),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: context.w(16),
                  mainAxisSpacing: context.h(16),
                  mainAxisExtent: _Card.cardH(context),
                ),
                itemCount: filteredProducts.length,
                itemBuilder: (ctx, i) => _buildCard(filteredProducts[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card ─────────────────────────────────────────────────────────────────────

  List<Product> _carousel(Product p) {
    final list = <Product>[p];
    if (p.productsImages.contains(',')) {
      for (final url in p.productsImages.split(',')) {
        final t = url.trim();
        if (t.isNotEmpty && t != p.image) {
          list.add(
            Product(
              id: p.id,
              name: p.name,
              image: ImageUtils.getValidImageUrl(t),
              productsImages: p.productsImages,
              weight: p.weight,
              price: p.price,
              mrp: p.mrp,
              discount: p.discount,
              brand: p.brand,
              category: p.category,
              isFreeCupEligible: p.isFreeCupEligible,
              isWarehouseProduct: p.isWarehouseProduct,
            ),
          );
        }
      }
    }
    return list;
  }

  Widget _buildFreeCupBadge() {
    final isTablet = context.isTablet;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(4),
        vertical: context.h(2),
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [SiporaTheme.gold, SiporaTheme.greenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(context.r(10)),
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
            size: isTablet ? context.w(10) : context.w(8),
          ),
          SizedBox(width: context.w(2)),
          Text(
            'FREE',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? context.sp(8) : context.sp(7),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Product raw) {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;
    final imgH = _Card.imageH(context);

    final resolvedImage = (raw.image.isEmpty || raw.image == 'null')
        ? ImageUtils.fallbackImagePath
        : ImageUtils.getValidImageUrl(raw.image);

    final product = Product(
      id: raw.id,
      name: raw.name,
      image: resolvedImage,
      productsImages: raw.productsImages,
      weight: raw.weight,
      price: raw.price,
      mrp: raw.mrp,
      discount: raw.discount,
      brand: raw.brand,
      category: raw.category,
      isFreeCupEligible: raw.isFreeCupEligible,
      isWarehouseProduct: raw.isWarehouseProduct,
    );

    final slides = _carousel(product);
    final hasMultipleImages = slides.length > 1;

    return GestureDetector(
      onTap: () => _showDetails(product),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_Card.borderRadius.r),
          boxShadow: [
            BoxShadow(
              color: SiporaTheme.shadowLight.withValues(alpha: 0.08),
              blurRadius: context.r(12),
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_Card.borderRadius.r),
          child: Container(
            decoration: BoxDecoration(
              color: theme.white,
              border: Border.all(
                color: SiporaTheme.goldBg.withValues(alpha: 0.2),
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image ───────────────────────────────────────────────────
                Stack(
                  children: [
                    InfiniteCarousel(
                      products: slides,
                      type: CarouselType.card,
                      height: imgH,
                      width: double.infinity,
                      borderRadius: _Card.borderRadius,
                      showDots: hasMultipleImages,
                      showCounter: false,
                      showOverlay: false,
                      autoSlideDuration: const Duration(seconds: 3),
                      animationDuration: const Duration(milliseconds: 500),
                      onTap: () => _showDetails(product),
                    ),
                    // Free Cup Eligibility Badge - Top Left
                    if (product.isFreeCupEligible)
                      Positioned(
                        top: context.h(6),
                        left: context.w(6),
                        child: _buildFreeCupBadge(),
                      ),
                    // Cart Button - Bottom Right
                    Positioned(
                      bottom: context.h(6),
                      right: context.w(6),
                      child: _cartButton(product),
                    ),
                  ],
                ),

                // ── Content ─────────────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.w(8),
                      context.h(6),
                      context.w(8),
                      context.h(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (product.brand.isNotEmpty)
                              Text(
                                product.brand,
                                style: TextStyle(
                                  fontSize: _Card.brandSz(context),
                                  color: SiporaTheme.greenPill,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            SizedBox(height: _Card.brandGap(context)),
                            Text(
                              product.name,
                              style: TextStyle(
                                fontSize: _Card.nameSz(context),
                                fontWeight: FontWeight.w600,
                                color: theme.textDark,
                                height: 1.2,
                              ),
                              maxLines: isTablet ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '₹${product.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: _Card.priceSz(context),
                                fontWeight: FontWeight.w700,
                                color: SiporaTheme.greenDark,
                              ),
                            ),
                            if (product.isFreeCupEligible) ...[
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
                                    color: SiporaTheme.gold.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 0.5.w,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.local_cafe_rounded,
                                      color: SiporaTheme.gold,
                                      size: context.w(8),
                                    ),
                                    SizedBox(width: context.w(2)),
                                    Text(
                                      'FREE',
                                      style: TextStyle(
                                        fontSize: context.sp(7),
                                        fontWeight: FontWeight.w700,
                                        color: SiporaTheme.gold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
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

  Widget _cartButton(Product product) => Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [SiporaTheme.greenDark, SiporaTheme.greenMid],
      ),
      borderRadius: BorderRadius.circular(context.r(20)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: context.r(4),
          offset: Offset(0, 1.h),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _addToCart(product),
        borderRadius: BorderRadius.circular(context.r(20)),
        child: Padding(
          padding: EdgeInsets.all(context.w(6)),
          child: Icon(
            Icons.add_shopping_cart_rounded,
            size: context.w(16),
            color: Colors.white,
          ),
        ),
      ),
    ),
  );

  // ── Actions ──────────────────────────────────────────────────────────────────

  void _addToCart(Product product) {
    CartHelperService.addProductToCart(
      productId: product.id,
      productName: product.name,
      imageUrl: product.image,
      weight: product.weight,
      price: product.price,
      mrp: product.mrp,
      discount: product.discount,
      isFreeCupEligible: product.isFreeCupEligible,
      itemType: product.isWarehouseProduct ? 'warehouse' : 'product',
      quantity: 1,
      onCartUpdated: _refresh,
      onSuccess: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${product.name} to cart'),
            duration: const Duration(seconds: 1),
            backgroundColor: SiporaTheme.greenDark,
          ),
        );
      },
    );
  }

  void _showDetails(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductDetailsPage(
        product: RecommendedProduct(
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
          shortDescription: product.weight,
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
        ),
        onCartUpdated: _refresh,
      ),
    );
  }

  // ── Skeleton ─────────────────────────────────────────────────────────────────

  Widget _buildSkeleton() {
    final theme = context.siporaTheme;
    final imgH = _Card.imageH(context);
    final contentH = _Card.contentH(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.w(20),
        context.h(16),
        context.w(20),
        context.h(32),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: context.w(16),
          mainAxisSpacing: context.h(16),
          mainAxisExtent: _Card.cardH(context),
        ),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: theme.white,
            borderRadius: BorderRadius.circular(_Card.borderRadius.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: context.r(12),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: imgH,
                decoration: BoxDecoration(
                  color: theme.greenBg,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(_Card.borderRadius.r),
                  ),
                ),
              ),
              SizedBox(
                height: contentH,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.w(8),
                    context.h(6),
                    context.w(8),
                    context.h(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sh(40, _Card.brandSz(context), theme),
                          SizedBox(height: _Card.brandGap(context)),
                          _sh(80, _Card.nameSz(context), theme),
                        ],
                      ),
                      _sh(60, _Card.priceSz(context), theme),
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

  Widget _sh(double w, double h, dynamic theme) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: theme.greenBg,
      borderRadius: BorderRadius.circular(context.r(3)),
    ),
  );
}
