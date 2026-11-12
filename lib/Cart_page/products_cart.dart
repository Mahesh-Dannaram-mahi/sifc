import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../utils/image_utils.dart';
import '../utils/screen_utils.dart';
import 'helper/discount_distribution_helper.dart';

import '../theme/sipora_theme.dart';

import '../Home_page/widgets/bottom_nav_text_row.dart';

import '../Setting_page/widgets/wallet_recharge_page.dart';

import 'widgets/cart_coupon_section.dart';
import 'widgets/payment_success_overlay.dart';
import 'widgets/unified_product_card.dart';

import '../services/cart_service.dart';
import '../services/discount_service.dart';
import '../services/razorpay_service.dart';
import '../services/shop_service.dart';
import '../services/storage_service.dart';
import '../services/jwt_service.dart';
import '../services/recommended_products_service.dart';
import '../services/wallet_service.dart';
import '../services/wallet_security_service.dart';

import '../models/active_discount_models.dart';
import '../models/checkout_discount_info.dart';
import '../models/recommended_product.dart';
import '../models/cart_item.dart';

import '../Shop_page/shop_page.dart';
import '../Shop_page/widgets/products_details_page.dart';
import '../Home_page/home_page.dart';
import '../Login_page/widgets/login.dart';

class PremiumLoader extends StatelessWidget {
  final String? message;
  final bool showLogo;

  const PremiumLoader({super.key, this.message, this.showLogo = true});

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;

