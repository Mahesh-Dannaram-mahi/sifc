import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'storage_service.dart';
import 'jwt_service.dart';

class WalletData {
  final double currentBalance;
  final List<WalletTransaction> transactions;

  const WalletData({
    required this.currentBalance,
    required this.transactions,
  });

  factory WalletData.fromJson(Map<String, dynamic> json) {
    final txList = (json['transactions'] as List<dynamic>? ?? [])
        .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
        .toList();
    return WalletData(
      currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0,
      transactions: txList,
    );
  }
}

class WalletTransaction {
  final String transactionId;
  final String transactionType;
  final double amount;
  final String? referenceId;
  final String? createdAt;

  const WalletTransaction({
    required this.transactionId,
    required this.transactionType,
    required this.amount,
    this.referenceId,
    this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      transactionId: json['transaction_id']?.toString() ?? '',
      transactionType: json['transaction_type']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      referenceId: json['reference_id']?.toString(),
      createdAt: json['createdatetime']?.toString(),
    );
  }
}

class WalletService {
  static const String _walletBase =
      '${ApiConfig.baseUrl}/api/customer_wallet';
  static const String _checkoutUrl =
      '${ApiConfig.baseUrl}/api/razorpay-payments/checkout';
  static const String _verifyUrl =
      '${ApiConfig.baseUrl}/api/razorpay-payments/verify';
  static const String _paymentSaveUrl =
      '${ApiConfig.baseUrl}/api/razorpay-payments/payment-save';
  static const String _razorpayKeyId = 'rzp_live_SVkpspBGiYT39H';
  // static const String _razorpayKeyId = 'rzp_test_S2KFL68OncpB71';

  static Future<String?> _resolveUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = await StorageService.getUserId();
    userId ??= prefs.getString('user_id');
    if (userId == null) {
      final token = prefs.getString('tea_app_token');
      if (token != null) {
        userId = JwtService.extractUserId(token);
      }
    }
    return userId;
  }

  static Future<WalletData?> fetchWallet() async {
    final userId = await _resolveUserId();
    if (userId == null || userId.isEmpty) return null;

    final response = await http
        .get(Uri.parse('$_walletBase/wallet/$userId'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) return null;
    final decoded = json.decode(response.body) as Map<String, dynamic>;
    if (decoded['success'] != true) return null;
    return WalletData.fromJson(decoded);
  }

  static String generateTransactionId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(999999);
    return 'wallet_txn_${ts}_$rand';
  }

  static Future<double?> rechargeWallet({
    required Razorpay razorpay,
    required double amount,
    required String name,
    required String email,
    required String contact,
    required void Function(String message) onError,
    required void Function(double newBalance) onSuccess,
  }) async {
    final userId = await _resolveUserId();
    if (userId == null || userId.isEmpty) {
      onError('Please log in to recharge wallet');
      return null;
    }

    if (amount <= 0) {
      onError('Enter a valid recharge amount');
      return null;
    }

    try {
      final checkoutResponse = await http
          .post(
            Uri.parse(_checkoutUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'amount': amount.round(),
              'name': name,
              'email': email,
              'contact': contact,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (checkoutResponse.statusCode != 200) {
        onError('Could not start wallet recharge');
        return null;
      }

      final orderResponse =
          json.decode(checkoutResponse.body) as Map<String, dynamic>;
      final razorpayOrder =
          orderResponse['razorpay_order'] as Map<String, dynamic>?;
      if (razorpayOrder == null || razorpayOrder['order_id'] == null) {
        onError('Invalid recharge order response');
        return null;
      }

      final completer = Completer<double?>();

      void handleFailure(PaymentFailureResponse response) {
        onError(response.message ?? 'Recharge payment failed');
        if (!completer.isCompleted) completer.complete(null);
      }

      void handleSuccess(PaymentSuccessResponse response) async {

        try {
          final verifyResponse = await http.post(
            Uri.parse(_verifyUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'razorpay_order_id': response.orderId,
              'razorpay_payment_id': response.paymentId,
              'razorpay_signature': response.signature,
            }),
          );

          if (verifyResponse.statusCode != 200) {
            onError('Payment verification failed');
            if (!completer.isCompleted) completer.complete(null);
            return;
          }

          final orderDetails = {
            'success': true,
            'order_count': 1,
            'receipt': orderResponse['receipt'],
            'razorpay_order': razorpayOrder,
            'customer_details': {
              'name': name,
              'email': email,
              'contact': contact,
            },
            'status': 'success',
            'created_at': DateTime.now().toIso8601String(),
          };

          await http.post(
            Uri.parse(_paymentSaveUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'user_id': userId,
              'franchise_id': '',
              'receipt': orderResponse['receipt'],
              'razorpay_payment_id': response.paymentId,
              'razorpay_order_id': response.orderId,
              'razorpay_signature': response.signature,
              'order_details': orderDetails,
            }),
          );

          final txnId = generateTransactionId();
          final rechargeResponse = await http.post(
            Uri.parse('$_walletBase/wallet/recharge'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'user_id': userId,
              'amount': amount,
              'transaction_id': txnId,
              'razorpay_order_id': response.orderId,
            }),
          );

          if (rechargeResponse.statusCode != 200) {
            onError('Wallet recharge failed after payment');
            if (!completer.isCompleted) completer.complete(null);
            return;
          }

          final result =
              json.decode(rechargeResponse.body) as Map<String, dynamic>;
          final newBalance =
              (result['current_balance'] as num?)?.toDouble() ?? amount;
          onSuccess(newBalance);
          if (!completer.isCompleted) completer.complete(newBalance);
        } catch (e) {
          onError('Wallet recharge failed: $e');
          if (!completer.isCompleted) completer.complete(null);
        }
      }

      razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handleSuccess);
      razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handleFailure);

      razorpay.open({
        'key': _razorpayKeyId,
        'amount': razorpayOrder['amount'],
        'currency': 'INR',
        'name': 'South Indian Filter Coffee',
        'description': 'Wallet Recharge',
        'order_id': razorpayOrder['order_id'],
        'prefill': {'name': name, 'email': email, 'contact': contact},
        'theme': {'color': '#8B4513'},
      });

      return completer.future;
    } catch (e) {
      onError('Wallet recharge error: $e');
      return null;
    }
  }
}
