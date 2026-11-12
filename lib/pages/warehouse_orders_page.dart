// lib/pages/warehouse_orders_page.dart
// Shows the user's warehouse order history with tracking timeline
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import '../theme/sipora_theme.dart';
import '../utils/screen_utils.dart';

class WarehouseOrdersPage extends StatefulWidget {
  const WarehouseOrdersPage({super.key});

  @override
  State<WarehouseOrdersPage> createState() => _WarehouseOrdersPageState();
}

class _WarehouseOrdersPageState extends State<WarehouseOrdersPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('tea_app_token');
  }

  Future<void> _fetchOrders() async {
    setState(() => _loading = true);
    final token = await _getToken();
    if (token == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final resp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/warehouse-orders/my-orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'accept': 'application/json',
        },
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          _orders = List<Map<String, dynamic>>.from(data['orders'] ?? []);
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
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
        centerTitle: true,
        title: Text(
          'My Orders',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: theme.textDark,
            fontSize: isTablet ? context.sp(20) : context.sp(18),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            color: theme.textDark,
            size: isTablet ? context.w(28) : context.w(24),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: theme.textDark,
              size: isTablet ? context.w(24) : context.w(20),
            ),
            onPressed: _fetchOrders,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
          ? _buildEmpty(theme)
          : RefreshIndicator(
              onRefresh: _fetchOrders,
              child: ListView.builder(
                padding: EdgeInsets.all(context.w(16)),
                itemCount: _orders.length,
                itemBuilder: (ctx, i) => _buildOrderCard(_orders[i], theme),
              ),
            ),
    );
  }

  Widget _buildEmpty(SiporaThemeExtension theme) {
    final isTablet = context.isTablet;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '📦',
            style: TextStyle(
              fontSize: isTablet ? context.sp(72) : context.sp(60),
            ),
          ),
          SizedBox(height: context.h(16)),
          Text(
            'No orders yet',
            style: TextStyle(
              fontSize: isTablet ? context.sp(22) : context.sp(18),
              fontWeight: FontWeight.w700,
              color: theme.textDark,
            ),
          ),
          SizedBox(height: context.h(8)),
          Text(
            'Your warehouse orders will appear here',
            style: TextStyle(
              fontSize: isTablet ? context.sp(16) : context.sp(14),
              color: theme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(
    Map<String, dynamic> order,
    SiporaThemeExtension theme,
  ) {
    final isTablet = context.isTablet;
    final status = order['shipment_status']?.toString() ?? 'pending';
    final productName = order['product_name']?.toString() ?? 'Product';
    final orderId = order['order_id']?.toString() ?? '';
    final createdAt = order['created_at']?.toString() ?? '';
    final total = (order['total_price'] as num?)?.toDouble() ?? 0;
    final deliveryFee = (order['delivery_fee'] as num?)?.toDouble() ?? 0;
    final deliveryAddr =
        order['delivery_address']?.toString() ??
        order['city']?.toString() ??
        '';
    final trackingUrl = order['tracking_url']?.toString();
    final images = order['products_images']?.toString() ?? '';
    final firstImage = images.split(',').first.trim();

    return Container(
      margin: EdgeInsets.only(bottom: context.h(16)),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(context.r(16)),
        border: Border.all(color: theme.border, width: 1.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(context.w(14)),
            decoration: BoxDecoration(
              color: theme.cream,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(context.r(16)),
              ),
            ),
            child: Row(
              children: [
                if (firstImage.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(context.r(8)),
                    child: Image.network(
                      firstImage,
                      width: isTablet ? context.w(56) : context.w(48),
                      height: isTablet ? context.w(56) : context.w(48),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: isTablet ? context.w(56) : context.w(48),
                        height: isTablet ? context.w(56) : context.w(48),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(context.r(8)),
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.grey,
                          size: context.w(24),
                        ),
                      ),
                    ),
                  ),
                SizedBox(width: context.w(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: isTablet ? context.sp(16) : context.sp(14),
                          color: theme.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Order #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}…',
                        style: TextStyle(
                          fontSize: isTablet ? context.sp(12) : context.sp(11),
                          color: theme.textMuted,
                        ),
                      ),
                      if (createdAt.isNotEmpty)
                        Text(
                          _formatDate(createdAt),
                          style: TextStyle(
                            fontSize: isTablet
                                ? context.sp(12)
                                : context.sp(11),
                            color: theme.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                _statusBadge(status),
              ],
            ),
          ),

          // Tracking timeline
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(14),
              context.h(12),
              context.w(14),
              0,
            ),
            child: _buildTimeline(status, order, theme),
          ),

          // Price + address
          Padding(
            padding: EdgeInsets.all(context.w(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (deliveryAddr.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: context.w(14),
                        color: theme.textMuted,
                      ),
                      SizedBox(width: context.w(4)),
                      Expanded(
                        child: Text(
                          deliveryAddr,
                          style: TextStyle(
                            fontSize: isTablet
                                ? context.sp(13)
                                : context.sp(12),
                            color: theme.textMuted,
                          ),
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                SizedBox(height: context.h(8)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${total.toStringAsFixed(0)} + ₹${deliveryFee.toStringAsFixed(0)} delivery',
                      style: TextStyle(
                        fontSize: isTablet ? context.sp(13) : context.sp(12),
                        color: theme.textMuted,
                      ),
                    ),
                    Text(
                      '₹${(total + deliveryFee).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: isTablet ? context.sp(17) : context.sp(15),
                        color: SiporaTheme.greenDark,
                      ),
                    ),
                  ],
                ),
                if (trackingUrl != null && trackingUrl.isNotEmpty) ...[
                  SizedBox(height: context.h(10)),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(trackingUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      icon: Icon(Icons.open_in_new, size: context.w(14)),
                      label: Text(
                        'Track Shipment',
                        style: TextStyle(
                          fontSize: isTablet ? context.sp(14) : context.sp(13),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SiporaTheme.greenDark,
                        side: BorderSide(
                          color: SiporaTheme.greenDark,
                          width: 1.w,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.r(10)),
                        ),
                        padding: EdgeInsets.symmetric(vertical: context.h(10)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tracking timeline ───────────────────────────────────────────────────

  static const _steps = [
    {'key': 'pending', 'label': 'Order\nPlaced', 'icon': '🛒'},
    {'key': 'pickup_assigned', 'label': 'Pickup\nAssigned', 'icon': '🏭'},
    {'key': 'picked_up', 'label': 'Picked\nUp', 'icon': '📦'},
    {'key': 'in_transit', 'label': 'In\nTransit', 'icon': '🚚'},
    {'key': 'out_for_delivery', 'label': 'Out for\nDelivery', 'icon': '🛵'},
    {'key': 'delivered', 'label': 'Delivered', 'icon': '✅'},
  ];

  static const _stepOrder = [
    'pending',
    'pickup_assigned',
    'picked_up',
    'in_transit',
    'out_for_delivery',
    'delivered',
  ];

  Widget _buildTimeline(
    String status,
    Map<String, dynamic> order,
    SiporaThemeExtension theme,
  ) {
    final isTablet = context.isTablet;
    final currentIndex = _stepOrder.indexOf(status);
    final iconSize = isTablet ? context.w(38) : context.w(34);
    final fontSize = isTablet ? context.sp(9) : context.sp(8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: isTablet ? context.h(80) : context.h(72),
          child: Row(
            children: List.generate(_steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                // Connector line
                final stepIdx = i ~/ 2;
                final active = stepIdx < currentIndex;
                return Expanded(
                  child: Container(
                    height: context.h(2),
                    color: active
                        ? SiporaTheme.greenDark
                        : Colors.grey.shade200,
                  ),
                );
              }
              final stepIdx = i ~/ 2;
              final step = _steps[stepIdx];
              final done = stepIdx <= currentIndex;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: done
                          ? SiporaTheme.greenDark.withValues(alpha: 0.12)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: done
                            ? SiporaTheme.greenDark
                            : Colors.grey.shade300,
                        width: stepIdx == currentIndex ? 2.5.w : 1.5.w,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        step['icon']!,
                        style: TextStyle(
                          fontSize: isTablet ? context.sp(16) : context.sp(14),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: context.h(4)),
                  Text(
                    step['label']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: done
                          ? SiporaTheme.greenDark
                          : Colors.grey.shade400,
                      fontWeight: done ? FontWeight.w700 : FontWeight.normal,
                      height: 1.2,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
        // Dates
        if (order['shiprocket_pickup_date'] != null ||
            order['shiprocket_estimated_date'] != null)
          Padding(
            padding: EdgeInsets.only(top: context.h(4)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (order['shiprocket_pickup_date'] != null)
                  _dateChip(
                    '📦 Pickup',
                    order['shiprocket_pickup_date'],
                    theme,
                  ),
                if (order['shiprocket_estimated_date'] != null)
                  _dateChip(
                    '📅 Est. Delivery',
                    order['shiprocket_estimated_date'],
                    theme,
                  ),
                if (order['shiprocket_drop_date'] != null)
                  _dateChip(
                    '✅ Delivered',
                    order['shiprocket_drop_date'],
                    theme,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _dateChip(String label, dynamic dateStr, SiporaThemeExtension theme) {
    final isTablet = context.isTablet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? context.sp(10) : context.sp(9),
            color: theme.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          _formatDate(dateStr?.toString() ?? ''),
          style: TextStyle(
            fontSize: isTablet ? context.sp(11) : context.sp(10),
            color: theme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    final isTablet = context.isTablet;
    final colors = <String, (Color, Color)>{
      'pending': (Colors.amber.shade100, Colors.amber.shade900),
      'pickup_assigned': (Colors.blue.shade100, Colors.blue.shade900),
      'picked_up': (Colors.indigo.shade100, Colors.indigo.shade900),
      'in_transit': (Colors.purple.shade100, Colors.purple.shade900),
      'out_for_delivery': (Colors.orange.shade100, Colors.orange.shade900),
      'delivered': (Colors.green.shade100, Colors.green.shade900),
      'cancelled': (Colors.red.shade100, Colors.red.shade900),
    };
    final (bg, fg) =
        colors[status] ?? (Colors.grey.shade100, Colors.grey.shade800);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(10),
        vertical: context.h(4),
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(context.r(20)),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          fontSize: isTablet ? context.sp(11) : context.sp(10),
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  String _formatDate(String s) {
    if (s.isEmpty) return '';
    try {
      final d = DateTime.parse(s);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return s.substring(0, 10);
    }
  }
}