    return Scaffold(
      backgroundColor: theme.cream,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showLogo) ...[
              Container(
                width: isTablet ? context.w(100) : context.w(80),
                height: isTablet ? context.w(100) : context.w(80),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [SiporaTheme.greenDark, SiporaTheme.greenMid],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: SiporaTheme.greenDark.withValues(alpha: 0.3),
                      blurRadius: 20.r,
                      offset: Offset(0, 8.h),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.coffee_rounded,
                    color: Colors.white,
                    size: context.w(40),
                  ),
                ),
              ),
              SizedBox(height: context.h(32)),
            ],
            SizedBox(
              width: isTablet ? context.w(60) : context.w(50),
              height: isTablet ? context.w(60) : context.w(50),
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                color: SiporaTheme.greenDark,
              ),
            ),
            SizedBox(height: context.h(24)),
            Text(
              message ?? 'Loading your cart...',
              style: TextStyle(
                fontSize: isTablet ? context.sp(16) : context.sp(14),
                fontWeight: FontWeight.w500,
                color: theme.textDark,
              ),
            ),
            SizedBox(height: context.h(8)),
            Text(
              'Please wait',
              style: TextStyle(
                fontSize: isTablet ? context.sp(14) : context.sp(12),
                color: theme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductsCart extends StatefulWidget {
  const ProductsCart({super.key});

  @override
  State<ProductsCart> createState() => _ProductsCartState();
}

class _ProductsCartState extends State<ProductsCart>
    with SingleTickerProviderStateMixin {
  final RazorpayService _razorpayService = RazorpayService();
  bool _isProcessingPayment = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  ActiveDiscountsData? _activeDiscounts;
  List<CartDiscountOffer> _discountOffers = [];
  CartDiscountOffer? _appliedOffer;
  DiscountConfirmData? _appliedConfirm;
  bool _discountsLoading = false;
  String? _applyingCouponCupId;

  List<RecommendedProduct> _recommendedProducts = [];
  bool _recommendedLoading = false;
  bool _isInitialLoading = true;

  double _walletBalance = 0;
  bool _useWallet = false;
  bool _walletLoading = false;

  // Cache for product discounts to avoid recalculation
  Map<String, double>? _cachedProductDiscounts;

  AppliedCartDiscount? get _appliedDiscount => _buildAppliedDiscountForCart();

  AppliedCartDiscount? _buildAppliedDiscountForCart() {
    if (_appliedOffer == null || _appliedConfirm == null) return null;
    var freeCupPrice = 0.0;
    if (_appliedOffer!.type == CartDiscountType.freeCup &&
        CartService.items.isNotEmpty) {
      final eligibleProducts = CartService.items
          .where((item) => item.isFreeCupEligible)
          .toList();
      if (eligibleProducts.isNotEmpty) {
        freeCupPrice = eligibleProducts
            .map((i) => i.price)
            .reduce((a, b) => a < b ? a : b);
      }
    }
    return DiscountService.buildAppliedDiscount(
      offer: _appliedOffer!,
      confirm: _appliedConfirm!,
      cartSubtotal: CartService.subtotal,
      freeCupUnitPrice: freeCupPrice,
    );
  }

  // ─── Getters ──────────────────────────────────────────────────────────────

  int get _cartCupCount =>
      CartService.items.fold(0, (sum, item) => sum + item.quantity);

  double get _payableAmount =>
      _appliedDiscount?.payableAmount ?? CartService.subtotal;

  double get _walletAppliedAmount {
    if (!_useWallet || _walletBalance <= 0) return 0;
    return _walletBalance >= _payableAmount ? _payableAmount : _walletBalance;
  }

  double get _razorpayAmount =>
      (_payableAmount - _walletAppliedAmount).clamp(0, double.infinity);

  double get _couponDiscount => _appliedDiscount?.discountAmount ?? 0;

  bool get _cartHasFranchiseItems {
    return CartService.items.any((item) {
      final itemType = item.itemType.toLowerCase();
      return !itemType.contains('warehouse');
    });
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
    CartService.addListener(_onCartChanged);
    _loadSavedCart();
    _loadAllData();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    CartService.removeListener(_onCartChanged);
    _razorpayService.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ─── Initialization ──────────────────────────────────────────────────────

  void _initializeRazorpay() {
    _razorpayService.initialize(
      onPaymentSuccess: _onPaymentSuccess,
      onPaymentError: _onPaymentError,
      onPaymentCancel: _onPaymentCancelled,
    );
  }

  Future<void> _loadSavedCart() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCart = prefs.getString('saved_cart');

    if (savedCart != null && savedCart.isNotEmpty) {
      try {
        final List<dynamic> decoded = json.decode(savedCart);
        final List<CartItem> loadedItems = [];

        for (var item in decoded) {
          loadedItems.add(CartItem.fromMap(item));
        }

        CartService.replaceItems(loadedItems);

        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        // Ignore invalid local cache and continue with backend fetch.
      }
    }

    try {
      final remoteItems = await CartService.fetchRemoteCartItems();
      if (remoteItems.isNotEmpty) {
        CartService.replaceItems(remoteItems);
        await _saveCart();
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      // Keep the locally cached cart available when the backend is unreachable.
    }
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isInitialLoading = true;
    });

    await Future.wait([
      _loadDiscounts(),
      _loadRecommendedProducts(),
      _loadWalletBalance(),
    ]);

    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  // ─── Save / Load Cart ────────────────────────────────────────────────────

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> cartJson = [];

    for (var item in CartService.items) {
      cartJson.add(item.toMap());
    }

    await prefs.setString('saved_cart', json.encode(cartJson));
  }

  // ─── Cart Change Handlers ───────────────────────────────────────────────

  void _onCartChanged() {
    _refreshOfferSuggestions();
    if (_appliedOffer != null && !_isAppliedDiscountStillValid()) {
      setState(() {
        _appliedOffer = null;
        _appliedConfirm = null;
        _cachedProductDiscounts = null;
      });
    } else if (_appliedOffer != null && mounted) {
      setState(() {});
      _updateProductDiscountsCache();
    }
    _saveCart();
  }

  void _updateUI() {
    if (mounted) {
      setState(() {});
      _refreshOfferSuggestions();
      _updateProductDiscountsCache();
    }
    _saveCart();
  }

  // ─── Discount Methods ────────────────────────────────────────────────────

  bool _isAppliedDiscountStillValid() {
    if (_appliedOffer == null || _activeDiscounts == null) return false;
    final offers = DiscountService.evaluateCartOffers(
      discounts: _activeDiscounts!,
      franchiseId: ShopService.selectedShopId ?? '',
      cartTotal: CartService.subtotal,
      cartCupCount: _cartCupCount,
    );
    return offers.any((o) => o.cupId == _appliedOffer!.cupId && o.canApply);
  }

  void _refreshOfferSuggestions() {
    if (_activeDiscounts == null || !ShopService.hasSelectedShop()) return;
    final offers = DiscountService.evaluateCartOffers(
      discounts: _activeDiscounts!,
      franchiseId: ShopService.selectedShopId!,
      cartTotal: CartService.subtotal,
      cartCupCount: _cartCupCount,
    );
    if (mounted) {
      setState(() => _discountOffers = offers);
    }
  }

  void _updateProductDiscountsCache() {
    final applied = _appliedDiscount;
    if (applied == null || CartService.items.isEmpty) {
      _cachedProductDiscounts = null;
      return;
    }

    _cachedProductDiscounts =
        DiscountDistributionHelper.distributeDiscountProportionally(
          CartService.items,
          applied.discountAmount,
        );
  }

  Map<String, double>? _getProductDiscountsForDisplay() {
    return _cachedProductDiscounts;
  }

  Future<void> _loadDiscounts() async {
    if (!ShopService.hasSelectedShop()) return;
    setState(() => _discountsLoading = true);
    try {
      await ShopService.loadSelectedShop();
      final franchiseId = ShopService.selectedShopId!;
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('tea_app_token');
      String? userId = await StorageService.getUserId();
      userId ??= prefs.getString('user_id');
      if (userId == null && token != null) {
        userId = JwtService.extractUserId(token);
      }
      if (userId == null) {
        if (mounted) setState(() => _discountsLoading = false);
        return;
      }
      final data = await DiscountService.fetchActiveDiscounts(
        userId: userId,
        franchiseId: franchiseId,
        authToken: token,
      );
      if (!mounted) return;
      if (data != null) {
        final offers = DiscountService.evaluateCartOffers(
          discounts: data,
          franchiseId: franchiseId,
          cartTotal: CartService.subtotal,
          cartCupCount: _cartCupCount,
        );
        setState(() {
          _activeDiscounts = data;
          _discountOffers = offers;
          _discountsLoading = false;
        });
      } else {
        setState(() => _discountsLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _discountsLoading = false);
    }
  }

  Future<void> _applyCoupon(CartDiscountOffer offer) async {
    if (!ShopService.hasSelectedShop()) return;

    if (offer.type == CartDiscountType.freeCup && !offer.hasEligibleProducts) {
      SiporaTheme.showSnackBar(
        context,
        'This coupon requires eligible products in your cart. Add products marked "Free Cup Eligible" to use this coupon.',
        isError: true,
      );
      return;
    }

    setState(() => _applyingCouponCupId = offer.cupId);
    try {
      final franchiseId = ShopService.selectedShopId!;
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('tea_app_token');
      final confirm = await DiscountService.confirmDiscount(
        franchiseId: franchiseId,
        cupId: offer.cupId,
        authToken: token,
      );
      if (confirm == null) {
        if (mounted) {
          SiporaTheme.showSnackBar(
            context,
            'Could not confirm this coupon',
            isError: true,
          );
        }
        return;
      }
      double freeCupPrice = 0;
      if (offer.type == CartDiscountType.freeCup &&
          CartService.items.isNotEmpty) {
        final eligibleProducts = CartService.items
            .where((item) => item.isFreeCupEligible)
            .toList();
        if (eligibleProducts.isNotEmpty) {
          freeCupPrice = eligibleProducts
              .map((i) => i.price)
              .reduce((a, b) => a < b ? a : b);
        }
      }
      final applied = DiscountService.buildAppliedDiscount(
        offer: offer,
        confirm: confirm,
        cartSubtotal: CartService.subtotal,
        freeCupUnitPrice: freeCupPrice,
      );
      if (mounted && applied != null) {
        setState(() {
          _appliedOffer = offer;
          _appliedConfirm = confirm;
          _applyingCouponCupId = null;
        });
        _updateProductDiscountsCache();
        SiporaTheme.showSnackBar(
          context,
          '${offer.title} applied successfully',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        SiporaTheme.showSnackBar(
          context,
          'Error applying coupon: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _applyingCouponCupId = null);
      }
    }
  }

  // ─── Wallet Methods ──────────────────────────────────────────────────────

  Future<void> _loadWalletBalance() async {
    setState(() => _walletLoading = true);
    try {
      final wallet = await WalletService.fetchWallet();
      if (mounted) {
        setState(() {
          _walletBalance = wallet?.currentBalance ?? 0;
          _walletLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _walletLoading = false);
    }
  }

  Future<void> _openWalletRecharge() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WalletRechargePage(
          initialBalance: _walletBalance,
          onBalanceUpdated: _loadWalletBalance,
        ),
      ),
    );
    await _loadWalletBalance();
  }

  // ─── Recommended Products ────────────────────────────────────────────────

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

  // ─── Payment Methods ─────────────────────────────────────────────────────

  void _onPaymentSuccess(PaymentSuccessResult result) {
    setState(() => _isProcessingPayment = false);
    CartService.clearCart();
    _saveCart();
    setState(() {
      _appliedOffer = null;
      _appliedConfirm = null;
      _useWallet = false;
      _cachedProductDiscounts = null;
    });
    _loadWalletBalance();
    PaymentSuccessOverlay.show(
      context,
      result: result,
      onDone: () {
        Navigator.of(context).pop();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ShopPage()),
          (route) => false,
        );
      },
    );
  }

  void _onPaymentError(String error) {
    setState(() => _isProcessingPayment = false);
    // Don't show cancellation as error
    if (error.toLowerCase().contains('cancelled')) {
      SiporaTheme.showSnackBar(context, 'Payment cancelled', isError: false);
    } else {
      SiporaTheme.showSnackBar(context, error, isError: true);
    }
  }

  void _onPaymentCancelled() {
    setState(() => _isProcessingPayment = false);
    SiporaTheme.showSnackBar(context, 'Payment cancelled', isError: false);
  }

  Future<void> _proceedToPayment() async {
    if (CartService.isEmpty) {
      SiporaTheme.showSnackBar(context, 'Your cart is empty', isError: true);
      return;
    }

    // Checkout is account-based; browsing and maintaining a guest cart are public.
    final token = await StorageService.getToken();
    final isAuthenticated = token != null &&
        token.isNotEmpty &&
        await StorageService.isTokenValid();
    if (!isAuthenticated) {
      if (!mounted) return;
      final theme = context.siporaTheme;
      showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => Dialog(
          backgroundColor: theme.white,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: SiporaTheme.greenBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          color: SiporaTheme.greenDark,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Login required',
                          style: TextStyle(
                            color: theme.textDark,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Please log in or create an account to continue to checkout. '
                    'Your cart will be saved, and you can keep browsing as a guest.',
                    style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(
                            'Not now',
                            style: TextStyle(
                              color: theme.textDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                            );
                          },
                          child: const Text('Login / Register'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      return;
    }

    // Check if payment is already in progress
    if (_razorpayService.isPaymentInProgress) {
      SiporaTheme.showSnackBar(
        context,
        'Payment already in progress',
        isError: false,
      );
      return;
    }

    setState(() => _isProcessingPayment = true);

    try {
      final canAcceptOrder = await _canAcceptFranchiseOrder();
      if (!canAcceptOrder) {
        if (mounted) setState(() => _isProcessingPayment = false);
        return;
      }

      if (_walletAppliedAmount > 0) {
        if (!mounted) return;
        final authenticated =
            await WalletSecurityService.authenticateForWalletAction(
              context,
              reason: 'Authenticate to pay using wallet',
            );
        if (!authenticated) {
          if (mounted) setState(() => _isProcessingPayment = false);
          return;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('user_name') ?? 'User';
      final email = prefs.getString('user_email') ?? 'user@example.com';
      final contact = prefs.getString('user_phone') ?? '9999999999';
      CheckoutDiscountInfo? checkoutDiscount;
      final applied = _appliedDiscount;
      if (applied != null && _appliedConfirm != null) {
        final productDiscounts =
            DiscountDistributionHelper.distributeDiscountProportionally(
              CartService.items,
              applied.discountAmount,
            );

        _cachedProductDiscounts = productDiscounts;

        checkoutDiscount = CheckoutDiscountInfo(
          discountAmount: applied.discountAmount,
          discountPercentage:
              _appliedConfirm!.discountPercent ??
              _appliedOffer?.discountPercent ??
              0,
          cupId: _appliedConfirm!.cupId,
          discountType: applied.type,
          productDiscounts: productDiscounts,
        );
      }

      await _razorpayService.openCheckout(
        amount: _razorpayAmount,
        name: name,
        email: email,
        contact: contact,
        cartItems: CartService.items,
        discountInfo: checkoutDiscount,
        walletAmount: _walletAppliedAmount,
      );

      // Note: _isProcessingPayment will be reset by callbacks
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
        SiporaTheme.showSnackBar(context, 'Error: $e', isError: true);
      }
    }
  }

  Future<bool> _canAcceptFranchiseOrder() async {
    if (!_cartHasFranchiseItems) return true;

    final selectedShop = await ShopService.getSelectedShopWithLocation();
    if (selectedShop == null) {
      if (mounted) {
        SiporaTheme.showSnackBar(
          context,
          'Please select a franchise before checkout',
          isError: true,
        );
      }
      return false;
    }

    if (selectedShop.lat == 0.0 || selectedShop.lng == 0.0) {
      if (mounted) {
        SiporaTheme.showSnackBar(
          context,
          'Selected franchise location is unavailable',
          isError: true,
        );
      }
      return false;
    }

    final userLocation = await ShopService.getCurrentLocation(
      forceRefresh: true,
    );
    if (userLocation == null) {
      if (mounted) {
        SiporaTheme.showSnackBar(
          context,
          'Please enable location to order from this franchise',
          isError: true,
        );
      }
      return false;
    }

    final distance = ShopService.calculateDistanceToShop(selectedShop);
    if (distance == null) {
      if (mounted) {
        SiporaTheme.showSnackBar(
          context,
          'Unable to verify your distance from the franchise',
          isError: true,
        );
      }
      return false;
    }

    if (distance > 20000000000000) {
      if (mounted) {
        final displayDistance = distance < 1000
            ? '${distance.round()} m'
            : '${(distance / 1000).toStringAsFixed(1)} km';
        SiporaTheme.showSnackBar(
          context,
          'Franchise orders are accepted only within 20 km. You are $displayDistance away.',
          isError: true,
        );
      }
      return false;
    }

    return true;
  }

  void _showClearCartDialog() {
    final theme = context.siporaTheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.r(12)),
        ),
        title: Text(
          'Clear Cart',
          style: TextStyle(fontSize: context.sp(16), color: theme.textDark),
        ),
        content: Text(
          'Are you sure you want to remove all items from your cart?',
          style: TextStyle(fontSize: context.sp(14), color: theme.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: context.sp(14),
                color: theme.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              CartService.clearCart();
              _updateUI();
              _saveCart();
              Navigator.pop(ctx);
              SiporaTheme.showSnackBar(context, 'Cart cleared', isError: false);
            },
            style: TextButton.styleFrom(foregroundColor: theme.red),
            child: Text(
              'Clear All',
              style: TextStyle(fontSize: context.sp(14), color: theme.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showProductDetails(RecommendedProduct product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailsPage(
        product: product,
        onCartUpdated: () {
          setState(() {});
          _refreshOfferSuggestions();
          _saveCart();
          _updateProductDiscountsCache();
        },
      ),
    );
  }

  // ─── Build UI ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;

    if (_isInitialLoading) {
      return const PremiumLoader(
        message: 'Loading your cart...',
        showLogo: true,
      );
    }

    return Scaffold(
      backgroundColor: theme.cream,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CartService.isEmpty
            ? _buildEmptyCartUI()
            : _buildCartWithItems(),
      ),
      bottomNavigationBar: const BottomNavTextRow(currentPage: 'cart'),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;

    return AppBar(
      backgroundColor: theme.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: isTablet ? context.w(70) : context.w(62),
      leading: Padding(
        padding: EdgeInsets.only(left: context.w(12)),
        child: Center(
          child: _buildAppBarIconButton(
            icon: Icons.chevron_left,
            onTap: () {
              final navigator = Navigator.of(context);
              if (navigator.canPop()) {
                navigator.pop();
              } else {
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomePage()),
                  (route) => false,
                );
              }
            },
          ),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAppBarCartIcon(),
          SizedBox(width: context.w(10)),
          Text(
            'My Cart',
            style: TextStyle(
              fontSize: isTablet ? context.sp(20) : context.sp(18),
              fontWeight: FontWeight.w700,
              color: theme.textDark,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        _buildAppBarIconButton(
          icon: Icons.favorite_border_rounded,
          onTap: () {},
        ),
        SizedBox(width: context.w(8)),
        _buildAppBarIconButton(
          icon: Icons.more_vert_rounded,
          onTap: _showCartMoreOptions,
        ),
        SizedBox(width: context.w(12)),
      ],
    );
  }

  Widget _buildAppBarIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isTablet ? context.w(44) : context.w(38),
        height: isTablet ? context.w(44) : context.w(38),
        decoration: BoxDecoration(
          color: theme.white,
          border: Border.all(color: theme.border, width: 1.5.w),
          borderRadius: BorderRadius.circular(context.r(12)),
        ),
        child: Icon(
          icon,
          color: theme.textDark,
          size: isTablet ? context.w(24) : context.w(20),
        ),
      ),
    );
  }

  Widget _buildAppBarCartIcon() {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;

    return Container(
      width: isTablet ? context.w(44) : context.w(38),
      height: isTablet ? context.w(44) : context.w(38),
      decoration: BoxDecoration(
        color: theme.white,
        border: Border.all(color: theme.border, width: 1.5.w),
        borderRadius: BorderRadius.circular(context.r(12)),
      ),
      child: Icon(
        Icons.shopping_cart_outlined,
        color: theme.textDark,
        size: isTablet ? context.w(24) : context.w(20),
      ),
    );
  }

  void _showCartMoreOptions() {
    final theme = context.siporaTheme;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.r(20)),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: context.h(8)),
            Container(
              width: context.w(40),
              height: context.h(4),
              decoration: BoxDecoration(
                color: theme.border,
                borderRadius: BorderRadius.circular(context.r(2)),
              ),
            ),
            SizedBox(height: context.h(16)),
            if (CartService.isNotEmpty)
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: theme.red,
                  size: context.w(24),
                ),
                title: Text(
                  'Clear Cart',
                  style: TextStyle(
                    color: theme.red,
                    fontWeight: FontWeight.w600,
                    fontSize: context.sp(14),
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showClearCartDialog();
                },
              ),
            ListTile(
              leading: Icon(
                Icons.share_outlined,
                color: theme.textDark,
                size: context.w(24),
              ),
              title: Text(
                'Share Cart',
                style: TextStyle(fontSize: context.sp(14)),
              ),
              onTap: () => Navigator.pop(ctx),
            ),
            SizedBox(height: context.h(8)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCartUI() {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 0.72;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: Offset(0, -30.h),
            child: Image.network(
              'https://siporaimagescollection.blob.core.windows.net/websiteimages/MobileApp/For_Logout-removebg.png',
              width: imageSize,
              height: imageSize,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  ImageUtils.assetImage(
                    path: '/assets/images/sipora_logo.png',
                    width: imageSize * 0.5,
                    height: imageSize * 0.5,
                  ),
            ),
          ),
          SizedBox(
            height: 0,
            child: OverflowBox(
              maxHeight: double.infinity,
              alignment: Alignment.topCenter,
              child: Transform.translate(
                offset: Offset(0, -(imageSize * 0.22)),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.w(32)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Your cart is empty',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? context.sp(26) : context.sp(22),
                          fontWeight: FontWeight.w700,
                          color: theme.textDark,
                        ),
                      ),
                      SizedBox(height: context.h(10)),
                      Text(
                        'Looks like you haven\'t added anything yet. Explore our cafe menu and find something you\'ll love!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? context.sp(16) : context.sp(14),
                          color: theme.textMuted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: context.h(90)),
          Container(
            margin: EdgeInsets.symmetric(horizontal: context.w(16)),
            padding: EdgeInsets.symmetric(
              horizontal: context.w(8),
              vertical: context.h(16),
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: SiporaTheme.greenLight.withValues(alpha: 0.4),
                width: 1.w,
              ),
              borderRadius: BorderRadius.circular(context.r(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFeatureItem('Made\nwith Love', Icons.favorite_border),
                _buildFeatureItem('Quality\nIngredients', Icons.verified),
                _buildFeatureItem('Freshly\nPrepared', Icons.local_cafe),
                _buildFeatureItem('Cozy\nAmbience', Icons.chair),
              ],
            ),
          ),
          _buildYouMightLikeSection(),
          SizedBox(height: context.h(16)),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String label, IconData icon) {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isTablet ? context.w(60) : context.w(50),
          height: isTablet ? context.w(60) : context.w(50),
          decoration: BoxDecoration(
            color: theme.greenBg,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: SiporaTheme.greenDark,
            size: isTablet ? context.w(28) : context.w(24),
          ),
        ),
        SizedBox(height: context.h(8)),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isTablet ? context.sp(14) : context.sp(12),
            fontWeight: FontWeight.w600,
            color: theme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildOfferBanner() {
    final theme = context.siporaTheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.w(16)),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(context.r(10)),
        border: Border.all(color: const Color(0xFFDDE8D0), width: 1.w),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(8),
                  vertical: context.h(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      color: SiporaTheme.greenDark,
                      size: context.w(22),
                    ),
                    SizedBox(width: context.w(6)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Add items worth ₹499',
                            style: TextStyle(
                              fontSize: context.sp(8),
                              fontWeight: FontWeight.w600,
                              color: theme.textDark,
                            ),
                          ),
                          Text(
                            'to unlock a special offer!',
                            style: TextStyle(
                              fontSize: context.sp(8),
                              fontWeight: FontWeight.w600,
                              color: theme.textDark,
                            ),
                          ),
                          SizedBox(height: context.h(3)),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(context.r(2)),
                            child: LinearProgressIndicator(
                              value: (CartService.subtotal / 499).clamp(
                                0.0,
                                1.0,
                              ),
                              minHeight: context.h(2),
                              backgroundColor: const Color(0xFFE8F0E0),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                SiporaTheme.greenDark,
                              ),
                            ),
                          ),
                          SizedBox(height: context.h(2)),
                          Text(
                            '₹${CartService.subtotal.toStringAsFixed(0)} / ₹499',
                            style: TextStyle(
                              fontSize: context.sp(7),
                              color: theme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(width: 1.w, color: const Color(0xFFDDE8D0)),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(8),
                  vertical: context.h(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.card_giftcard_outlined,
                      color: SiporaTheme.greenDark,
                      size: context.w(22),
                    ),
                    SizedBox(width: context.w(6)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Special Offer',
                            style: TextStyle(
                              fontSize: context.sp(9),
                              fontWeight: FontWeight.w700,
                              color: theme.textDark,
                            ),
                          ),
                          SizedBox(height: context.h(1)),
                          Text(
                            'Add more items to unlock',
                            style: TextStyle(
                              fontSize: context.sp(7),
                              color: theme.textMuted,
                            ),
                          ),
                          Text(
                            'exciting rewards!',
                            style: TextStyle(
                              fontSize: context.sp(7),
                              color: theme.textMuted,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildYouMightLikeSection() {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;
    final screenPadding = context.w(16);
    final gridSpacing = context.h(12);

    Widget youMightLikeContent;

    if (_recommendedLoading) {
      youMightLikeContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenPadding),
            child: Text(
              'You might like',
              style: TextStyle(
                fontSize: isTablet ? context.sp(18) : context.sp(16),
                fontWeight: FontWeight.w700,
                color: theme.textMuted,
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
    } else if (_recommendedProducts.isEmpty && !_recommendedLoading) {
      youMightLikeContent = const SizedBox.shrink();
    } else {
      final double cardWidth = isTablet ? context.w(200) : context.w(160);
      final double carouselHeight = isTablet ? context.h(120) : context.h(100);

      youMightLikeContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: gridSpacing * 3),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'You might like',
                  style: TextStyle(
                    fontSize: isTablet ? context.sp(18) : context.sp(16),
                    fontWeight: FontWeight.w700,
                    color: theme.textMuted,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const ShopPage()),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View all',
                    style: TextStyle(
                      fontSize: isTablet ? context.sp(14) : context.sp(13),
                      fontWeight: FontWeight.w600,
                      color: SiporaTheme.greenPill,
                    ),
                  ),
                ),
              ],
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
                  onCartUpdated: () {
                    setState(() {});
                    _refreshOfferSuggestions();
                    _saveCart();
                    _updateProductDiscountsCache();
                  },
                  cardWidth: cardWidth,
                  imageHeight: carouselHeight,
                );
              },
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        youMightLikeContent,
        SizedBox(height: context.h(10)),
        _buildOfferBanner(),
        SizedBox(height: context.h(8)),
        if (CartService.isEmpty)
          GestureDetector(
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ShopPage()),
            ),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: context.w(16)),
              padding: EdgeInsets.symmetric(
                horizontal: context.w(12),
                vertical: context.h(10),
              ),
              decoration: BoxDecoration(
                color: SiporaTheme.greenDark,
                borderRadius: BorderRadius.circular(context.r(10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.coffee_outlined,
                    color: Colors.white,
                    size: context.w(16),
                  ),
                  SizedBox(width: context.w(6)),
                  Text(
                    'Start Ordering',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: context.sp(12),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: context.w(16),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecommendedProductSkeleton() {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;
    final double cardWidth = isTablet ? context.w(220) : context.w(170);
    final double carouselHeight = isTablet ? context.h(200) : context.h(160);
    final cardPadding = context.w(16);

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
              child: ImageUtils.assetImage(
                path: '/assets/images/sipora_logo.png',
                width: context.w(60),
                height: context.w(60),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(cardPadding * 0.7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: context.w(60),
                  height: isTablet ? context.sp(13) : context.sp(12),
                  decoration: BoxDecoration(
                    color: theme.border.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(context.r(4)),
                  ),
                ),
                SizedBox(height: context.h(8)),
                Container(
                  width: context.w(120),
                  height: isTablet ? context.sp(15) : context.sp(14),
                  decoration: BoxDecoration(
                    color: theme.border.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(context.r(4)),
                  ),
                ),
                SizedBox(height: context.h(4)),
                Container(
                  width: context.w(80),
                  height: isTablet ? context.sp(13) : context.sp(12),
                  decoration: BoxDecoration(
                    color: theme.border.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(context.r(4)),
                  ),
                ),
                SizedBox(height: context.h(12)),
                Container(
                  width: context.w(60),
                  height: isTablet ? context.sp(17) : context.sp(16),
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

  Widget _buildCartWithItems() {
    final screenPadding = context.w(16);

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  screenPadding,
                  context.h(8),
                  screenPadding,
                  0,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildCartItem(CartService.items[index]),
                    childCount: CartService.items.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: CartCouponSection(
                  offers: _discountOffers,
                  appliedDiscount: _appliedDiscount,
                  isLoading: _discountsLoading,
                  applyingCupId: _applyingCouponCupId,
                  onRemove: () => setState(() {
                    _appliedOffer = null;
                    _appliedConfirm = null;
                    _cachedProductDiscounts = null;
                    _saveCart();
                  }),
                  onApply: _applyCoupon,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: context.h(10)),
                  child: _buildYouMightLikeSection(),
                ),
              ),
            ],
          ),
        ),
        _buildBottomSummary(),
      ],
    );
  }

  Widget _buildCartItem(CartItem item) {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;
    final discountPercent = item.mrp > item.price
        ? ((item.mrp - item.price) / item.mrp * 100).round()
        : 0;

    final productDiscounts = _getProductDiscountsForDisplay();
    final discountForProduct = DiscountDistributionHelper.getDiscountForProduct(
      productDiscounts,
      item.productId,
    );

    return Container(
      margin: EdgeInsets.only(bottom: context.h(10)),
      padding: EdgeInsets.all(context.w(8)),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(context.r(10)),
        border: Border.all(color: theme.border, width: 1.w),
      ),
      child: Row(
        children: [
          Container(
            width: isTablet ? context.w(65) : context.w(55),
            height: isTablet ? context.w(65) : context.w(55),
            decoration: BoxDecoration(
              color: theme.greenBg,
              borderRadius: BorderRadius.circular(context.r(8)),
            ),
            child: item.image.isNotEmpty && item.image != 'null'
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(context.r(8)),
                    child: ImageUtils.networkImage(
                      url: item.image,
                      width: isTablet ? context.w(65) : context.w(55),
                      height: isTablet ? context.w(65) : context.w(55),
                      fit: BoxFit.cover,
                    ),
                  )
                : ImageUtils.assetImage(
                    path: '/assets/images/sipora_logo.png',
                    width: isTablet ? context.w(65) : context.w(55),
                    height: isTablet ? context.w(65) : context.w(55),
                  ),
          ),
          SizedBox(width: context.w(8)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: isTablet ? context.sp(15) : context.sp(13),
                    fontWeight: FontWeight.w600,
                    color: theme.textDark,
                  ),
                ),
                SizedBox(height: context.h(4)),
                Row(
                  children: [
                    Text(
                      '₹${item.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: isTablet ? context.sp(15) : context.sp(13),
                        fontWeight: FontWeight.w700,
                        color: theme.textDark,
                      ),
                    ),
                    if (item.mrp > item.price) ...[
                      SizedBox(width: context.w(5)),
                      Text(
                        '₹${item.mrp.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: isTablet ? context.sp(12) : context.sp(10),
                          color: theme.textMuted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      if (discountPercent > 0) ...[
                        SizedBox(width: context.w(4)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.w(3),
                            vertical: context.h(1),
                          ),
                          decoration: BoxDecoration(
                            color: SiporaTheme.greenDark.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(context.r(2)),
                          ),
                          child: Text(
                            '$discountPercent%',
                            style: TextStyle(
                              fontSize: context.sp(8),
                              fontWeight: FontWeight.w600,
                              color: SiporaTheme.greenDark,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
                if (discountForProduct > 0)
                  Padding(
                    padding: EdgeInsets.only(top: context.h(2)),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(6),
                        vertical: context.h(2),
                      ),
                      decoration: BoxDecoration(
                        color: SiporaTheme.greenDark.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(context.r(4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_offer_outlined,
                            size: context.w(10),
                            color: SiporaTheme.greenDark,
                          ),
                          SizedBox(width: context.w(4)),
                          Text(
                            'Coupon discount: -₹${discountForProduct.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: context.sp(9),
                              fontWeight: FontWeight.w600,
                              color: SiporaTheme.greenDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (item.isFreeCupEligible)
                  Padding(
                    padding: EdgeInsets.only(top: context.h(2)),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(4),
                        vertical: context.h(1),
                      ),
                      decoration: BoxDecoration(
                        color: SiporaTheme.greenDark.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(context.r(4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_cafe_rounded,
                            size: context.w(8),
                            color: SiporaTheme.greenDark,
                          ),
                          SizedBox(width: context.w(2)),
                          Text(
                            'Free Cup Eligible',
                            style: TextStyle(
                              fontSize: context.sp(7),
                              fontWeight: FontWeight.w500,
                              color: SiporaTheme.greenDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (item.quantity > 1)
                  Padding(
                    padding: EdgeInsets.only(top: context.h(2)),
                    child: Text(
                      'Total: ₹${(item.price * item.quantity).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: context.sp(9),
                        fontWeight: FontWeight.w500,
                        color: SiporaTheme.greenPill,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  CartService.removeItem(item.name);
                  _updateUI();
                  _saveCart();
                },
                child: Icon(
                  Icons.delete_outline,
                  size: isTablet ? context.w(20) : context.w(16),
                  color: theme.red,
                ),
              ),
              SizedBox(height: context.h(8)),
              _buildQuantitySelector(item),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector(CartItem item) {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;

    return Container(
      height: isTablet ? context.h(30) : context.h(26),
      decoration: BoxDecoration(
        color: theme.greenBg,
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(color: theme.border, width: 1.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              if (item.quantity > 1) {
                CartService.updateQuantity(item.name, item.quantity - 1);
                _updateUI();
              } else {
                CartService.removeItem(item.name);
                _updateUI();
              }
              _saveCart();
            },
            child: Container(
              width: isTablet ? context.w(26) : context.w(22),
              height: isTablet ? context.w(30) : context.w(26),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(context.r(14)),
                ),
                color: item.quantity == 1
                    ? theme.greenBg
                    : SiporaTheme.greenDark,
              ),
              child: Icon(
                Icons.remove,
                size: isTablet ? context.w(14) : context.w(12),
                color: item.quantity == 1
                    ? SiporaTheme.greenDark
                    : Colors.white,
              ),
            ),
          ),
          Container(
            width: isTablet ? context.w(28) : context.w(24),
            alignment: Alignment.center,
            child: Text(
              '${item.quantity}',
              style: TextStyle(
                fontSize: isTablet ? context.sp(13) : context.sp(11),
                fontWeight: FontWeight.w600,
                color: theme.textDark,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              CartService.updateQuantity(item.name, item.quantity + 1);
              _updateUI();
              _saveCart();
            },
            child: Container(
              width: isTablet ? context.w(26) : context.w(22),
              height: isTablet ? context.w(30) : context.w(26),
              decoration: BoxDecoration(
                color: SiporaTheme.greenDark,
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(context.r(14)),
                ),
              ),
              child: Icon(
                Icons.add,
                size: isTablet ? context.w(14) : context.w(12),
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSummary() {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;

    final double finalAmount = _useWallet ? _razorpayAmount : _payableAmount;
    final bool isFullWalletPayment = _useWallet && _razorpayAmount <= 0;
    final bool isPartialWalletPayment = _useWallet && _razorpayAmount > 0;

    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.r(12)),
        ),
        border: Border(
          top: BorderSide(color: theme.border, width: 1.w),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: TextStyle(
                  fontSize: isTablet ? context.sp(14) : context.sp(12),
                  color: theme.textMuted,
                ),
              ),
              Text(
                '₹${CartService.subtotal.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: isTablet ? context.sp(15) : context.sp(13),
                  fontWeight: FontWeight.w600,
                  color: theme.textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(6)),
          if (_couponDiscount > 0)
            Padding(
              padding: EdgeInsets.only(bottom: context.h(6)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Coupon Discount',
                    style: TextStyle(
                      fontSize: isTablet ? context.sp(14) : context.sp(12),
                      color: SiporaTheme.greenDark,
                    ),
                  ),
                  Text(
                    '-₹${_couponDiscount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: isTablet ? context.sp(15) : context.sp(13),
                      fontWeight: FontWeight.w600,
                      color: SiporaTheme.greenDark,
                    ),
                  ),
                ],
              ),
            ),
          _buildWalletSection(theme),

          if (_useWallet && _walletAppliedAmount > 0)
            Padding(
              padding: EdgeInsets.only(bottom: context.h(6)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Wallet Used',
                    style: TextStyle(
                      fontSize: isTablet ? context.sp(14) : context.sp(12),
                      color: SiporaTheme.greenDark,
                    ),
                  ),
                  Text(
                    '-₹${_walletAppliedAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: isTablet ? context.sp(15) : context.sp(13),
                      fontWeight: FontWeight.w600,
                      color: SiporaTheme.greenDark,
                    ),
                  ),
                ],
              ),
            ),

          if (isPartialWalletPayment)
            Padding(
              padding: EdgeInsets.only(bottom: context.h(6)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Amount to Pay',
                    style: TextStyle(
                      fontSize: isTablet ? context.sp(14) : context.sp(12),
                      color: theme.textMuted,
                    ),
                  ),
                  Text(
                    '₹${_razorpayAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: isTablet ? context.sp(15) : context.sp(13),
                      fontWeight: FontWeight.w600,
                      color: theme.textDark,
                    ),
                  ),
                ],
              ),
            ),

          _buildDiscountDistributionSummary(),

          Divider(height: context.h(6)),
          SizedBox(height: context.h(6)),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isFullWalletPayment ? 'Paid via Wallet' : 'Total',
                style: TextStyle(
                  fontSize: isTablet ? context.sp(17) : context.sp(15),
                  fontWeight: FontWeight.w700,
                  color: theme.textDark,
                ),
              ),
              Text(
                '₹${finalAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: isTablet ? context.sp(20) : context.sp(18),
                  fontWeight: FontWeight.w800,
                  color: theme.textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(12)),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessingPayment ? null : _proceedToPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: SiporaTheme.greenDark,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: context.h(10)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.r(22)),
                ),
                elevation: 0,
              ),
              child: _isProcessingPayment
                  ? SizedBox(
                      width: context.w(18),
                      height: context.w(18),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      isFullWalletPayment
                          ? 'Pay ₹${finalAmount.toStringAsFixed(0)} with Wallet'
                          : isPartialWalletPayment
                          ? 'Pay ₹${_razorpayAmount.toStringAsFixed(0)}'
                          : 'Checkout (₹${_payableAmount.toStringAsFixed(0)})',
                      style: TextStyle(
                        fontSize: isTablet ? context.sp(15) : context.sp(13),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountDistributionSummary() {
    final applied = _appliedDiscount;
    if (applied == null || _appliedConfirm == null) {
      return const SizedBox.shrink();
    }

    final productDiscounts = _getProductDiscountsForDisplay();
    if (productDiscounts == null || productDiscounts.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = context.siporaTheme;
    final isTablet = context.isTablet;

    return Container(
      margin: EdgeInsets.only(bottom: context.h(8)),
      padding: EdgeInsets.all(context.w(8)),
      decoration: BoxDecoration(
        color: SiporaTheme.greenBg,
        borderRadius: BorderRadius.circular(context.r(8)),
        border: Border.all(
          color: SiporaTheme.greenLight.withValues(alpha: 0.3),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discount Distribution',
            style: TextStyle(
              fontSize: isTablet ? context.sp(13) : context.sp(11),
              fontWeight: FontWeight.w600,
              color: theme.textDark,
            ),
          ),
          SizedBox(height: context.h(6)),
          ...CartService.items.map((item) {
            final discount = DiscountDistributionHelper.getDiscountForProduct(
              productDiscounts,
              item.productId,
            );
            if (discount <= 0) return const SizedBox.shrink();

            return Padding(
              padding: EdgeInsets.symmetric(vertical: context.h(2)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        fontSize: isTablet ? context.sp(12) : context.sp(10),
                        color: theme.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '-₹${discount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: isTablet ? context.sp(12) : context.sp(10),
                      fontWeight: FontWeight.w600,
                      color: SiporaTheme.greenDark,
                    ),
                  ),
                ],
              ),
            );
          }),
          Divider(height: context.h(8)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Discount',
                style: TextStyle(
                  fontSize: isTablet ? context.sp(13) : context.sp(11),
                  fontWeight: FontWeight.w700,
                  color: theme.textDark,
                ),
              ),
              Text(
                '-₹${applied.discountAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: isTablet ? context.sp(13) : context.sp(11),
                  fontWeight: FontWeight.w700,
                  color: SiporaTheme.greenDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletSection(SiporaThemeExtension theme) {
    final isTablet = context.isTablet;

    return Padding(
      padding: EdgeInsets.only(bottom: context.h(8)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(10),
          vertical: context.h(8),
        ),
        decoration: BoxDecoration(
          color: theme.greenBg,
          borderRadius: BorderRadius.circular(context.r(10)),
          border: Border.all(color: theme.border, width: 1.w),
        ),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: isTablet ? context.w(22) : context.w(18),
              color: SiporaTheme.greenDark,
            ),
            SizedBox(width: context.w(8)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wallet Balance',
                    style: TextStyle(
                      fontSize: isTablet ? context.sp(13) : context.sp(11),
                      color: theme.textMuted,
                    ),
                  ),
                  _walletLoading
                      ? SizedBox(
                          width: context.w(14),
                          height: context.w(14),
                          child: CircularProgressIndicator(strokeWidth: 2.w),
                        )
                      : Text(
                          '₹${_walletBalance.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: isTablet
                                ? context.sp(16)
                                : context.sp(14),
                            fontWeight: FontWeight.w700,
                            color: theme.textDark,
                          ),
                        ),
                ],
              ),
            ),
            TextButton(
              onPressed: _openWalletRecharge,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Recharge',
                style: TextStyle(
                  fontSize: isTablet ? context.sp(14) : context.sp(12),
                  fontWeight: FontWeight.w600,
                  color: SiporaTheme.greenPill,
                ),
              ),
            ),
            if (_walletBalance > 0) ...[
              SizedBox(width: context.w(4)),
              Switch(
                value: _useWallet,
                activeThumbColor: SiporaTheme.greenDark,
                onChanged: (value) => setState(() => _useWallet = value),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
