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

class ShopDashboardCards extends StatefulWidget {
  final DateViewMode dateViewMode;
  final DateTime selectedDate;
  final DateTime? weekStart;
  final DateTime? weekEnd;

  const ShopDashboardCards({
    super.key,
    required this.dateViewMode,
    required this.selectedDate,
    this.weekStart,
    this.weekEnd,
  });

  @override
  State<ShopDashboardCards> createState() => _ShopDashboardCardsState();
}

class _ShopDashboardCardsState extends State<ShopDashboardCards> {
  bool _isLoading = true;
  String? _errorMessage;

  // Dashboard data
  double _totalRevenue = 0;
  int _totalOrders = 0;
  double _totalGst = 0;
  int _activeCustomers = 0;

  // Previous period for change calculation
  double _previousRevenue = 0;
  int _previousOrders = 0;
  double _previousGst = 0;
  int _previousCustomers = 0;

  // Week label for display
  String _weekLabel = '';

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  @override
  void didUpdateWidget(ShopDashboardCards oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dateViewMode != widget.dateViewMode ||
        oldWidget.selectedDate != widget.selectedDate ||
        oldWidget.weekStart != widget.weekStart ||
        oldWidget.weekEnd != widget.weekEnd) {
      _fetchDashboardData();
    }
  }

  // Helper to get week-of-month (w1-w5) instead of ISO week
  int _getWeekOfMonth(DateTime date) {
    return ((date.day - 1) ~/ 7) + 1;
  }

  String _getWeekLabel() {
    if (widget.weekStart != null) {
      final weekOfMonth = _getWeekOfMonth(widget.weekStart!);
      return 'w$weekOfMonth';
    }
    final now = DateTime.now();
    final weekOfMonth = _getWeekOfMonth(now);
    return 'w$weekOfMonth';
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);

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
      final franchiseId = prefs.getString('selected_franchise_id');

      if (franchiseId == null || franchiseId.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No franchise selected';
        });
        return;
      }

      // Get date range based on filter
      String startDateStr, endDateStr;

      switch (widget.dateViewMode) {
        case DateViewMode.day:
          startDateStr = _formatDate(widget.selectedDate);
          endDateStr = _formatDate(widget.selectedDate);
          break;
        case DateViewMode.week:
          if (widget.weekStart != null && widget.weekEnd != null) {
            startDateStr = _formatDate(widget.weekStart!);
            endDateStr = _formatDate(widget.weekEnd!);
          } else {
            final now = DateTime.now();
            final weekday = now.weekday;
            final start = now.subtract(Duration(days: weekday - 1));
            final end = start.add(Duration(days: 6));
            startDateStr = _formatDate(start);
            endDateStr = _formatDate(end);
          }
          _weekLabel = _getWeekLabel();
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
          startDateStr = _formatDate(startDate);
          endDateStr = _formatDate(endDate);
          break;
        case DateViewMode.year:
          final startDate = DateTime(widget.selectedDate.year, 1, 1);
          final endDate = DateTime(widget.selectedDate.year, 12, 31);
          startDateStr = _formatDate(startDate);
          endDateStr = _formatDate(endDate);
          break;
      }

      // Fetch current period data
      final currentUrl = Uri.parse(
        '${ApiConfig.baseUrl}/api/dashboard/franchise/summary'
        '?owner_user_id=$userId'
        '&franchise_id=$franchiseId'
        '&start_date=$startDateStr'
        '&end_date=$endDateStr',
      );

      final currentResponse = await http.get(
        currentUrl,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (currentResponse.statusCode == 200) {
        final Map<String, dynamic> currentData = json.decode(
          currentResponse.body,
        );

        if (currentData['success'] == true) {
          setState(() {
            _totalRevenue =
                currentData['total_revenue']?['total']?.toDouble() ?? 0;
            _totalOrders = currentData['total_orders']?['orders'] ?? 0;
            _totalGst =
                (currentData['total_revenue']?['total_cgst']?.toDouble() ?? 0) +
                (currentData['total_revenue']?['total_sgst']?.toDouble() ?? 0);
            _activeCustomers =
                currentData['active_customers']?['active_users'] ?? 0;
          });
        }
      }

      // Calculate previous period based on current view mode
      DateTime prevStartDate, prevEndDate;

      switch (widget.dateViewMode) {
        case DateViewMode.day:
          prevStartDate = widget.selectedDate.subtract(const Duration(days: 1));
          prevEndDate = prevStartDate;
          break;
        case DateViewMode.week:
          if (widget.weekStart != null) {
            prevStartDate = widget.weekStart!.subtract(const Duration(days: 7));
            prevEndDate = widget.weekStart!.subtract(const Duration(days: 1));
          } else {
            final now = DateTime.now();
            final weekday = now.weekday;
            final start = now.subtract(Duration(days: weekday - 1));
            prevStartDate = start.subtract(const Duration(days: 7));
            prevEndDate = start.subtract(const Duration(days: 1));
          }
          break;
        case DateViewMode.month:
          final prevMonth = widget.selectedDate.month == 1
              ? 12
              : widget.selectedDate.month - 1;
          final prevYear = widget.selectedDate.month == 1
              ? widget.selectedDate.year - 1
              : widget.selectedDate.year;
          prevStartDate = DateTime(prevYear, prevMonth, 1);
          prevEndDate = DateTime(prevYear, prevMonth + 1, 0);
          break;
        case DateViewMode.year:
          prevStartDate = DateTime(widget.selectedDate.year - 1, 1, 1);
          prevEndDate = DateTime(widget.selectedDate.year - 1, 12, 31);
          break;
      }

      final prevStartDateStr = _formatDate(prevStartDate);
      final prevEndDateStr = _formatDate(prevEndDate);

      // Fetch previous period data
      final prevUrl = Uri.parse(
        '${ApiConfig.baseUrl}/api/dashboard/franchise/summary'
        '?owner_user_id=$userId'
        '&franchise_id=$franchiseId'
        '&start_date=$prevStartDateStr'
        '&end_date=$prevEndDateStr',
      );

      final prevResponse = await http.get(
        prevUrl,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (prevResponse.statusCode == 200) {
        final Map<String, dynamic> prevData = json.decode(prevResponse.body);

        if (prevData['success'] == true) {
          setState(() {
            _previousRevenue =
                prevData['total_revenue']?['total']?.toDouble() ?? 0;
            _previousOrders = prevData['total_orders']?['orders'] ?? 0;
            _previousGst =
                (prevData['total_revenue']?['total_cgst']?.toDouble() ?? 0) +
                (prevData['total_revenue']?['total_sgst']?.toDouble() ?? 0);
            _previousCustomers =
                prevData['active_customers']?['active_users'] ?? 0;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Network error: $e';
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(double amount) {
    // Format with 2 decimal places, no abbreviations
    return '₹${amount.toStringAsFixed(2)}';
  }

  String _calculateChange(double current, double previous) {
    if (previous == 0) {
      if (current == 0) return '+0%';
      return '+100%';
    }
    final change = ((current - previous) / previous) * 100;
    final sign = change >= 0 ? '+' : '';
    return '${sign}${change.toStringAsFixed(1)}%';
  }

  String _getCardTitle(String baseTitle) {
    if (widget.dateViewMode == DateViewMode.week) {
      return '$baseTitle $_weekLabel';
    }
    return baseTitle;
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    final crossAxisCount = isTablet ? 4 : 2;

    if (_isLoading) {
      return _buildLoadingState(isTablet);
    }

    if (_errorMessage != null) {
      return _buildErrorState(isTablet);
    }

    final cards = [
      _AnalyticsCardData(
        title: _getCardTitle('Total Orders'),
        value: _totalOrders.toString(),
        change: _calculateChange(
          _totalOrders.toDouble(),
          _previousOrders.toDouble(),
        ),
        icon: Icons.shopping_bag_rounded,
        color: SiporaTheme.greenDark,
      ),
      _AnalyticsCardData(
        title: _getCardTitle('Total Revenue'),
        value: _formatCurrency(_totalRevenue),
        change: _calculateChange(_totalRevenue, _previousRevenue),
        icon: Icons.trending_up_rounded,
        color: SiporaTheme.gold,
      ),
      _AnalyticsCardData(
        title: _getCardTitle('GST'),
        value: _formatCurrency(_totalGst),
        change: _calculateChange(_totalGst, _previousGst),
        icon: Icons.receipt_rounded,
        color: Colors.purple.shade600,
        subtitle: 'CGST + SGST',
      ),
      _AnalyticsCardData(
        title: _getCardTitle('Active Customers'),
        value: _activeCustomers.toString(),
        change: _calculateChange(
          _activeCustomers.toDouble(),
          _previousCustomers.toDouble(),
        ),
        icon: Icons.people_rounded,
        color: Colors.orange.shade600,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: context.w(12),
        mainAxisSpacing: context.h(12),
        childAspectRatio: isTablet ? 1.8 : 1.6,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final data = cards[index];
        return _AnalyticsCard(data: data);
      },
    );
  }

  Widget _buildLoadingState(bool isTablet) {
    final theme = context.siporaTheme;
    final crossAxisCount = isTablet ? 4 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: context.w(12),
        mainAxisSpacing: context.h(12),
        childAspectRatio: isTablet ? 1.8 : 1.6,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          padding: EdgeInsets.all(context.w(10)),
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
                    padding: EdgeInsets.all(context.w(5)),
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
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(6),
                      vertical: context.h(2),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(context.r(10)),
                    ),
                    child: Text(
                      '--',
                      style: TextStyle(
                        fontSize: isTablet ? context.sp(11) : context.sp(9),
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: context.w(50),
                    height: isTablet ? context.h(20) : context.h(18),
                    color: Colors.grey.shade200,
                  ),
                  SizedBox(height: context.h(3)),
                  Container(
                    width: context.w(35),
                    height: isTablet ? context.h(12) : context.h(10),
                    color: Colors.grey.shade200,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(bool isTablet) {
    final theme = context.siporaTheme;

    return Container(
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        border: Border.all(color: Colors.red.shade200, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade400,
            size: context.w(32),
          ),
          SizedBox(height: context.h(8)),
          Text(
            _errorMessage ?? 'Failed to load data',
            style: TextStyle(
              fontSize: isTablet ? context.sp(14) : context.sp(12),
              color: Colors.red.shade400,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.h(8)),
          ElevatedButton(
            onPressed: _fetchDashboardData,
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
                fontSize: isTablet ? context.sp(13) : context.sp(11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCardData {
  final String title;
  final String value;
  final String change;
  final IconData icon;
  final Color color;
  final String? subtitle;

  _AnalyticsCardData({
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
    required this.color,
    this.subtitle,
  });
}

class _AnalyticsCard extends StatelessWidget {
  final _AnalyticsCardData data;

  const _AnalyticsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;

    return Container(
      padding: EdgeInsets.all(context.w(10)),
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
                padding: EdgeInsets.all(context.w(5)),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(context.r(8)),
                ),
                child: Icon(
                  data.icon,
                  color: data.color,
                  size: isTablet ? context.w(20) : context.w(16),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(6),
                  vertical: context.h(2),
                ),
                decoration: BoxDecoration(
                  color: data.change.startsWith('+')
                      ? SiporaTheme.greenMid.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(context.r(10)),
                ),
                child: Text(
                  data.change,
                  style: TextStyle(
                    fontSize: isTablet ? context.sp(10) : context.sp(8),
                    fontWeight: FontWeight.w700,
                    color: data.change.startsWith('+')
                        ? SiporaTheme.greenMid
                        : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.value,
                style: TextStyle(
                  fontSize: isTablet ? context.sp(20) : context.sp(16),
                  fontWeight: FontWeight.w800,
                  color: theme.textDark,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: context.h(1)),
              Row(
                children: [
                  Text(
                    data.title,
                    style: TextStyle(
                      fontSize: isTablet ? context.sp(11) : context.sp(10),
                      color: theme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (data.subtitle != null) ...[
                    SizedBox(width: context.w(4)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(4),
                        vertical: context.h(1),
                      ),
                      decoration: BoxDecoration(
                        color: data.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(context.r(4)),
                      ),
                      child: Text(
                        data.subtitle!,
                        style: TextStyle(
                          fontSize: isTablet ? context.sp(7) : context.sp(6),
                          color: data.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
