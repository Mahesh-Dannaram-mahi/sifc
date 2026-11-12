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
import 'analytics_cups_discounts.dart';
import 'analytics_wallet_payments.dart';

class ShopAnalyticsContent extends StatefulWidget {
  final DateViewMode initialDateViewMode;
  final DateTime initialSelectedDate;
  final DateTime? initialWeekStart;
  final DateTime? initialWeekEnd;
  final Function(DateViewMode mode, DateTime date)? onFilterChanged;

  const ShopAnalyticsContent({
    super.key,
    required this.initialDateViewMode,
    required this.initialSelectedDate,
    this.initialWeekStart,
    this.initialWeekEnd,
    this.onFilterChanged,
  });

  @override
  State<ShopAnalyticsContent> createState() => _ShopAnalyticsContentState();
}

class _ShopAnalyticsContentState extends State<ShopAnalyticsContent> {
  bool _isLoading = true;
  String? _errorMessage;

  // Filter state
  DateViewMode _dateViewMode = DateViewMode.day;
  DateTime _selectedDate = DateTime.now();
  DateTime? _weekStart;
  DateTime? _weekEnd;

  // Analytics data
  double _totalRevenue = 0;
  double _totalGst = 0;
  int _posCashCount = 0;
  int _posQrCount = 0;
  int _onlineOrdersCount = 0;
  double _totalDiscount = 0;
  int _uniqueReceipts = 0;
  int _totalItems = 0;

  // Cups & Discounts
  Map<String, dynamic>? _cupsData;
  bool _isLoadingCups = false;
  String? _cupsError;

  // Wallet Payments
  Map<String, dynamic>? _walletData;
  bool _isLoadingWallet = false;
  String? _walletError;

