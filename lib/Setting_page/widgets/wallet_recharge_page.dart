import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/razorpay_service.dart';
import '../../services/wallet_security_service.dart';
import '../../services/wallet_service.dart';
import '../../theme/sipora_theme.dart';
// ✅ Add this import for PaymentSuccessResult
import '../../Cart_page/widgets/payment_success_overlay.dart';

class WalletRechargePage extends StatefulWidget {
  final double? initialBalance;
  final VoidCallback? onBalanceUpdated;

  const WalletRechargePage({
    super.key,
    this.initialBalance,
    this.onBalanceUpdated,
  });

  @override
  State<WalletRechargePage> createState() => _WalletRechargePageState();
}

class _WalletRechargePageState extends State<WalletRechargePage> {
  static final _currencyFormat = NumberFormat.currency(
    symbol: '\u20B9',
    decimalDigits: 0,
  );

  final TextEditingController _amountController = TextEditingController();
  final RazorpayService _razorpayService = RazorpayService();
  bool _isProcessing = false;
  double _balance = 0;

  String _formatAmount(double amount) => _currencyFormat.format(amount);

  @override
  void initState() {
    super.initState();
    _balance = widget.initialBalance ?? 0;
    _loadBalance();
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpayService.initialize(
      onPaymentSuccess: _onPaymentSuccess,
      onPaymentError: _onPaymentError,
      onPaymentCancel: _onPaymentCancelled,
    );
  }

  Future<void> _loadBalance() async {
    final wallet = await WalletService.fetchWallet();
    if (mounted && wallet != null) {
      setState(() => _balance = wallet.currentBalance);
    }
  }

  void _addAmount(int amountToAdd) {
    final currentAmount = double.tryParse(_amountController.text.trim()) ?? 0;
    final newAmount = currentAmount + amountToAdd;
    _amountController.text = newAmount.toStringAsFixed(0);
  }

  void _onPaymentSuccess(PaymentSuccessResult result) {
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _amountController.clear();
      });
      _loadBalance();
      widget.onBalanceUpdated?.call();
      SiporaTheme.showSnackBar(
        context,
        'Wallet recharged successfully!',
        isError: false,
      );
    }
  }

  void _onPaymentError(String error) {
    if (mounted) {
      setState(() => _isProcessing = false);
      // Don't show cancellation as error
      if (error.toLowerCase().contains('cancelled')) {
        SiporaTheme.showSnackBar(context, 'Payment cancelled', isError: false);
      } else {
        SiporaTheme.showSnackBar(context, error, isError: true);
      }
    }
  }

  void _onPaymentCancelled() {
    if (mounted) {
      setState(() => _isProcessing = false);
      SiporaTheme.showSnackBar(context, 'Payment cancelled', isError: false);
    }
  }

  Future<void> _recharge() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      SiporaTheme.showSnackBar(context, 'Enter a valid amount', isError: true);
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

    setState(() => _isProcessing = true);

    try {
      final authenticated =
          await WalletSecurityService.authenticateForWalletAction(
            context,
            reason: 'Authenticate to recharge your wallet',
          );
      if (!authenticated) {
        if (mounted) setState(() => _isProcessing = false);
        return;
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        SiporaTheme.showSnackBar(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? 'User';
    final email = prefs.getString('user_email') ?? 'user@example.com';
    final contact = prefs.getString('user_phone') ?? '9999999999';

    try {
      // Use the RazorpayService to handle the payment
      // For wallet recharge, we pass an empty cart list
      await _razorpayService.openCheckout(
        amount: amount,
        name: name,
        email: email,
        contact: contact,
        cartItems: [], // Empty cart for wallet recharge
        discountInfo: null,
        walletAmount: 0,
      );
      // Note: _isProcessing will be reset by callbacks
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        SiporaTheme.showSnackBar(
          context,
          'Error: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _razorpayService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;

    return Scaffold(
      backgroundColor: theme.cream,
      appBar: AppBar(
        backgroundColor: theme.white,
        elevation: 0,
        title: Text(
          'Wallet',
          style: TextStyle(color: theme.textDark, fontWeight: FontWeight.w700),
        ),
        iconTheme: IconThemeData(color: theme.textDark),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [SiporaTheme.greenDark, SiporaTheme.greenMid],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: SiporaTheme.greenDark.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Available Balance',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _formatAmount(_balance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Recharge Amount',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: theme.textDark,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.textDark,
                ),
                decoration: InputDecoration(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 16, right: 8),
                    child: Icon(
                      Icons.currency_rupee,
                      color: SiporaTheme.greenDark,
                      size: 22,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0),
                  hintText: 'Enter amount',
                  hintStyle: TextStyle(color: theme.textMuted, fontSize: 16),
                  filled: true,
                  fillColor: theme.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: theme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: SiporaTheme.greenDark,
                      width: 1.5,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: theme.border),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Quick add',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: theme.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.8,
                children: [100, 200, 500, 1000].map((value) {
                  return _QuickAddButton(
                    label: _formatAmount(value.toDouble()),
                    onTap: () => _addAmount(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _recharge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SiporaTheme.greenDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payment, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Recharge via Razorpay',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickAddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    return Material(
      color: theme.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: theme.textDark,
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: SiporaTheme.greenDark.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  size: 16,
                  color: SiporaTheme.greenDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
