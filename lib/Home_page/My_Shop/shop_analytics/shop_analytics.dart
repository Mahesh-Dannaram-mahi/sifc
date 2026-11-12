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
import '../widgets/shop_dashboard_header.dart';
import '../widgets/shop_bottom_nav.dart';
import 'analytics_cups_discounts.dart';
import 'analytics_wallet_payments.dart';

class ShopAnalyticsPage extends StatefulWidget {
  const ShopAnalyticsPage({super.key});

  @override
  State<ShopAnalyticsPage> createState() => _ShopAnalyticsPageState();
}

class _ShopAnalyticsPageState extends State<ShopAnalyticsPage> {
  bool _isLoading = true;
  String? _errorMessage;

  // Bottom nav state
  int _selectedNavIndex = 1; // Analytics tab

  // Filter state - default to Day
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
  String _shopName = 'My Shop';
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? 'user';
    _isAdmin = role.toLowerCase() == 'admin';
    _franchiseId = prefs.getString('selected_franchise_id');
    _shopName = prefs.getString('selected_shop_name') ?? 'My Shop';

    // Fetch analytics data
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

      // Get date range based on filter
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
          final startDate = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            1,
          );
          final endDate = DateTime(
            _selectedDate.year,
            _selectedDate.month + 1,
            0,
          );
          startDateStr = _formatDate(startDate);
          endDateStr = _formatDate(endDate);
          break;
        case DateViewMode.year:
          final startDate = DateTime(_selectedDate.year, 1, 1);
          final endDate = DateTime(_selectedDate.year, 12, 31);
          startDateStr = _formatDate(startDate);
          endDateStr = _formatDate(endDate);
          break;
      }

      // Build URL with franchise filter if not admin or if specific franchise selected
      String url =
          '${ApiConfig.baseUrl}/api/combined-transactions/summary'
          '?from_date=$startDateStr'
          '&to_date=$endDateStr';

      if (!_isAdmin && _franchiseId != null && _franchiseId!.isNotEmpty) {
        url += '&franchise_id=$_franchiseId';
      } else if (_isAdmin && _franchiseId != null && _franchiseId!.isNotEmpty) {
        url += '&franchise_id=$_franchiseId';
      } else if (!_isAdmin) {
        url += '&user_id=$userId';
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
      // Add view parameter
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

    _fetchAnalyticsData();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(double amount) {
    // Format with 2 decimal places, no abbreviations
    return '₹${amount.toStringAsFixed(2)}';
  }

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

  void _handleNavTap(int index) {
    setState(() {
      _selectedNavIndex = index;
    });

    switch (index) {
      case 0:
        // Navigate back to Dashboard
        Navigator.pop(context);
        break;
      case 1:
        // Already on Analytics page
        break;
      case 2:
        _showComingSoon('Orders Management');
        break;
      case 3:
        _showComingSoon('Products Management');
        break;
      case 4:
        Navigator.pop(context);
        // Navigate to Settlements (will be handled by parent)
        // We use a different approach - navigate back and let parent handle it
        break;
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: SiporaTheme.greenDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;

    return Scaffold(
      backgroundColor: theme.cream,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Custom Header ──────────────────────────────────────────
            ShopDashboardHeader(
              shopName: _shopName,
              onMyAppTap: () {
                Navigator.pop(context);
              },
            ),

            // ─── Universal Filter ──────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(16),
                vertical: context.h(8),
              ),
              child: UniversalFilter(
                initialMode: _dateViewMode,
                initialDate: _selectedDate,
                onFilterChanged: _onFilterChanged,
              ),
            ),

            // ─── Main Content ──────────────────────────────────────────
            Expanded(child: _buildBody(isTablet)),
          ],
        ),
      ),
      // ─── Bottom Navigation ──────────────────────────────────────────
      bottomNavigationBar: ShopBottomNav(
        selectedIndex: _selectedNavIndex,
        onItemTapped: _handleNavTap,
      ),
    );
  }

  Widget _buildBody(bool isTablet) {
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
          // ─── Stats Grid ────────────────────────────────────────────────
          _buildStatsGrid(isTablet),

          SizedBox(height: context.h(24)),

          // ─── Additional Info ──────────────────────────────────────────
          _buildAdditionalInfo(isTablet),

          // ─── Cups & Discounts ──────────────────────────────────────────
          AnalyticsCupsDiscounts(
            data: _cupsData,
            isLoading: _isLoadingCups,
            error: _cupsError,
          ),

          // ─── Wallet Payments ──────────────────────────────────────────
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

  Widget _buildStatsGrid(bool isTablet) {
    final theme = context.siporaTheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: context.w(12),
        mainAxisSpacing: context.h(12),
        childAspectRatio: 1.2,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
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
                  if ((stat['sub'] as String).isNotEmpty) ...[
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
                ],
              ),
            ],
          ),
        );
      },
    );
  }

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

  Widget _buildSkeletonUI(bool isTablet) {
    final theme = context.siporaTheme;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(8),
      ),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: context.w(12),
              mainAxisSpacing: context.h(12),
              childAspectRatio: 1.2,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return Container(
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
              );
            },
          ),
        ],
      ),
    );
  }

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