  // Franchise info
  String? _franchiseId;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _dateViewMode = widget.initialDateViewMode;
    _selectedDate = widget.initialSelectedDate;
    _weekStart = widget.initialWeekStart;
    _weekEnd = widget.initialWeekEnd;
    _loadUserData();
  }

  @override
  void didUpdateWidget(ShopAnalyticsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDateViewMode != widget.initialDateViewMode ||
        oldWidget.initialSelectedDate != widget.initialSelectedDate ||
        oldWidget.initialWeekStart != widget.initialWeekStart ||
        oldWidget.initialWeekEnd != widget.initialWeekEnd) {
      setState(() {
        _dateViewMode = widget.initialDateViewMode;
        _selectedDate = widget.initialSelectedDate;
        _weekStart = widget.initialWeekStart;
        _weekEnd = widget.initialWeekEnd;
      });
      _fetchAnalyticsData();
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? 'user';
    _isAdmin = role.toLowerCase() == 'admin';
    _franchiseId = prefs.getString('selected_franchise_id');
    await _fetchAnalyticsData();
  }

  Future<void> _fetchAnalyticsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _cupsData = null;
      _cupsError = null;
      _walletData = null;
      _walletError = null;
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

      // Build date range
      String startDateStr, endDateStr;
      switch (_dateViewMode) {
        case DateViewMode.day:
          startDateStr = _formatDate(_selectedDate);
          endDateStr = _formatDate(_selectedDate);
          break;
        case DateViewMode.week:
          if (_weekStart != null && _weekEnd != null) {
            startDateStr = _formatDate(_weekStart!);
            endDateStr = _formatDate(_weekEnd!);
          } else {
            final now = DateTime.now();
            final weekday = now.weekday;
            final start = now.subtract(Duration(days: weekday - 1));
            final end = start.add(Duration(days: 6));
            startDateStr = _formatDate(start);
            endDateStr = _formatDate(end);
          }
          break;
        case DateViewMode.month:
          startDateStr = _formatDate(
            DateTime(_selectedDate.year, _selectedDate.month, 1),
          );
          endDateStr = _formatDate(
            DateTime(_selectedDate.year, _selectedDate.month + 1, 0),
          );
          break;
        case DateViewMode.year:
          startDateStr = _formatDate(DateTime(_selectedDate.year, 1, 1));
          endDateStr = _formatDate(DateTime(_selectedDate.year, 12, 31));
          break;
      }

      // Summary API
      String summaryUrl =
          '${ApiConfig.baseUrl}/api/combined-transactions/summary'
          '?from_date=$startDateStr'
          '&to_date=$endDateStr';
      if (_franchiseId != null && _franchiseId!.isNotEmpty) {
        summaryUrl += '&franchise_id=$_franchiseId';
      } else if (!_isAdmin) {
        summaryUrl += '&user_id=$userId';
      }

      final summaryResponse = await http.get(
        Uri.parse(summaryUrl),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (summaryResponse.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(summaryResponse.body);
        if (data['success'] == true) {
          final summary = data['summary'] ?? {};
          final overall = summary['overall'] ?? {};
          final customerInvoice = summary['customer_invoice'] ?? {};
          final posCash = summary['pos_cash'] ?? {};
          final posQr = summary['pos_qr'] ?? {};

          setState(() {
            _totalRevenue = (overall['total_amount'] ?? 0).toDouble();
            _totalGst = (overall['total_gst'] ?? 0).toDouble();
            _posCashCount = (posCash['count'] ?? 0).toInt();
            _posQrCount = (posQr['count'] ?? 0).toInt();
            _onlineOrdersCount = (customerInvoice['count'] ?? 0).toInt();
            _totalDiscount = (overall['total_discount'] ?? 0).toDouble();
            _uniqueReceipts = (overall['count'] ?? 0).toInt();
            _totalItems = (overall['total_items'] ?? 0).toInt();
            _isLoading = false;
          });

          // Fetch cups data
          await _fetchCupsDiscountsData(
            userId,
            token,
            startDateStr,
            endDateStr,
          );

          // Fetch wallet data
          await _fetchWalletPaymentsData(
            userId,
            token,
            startDateStr,
            endDateStr,
          );
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = data['message'] ?? 'Failed to load analytics';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load analytics data';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Network error: $e';
      });
    }
  }

  Future<void> _fetchCupsDiscountsData(
    String userId,
    String token,
    String startDate,
    String endDate,
  ) async {
    setState(() {
      _isLoadingCups = true;
      _cupsError = null;
    });

    try {
      // ✅ Add view parameter
      String view = _dateViewMode.name
          .toLowerCase(); // "day", "week", "month", "year"
      String url =
          '${ApiConfig.baseUrl}/api/dashboard/franchise/analytics/cups-discounts'
          '?owner_user_id=$userId'
          '&start_date=$startDate'
          '&end_date=$endDate'
          '&view=$view';

      if (_franchiseId != null && _franchiseId!.isNotEmpty) {
        url += '&franchise_id=$_franchiseId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _cupsData = data;
            _isLoadingCups = false;
          });
        } else {
          setState(() {
            _isLoadingCups = false;
            _cupsError = data['message'] ?? 'Failed to load cups data';
          });
        }
      } else {
        setState(() {
          _isLoadingCups = false;
          _cupsError = 'Failed to load cups data (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingCups = false;
        _cupsError = 'Network error: $e';
      });
    }
  }

  Future<void> _fetchWalletPaymentsData(
    String userId,
    String token,
    String startDate,
    String endDate,
  ) async {
    setState(() {
      _isLoadingWallet = true;
      _walletError = null;
    });

    try {
      String view = _dateViewMode.name.toLowerCase();
      String url =
          '${ApiConfig.baseUrl}/api/dashboard/franchise/analytics/wallet-payments'
          '?owner_user_id=$userId'
          '&start_date=$startDate'
          '&end_date=$endDate'
          '&view=$view';

      if (_franchiseId != null && _franchiseId!.isNotEmpty) {
        url += '&franchise_id=$_franchiseId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _walletData = data;
            _isLoadingWallet = false;
          });
        } else {
          setState(() {
            _isLoadingWallet = false;
            _walletError = data['message'] ?? 'Failed to load wallet data';
          });
        }
      } else {
        setState(() {
          _isLoadingWallet = false;
          _walletError = 'Failed to load wallet data (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingWallet = false;
        _walletError = 'Network error: $e';
      });
    }
  }

  void _onFilterChanged(DateViewMode mode, DateTime date) {
    DateTime? weekStart;
    DateTime? weekEnd;
    if (mode == DateViewMode.week) {
      final weekday = date.weekday;
      weekStart = date.subtract(Duration(days: weekday - 1));
      weekEnd = weekStart.add(Duration(days: 6));
    }
    setState(() {
      _dateViewMode = mode;
      _selectedDate = date;
      _weekStart = weekStart;
      _weekEnd = weekEnd;
    });
    if (widget.onFilterChanged != null) {
      widget.onFilterChanged!(mode, date);
    }
    _fetchAnalyticsData();
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _formatCurrency(double amount) => '₹${amount.toStringAsFixed(2)}';

  String _getDateRangeLabel() {
    switch (_dateViewMode) {
      case DateViewMode.day:
        return _formatDisplayDate(_selectedDate);
      case DateViewMode.week:
        if (_weekStart != null && _weekEnd != null) {
          return '${_formatDisplayDate(_weekStart!)} - ${_formatDisplayDate(_weekEnd!)}';
        }
        return 'This Week';
      case DateViewMode.month:
        return _getMonthName(_selectedDate.month);
      case DateViewMode.year:
        return '${_selectedDate.year}';
    }
  }

  String _formatDisplayDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _getMonthName(int month) => const [
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
  ][month - 1];

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;

    if (_isLoading) {
      return _buildSkeletonUI(isTablet);
    }

    if (_errorMessage != null) {
      return _buildErrorState(isTablet);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(8),
      ),
      child: Column(
        children: [
          _buildStatsGrid(isTablet),
          SizedBox(height: context.h(24)),
          _buildAdditionalInfo(isTablet),
          AnalyticsCupsDiscounts(
            data: _cupsData,
            isLoading: _isLoadingCups,
            error: _cupsError,
          ),
          AnalyticsWalletPayments(
            data: _walletData,
            isLoading: _isLoadingWallet,
            error: _walletError,
          ),
          SizedBox(height: context.h(80)),
        ],
      ),
    );
  }

  // ---------- Stats Grid ----------
  Widget _buildStatsGrid(bool isTablet) {
    final theme = context.siporaTheme;
    final stats = [
      {
        'title': 'Shop Revenue',
        'value': _formatCurrency(_totalRevenue),
        'sub': '${_uniqueReceipts} receipts · ${_getDateRangeLabel()}',
        'icon': Icons.trending_up_rounded,
        'color': Colors.blue.shade600,
        'bgColor': Colors.blue.shade50,
      },
      {
        'title': 'Platform Charge',
        'value': _formatCurrency(_totalGst),
        'sub': '',
        'icon': Icons.account_balance_wallet_rounded,
        'color': Colors.purple.shade600,
        'bgColor': Colors.purple.shade50,
      },
      {
        'title': 'POS Cash',
        'value': '$_posCashCount',
        'sub': 'cash transactions',
        'icon': Icons.money_rounded,
        'color': Colors.green.shade600,
        'bgColor': Colors.green.shade50,
      },
      {
        'title': 'POS QR',
        'value': '$_posQrCount',
        'sub': 'QR transactions',
        'icon': Icons.qr_code_scanner_rounded,
        'color': Colors.deepPurple.shade600,
        'bgColor': Colors.deepPurple.shade50,
      },
      {
        'title': 'Online Orders',
        'value': '$_onlineOrdersCount',
        'sub': 'online orders',
        'icon': Icons.shopping_bag_rounded,
        'color': Colors.blue.shade600,
        'bgColor': Colors.blue.shade50,
      },
      {
        'title': 'Total Discount',
        'value': _formatCurrency(_totalDiscount),
        'sub': 'applied across all items',
        'icon': Icons.local_offer_rounded,
        'color': Colors.orange.shade600,
        'bgColor': Colors.orange.shade50,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: context.w(12),
        mainAxisSpacing: context.h(12),
        childAspectRatio: 1.2,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: EdgeInsets.all(context.w(12)),
          decoration: BoxDecoration(
            color: theme.white,
            borderRadius: BorderRadius.circular(context.r(14)),
            border: Border.all(color: theme.border, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: SiporaTheme.shadowLight.withValues(alpha: 0.05),
                blurRadius: 8.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(context.w(6)),
                    decoration: BoxDecoration(
                      color: stat['bgColor'] as Color,
                      borderRadius: BorderRadius.circular(context.r(8)),
                    ),
                    child: Icon(
                      stat['icon'] as IconData,
                      color: stat['color'] as Color,
                      size: isTablet ? context.w(18) : context.w(16),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat['value'] as String,
                    style: TextStyle(
                      fontSize: isTablet ? context.sp(18) : context.sp(16),
                      fontWeight: FontWeight.w800,
                      color: theme.textDark,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: context.h(2)),
                  Text(
                    stat['title'] as String,
                    style: TextStyle(
                      fontSize: isTablet ? context.sp(11) : context.sp(10),
                      color: theme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if ((stat['sub'] as String).isNotEmpty)
                    Text(
                      stat['sub'] as String,
                      style: TextStyle(
                        fontSize: isTablet ? context.sp(9) : context.sp(8),
                        color: theme.textMuted.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------- Additional Info ----------
  Widget _buildAdditionalInfo(bool isTablet) {
    final theme = context.siporaTheme;
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
          Text(
            '📊 Analytics Summary',
            style: TextStyle(
              fontSize: isTablet ? context.sp(16) : context.sp(14),
              fontWeight: FontWeight.w700,
              color: theme.textDark,
            ),
          ),
          SizedBox(height: context.h(8)),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  context,
                  label: 'Total Receipts',
                  value: '$_uniqueReceipts',
                  isTablet: isTablet,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  context,
                  label: 'Avg Order Value',
                  value: _uniqueReceipts > 0
                      ? _formatCurrency(_totalRevenue / _uniqueReceipts)
                      : '₹0.00',
                  isTablet: isTablet,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(8)),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  context,
                  label: 'Total Items',
                  value: '$_totalItems',
                  isTablet: isTablet,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  context,
                  label: 'Net Revenue',
                  value: _formatCurrency(_totalRevenue - _totalGst),
                  isTablet: isTablet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required String label,
    required String value,
    required bool isTablet,
  }) {
    final theme = context.siporaTheme;
    return Container(
      padding: EdgeInsets.all(context.w(10)),
      decoration: BoxDecoration(
        color: theme.cream,
        borderRadius: BorderRadius.circular(context.r(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTablet ? context.sp(10) : context.sp(9),
              color: theme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: context.h(2)),
          Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? context.sp(14) : context.sp(12),
              fontWeight: FontWeight.w700,
              color: theme.textDark,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ---------- Skeleton ----------
  Widget _buildSkeletonUI(bool isTablet) {
    final theme = context.siporaTheme;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(8),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: context.w(12),
          mainAxisSpacing: context.h(12),
          childAspectRatio: 1.2,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => Container(
          padding: EdgeInsets.all(context.w(12)),
          decoration: BoxDecoration(
            color: theme.white,
            borderRadius: BorderRadius.circular(context.r(14)),
            border: Border.all(color: theme.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(context.w(6)),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(context.r(8)),
                ),
                child: const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: context.w(50),
                    height: isTablet ? context.h(18) : context.h(16),
                    color: Colors.grey.shade200,
                  ),
                  SizedBox(height: context.h(4)),
                  Container(
                    width: context.w(60),
                    height: isTablet ? context.h(12) : context.h(10),
                    color: Colors.grey.shade200,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Error ----------
  Widget _buildErrorState(bool isTablet) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.w(32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade400,
              size: context.w(48),
            ),
            SizedBox(height: context.h(16)),
            Text(
              _errorMessage ?? 'Something went wrong',
              style: TextStyle(
                fontSize: isTablet ? context.sp(16) : context.sp(14),
                color: Colors.red.shade400,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.h(16)),
            ElevatedButton(
              onPressed: _fetchAnalyticsData,
              style: ElevatedButton.styleFrom(
                backgroundColor: SiporaTheme.greenDark,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(24),
                  vertical: context.h(12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.r(8)),
                ),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  fontSize: isTablet ? context.sp(14) : context.sp(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
