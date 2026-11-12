import 'dart:convert';
import 'dart:io' show Platform, SocketException;
import 'dart:async';
import 'dart:math';
import 'dart:ui' show VoidCallback;
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/cart_item.dart';
import '../models/active_discount_models.dart';
import '../models/checkout_discount_info.dart';
import '../Cart_page/widgets/payment_success_overlay.dart';
import 'wallet_service.dart';
import 'shop_service.dart';

class RazorpayService {
  static const String _checkoutUrl =
      "${ApiConfig.baseUrl}/api/razorpay-payments/checkout";
  static const String _verifyUrl =
      "${ApiConfig.baseUrl}/api/razorpay-payments/verify";
  static const String _paymentSaveUrl =
      "${ApiConfig.baseUrl}/api/razorpay-payments/payment-save";
  static const String _invoiceUrl =
      "${ApiConfig.baseUrl}/api/invoice/customer-invoice";
  static const String _confirmationUrl =
      "${ApiConfig.baseUrl}/api/razorpay-payments/payment-confirmation";

  // production key
  static const String _razorpayKeyId = "rzp_live_SVkpspBGiYT39H";

  //development key
  // static const String _razorpayKeyId = "rzp_test_S2KFL68OncpB71";

  late Razorpay _razorpay;
  Function(PaymentSuccessResult result)? _onPaymentSuccess;
  Function(String error)? _onPaymentError;
  VoidCallback? _onPaymentCancel;

  PaymentState _paymentState = PaymentState.idle;
  final StreamController<PaymentState> _stateController =
      StreamController.broadcast();

  bool _isPaymentInProgress = false;

  Stream<PaymentState> get stateStream => _stateController.stream;
  PaymentState get paymentState => _paymentState;

  void initialize({
    required Function(PaymentSuccessResult result) onPaymentSuccess,
    required Function(String error) onPaymentError,
    VoidCallback? onPaymentCancel,
  }) {
    _razorpay = Razorpay();
    _onPaymentSuccess = onPaymentSuccess;
    _onPaymentError = onPaymentError;
    _onPaymentCancel = onPaymentCancel;

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _updateState(PaymentState state) {
    _paymentState = state;
    _stateController.add(state);
  }

  void _resetPaymentState() {
    _isPaymentInProgress = false;
    _updateState(PaymentState.idle);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _isPaymentInProgress = false;
    _processPaymentAfterSuccess(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _isPaymentInProgress = false;

    // ✅ CORRECT: Razorpay.PAYMENT_CANCELLED (2) = user cancelled
    // Razorpay error codes:
    // 0 = NETWORK_ERROR
    // 1 = INVALID_OPTIONS
    // 2 = PAYMENT_CANCELLED
    // 3 = TLS_ERROR
    // 4 = INCOMPATIBLE_PLUGIN
    // 100 = UNKNOWN_ERROR
    final bool isCancellation =
        response.code == Razorpay.PAYMENT_CANCELLED ||
        (response.message?.toLowerCase().contains('cancelled') ?? false) ||
        (response.message?.toLowerCase().contains('cancel') ?? false);

    if (isCancellation) {
      // print(
      //   '🔄 Payment cancelled by user (code: ${response.code}, message: ${response.message})',
      // );
      _updateState(PaymentState.cancelled);

      if (_onPaymentCancel != null) {
        _onPaymentCancel!();
      }
      Future.delayed(const Duration(milliseconds: 500), _resetPaymentState);
      return;
    }

    // Handle other errors using correct Razorpay constants
    String errorMessage = "Payment failed";

    // ✅ CORRECT: Razorpay.NETWORK_ERROR (0) = network error
    if (response.code == Razorpay.NETWORK_ERROR) {
      errorMessage = "Network error. Please check your internet connection.";
      _updateState(PaymentState.networkError);
    }
    // ✅ CORRECT: Razorpay.INVALID_OPTIONS (1) = invalid options
    else if (response.code == Razorpay.INVALID_OPTIONS) {
      errorMessage = "Invalid order configuration. Please try again.";
      _updateState(PaymentState.failed);
    }
    // ✅ CORRECT: Razorpay.TLS_ERROR (3) = TLS/SSL error
    else if (response.code == Razorpay.TLS_ERROR) {
      errorMessage = "Connection security error. Please check your network.";
      _updateState(PaymentState.networkError);
    }
    // ✅ CORRECT: Razorpay.INCOMPATIBLE_PLUGIN (4) = plugin compatibility issue
    else if (response.code == Razorpay.INCOMPATIBLE_PLUGIN) {
      errorMessage = "Payment plugin error. Please update the app.";
      _updateState(PaymentState.failed);
    }
    // ✅ CORRECT: Razorpay.UNKNOWN_ERROR (100) = unknown error
    else if (response.code == Razorpay.UNKNOWN_ERROR) {
      errorMessage = "An unknown error occurred. Please try again.";
      _updateState(PaymentState.failed);
    } else {
      errorMessage = response.message ?? "Payment failed. Please try again.";
      _updateState(PaymentState.failed);
    }

    if (_onPaymentError != null) {
      _onPaymentError!(errorMessage);
    }

    Future.delayed(const Duration(milliseconds: 500), _resetPaymentState);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // External wallet handling
  }

  Future<String> _getActualUserId() async {
    final prefs = await SharedPreferences.getInstance();

    String? userId =
        prefs.getString("user_id") ??
        prefs.getString("userId") ??
        prefs.getString("id") ??
        prefs.getString("user_UUID");

    if ((userId == null || userId.isEmpty) &&
        prefs.containsKey("tea_app_token")) {
      String? token = prefs.getString("tea_app_token");
      if (token != null && token.isNotEmpty) {
        userId = _extractUserIdFromToken(token);
      }
    }

    return userId ?? "GUEST_USER";
  }

  String? _extractUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      String payload = parts[1];
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      final decodedBytes = base64.decode(payload);
      final decodedString = utf8.decode(decodedBytes);
      final Map<String, dynamic> jsonData = json.decode(decodedString);

      return jsonData['user_id'] ??
          jsonData['sub'] ??
          jsonData['id'] ??
          jsonData['userId'];
    } catch (e) {
      return null;
    }
  }

