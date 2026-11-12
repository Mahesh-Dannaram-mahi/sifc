// lib/Cart_page/warehouse_checkout_page.dart Address selection + delivery fee preview for warehouse product checkout
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_item.dart';
import '../models/user_address.dart';
import '../services/address_service.dart';
import '../services/razorpay_service.dart';
import '../theme/sipora_theme.dart';
import '../utils/screen_utils.dart';
import 'widgets/payment_success_overlay.dart';

class WarehouseCheckoutPage extends StatefulWidget {
  final List<CartItem> warehouseItems;
  final double productTotal;
  final String? warehousePincode;
  final String? warehouseId;
  final VoidCallback? onSuccess;

  const WarehouseCheckoutPage({
    super.key,
    required this.warehouseItems,
    required this.productTotal,
    this.warehousePincode,
    this.warehouseId,
    this.onSuccess,
  });

  @override
  State<WarehouseCheckoutPage> createState() => _WarehouseCheckoutPageState();
}

class _WarehouseCheckoutPageState extends State<WarehouseCheckoutPage> {
  final RazorpayService _razorpayService = RazorpayService();

  List<UserAddress> _addresses = [];
  String? _selectedAddressId;
  bool _addrLoading = true;
  double _deliveryFee = 60.0;
  bool _feeLoading = false;
  bool _isProcessing = false;
  bool _showAddForm = false;

  // New address form
  final _formKey = GlobalKey<FormState>();
  final _houseCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  String _addrType = 'home';
  bool _isDefault = false;
  bool _savingAddr = false;

  @override
  void initState() {
    super.initState();
    _razorpayService.initialize(
      onPaymentSuccess: _onPaymentSuccess,
      onPaymentError: (e) => _showError(e.toString()),
      onPaymentCancel: () => setState(() => _isProcessing = false),
    );
    _loadAddresses();
  }

  @override
  void dispose() {
    _houseCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _landmarkCtrl.dispose();
    _razorpayService.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    setState(() => _addrLoading = true);
    final list = await AddressService.fetchAddresses();
    setState(() {
      _addresses = list;
      if (list.isNotEmpty) {
        // Prefer the default address; fall back to first
        final def = list.firstWhere(
          (a) => a.isDefault,
          orElse: () => list.first,
        );
        _selectedAddressId = def.addressId.isNotEmpty
            ? def.addressId
            : list.first.addressId;
      }
      _addrLoading = false;
    });
    if (_selectedAddressId != null) _refreshDeliveryFee();
  }

  Future<void> _refreshDeliveryFee() async {
    if (widget.warehousePincode == null) return;
    final addr = _addresses.firstWhere(
      (a) => a.addressId == _selectedAddressId,
      orElse: () => _addresses.first,
    );
    if (addr.pincode.isEmpty) return;
    setState(() => _feeLoading = true);
    final fee = await AddressService.getDeliveryFee(
      pickupPincode: widget.warehousePincode!,
      deliveryPincode: addr.pincode,
    );
    setState(() {
      _deliveryFee = fee;
      _feeLoading = false;
    });
  }

