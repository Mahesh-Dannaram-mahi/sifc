import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/sipora_theme.dart';
import '../../../utils/screen_utils.dart';
import '../../../services/storage_service.dart';
import '../../../config/api_config.dart';
import '../widgets/universal_filter.dart';

class ShopRecentOrders extends StatefulWidget {
  final String? franchiseId;
  final DateViewMode dateViewMode;
  final DateTime selectedDate;
  final DateTime? weekStart;
  final DateTime? weekEnd;
  final int limit;

  const ShopRecentOrders({
    super.key,
    this.franchiseId,
    required this.dateViewMode,
    required this.selectedDate,
    this.weekStart,
    this.weekEnd,
    this.limit = 5,
  });

  @override
  State<ShopRecentOrders> createState() => _ShopRecentOrdersState();
}

class _ShopRecentOrdersState extends State<ShopRecentOrders> {
  bool _isLoading = true;
  String? _errorMessage;
  List<OrderData> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchRecentOrders();
  }

  @override
  void didUpdateWidget(ShopRecentOrders oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.franchiseId != widget.franchiseId ||
        oldWidget.dateViewMode != widget.dateViewMode ||
        oldWidget.selectedDate != widget.selectedDate ||
        oldWidget.weekStart != widget.weekStart ||
        oldWidget.weekEnd != widget.weekEnd) {
      _fetchRecentOrders();
    }
  }

  Future<void> _fetchRecentOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await StorageService.getToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please login again';
        });
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null || userId.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not found';
        });
        return;
      }

      // Get date range based on filter mode
      String startDateStr, endDateStr;

      switch (widget.dateViewMode) {
        case DateViewMode.day:
          startDateStr = _formatDateForApi(widget.selectedDate);
          endDateStr = _formatDateForApi(widget.selectedDate);
          break;

        case DateViewMode.week:
          if (widget.weekStart != null && widget.weekEnd != null) {
            startDateStr = _formatDateForApi(widget.weekStart!);
            endDateStr = _formatDateForApi(widget.weekEnd!);
          } else {
            final now = DateTime.now();
            final weekday = now.weekday;
            final start = now.subtract(Duration(days: weekday - 1));
            final end = start.add(Duration(days: 6));
            startDateStr = _formatDateForApi(start);
            endDateStr = _formatDateForApi(end);
          }
          break;

        case DateViewMode.month:
          final startDate = DateTime(
            widget.selectedDate.year,
            widget.selectedDate.month,
            1,
          );
          final endDate = DateTime(
            widget.selectedDate.year,
            widget.selectedDate.month + 1,
            0,
          );
          startDateStr = _formatDateForApi(startDate);
          endDateStr = _formatDateForApi(endDate);
          break;

        case DateViewMode.year:
          final startDate = DateTime(widget.selectedDate.year, 1, 1);
          final endDate = DateTime(widget.selectedDate.year, 12, 31);
          startDateStr = _formatDateForApi(startDate);
          endDateStr = _formatDateForApi(endDate);
          break;
      }

      // Use combined-transactions endpoint to get actual order data
      final url = Uri.parse('${ApiConfig.baseUrl}/api/combined-transactions');

      final Map<String, Object> requestBody = {
        'page': 1,
        'page_size': widget.limit,
        'from_date': startDateStr,
        'to_date': endDateStr,
      };

      // Add franchise_id if available
      if (widget.franchiseId != null && widget.franchiseId!.isNotEmpty) {
        requestBody['franchise_id'] = widget.franchiseId!;
      } else {
        // If no franchise_id, use user_id to get their franchises
        requestBody['user_id'] = userId;
      }

      final response = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          final List<dynamic> transactions = data['data'] ?? [];

          // Group transactions by receipt_id to create order objects
          final Map<String, List<Map<String, dynamic>>> groupedOrders = {};

          for (var tx in transactions) {
            final receiptId = tx['receipt_id']?.toString() ?? '';
            if (receiptId.isEmpty) continue;

            if (!groupedOrders.containsKey(receiptId)) {
              groupedOrders[receiptId] = [];
            }
            groupedOrders[receiptId]!.add(tx);
          }

          // Convert grouped transactions to OrderData
          List<OrderData> orders = [];

          for (var entry in groupedOrders.entries) {
            final receiptId = entry.key;
            final items = entry.value;

            // Calculate total for this receipt
            double totalAmount = 0;
            int totalQuantity = 0;
            DateTime? orderDate;
            String? franchiseName;
            String? transactionType;

            for (var item in items) {
              totalAmount += (item['total_amount'] as num?)?.toDouble() ?? 0;
              totalQuantity += (item['quantity'] as num?)?.toInt() ?? 0;

              // Get date from timestamp or order_created_at
              final dateStr = item['timestamp'] ?? item['order_created_at'];
              if (dateStr != null) {
                try {
                  orderDate = DateTime.tryParse(dateStr.toString());
                } catch (e) {
                  // ignore
                }
              }

              franchiseName ??= item['franchise_name']?.toString();
              transactionType ??= item['transaction_type']?.toString();
            }

            // Get product names for display
            final productNames = items
                .map((item) => item['product_name']?.toString() ?? 'Product')
                .where((name) => name.isNotEmpty)
                .toList();

            final productDisplay = productNames.isNotEmpty
                ? productNames.take(2).join(', ') +
                      (productNames.length > 2
                          ? ' +${productNames.length - 2} more'
                          : '')
                : 'Order';

            orders.add(
              OrderData(
                receiptId: receiptId,
                product: productDisplay,
                quantity: totalQuantity,
                value: totalAmount,
                date: orderDate ?? DateTime.now(),
                franchiseId: widget.franchiseId,
                orderCount: 1,
                platform: transactionType,
                itemTotal: totalAmount,
                discount: 0,
                status: 'Completed',
              ),
            );
          }

          // Sort by date descending (most recent first)
          orders.sort((a, b) {
            if (a.date == null && b.date == null) return 0;
            if (a.date == null) return 1;
            if (b.date == null) return -1;
            return b.date!.compareTo(a.date!);
          });

          // Take only the limit
          final limitedOrders = orders.take(widget.limit).toList();

          setState(() {
            _orders = limitedOrders;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = data['message'] ?? 'Failed to load orders';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load orders (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Network error: $e';
      });
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(double amount) {
    // Format with 2 decimal places, no abbreviations
    return '₹${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;

    return Container(
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(context.r(16)),
        border: Border.all(color: theme.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: SiporaTheme.shadowLight.withValues(alpha: 0.05),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getHeading(),
                    style: TextStyle(
                      fontSize: isTablet ? context.sp(18) : context.sp(16),
                      fontWeight: FontWeight.w700,
                      color: theme.textDark,
                    ),
                  ),
                  Text(
                    _getSubheading(),
                    style: TextStyle(
                      fontSize: isTablet ? context.sp(12) : context.sp(11),
                      color: theme.textMuted,
                    ),
                  ),
                ],
              ),
              if (_orders.isNotEmpty)
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('View all orders coming soon!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: SiporaTheme.gold,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      fontSize: isTablet ? context.sp(13) : context.sp(12),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: context.h(12)),
          if (_isLoading)
            _buildLoadingState(isTablet)
          else if (_errorMessage != null)
            _buildErrorState(isTablet)
          else if (_orders.isEmpty)
            _buildEmptyState(isTablet)
          else
            ..._buildOrderItems(context, isTablet),
        ],
      ),
    );
  }

  String _getHeading() {
    switch (widget.dateViewMode) {
      case DateViewMode.day:
        return 'Today\'s Orders';
      case DateViewMode.week:
        return 'Week Orders';
      case DateViewMode.month:
        return 'Month Orders';
      case DateViewMode.year:
        return 'Yearly Orders';
    }
  }

  String _getSubheading() {
    switch (widget.dateViewMode) {
      case DateViewMode.day:
        final date = widget.selectedDate;
        return 'Orders for ${_formatDate(date)}';
      case DateViewMode.week:
        if (widget.weekStart != null && widget.weekEnd != null) {
          return '${_formatDate(widget.weekStart!)} - ${_formatDate(widget.weekEnd!)}';
        }
        return 'Orders for this week';
      case DateViewMode.month:
        return 'Orders for ${_getMonthName(widget.selectedDate.month)} ${widget.selectedDate.year}';
      case DateViewMode.year:
        return 'Orders for ${widget.selectedDate.year}';
    }
  }

  String _formatDate(DateTime date) {
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }

  Widget _buildLoadingState(bool isTablet) {
    return SizedBox(
      height: isTablet ? context.h(200) : context.h(160),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(bool isTablet) {
    return SizedBox(
      height: isTablet ? context.h(200) : context.h(160),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade400,
              size: context.w(32),
            ),
            SizedBox(height: context.h(8)),
            Text(
              _errorMessage ?? 'Failed to load orders',
              style: TextStyle(
                fontSize: isTablet ? context.sp(13) : context.sp(11),
                color: Colors.red.shade400,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.h(8)),
            ElevatedButton(
              onPressed: _fetchRecentOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: SiporaTheme.greenDark,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(16),
                  vertical: context.h(6),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.r(8)),
                ),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  fontSize: isTablet ? context.sp(12) : context.sp(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isTablet) {
    final theme = context.siporaTheme;

    return SizedBox(
      height: isTablet ? context.h(200) : context.h(160),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              color: theme.textMuted.withValues(alpha: 0.5),
              size: context.w(48),
            ),
            SizedBox(height: context.h(8)),
            Text(
              'No orders found',
              style: TextStyle(
                fontSize: isTablet ? context.sp(14) : context.sp(12),
                color: theme.textMuted,
              ),
            ),
            SizedBox(height: context.h(4)),
            Text(
              'for the selected ${widget.dateViewMode.label.toLowerCase()}',
              style: TextStyle(
                fontSize: isTablet ? context.sp(12) : context.sp(10),
                color: theme.textMuted.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOrderItems(BuildContext context, bool isTablet) {
    return _orders.take(widget.limit).map((order) {
      final statusColor = order.statusColor;
      final statusDisplay = order.statusDisplay;

      return Container(
        padding: EdgeInsets.symmetric(vertical: context.h(10)),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: context.siporaTheme.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: isTablet ? context.w(40) : context.w(34),
              height: isTablet ? context.w(40) : context.w(34),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(context.r(10)),
              ),
              child: Icon(
                _getStatusIcon(order.status),
                color: statusColor,
                size: isTablet ? context.w(20) : context.w(16),
              ),
            ),
            SizedBox(width: context.w(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.receiptId != null && order.receiptId!.length > 16
                        ? '${order.receiptId!.substring(0, 16)}...'
                        : order.receiptId ?? '#ORD-0000',
                    style: TextStyle(
                      fontSize: isTablet ? context.sp(14) : context.sp(13),
                      fontWeight: FontWeight.w600,
                      color: context.siporaTheme.textDark,
                    ),
                  ),
                  Text(
                    order.product ?? 'Order',
                    style: TextStyle(
                      fontSize: isTablet ? context.sp(12) : context.sp(11),
                      color: context.siporaTheme.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (order.date != null)
                    Text(
                      _formatDate(order.date!),
                      style: TextStyle(
                        fontSize: isTablet ? context.sp(10) : context.sp(9),
                        color: context.siporaTheme.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(order.amount),
                  style: TextStyle(
                    fontSize: isTablet ? context.sp(15) : context.sp(14),
                    fontWeight: FontWeight.w700,
                    color: context.siporaTheme.textDark,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(6),
                    vertical: context.h(2),
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(context.r(8)),
                  ),
                  child: Text(
                    statusDisplay,
                    style: TextStyle(
                      fontSize: isTablet ? context.sp(10) : context.sp(9),
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                // Show platform type if available
                if (order.platform != null && order.platform!.isNotEmpty)
                  Text(
                    order.platform!.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: isTablet ? context.sp(8) : context.sp(7),
                      color: context.siporaTheme.textMuted,
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return Icons.check_circle_rounded;
      case 'processing':
      case 'pending':
        return Icons.hourglass_empty_rounded;
      case 'failed':
      case 'cancelled':
        return Icons.error_outline_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }
}

// ─── Order Data Model ──────────────────────────────────────────────────────

class OrderData {
  final String? id;
  final String? receiptId;
  final String? userId;
  final String? product;
  final String? category;
  final String? platform;
  final String? platformRaw;
  final int quantity;
  final double value;
  final double itemTotal;
  final double discount;
  final DateTime? date;
  final String? franchiseId;
  final String? state;
  final String? city;
  final int? orderCount;
  final String status;

  OrderData({
    this.id,
    this.receiptId,
    this.userId,
    this.product,
    this.category,
    this.platform,
    this.platformRaw,
    this.quantity = 0,
    this.value = 0,
    this.itemTotal = 0,
    this.discount = 0,
    this.date,
    this.franchiseId,
    this.state,
    this.city,
    this.orderCount,
    this.status = 'Completed',
  });

  factory OrderData.fromJson(Map<String, dynamic> json) {
    return OrderData(
      id: json['id']?.toString(),
      receiptId: json['receipt_id']?.toString(),
      userId: json['user_id']?.toString(),
      product: json['product']?.toString(),
      category: json['category']?.toString(),
      platform: json['platform']?.toString(),
      platformRaw: json['platform_raw']?.toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      value: (json['value'] as num?)?.toDouble() ?? 0,
      itemTotal: (json['item_total'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
      franchiseId: json['franchise_id']?.toString(),
      state: json['state']?.toString(),
      city: json['city']?.toString(),
      orderCount: (json['order_count'] as num?)?.toInt(),
      status: json['status']?.toString() ?? 'Completed',
    );
  }

  double get amount => value;

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return SiporaTheme.greenMid;
      case 'processing':
      case 'pending':
        return SiporaTheme.gold;
      case 'failed':
      case 'cancelled':
        return Colors.red.shade400;
      default:
        return SiporaTheme.greenMid;
    }
  }

  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return 'Completed';
      case 'processing':
        return 'Processing';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Completed';
    }
  }
}