  String _generateZeroAmountReceipt() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return "zero_order_${timestamp}_$random";
  }

  List<String> _getCartProductIds(List<CartItem> cartItems) {
    final productIds = cartItems
        .map((item) => item.productId.trim())
        .where((productId) => productId.isNotEmpty)
        .toList();

    if (productIds.length != cartItems.length) {
      throw Exception("Product ID missing for one or more cart items");
    }

    return productIds;
  }

  String? _resolveDiscountProductId(
    List<CartItem> cartItems,
    CheckoutDiscountInfo? discountInfo,
  ) {
    if (discountInfo == null || discountInfo.discountAmount <= 0) {
      return null;
    }

    if (discountInfo.discountProductId != null &&
        discountInfo.discountProductId!.isNotEmpty) {
      return discountInfo.discountProductId;
    }

    final type = discountInfo.discountType;
    if (type == CartDiscountType.freeCup) {
      final eligible = cartItems
          .where((item) => item.isFreeCupEligible)
          .toList();
      if (eligible.isEmpty) return null;
      eligible.sort((a, b) => a.price.compareTo(b.price));
      return eligible.first.productId;
    }

    if (type == CartDiscountType.event ||
        type == CartDiscountType.cupDiscount) {
      final sorted = List<CartItem>.from(cartItems);
      sorted.sort(
        (a, b) => (b.price * b.quantity).compareTo(a.price * a.quantity),
      );
      return sorted.first.productId;
    }

    return null;
  }

  CheckoutDiscountInfo _withDiscountProduct(
    CheckoutDiscountInfo? discountInfo,
    List<CartItem> cartItems,
  ) {
    if (discountInfo == null) {
      return const CheckoutDiscountInfo(
        discountAmount: 0,
        discountPercentage: 0,
      );
    }

    final productId = _resolveDiscountProductId(cartItems, discountInfo);
    return discountInfo.copyWith(discountProductId: productId);
  }

  Map<String, dynamic> _buildInvoiceBody({
    required String userId,
    required String franchiseId,
    required String receiptId,
    required List<CartItem> cartItems,
    required CheckoutDiscountInfo discountInfo,
    required String platform,
    double walletAmount = 0,
    String? walletTransactionId,
    String? warehouseId,
    String? deliveryAddressId,
    double deliveryFee = 0,
  }) {
    final body = {
      "user_id": userId,
      "franchise_id": franchiseId,
      "receipt_id": receiptId,
      "products_id": _getCartProductIds(cartItems),
      "quantity": cartItems.map((e) => e.quantity).toList(),
      "payment_platform": platform,
      ...discountInfo.toJson(),
      if (walletAmount > 0) ...{
        "wallet_amount": walletAmount,
        "wallet_transaction_id":
            walletTransactionId ?? WalletService.generateTransactionId(),
      },
      if (warehouseId?.isNotEmpty ?? false) "warehouse_id": warehouseId,
      if (deliveryAddressId?.isNotEmpty ?? false)
        "delivery_address_id": deliveryAddressId,
      if (deliveryFee > 0) "delivery_fee": deliveryFee,
    };

    return body;
  }

  String _platformName() {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return 'Web';
  }

  Future<void> openCheckout({
    required double amount,
    required String name,
    required String email,
    required String contact,
    required List<CartItem> cartItems,
    CheckoutDiscountInfo? discountInfo,
    double walletAmount = 0,
    String? warehouseId,
    String? deliveryAddressId,
    double deliveryFee = 0,
  }) async {
    // Prevent duplicate payment attempts
    if (_isPaymentInProgress) {
      return;
    }

    try {
      _getCartProductIds(cartItems);
    } catch (e) {
      _updateState(PaymentState.failed);
      if (_onPaymentError != null) {
        _onPaymentError!(
          "Some cart items are missing product IDs. Please remove and add them again.",
        );
      }
      return;
    }

    // Zero amount handling
    if (amount <= 0) {
      await _processZeroAmountOrder(
        name: name,
        email: email,
        contact: contact,
        cartItems: cartItems,
        discountInfo: discountInfo,
        walletAmount: walletAmount,
        warehouseId: warehouseId,
        deliveryAddressId: deliveryAddressId,
        deliveryFee: deliveryFee,
      );
      return;
    }

    try {
      _isPaymentInProgress = true;
      _updateState(PaymentState.creatingOrder);

      int amountInRupees = amount.round();

      final timeout = TimeoutException(
        "Backend is taking too long to respond.",
      );

      final response = await http
          .post(
            Uri.parse(_checkoutUrl),
            headers: {"Content-Type": "application/json"},
            body: json.encode({
              "amount": amountInRupees,
              "name": name,
              "email": email,
              "contact": contact,
            }),
          )
          .timeout(const Duration(seconds: 10), onTimeout: () => throw timeout);

      if (response.statusCode != 200) {
        String message = "Payment could not be started. Please try again.";
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map<String, dynamic>) {
            final detail = errorData['detail'] ?? errorData['message'];
            if (detail is String && detail.trim().isNotEmpty) {
              message = detail.trim();
            }
          }
        } catch (_) {
          // Keep the safe fallback when the backend response isn't JSON.
        }
        throw Exception(message);
      }

      final orderResponse = json.decode(response.body);

      if (orderResponse['razorpay_order'] == null ||
          orderResponse['razorpay_order']['order_id'] == null) {
        throw Exception("Invalid order response");
      }

      final prefs = await SharedPreferences.getInstance();

      final options = {
        "key": _razorpayKeyId,
        "amount": orderResponse["razorpay_order"]["amount"],
        "currency": "INR",
        "name": "South Indian Filter Coffee",
        "description": "Order Payment",
        "order_id": orderResponse["razorpay_order"]["order_id"],
        "prefill": {"name": name, "email": email, "contact": contact},
        "theme": {"color": "#8B4513"},
        "timeout": 300,
        "retry": 0,
        "modal": {"escape": false},
      };

      // Store pending data
      final pendingData = {
        "receipt": orderResponse["receipt"],
        "razorpay_order": orderResponse["razorpay_order"],
        "customer_details": {"name": name, "email": email, "contact": contact},
        "created_at": DateTime.now().toIso8601String(),
      };

      await prefs.setString("pending_order", json.encode(pendingData));
      await prefs.setString(
        "pending_cart_items",
        json.encode(cartItems.map((e) => e.toMap()).toList()),
      );

      if (discountInfo != null) {
        final discountWithProduct = _withDiscountProduct(
          discountInfo,
          cartItems,
        );
        await prefs.setString(
          "pending_checkout_discount",
          json.encode(discountWithProduct.toJson()),
        );
      } else {
        await prefs.remove("pending_checkout_discount");
      }

      if (walletAmount > 0) {
        await prefs.setDouble("pending_wallet_amount", walletAmount);
      } else {
        await prefs.remove("pending_wallet_amount");
      }

      if (warehouseId?.isNotEmpty ?? false) {
        await prefs.setString("pending_warehouse_id", warehouseId!);
      } else {
        await prefs.remove("pending_warehouse_id");
      }
      if (deliveryAddressId?.isNotEmpty ?? false) {
        await prefs.setString(
          "pending_delivery_address_id",
          deliveryAddressId!,
        );
      } else {
        await prefs.remove("pending_delivery_address_id");
      }
      if (deliveryFee > 0) {
        await prefs.setDouble("pending_delivery_fee", deliveryFee);
      } else {
        await prefs.remove("pending_delivery_fee");
      }

      final franchiseId = ShopService.selectedShopId;
      if (franchiseId != null && franchiseId.isNotEmpty) {
        await prefs.setString("selected_shop_id", franchiseId);
      }

      _updateState(PaymentState.processingPayment);

      // Small delay to ensure UI is ready
      await Future.delayed(const Duration(milliseconds: 100));
      _razorpay.open(options);
    } on TimeoutException catch (_) {
      _isPaymentInProgress = false;
      _updateState(PaymentState.networkError);
      if (_onPaymentError != null) {
        _onPaymentError!("Backend server is slow. Please try again.");
      }
      Future.delayed(const Duration(milliseconds: 500), _resetPaymentState);
    } on SocketException catch (_) {
      _isPaymentInProgress = false;
      _updateState(PaymentState.networkError);
      if (_onPaymentError != null) {
        _onPaymentError!("No internet connection. Please check your network.");
      }
      Future.delayed(const Duration(milliseconds: 500), _resetPaymentState);
    } catch (e) {
      _isPaymentInProgress = false;
      _updateState(PaymentState.failed);
      if (_onPaymentError != null) {
        _onPaymentError!(e.toString());
      }
      Future.delayed(const Duration(milliseconds: 500), _resetPaymentState);
    }
  }

  Future<void> _processZeroAmountOrder({
    required String name,
    required String email,
    required String contact,
    required List<CartItem> cartItems,
    CheckoutDiscountInfo? discountInfo,
    double walletAmount = 0,
    String? warehouseId,
    String? deliveryAddressId,
    double deliveryFee = 0,
  }) async {
    try {
      _updateState(PaymentState.creatingOrder);

      final prefs = await SharedPreferences.getInstance();
      final userId = await _getActualUserId();

      if (userId.startsWith("eyJ")) {
        throw Exception("Invalid user ID format. Please re-login.");
      }

      final franchiseId =
          ShopService.selectedShopId ?? prefs.getString("selected_shop_id");
      if (franchiseId == null || franchiseId.isEmpty) {
        throw Exception("No shop selected");
      }

      final receiptId = _generateZeroAmountReceipt();

      final effectiveDiscount = _withDiscountProduct(
        discountInfo ??
            const CheckoutDiscountInfo(
              discountAmount: 0,
              discountPercentage: 0,
            ),
        cartItems,
      );

      final platform = _platformName();

      final invoiceBody = _buildInvoiceBody(
        userId: userId,
        franchiseId: franchiseId,
        receiptId: receiptId,
        cartItems: cartItems,
        discountInfo: effectiveDiscount,
        platform: platform,
        walletAmount: walletAmount,
        warehouseId: warehouseId,
        deliveryAddressId: deliveryAddressId,
        deliveryFee: deliveryFee,
      );

      final invoiceResponse = await http
          .post(
            Uri.parse(_invoiceUrl),
            headers: {"Content-Type": "application/json"},
            body: json.encode(invoiceBody),
          )
          .timeout(const Duration(seconds: 8));

      if (invoiceResponse.statusCode != 200) {
        throw Exception("Failed to create invoice for zero-amount order");
      }

      final invoiceResult = json.decode(invoiceResponse.body);

      // Clean up
      await prefs.remove("pending_order");
      await prefs.remove("pending_cart_items");
      await prefs.remove("pending_checkout_discount");
      await prefs.remove("pending_wallet_amount");
      await prefs.remove("pending_warehouse_id");
      await prefs.remove("pending_delivery_address_id");
      await prefs.remove("pending_delivery_fee");

      _updateState(PaymentState.success);
      _isPaymentInProgress = false;

      if (_onPaymentSuccess != null) {
        _onPaymentSuccess!(
          PaymentSuccessResult(
            orderId: receiptId,
            invoiceId: invoiceResult['invoice_id'] as int?,
          ),
        );
      }
    } catch (e) {
      _isPaymentInProgress = false;
      _updateState(PaymentState.failed);
      if (_onPaymentError != null) {
        _onPaymentError!(
          "Failed to process zero-amount order: ${e.toString()}",
        );
      }
      Future.delayed(const Duration(milliseconds: 500), _resetPaymentState);
    }
  }

  Future<void> _processPaymentAfterSuccess(
    PaymentSuccessResponse response,
  ) async {
    try {
      _updateState(PaymentState.verifyingPayment);

      if (response.orderId == null || response.paymentId == null) {
        throw Exception("Invalid payment response");
      }

      // Verify payment
      final verifyResponse = await http
          .post(
            Uri.parse(_verifyUrl),
            headers: {"Content-Type": "application/json"},
            body: json.encode({
              "razorpay_order_id": response.orderId,
              "razorpay_payment_id": response.paymentId,
              "razorpay_signature": response.signature,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (verifyResponse.statusCode != 200) {
        throw Exception("Verification failed: ${verifyResponse.body}");
      }

      final prefs = await SharedPreferences.getInstance();

      final userId = await _getActualUserId();

      if (userId.startsWith("eyJ")) {
        throw Exception("Invalid user ID format. Please re-login.");
      }

      final franchiseId =
          ShopService.selectedShopId ?? prefs.getString("selected_shop_id");
      if (franchiseId == null || franchiseId.isEmpty) {
        throw Exception("No shop selected");
      }

      final pendingOrderJson = prefs.getString("pending_order");
      final cartDataJson = prefs.getString("pending_cart_items");
      final pendingDiscountJson = prefs.getString("pending_checkout_discount");
      final pendingWalletAmount = prefs.getDouble("pending_wallet_amount") ?? 0;
      final pendingWarehouseId = prefs.getString("pending_warehouse_id");
      final pendingDeliveryAddressId = prefs.getString(
        "pending_delivery_address_id",
      );
      final pendingDeliveryFee = prefs.getDouble("pending_delivery_fee") ?? 0;

      if (pendingOrderJson == null || cartDataJson == null) {
        throw Exception("Missing order data");
      }

      final pendingOrder = json.decode(pendingOrderJson);
      final cartData = json.decode(cartDataJson);

      List<CartItem> cartItems = cartData
          .map<CartItem>((e) => CartItem.fromMap(e))
          .toList();

      CheckoutDiscountInfo discountInfo = const CheckoutDiscountInfo(
        discountAmount: 0,
        discountPercentage: 0,
      );
      if (pendingDiscountJson != null && pendingDiscountJson.isNotEmpty) {
        final decodedDiscount = json.decode(pendingDiscountJson);
        if (decodedDiscount is Map<String, dynamic>) {
          discountInfo = CheckoutDiscountInfo.fromJson(decodedDiscount);
        }
      }
      discountInfo = _withDiscountProduct(discountInfo, cartItems);

      _updateState(PaymentState.completingOrder);

      final razorpayOrder = pendingOrder["razorpay_order"] ?? {};
      final customerDetails = pendingOrder["customer_details"] ?? {};

      final orderDetails = {
        "success": true,
        "order_count": cartItems.length,
        "receipt": pendingOrder["receipt"]?.toString() ?? "",
        "razorpay_order": {
          "order_id":
              razorpayOrder["order_id"]?.toString() ?? response.orderId ?? "",
          "amount": razorpayOrder["amount"]?.toString() ?? "0",
          "currency": razorpayOrder["currency"]?.toString() ?? "INR",
          "status": razorpayOrder["status"]?.toString() ?? "paid",
        },
        "customer_details": {
          "name": customerDetails["name"]?.toString() ?? "",
          "email": customerDetails["email"]?.toString() ?? "",
          "contact": customerDetails["contact"]?.toString() ?? "",
        },
        "status": "success",
        "created_at":
            pendingOrder["created_at"]?.toString() ??
            DateTime.now().toIso8601String(),
      };

      final paymentSaveBody = {
        "user_id": userId,
        "franchise_id": franchiseId,
        "receipt": pendingOrder["receipt"]?.toString() ?? "",
        "razorpay_payment_id": response.paymentId,
        "razorpay_order_id": response.orderId,
        "razorpay_signature": response.signature ?? "",
        "order_details": orderDetails,
      };

      final paymentSaveResponse = await http
          .post(
            Uri.parse(_paymentSaveUrl),
            headers: {"Content-Type": "application/json"},
            body: json.encode(paymentSaveBody),
          )
          .timeout(const Duration(seconds: 8));

      if (paymentSaveResponse.statusCode != 200) {
        throw Exception("Failed to save payment details");
      }

      final platform = _platformName();

      final invoiceBody = _buildInvoiceBody(
        userId: userId,
        franchiseId: franchiseId,
        receiptId: pendingOrder["receipt"]?.toString() ?? "",
        cartItems: cartItems,
        discountInfo: discountInfo,
        platform: platform,
        walletAmount: pendingWalletAmount,
        warehouseId: pendingWarehouseId,
        deliveryAddressId: pendingDeliveryAddressId,
        deliveryFee: pendingDeliveryFee,
      );

      final invoiceResponse = await http
          .post(
            Uri.parse(_invoiceUrl),
            headers: {"Content-Type": "application/json"},
            body: json.encode(invoiceBody),
          )
          .timeout(const Duration(seconds: 8));

      int? invoiceId;
      if (invoiceResponse.statusCode == 200) {
        final invoiceResult = json.decode(invoiceResponse.body);
        invoiceId = invoiceResult['invoice_id'] as int?;
      }

      // Send confirmation
      await http
          .post(
            Uri.parse(_confirmationUrl),
            headers: {"Content-Type": "application/json"},
            body: json.encode({"razorpay_order_id": response.orderId}),
          )
          .timeout(const Duration(seconds: 8));

      // Clean up
      await prefs.remove("pending_order");
      await prefs.remove("pending_cart_items");
      await prefs.remove("pending_checkout_discount");
      await prefs.remove("pending_wallet_amount");
      await prefs.remove("pending_warehouse_id");
      await prefs.remove("pending_delivery_address_id");
      await prefs.remove("pending_delivery_fee");

      _updateState(PaymentState.success);
      _isPaymentInProgress = false;

      if (_onPaymentSuccess != null) {
        _onPaymentSuccess!(
          PaymentSuccessResult(
            orderId:
                pendingOrder["receipt"]?.toString() ?? response.orderId ?? '',
            invoiceId: invoiceId,
          ),
        );
      }
    } catch (e) {
      _isPaymentInProgress = false;
      _updateState(PaymentState.failed);
      if (_onPaymentError != null) {
        _onPaymentError!(
          "Payment was successful but order completion failed: ${e.toString()}",
        );
      }
      Future.delayed(const Duration(milliseconds: 500), _resetPaymentState);
    }
  }

  void reset() {
    _resetPaymentState();
  }

  bool get isPaymentInProgress => _isPaymentInProgress;

  void dispose() {
    _razorpay.clear();
    _stateController.close();
  }
}

enum PaymentState {
  idle,
  creatingOrder,
  processingPayment,
  verifyingPayment,
  completingOrder,
  success,
  failed,
  cancelled,
  networkError,
}