  Future<void> _saveNewAddress() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _savingAddr = true);
    final payload = {
      'type': _addrType,
      'house': _houseCtrl.text.trim(),
      'streetArea': _streetCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'state': _stateCtrl.text.trim(),
      'pincode': _pincodeCtrl.text.trim(),
      'landmark': _landmarkCtrl.text.trim(),
      'country': 'India',
      'is_default': _isDefault,
      'fullAddress':
          '${_houseCtrl.text.trim()}, ${_streetCtrl.text.trim()}, ${_cityCtrl.text.trim()}, ${_stateCtrl.text.trim()} - ${_pincodeCtrl.text.trim()}',
    };
    final result = await AddressService.createAddress(payload);
    setState(() => _savingAddr = false);
    if (result.success) {
      _showMsg('Address saved');
      await _loadAddresses();
      if (result.addressId != null) {
        setState(() {
          _selectedAddressId = result.addressId;
          _showAddForm = false;
        });
      }
    } else {
      _showError(result.error ?? 'Failed to save address');
    }
  }

  void _showMsg(String msg) =>
      SiporaTheme.showSnackBar(context, msg, isError: false);
  void _showError(String msg) =>
      SiporaTheme.showSnackBar(context, msg, isError: true);

  double get _grandTotal => widget.productTotal + _deliveryFee;

  Future<void> _proceedToPayment() async {
    if (_selectedAddressId == null) {
      _showError('Please select a delivery address');
      return;
    }
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('user_name') ?? 'User';
      final email = prefs.getString('user_email') ?? 'user@example.com';
      final contact = prefs.getString('user_phone') ?? '9999999999';
      await _razorpayService.openCheckout(
        amount: _grandTotal,
        name: name,
        email: email,
        contact: contact,
        cartItems: widget.warehouseItems,
        warehouseId: widget.warehouseId,
        deliveryAddressId: _selectedAddressId,
        deliveryFee: _deliveryFee,
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Payment failed: $e');
    }
  }

  void _onPaymentSuccess(PaymentSuccessResult result) {
    setState(() => _isProcessing = false);
    PaymentSuccessOverlay.show(
      context,
      result: result,
      onDone: () {
        Navigator.of(context).pop();
        widget.onSuccess?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;

    return Scaffold(
      backgroundColor: theme.cream,
      appBar: AppBar(
        backgroundColor: theme.white,
        elevation: 0,
        title: Text(
          'Checkout',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: theme.textDark,
            fontSize: isTablet ? context.sp(20) : context.sp(18),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            color: theme.textDark,
            size: isTablet ? context.w(28) : context.w(24),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _addrLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(context.w(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderSummary(theme),
                  SizedBox(height: context.h(16)),
                  _buildAddressSection(theme),
                  SizedBox(height: context.h(16)),
                  if (_showAddForm) _buildNewAddressForm(theme),
                  SizedBox(height: context.h(16)),
                  _buildPriceBreakdown(theme),
                  SizedBox(height: context.h(8)),
                  _buildCodNote(theme),
                  SizedBox(height: context.h(80)),
                ],
              ),
            ),
      bottomNavigationBar: _buildPayButton(theme),
    );
  }

  // ─── UI helpers ────────────────────────────────────────────────────────────

  Widget _buildOrderSummary(SiporaThemeExtension theme) {
    final isTablet = context.isTablet;

    return Container(
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(context.r(16)),
        border: Border.all(color: theme.border, width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: isTablet ? context.sp(17) : context.sp(15),
              color: theme.textDark,
            ),
          ),
          SizedBox(height: context.h(12)),
          ...widget.warehouseItems.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: context.h(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item.name} ×${item.quantity}',
                      style: TextStyle(
                        fontSize: isTablet ? context.sp(14) : context.sp(13),
                        color: theme.textDark,
                      ),
                    ),
                  ),
                  Text(
                    '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? context.sp(14) : context.sp(13),
                      color: theme.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection(SiporaThemeExtension theme) {
    final isTablet = context.isTablet;

    return Container(
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(context.r(16)),
        border: Border.all(color: theme.border, width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Address',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: isTablet ? context.sp(17) : context.sp(15),
              color: theme.textDark,
            ),
          ),
          SizedBox(height: context.h(12)),
          if (_addresses.isEmpty)
            Text(
              'No saved addresses. Add one below.',
              style: TextStyle(
                color: theme.textMuted,
                fontSize: isTablet ? context.sp(14) : context.sp(13),
              ),
            )
          else
            ..._addresses.map(
              (addr) => GestureDetector(
                onTap: () {
                  setState(() => _selectedAddressId = addr.addressId);
                  _refreshDeliveryFee();
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: context.h(10)),
                  padding: EdgeInsets.all(context.w(12)),
                  decoration: BoxDecoration(
                    color: _selectedAddressId == addr.addressId
                        ? SiporaTheme.greenLight.withValues(alpha: 0.12)
                        : theme.cream,
                    borderRadius: BorderRadius.circular(context.r(12)),
                    border: Border.all(
                      color: _selectedAddressId == addr.addressId
                          ? SiporaTheme.greenDark
                          : theme.border,
                      width: _selectedAddressId == addr.addressId ? 2.w : 1.w,
                    ),
                  ),
                  child: Row(
                    children: [
                      Radio<String>(
                        value: addr.addressId,
                        groupValue: _selectedAddressId,
                        activeColor: SiporaTheme.greenDark,
                        onChanged: (v) {
                          setState(() => _selectedAddressId = v);
                          _refreshDeliveryFee();
                        },
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  addr.type.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: isTablet
                                        ? context.sp(12)
                                        : context.sp(11),
                                    fontWeight: FontWeight.w700,
                                    color: SiporaTheme.greenDark,
                                  ),
                                ),
                                if (addr.isDefault) ...[
                                  SizedBox(width: context.w(6)),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: context.w(6),
                                      vertical: context.h(1),
                                    ),
                                    decoration: BoxDecoration(
                                      color: SiporaTheme.greenDark,
                                      borderRadius: BorderRadius.circular(
                                        context.r(4),
                                      ),
                                    ),
                                    child: Text(
                                      'DEFAULT',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isTablet
                                            ? context.sp(10)
                                            : context.sp(9),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: context.h(2)),
                            Text(
                              addr.displayText,
                              style: TextStyle(
                                fontSize: isTablet
                                    ? context.sp(13)
                                    : context.sp(12),
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
            ),
          SizedBox(height: context.h(4)),
          TextButton.icon(
            onPressed: () => setState(() => _showAddForm = !_showAddForm),
            icon: Icon(
              _showAddForm
                  ? Icons.remove_circle_outline
                  : Icons.add_circle_outline,
              size: isTablet ? context.w(20) : context.w(18),
              color: SiporaTheme.greenDark,
            ),
            label: Text(
              _showAddForm ? 'Cancel' : 'Add New Address',
              style: TextStyle(
                color: SiporaTheme.greenDark,
                fontWeight: FontWeight.w600,
                fontSize: isTablet ? context.sp(14) : context.sp(13),
              ),
            ),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
          ),
        ],
      ),
    );
  }

  Widget _buildNewAddressForm(SiporaThemeExtension theme) {
    final isTablet = context.isTablet;

    return Container(
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(context.r(16)),
        border: Border.all(
          color: SiporaTheme.greenLight.withValues(alpha: 0.4),
          width: 1.w,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Address',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: isTablet ? context.sp(16) : context.sp(14),
                color: theme.textDark,
              ),
            ),
            SizedBox(height: context.h(12)),
            _field('House / Flat No. *', _houseCtrl, required: true),
            SizedBox(height: context.h(10)),
            _field('Street / Area', _streetCtrl),
            SizedBox(height: context.h(10)),
            Row(
              children: [
                Expanded(child: _field('City *', _cityCtrl, required: true)),
                SizedBox(width: context.w(10)),
                Expanded(child: _field('State *', _stateCtrl, required: true)),
              ],
            ),
            SizedBox(height: context.h(10)),
            Row(
              children: [
                Expanded(
                  child: _field(
                    'Pincode *',
                    _pincodeCtrl,
                    required: true,
                    keyboard: TextInputType.number,
                  ),
                ),
                SizedBox(width: context.w(10)),
                Expanded(child: _field('Landmark', _landmarkCtrl)),
              ],
            ),
            SizedBox(height: context.h(10)),
            DropdownButtonFormField<String>(
              value: _addrType,
              decoration: _inputDecoration('Address Type'),
              items: ['home', 'work', 'other']
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(t[0].toUpperCase() + t.substring(1)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _addrType = v ?? 'home'),
            ),
            SizedBox(height: context.h(10)),
            CheckboxListTile(
              value: _isDefault,
              contentPadding: EdgeInsets.zero,
              activeColor: SiporaTheme.greenDark,
              title: Text(
                'Set as default address',
                style: TextStyle(
                  fontSize: isTablet ? context.sp(14) : context.sp(13),
                  color: theme.textDark,
                ),
              ),
              onChanged: (v) => setState(() => _isDefault = v ?? false),
            ),
            SizedBox(height: context.h(8)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savingAddr ? null : _saveNewAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SiporaTheme.greenDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.r(12)),
                  ),
                  padding: EdgeInsets.symmetric(vertical: context.h(14)),
                ),
                child: _savingAddr
                    ? SizedBox(
                        width: context.w(18),
                        height: context.w(18),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Save Address',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: isTablet ? context.sp(16) : context.sp(14),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool required = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    final isTablet = context.isTablet;

    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: _inputDecoration(label),
      style: TextStyle(fontSize: isTablet ? context.sp(14) : context.sp(13)),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }

  InputDecoration _inputDecoration(String label) {
    final isTablet = context.isTablet;

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: isTablet ? context.sp(13) : context.sp(12),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(context.r(10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(context.r(10)),
        borderSide: const BorderSide(color: SiporaTheme.greenDark),
      ),
      isDense: true,
      contentPadding: EdgeInsets.symmetric(
        horizontal: context.w(12),
        vertical: context.h(10),
      ),
    );
  }

  Widget _buildPriceBreakdown(SiporaThemeExtension theme) {
    final isTablet = context.isTablet;

    return Container(
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(context.r(16)),
        border: Border.all(color: theme.border, width: 1.w),
      ),
      child: Column(
        children: [
          _priceRow(
            'Products',
            '₹${widget.productTotal.toStringAsFixed(0)}',
            theme,
          ),
          SizedBox(height: context.h(8)),
          _priceRow(
            'Delivery fee',
            _feeLoading ? '...' : '₹${_deliveryFee.toStringAsFixed(0)}',
            theme,
          ),
          Divider(height: context.h(20)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: isTablet ? context.sp(18) : context.sp(16),
                  color: theme.textDark,
                ),
              ),
              Text(
                '₹${_grandTotal.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: isTablet ? context.sp(18) : context.sp(16),
                  color: SiporaTheme.greenDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, SiporaThemeExtension theme) {
    final isTablet = context.isTablet;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? context.sp(14) : context.sp(13),
            color: theme.textMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTablet ? context.sp(14) : context.sp(13),
            fontWeight: FontWeight.w600,
            color: theme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildCodNote(SiporaThemeExtension theme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(12),
        vertical: context.h(10),
      ),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: Colors.amber.shade200, width: 1.w),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 16)),
          SizedBox(width: context.w(8)),
          Expanded(
            child: Text(
              'Cash on Delivery is available — select it in the payment window.',
              style: TextStyle(
                fontSize: context.sp(12),
                color: Colors.amber.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton(SiporaThemeExtension theme) {
    final isTablet = context.isTablet;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.w(16),
          context.h(8),
          context.w(16),
          context.h(16),
        ),
        child: SizedBox(
          width: double.infinity,
          height: isTablet ? context.h(60) : context.h(54),
          child: ElevatedButton(
            onPressed: (_isProcessing || _selectedAddressId == null)
                ? null
                : _proceedToPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: SiporaTheme.greenDark,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.r(16)),
              ),
            ),
            child: _isProcessing
                ? SizedBox(
                    width: context.w(22),
                    height: context.w(22),
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'Pay ₹${_grandTotal.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: isTablet ? context.sp(18) : context.sp(16),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
