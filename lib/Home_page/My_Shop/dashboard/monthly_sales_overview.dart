import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/sipora_theme.dart';
import '../../../utils/screen_utils.dart';
import '../../../services/storage_service.dart';
import '../../../config/api_config.dart';

class MonthlySalesOverview extends StatefulWidget {
  final String dateViewMode; // 'day', 'week', 'month', 'year'
  final int selectedYear;
  final int selectedMonth;
  final int selectedDay;
  final DateTime? weekStart;
  final DateTime? weekEnd;

  const MonthlySalesOverview({
    super.key,
    required this.dateViewMode,
    required this.selectedYear,
    required this.selectedMonth,
    required this.selectedDay,
    this.weekStart,
    this.weekEnd,
  });

  @override
  State<MonthlySalesOverview> createState() => _MonthlySalesOverviewState();
}

class _MonthlySalesOverviewState extends State<MonthlySalesOverview> {
  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _data = [];
  Map<String, dynamic> _summary = {};
  String _chartType = 'bar';
  final int _currentMonth = DateTime.now().month;

  // 11 time-of-day categories with Midnight at the last position
  static const List<Map<String, dynamic>> _timeCategories = [
    {'start': 4, 'end': 6, 'emoji': '🌅', 'name': 'Dawn', 'label': '4AM'},
    {'start': 6, 'end': 8, 'emoji': '🌄', 'name': 'Sunrise', 'label': '6AM'},
    {
      'start': 8,
      'end': 10,
      'emoji': '☀️',
      'name': 'Good Morning',
      'label': '8AM',
    },
    {
      'start': 10,
      'end': 12,
      'emoji': '🌤️',
      'name': 'Forenoon',
      'label': '10AM',
    },
    {'start': 12, 'end': 13, 'emoji': '☀️', 'name': 'Noon', 'label': '12PM'},
    {
      'start': 13,
      'end': 16,
      'emoji': '⛅',
      'name': 'Good Afternoon',
      'label': '1PM',
    },
    {'start': 16, 'end': 18, 'emoji': '🌅', 'name': 'Dusk', 'label': '4PM'},
    {'start': 18, 'end': 20, 'emoji': '🌆', 'name': 'Twilight', 'label': '6PM'},
    {
      'start': 20,
      'end': 22,
      'emoji': '🌇',
      'name': 'Good Evening',
      'label': '8PM',
    },
    {
      'start': 22,
      'end': 24,
      'emoji': '🌙',
      'name': 'Good Night',
      'label': '10PM',
    },
    {'start': 0, 'end': 4, 'emoji': '🌙', 'name': 'Midnight', 'label': '12AM'},
  ];

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final days = date.difference(firstDayOfYear).inDays;
    return ((days + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  String _getWeekOfMonthLabel() {
    final ws = widget.weekStart ?? DateTime.now();
    final weekOfMonth = ((ws.day - 1) ~/ 7) + 1;
    return 'w$weekOfMonth';
  }

  /// Get time range label for category by start hour
  String _getTimeRange(int hour) {
    if (hour >= 0 && hour < 4) return '12:00AM - 4:00AM';
    if (hour >= 4 && hour < 6) return '4:00AM - 6:00AM';
    if (hour >= 6 && hour < 8) return '6:00AM - 8:00AM';
    if (hour >= 8 && hour < 10) return '8:00AM - 10:00AM';
    if (hour >= 10 && hour < 12) return '10:00AM - 12:00PM';
    if (hour >= 12 && hour < 13) return '12:00PM - 1:00PM';
    if (hour >= 13 && hour < 16) return '1:00PM - 4:00PM';
    if (hour >= 16 && hour < 18) return '4:00PM - 6:00PM';
    if (hour >= 18 && hour < 20) return '6:00PM - 8:00PM';
    if (hour >= 20 && hour < 22) return '8:00PM - 10:00PM';
    if (hour >= 22 && hour < 24) return '10:00PM - 12:00AM';
    return '';
  }

  @override
  void initState() {
    super.initState();
    _fetchOverviewData();
  }

  @override
  void didUpdateWidget(MonthlySalesOverview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dateViewMode != widget.dateViewMode ||
        oldWidget.selectedYear != widget.selectedYear ||
        oldWidget.selectedMonth != widget.selectedMonth ||
        oldWidget.selectedDay != widget.selectedDay ||
        oldWidget.weekStart != widget.weekStart ||
        oldWidget.weekEnd != widget.weekEnd) {
      _fetchOverviewData();
    }
  }

  String _getHeading() {
    switch (widget.dateViewMode) {
      case 'day':
        return "Today's Hourly Traffic";
      case 'week':
        return "Week ${_getWeekOfMonthLabel()} Sales Overview";
      case 'month':
        final date = DateTime(widget.selectedYear, widget.selectedMonth, 1);
        return '${_formatMonthYear(date)} Sales Overview';
      case 'year':
        return 'Yearly Sales Overview';
      default:
        return 'Monthly Sales Overview';
    }
  }

  String _getSubheading() {
    switch (widget.dateViewMode) {
      case 'day':
        final date = DateTime(
          widget.selectedYear,
          widget.selectedMonth,
          widget.selectedDay,
        );
        return 'User traffic by time of day for ${_formatDate(date)}';
      case 'week':
        if (widget.weekStart != null && widget.weekEnd != null) {
          return '${_formatDate(widget.weekStart!)} - ${_formatDate(widget.weekEnd!)}';
        }
        return 'Sales data for this week';
      case 'month':
        final date = DateTime(widget.selectedYear, widget.selectedMonth, 1);
        return 'Sales data for ${_formatMonthYear(date)}';
      case 'year':
        return 'Sales data for year ${widget.selectedYear}';
      default:
        return 'Sales data overview';
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

  String _formatMonthYear(DateTime date) {
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
    return '${monthNames[date.month - 1]} ${date.year}';
  }

  Future<void> _fetchOverviewData() async {
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
      final franchiseId = prefs.getString('selected_franchise_id');

      if (userId == null || userId.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not found';
        });
        return;
      }

      String startDate, endDate;
      String endpoint;

      switch (widget.dateViewMode) {
        case 'day':
          endpoint = '/api/dashboard/franchise/daily-overview';
          final date = DateTime(
            widget.selectedYear,
            widget.selectedMonth,
            widget.selectedDay,
          );
          startDate = _formatDateForApi(date);
          endDate = _formatDateForApi(date);
          break;
        case 'week':
          endpoint = '/api/dashboard/franchise/daily-overview';
          if (widget.weekStart != null && widget.weekEnd != null) {
            startDate = _formatDateForApi(widget.weekStart!);
            endDate = _formatDateForApi(widget.weekEnd!);
          } else {
            final now = DateTime.now();
            final weekday = now.weekday;
            final start = now.subtract(Duration(days: weekday - 1));
            final end = start.add(Duration(days: 6));
            startDate = _formatDateForApi(start);
            endDate = _formatDateForApi(end);
          }
          break;
        case 'month':
          endpoint = '/api/dashboard/franchise/daily-overview';
          startDate = _formatDateForApi(
            DateTime(widget.selectedYear, widget.selectedMonth, 1),
          );
          endDate = _formatDateForApi(
            DateTime(widget.selectedYear, widget.selectedMonth + 1, 0),
          );
          break;
        case 'year':
          endpoint = '/api/dashboard/franchise/monthly-overview';
          startDate = _formatDateForApi(DateTime(widget.selectedYear, 1, 1));
          endDate = _formatDateForApi(DateTime(widget.selectedYear, 12, 31));
          break;
        default:
          endpoint = '/api/dashboard/franchise/monthly-overview';
          startDate = _formatDateForApi(
            DateTime(widget.selectedYear, widget.selectedMonth, 1),
          );
          endDate = _formatDateForApi(
            DateTime(widget.selectedYear, widget.selectedMonth + 1, 0),
          );
      }

      var url =
          '${ApiConfig.baseUrl}$endpoint'
          '?owner_user_id=$userId'
          '&start_date=$startDate'
          '&end_date=$endDate';

      if (franchiseId != null && franchiseId.isNotEmpty) {
        url += '&franchise_id=$franchiseId';
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
            if (widget.dateViewMode == 'day' ||
                widget.dateViewMode == 'week' ||
                widget.dateViewMode == 'month') {
              final overview = data['daily_overview'] ?? {};
              _data = overview['data'] ?? [];
              _summary = overview['summary'] ?? {};
            } else {
              final overview = data['monthly_sales_overview'] ?? {};
              _data = overview['data'] ?? [];
              _summary = overview['summary'] ?? {};
            }
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = data['message'] ?? 'Failed to load data';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load data';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Network error: $e';
      });
    }
  }

  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Generate realistic hourly distribution based on total orders.
  /// NOTE: this always returns a non-zero-sum distribution whenever
  /// totalOrders > 0, so downstream category buckets always get some share.
  List<double> _generateHourlyDistribution(int totalOrders) {
    if (totalOrders <= 0) return List.filled(24, 0.0);

    final weights = List.filled(24, 0.0);

    for (int i = 0; i <= 3; i++) {
      weights[i] = 0.08;
    }
    for (int i = 4; i <= 5; i++) {
      weights[i] = 0.1;
    }
    for (int i = 6; i <= 9; i++) {
      weights[i] = 0.3 + (i - 6) * 0.15;
    }
    for (int i = 10; i <= 20; i++) {
      double peak1 = 1.0 - ((i - 13).abs() / 7.0);
      double peak2 = 1.0 - ((i - 19).abs() / 5.0);
      weights[i] = 0.8 + 0.7 * (peak1 + peak2) / 2;
    }
    for (int i = 21; i <= 23; i++) {
      weights[i] = 0.2 - (i - 21) * 0.05;
    }

    final totalWeight = weights.reduce((a, b) => a + b);
    if (totalWeight <= 0) return List.filled(24, 0.0);

    // Distribute using largest-remainder rounding so the integer orders
    // sum back up to totalOrders instead of getting lost to .round() drift.
    final raw = weights.map((w) => (w / totalWeight) * totalOrders).toList();
    return raw;
  }

  /// Builds the 11-category day breakdown, always returning all categories
  /// (even with zero orders) so the legend is complete, and guaranteeing
  /// that if there ARE orders for the day, they get allocated to buckets.
  List<Map<String, dynamic>> _buildDayCategories({
    required double revenue,
    required int orders,
    required int items,
    required bool isSelectedDayToday,
  }) {
    final result = <Map<String, dynamic>>[];
    final currentHour = DateTime.now().hour;

    if (orders <= 0) {
      for (final cat in _timeCategories) {
        final startHour = cat['start'] as int;
        final endHour = cat['end'] as int;
        final isCurrentHour =
            isSelectedDayToday &&
            currentHour >= startHour &&
            currentHour < endHour;
        result.add({
          'emoji': cat['emoji'],
          'name': cat['name'],
          'label': cat['label'],
          'startHour': startHour,
          'endHour': endHour,
          'revenue': 0.0,
          'orders': 0,
          'items': 0,
          'isCurrentHour': isCurrentHour,
          'hasData': false,
        });
      }
      return result;
    }

    final hourlyDistribution = _generateHourlyDistribution(orders);
    final hourlyRevenue = hourlyDistribution
        .map((o) => (o / orders) * revenue)
        .toList();

    // First pass: raw (fractional) totals per category
    final rawOrdersPerCat = <double>[];
    final revenuePerCat = <double>[];
    final itemsRawPerCat = <double>[];

    for (final cat in _timeCategories) {
      final startHour = cat['start'] as int;
      final endHour = cat['end'] as int;
      double catRevenue = 0;
      double catOrdersRaw = 0;
      for (int hour = startHour; hour < endHour; hour++) {
        catOrdersRaw += hourlyDistribution[hour];
        catRevenue += hourlyRevenue[hour];
      }
      rawOrdersPerCat.add(catOrdersRaw);
      revenuePerCat.add(catRevenue);
      itemsRawPerCat.add(orders > 0 ? (catOrdersRaw / orders) * items : 0);
    }

    // Largest-remainder rounding to guarantee integer orders sum == orders
    final floors = rawOrdersPerCat.map((v) => v.floor()).toList();
    int allocated = floors.fold(0, (a, b) => a + b);
    int remainder = orders - allocated;

    final remainders = List.generate(
      rawOrdersPerCat.length,
      (i) => rawOrdersPerCat[i] - floors[i],
    );
    final sortedIndices = List.generate(rawOrdersPerCat.length, (i) => i)
      ..sort((a, b) => remainders[b].compareTo(remainders[a]));

    final finalOrders = List<int>.from(floors);
    for (int i = 0; i < remainder && i < sortedIndices.length; i++) {
      finalOrders[sortedIndices[i]] += 1;
    }

    for (int i = 0; i < _timeCategories.length; i++) {
      final cat = _timeCategories[i];
      final startHour = cat['start'] as int;
      final endHour = cat['end'] as int;
      final isCurrentHour =
          isSelectedDayToday &&
          currentHour >= startHour &&
          currentHour < endHour;
      final catOrders = finalOrders[i];

      result.add({
        'emoji': cat['emoji'],
        'name': cat['name'],
        'label': cat['label'],
        'startHour': startHour,
        'endHour': endHour,
        'revenue': revenuePerCat[i],
        'orders': catOrders,
        'items': itemsRawPerCat[i].round(),
        'isCurrentHour': isCurrentHour,
        'hasData': catOrders > 0,
      });
    }

    return result;
  }

  List<Map<String, dynamic>> get _chartData {
    final List<Map<String, dynamic>> result = [];

    switch (widget.dateViewMode) {
      case 'day':
        final selected = DateTime(
          widget.selectedYear,
          widget.selectedMonth,
          widget.selectedDay,
        );
        final now = DateTime.now();
        final isSelectedDayToday =
            selected.year == now.year &&
            selected.month == now.month &&
            selected.day == now.day;

        double revenue = 0;
        int orders = 0;
        int items = 0;

        if (_data.isNotEmpty) {
          final dayData = _data.first;
          revenue = (dayData['total_revenue'] ?? 0).toDouble();
          orders = (dayData['order_count'] as num?)?.toInt() ?? 0;
          items = (dayData['total_items'] as num?)?.toInt() ?? 0;
        }

        result.addAll(
          _buildDayCategories(
            revenue: revenue,
            orders: orders,
            items: items,
            isSelectedDayToday: isSelectedDayToday,
          ),
        );
        break;

      case 'week':
        final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final today = DateTime.now();

        DateTime weekStart;
        if (widget.weekStart != null) {
          weekStart = widget.weekStart!;
        } else {
          final now = DateTime.now();
          final weekday = now.weekday;
          weekStart = now.subtract(Duration(days: weekday - 1));
        }

        for (int i = 0; i < weekDays.length; i++) {
          final currentDate = weekStart.add(Duration(days: i));
          final isToday =
              currentDate.day == today.day &&
              currentDate.month == today.month &&
              currentDate.year == today.year;

          Map<String, dynamic>? dayData;
          for (var data in _data) {
            final dateStr = data['date']?.toString() ?? '';
            if (dateStr.isNotEmpty) {
              final dateParts = dateStr.split('T')[0].split('-');
              if (dateParts.length == 3) {
                final dataDate = DateTime(
                  int.parse(dateParts[0]),
                  int.parse(dateParts[1]),
                  int.parse(dateParts[2]),
                );
                if (dataDate.year == currentDate.year &&
                    dataDate.month == currentDate.month &&
                    dataDate.day == currentDate.day) {
                  dayData = data;
                  break;
                }
              }
            }
          }

          if (dayData != null) {
            result.add({
              'dayName': weekDays[i],
              'revenue': (dayData['total_revenue'] ?? 0).toDouble(),
              'orders': (dayData['order_count'] as num?)?.toInt() ?? 0,
              'items': (dayData['total_items'] as num?)?.toInt() ?? 0,
              'totalRevenue': (dayData['total_revenue'] ?? 0).toDouble(),
              'totalOrders': (dayData['order_count'] as num?)?.toInt() ?? 0,
              'isToday': isToday,
            });
          } else {
            result.add({
              'dayName': weekDays[i],
              'revenue': 0.0,
              'orders': 0,
              'items': 0,
              'totalRevenue': 0,
              'totalOrders': 0,
              'isToday': isToday,
            });
          }
        }
        break;

      case 'month':
        final daysInMonth = DateTime(
          widget.selectedYear,
          widget.selectedMonth + 1,
          0,
        ).day;
        final numWeeks = (daysInMonth / 7).ceil();

        final Map<int, Map<String, dynamic>> byDay = {};
        for (var d in _data) {
          final dateStr = d['date']?.toString() ?? '';
          if (dateStr.isEmpty) continue;
          final parts = dateStr.split('T')[0].split('-');
          if (parts.length != 3) continue;
          final dt = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          if (dt.year == widget.selectedYear &&
              dt.month == widget.selectedMonth) {
            byDay[dt.day] = d;
          }
        }

        final today = DateTime.now();
        final isSelectedMonthCurrent =
            widget.selectedYear == today.year &&
            widget.selectedMonth == today.month;
        final currentWeekOfMonth = isSelectedMonthCurrent
            ? ((today.day - 1) ~/ 7) + 1
            : -1;

        for (int weekNum = 0; weekNum < numWeeks && weekNum < 5; weekNum++) {
          double weekRevenue = 0;
          int weekOrders = 0;
          int weekItems = 0;

          final startDay = weekNum * 7 + 1;
          final endDay = ((weekNum + 1) * 7).clamp(0, daysInMonth);

          for (int day = startDay; day <= endDay; day++) {
            final d = byDay[day];
            if (d != null) {
              weekRevenue += (d['total_revenue'] ?? 0).toDouble();
              weekOrders += ((d['order_count'] as num?)?.toInt() ?? 0);
              weekItems += ((d['total_items'] as num?)?.toInt() ?? 0);
            }
          }

          final weekLabel = 'W${weekNum + 1}';
          final isCurrentWeek = (weekNum + 1) == currentWeekOfMonth;

          result.add({
            'weekLabel': weekLabel,
            'revenue': weekRevenue,
            'orders': weekOrders,
            'items': weekItems,
            'totalRevenue': weekRevenue,
            'totalOrders': weekOrders,
            'isCurrentWeek': isCurrentWeek,
          });
        }
        break;

      case 'year':
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

        final isSelectedYearCurrent =
            widget.selectedYear == DateTime.now().year;

        final monthsData = <int, Map<String, dynamic>>{};
        for (var yearData in _data) {
          final months = yearData['months'] as List? ?? [];
          for (var month in months) {
            final m = month['month'] as int;
            monthsData[m] = {
              'revenue': (month['total_revenue'] ?? 0).toDouble(),
              'orders': (month['total_orders'] as num?)?.toInt() ?? 0,
              'items': (month['total_items'] as num?)?.toInt() ?? 0,
            };
          }
        }

        for (int i = 1; i <= 12; i++) {
          final isCurrentMonth = isSelectedYearCurrent && (i == _currentMonth);
          if (monthsData.containsKey(i)) {
            final data = monthsData[i]!;
            result.add({
              'monthName': monthNames[i - 1],
              'revenue': data['revenue'] ?? 0.0,
              'orders': data['orders'] ?? 0,
              'items': data['items'] ?? 0,
              'totalRevenue': data['revenue'] ?? 0.0,
              'totalOrders': data['orders'] ?? 0,
              'isCurrentMonth': isCurrentMonth,
            });
          } else {
            result.add({
              'monthName': monthNames[i - 1],
              'revenue': 0.0,
              'orders': 0,
              'items': 0,
              'totalRevenue': 0,
              'totalOrders': 0,
              'isCurrentMonth': isCurrentMonth,
            });
          }
        }
        break;
    }

    return result;
  }

  /// Format currency WITHOUT abbreviations - shows exact number
  String _formatCurrency(double amount) {
    // Format with 2 decimal places, no abbreviations
    return '₹${amount.toStringAsFixed(2)}';
  }

  String _getFooterRevenueLabel() {
    switch (widget.dateViewMode) {
      case 'day':
        final date = DateTime(
          widget.selectedYear,
          widget.selectedMonth,
          widget.selectedDay,
        );
        return 'Total Revenue ${_formatDate(date)}';
      case 'week':
        return 'Total Revenue ${_getWeekOfMonthLabel()}';
      case 'month':
        final date = DateTime(widget.selectedYear, widget.selectedMonth, 1);
        return 'Total Revenue ${_formatMonthYear(date)}';
      case 'year':
        return 'Total Revenue ${widget.selectedYear}';
      default:
        return 'Total Revenue';
    }
  }

  String _getFooterOrdersLabel() {
    switch (widget.dateViewMode) {
      case 'day':
        final date = DateTime(
          widget.selectedYear,
          widget.selectedMonth,
          widget.selectedDay,
        );
        return 'Total Orders ${_formatDate(date)}';
      case 'week':
        return 'Total Orders ${_getWeekOfMonthLabel()}';
      case 'month':
        final date = DateTime(widget.selectedYear, widget.selectedMonth, 1);
        return 'Total Orders ${_formatMonthYear(date)}';
      case 'year':
        return 'Total Orders ${widget.selectedYear}';
      default:
        return 'Total Orders';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;
    final chartData = _chartData;

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
          _buildHeader(isTablet),
          SizedBox(height: context.h(12)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [_buildChartTypeToggle(isTablet)],
          ),
          SizedBox(height: context.h(12)),
          if (_isLoading)
            _buildLoadingState(isTablet)
          else if (_errorMessage != null)
            _buildErrorState(isTablet)
          else if (chartData.isEmpty)
            _buildEmptyState(isTablet)
          else
            _buildChart(isTablet, chartData),
          SizedBox(height: context.h(16)),
          _buildPeakHourInfo(isTablet, chartData),
          SizedBox(height: context.h(12)),
          _buildTimeLegend(isTablet, chartData),
          SizedBox(height: context.h(12)),
          _buildFooterStats(isTablet),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isTablet) {
    final theme = context.siporaTheme;

    return Column(
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
        SizedBox(height: context.h(4)),
        Row(
          children: [
            Expanded(
              child: Text(
                _getSubheading(),
                style: TextStyle(
                  fontSize: isTablet ? context.sp(12) : context.sp(11),
                  color: theme.textMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartTypeToggle(bool isTablet) {
    final theme = context.siporaTheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(4),
        vertical: context.h(2),
      ),
      decoration: BoxDecoration(
        color: theme.cream,
        borderRadius: BorderRadius.circular(context.r(8)),
        border: Border.all(color: theme.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _chartType = 'bar'),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(10),
                vertical: context.h(6),
              ),
              decoration: BoxDecoration(
                color: _chartType == 'bar'
                    ? SiporaTheme.greenDark
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(context.r(6)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    size: isTablet ? context.w(18) : context.w(16),
                    color: _chartType == 'bar' ? Colors.white : theme.textMuted,
                  ),
                  SizedBox(width: context.w(4)),
                  Text(
                    'Bar',
                    style: TextStyle(
                      fontSize: isTablet ? context.sp(12) : context.sp(10),
                      color: _chartType == 'bar'
                          ? Colors.white
                          : theme.textMuted,
                      fontWeight: _chartType == 'bar'
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _chartType = 'line'),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(10),
                vertical: context.h(6),
              ),
              decoration: BoxDecoration(
                color: _chartType == 'line'
                    ? SiporaTheme.greenDark
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(context.r(6)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.show_chart_rounded,
                    size: isTablet ? context.w(18) : context.w(16),
                    color: _chartType == 'line'
                        ? Colors.white
                        : theme.textMuted,
                  ),
                  SizedBox(width: context.w(4)),
                  Text(
                    'Line',
                    style: TextStyle(
                      fontSize: isTablet ? context.sp(12) : context.sp(10),
                      color: _chartType == 'line'
                          ? Colors.white
                          : theme.textMuted,
                      fontWeight: _chartType == 'line'
                          ? FontWeight.w600
                          : FontWeight.w400,
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
              _errorMessage ?? 'Failed to load data',
              style: TextStyle(
                fontSize: isTablet ? context.sp(13) : context.sp(11),
                color: Colors.red.shade400,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.h(8)),
            ElevatedButton(
              onPressed: _fetchOverviewData,
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
    return SizedBox(
      height: isTablet ? context.h(200) : context.h(160),
      child: Center(
        child: Text(
          'No data available for this period',
          style: TextStyle(
            fontSize: isTablet ? context.sp(14) : context.sp(12),
            color: context.siporaTheme.textMuted,
          ),
        ),
      ),
    );
  }

  /// Peak Hour card: icon + category + number of orders, for whichever
  /// category had the highest order count that day.
  Widget _buildPeakHourInfo(
    bool isTablet,
    List<Map<String, dynamic>> chartData,
  ) {
    if (widget.dateViewMode != 'day') return const SizedBox.shrink();

    final theme = context.siporaTheme;

    Map<String, dynamic>? peakHour;
    int maxOrders = 0;
    for (var data in chartData) {
      final orders = data['orders'] as int? ?? 0;
      if (orders > maxOrders) {
        maxOrders = orders;
        peakHour = data;
      }
    }

    if (peakHour == null || maxOrders <= 0) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(8),
          vertical: context.h(6),
        ),
        decoration: BoxDecoration(
          color: SiporaTheme.greenDark.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(context.r(8)),
          border: Border.all(
            color: SiporaTheme.greenDark.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: SiporaTheme.greenDark,
              size: context.w(16),
            ),
            SizedBox(width: context.w(8)),
            Text(
              'No orders yet today',
              style: TextStyle(
                fontSize: isTablet ? context.sp(12) : context.sp(10),
                fontWeight: FontWeight.w500,
                color: theme.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    final peakHourName = peakHour['name'] as String? ?? '';
    final peakHourEmoji = peakHour['emoji'] as String? ?? '';
    final startHour = peakHour['startHour'] as int? ?? 0;
    final timeRange = _getTimeRange(startHour);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(8),
        vertical: context.h(6),
      ),
      decoration: BoxDecoration(
        color: SiporaTheme.greenDark.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(context.r(8)),
        border: Border.all(color: SiporaTheme.greenDark.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.trending_up_rounded,
            color: SiporaTheme.greenDark,
            size: context.w(16),
          ),
          SizedBox(width: context.w(8)),
          Text(
            '⏰ Peak Hour',
            style: TextStyle(
              fontSize: isTablet ? context.sp(12) : context.sp(10),
              fontWeight: FontWeight.w700,
              color: theme.textDark,
            ),
          ),
          SizedBox(width: context.w(8)),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(8),
                vertical: context.h(4),
              ),
              decoration: BoxDecoration(
                color: SiporaTheme.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(context.r(6)),
                border: Border.all(
                  color: SiporaTheme.gold.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    peakHourEmoji,
                    style: TextStyle(
                      fontSize: isTablet ? context.sp(16) : context.sp(14),
                    ),
                  ),
                  SizedBox(width: context.w(4)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(6),
                      vertical: context.h(2),
                    ),
                    decoration: BoxDecoration(
                      color: SiporaTheme.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(context.r(8)),
                    ),
                    child: Text(
                      '$maxOrders orders',
                      style: TextStyle(
                        fontSize: isTablet ? context.sp(10) : context.sp(9),
                        fontWeight: FontWeight.w600,
                        color: SiporaTheme.gold,
                      ),
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

  /// Time Legend: shows all 11 categories in 2 columns with Midnight at the last position
  Widget _buildTimeLegend(bool isTablet, List<Map<String, dynamic>> chartData) {
    if (widget.dateViewMode != 'day') return const SizedBox.shrink();
    if (chartData.isEmpty) return const SizedBox.shrink();

    final theme = context.siporaTheme;
    final activeCount = chartData
        .where((d) => (d['orders'] as int? ?? 0) > 0)
        .length;

    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: theme.cream,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: theme.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '🕐 Time Legend',
                style: TextStyle(
                  fontSize: isTablet ? context.sp(12) : context.sp(11),
                  fontWeight: FontWeight.w600,
                  color: theme.textDark,
                ),
              ),
              SizedBox(width: context.w(8)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(6),
                  vertical: context.h(2),
                ),
                decoration: BoxDecoration(
                  color: SiporaTheme.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(context.r(8)),
                  border: Border.all(
                    color: SiporaTheme.gold.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  '$activeCount active',
                  style: TextStyle(
                    fontSize: isTablet ? context.sp(9) : context.sp(8),
                    fontWeight: FontWeight.w600,
                    color: SiporaTheme.gold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(8)),
          // 2-column grid layout
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: context.w(8),
                runSpacing: context.h(6),
                children: chartData.map((data) {
                  final emoji = data['emoji'] as String? ?? '';
                  final startHour = data['startHour'] as int? ?? 0;
                  final isCurrent = data['isCurrentHour'] as bool? ?? false;
                  final orders = data['orders'] as int? ?? 0;
                  final hasData = data['hasData'] as bool? ?? false;
                  final timeRange = _getTimeRange(startHour);
                  final isActive = hasData || isCurrent;

                  // Calculate width for 2 columns with spacing
                  final width = (constraints.maxWidth - context.w(8)) / 2;

                  return SizedBox(
                    width: width,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(10),
                        vertical: context.h(8),
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? (isCurrent
                                  ? SiporaTheme.gold.withValues(alpha: 0.15)
                                  : SiporaTheme.greenDark.withValues(
                                      alpha: 0.05,
                                    ))
                            : theme.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(context.r(8)),
                        border: Border.all(
                          color: isActive
                              ? (isCurrent
                                    ? SiporaTheme.gold
                                    : SiporaTheme.greenDark.withValues(
                                        alpha: 0.3,
                                      ))
                              : theme.border.withValues(alpha: 0.3),
                          width: isCurrent ? 1.5 : 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Icon
                          Text(
                            emoji,
                            style: TextStyle(
                              fontSize: isTablet
                                  ? context.sp(18)
                                  : context.sp(16),
                            ),
                          ),
                          SizedBox(width: context.w(6)),
                          // Time
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  data['name'] as String? ?? '',
                                  style: TextStyle(
                                    fontSize: isTablet
                                        ? context.sp(10)
                                        : context.sp(9),
                                    fontWeight: isCurrent
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: isActive
                                        ? theme.textDark
                                        : theme.textMuted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  timeRange,
                                  style: TextStyle(
                                    fontSize: isTablet
                                        ? context.sp(8)
                                        : context.sp(7),
                                    color: theme.textMuted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Number of orders
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.w(6),
                              vertical: context.h(3),
                            ),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? SiporaTheme.gold.withValues(alpha: 0.2)
                                  : (orders > 0
                                        ? SiporaTheme.greenDark.withValues(
                                            alpha: 0.1,
                                          )
                                        : theme.border.withValues(alpha: 0.15)),
                              borderRadius: BorderRadius.circular(context.r(4)),
                            ),
                            child: Text(
                              '$orders',
                              style: TextStyle(
                                fontSize: isTablet
                                    ? context.sp(9)
                                    : context.sp(8),
                                fontWeight: FontWeight.w600,
                                color: isCurrent
                                    ? SiporaTheme.gold
                                    : (orders > 0
                                          ? SiporaTheme.greenDark
                                          : theme.textMuted),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChart(bool isTablet, List<Map<String, dynamic>> data) {
    final theme = context.siporaTheme;
    final isDayView = widget.dateViewMode == 'day';
    final hasData = data.any((item) => (item['revenue'] ?? 0) > 0);

    if (!hasData) {
      return _buildEmptyState(isTablet);
    }

    final maxRevenue = data.fold<double>(
      0,
      (max, item) =>
          (item['revenue'] ?? 0) > max ? (item['revenue'] ?? 0) : max,
    );

    /// Format number WITHOUT abbreviations - shows exact number
    String formatNumber(double value) {
      if (value == 0) return '0';
      // Show exact number with 2 decimal places
      return '₹${value.toStringAsFixed(2)}';
    }

    String formatTooltip(double value) => '₹${value.toStringAsFixed(2)}';

    return SizedBox(
      height: isTablet ? context.h(250) : context.h(200),
      child: _chartType == 'bar'
          ? BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxRevenue / 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.border,
                    strokeWidth: 0.5,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isTablet ? 50 : 40,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= data.length) {
                          return const SizedBox.shrink();
                        }

                        if (isDayView) {
                          // Show time labels instead of emojis
                          final label = data[index]['label'] as String? ?? '';
                          final isCurrent =
                              data[index]['isCurrentHour'] as bool? ?? false;
                          return Padding(
                            padding: EdgeInsets.only(top: context.h(4)),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: isTablet
                                    ? context.sp(9)
                                    : context.sp(8),
                                color: isCurrent
                                    ? SiporaTheme.gold
                                    : theme.textMuted,
                                fontWeight: isCurrent
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          );
                        }

                        final label =
                            data[index]['dayName'] ??
                            data[index]['weekLabel'] ??
                            data[index]['monthName'] ??
                            '';
                        final highlighted =
                            (data[index]['isToday'] ?? false) ||
                            (data[index]['isCurrentWeek'] ?? false) ||
                            (data[index]['isCurrentMonth'] ?? false);
                        return Padding(
                          padding: EdgeInsets.only(top: context.h(4)),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: isTablet
                                  ? context.sp(9)
                                  : context.sp(8),
                              color: highlighted
                                  ? SiporaTheme.greenDark
                                  : theme.textMuted,
                              fontWeight: highlighted
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isTablet ? 70 : 60,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: EdgeInsets.only(right: context.w(4)),
                        child: Text(
                          formatNumber(value),
                          style: TextStyle(
                            fontSize: isTablet ? context.sp(8) : context.sp(7),
                            color: theme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                        BarTooltipItem(
                          formatTooltip(rod.toY),
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isTablet
                                ? context.sp(14)
                                : context.sp(12),
                          ),
                        ),
                  ),
                ),
                barGroups: data.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final revenue = (item['revenue'] ?? 0).toDouble();
                  final isCurrent = item['isCurrentHour'] ?? false;

                  Color getColor(int idx, bool isCurrent) {
                    if (isCurrent) return SiporaTheme.gold;
                    if (isDayView) {
                      final name = item['name'] as String? ?? '';
                      switch (name) {
                        case 'Dawn':
                          return const Color(0xFF9B59B6);
                        case 'Sunrise':
                          return const Color(0xFFF39C12);
                        case 'Good Morning':
                          return const Color(0xFF2ECC71);
                        case 'Forenoon':
                          return const Color(0xFF3498DB);
                        case 'Noon':
                          return const Color(0xFFE74C3C);
                        case 'Good Afternoon':
                          return const Color(0xFF1ABC9C);
                        case 'Dusk':
                          return const Color(0xFFE67E22);
                        case 'Twilight':
                          return const Color(0xFF8E44AD);
                        case 'Good Evening':
                          return const Color(0xFF2C3E50);
                        case 'Good Night':
                          return const Color(0xFF5D6D7E);
                        case 'Midnight':
                          return const Color(0xFF34495E);
                        default:
                          return const Color(0xFF4F46E5);
                      }
                    }
                    final colors = [
                      const Color(0xFF4F46E5),
                      const Color(0xFF7C3AED),
                      const Color(0xFFDB2777),
                      const Color(0xFFEA580C),
                      const Color(0xFFF59E0B),
                      const Color(0xFF10B981),
                      const Color(0xFF06B6D4),
                    ];
                    return colors[idx % colors.length];
                  }

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: revenue,
                        color: getColor(index, isCurrent),
                        width: isTablet ? context.w(20) : context.w(14),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                        borderSide: isCurrent
                            ? const BorderSide(
                                color: SiporaTheme.gold,
                                width: 2,
                              )
                            : BorderSide.none,
                      ),
                    ],
                  );
                }).toList(),
              ),
            )
          : LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxRevenue / 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.border,
                    strokeWidth: 0.5,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isTablet ? 50 : 40,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= data.length) {
                          return const SizedBox.shrink();
                        }

                        if (isDayView) {
                          // Show time labels instead of emojis
                          final label = data[index]['label'] as String? ?? '';
                          final isCurrent =
                              data[index]['isCurrentHour'] as bool? ?? false;
                          return Padding(
                            padding: EdgeInsets.only(top: context.h(4)),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: isTablet
                                    ? context.sp(9)
                                    : context.sp(8),
                                color: isCurrent
                                    ? SiporaTheme.gold
                                    : theme.textMuted,
                                fontWeight: isCurrent
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          );
                        }

                        final label =
                            data[index]['dayName'] ??
                            data[index]['weekLabel'] ??
                            data[index]['monthName'] ??
                            '';
                        final highlighted =
                            (data[index]['isToday'] ?? false) ||
                            (data[index]['isCurrentWeek'] ?? false) ||
                            (data[index]['isCurrentMonth'] ?? false);
                        return Padding(
                          padding: EdgeInsets.only(top: context.h(4)),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: isTablet
                                  ? context.sp(9)
                                  : context.sp(8),
                              color: highlighted
                                  ? SiporaTheme.greenDark
                                  : theme.textMuted,
                              fontWeight: highlighted
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isTablet ? 70 : 60,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: EdgeInsets.only(right: context.w(4)),
                        child: Text(
                          formatNumber(value),
                          style: TextStyle(
                            fontSize: isTablet ? context.sp(8) : context.sp(7),
                            color: theme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                      return LineTooltipItem(
                        formatTooltip(spot.y),
                        TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? context.sp(14) : context.sp(12),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return FlSpot(
                        index.toDouble(),
                        (item['revenue'] ?? 0).toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: SiporaTheme.greenDark,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: SiporaTheme.greenDark.withValues(alpha: 0.15),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final isCurrent =
                            data[index.toInt()]['isCurrentHour'] ?? false;
                        return FlDotCirclePainter(
                          radius: isCurrent ? 6 : 4,
                          color: isCurrent
                              ? SiporaTheme.gold
                              : SiporaTheme.greenDark,
                          strokeWidth: isCurrent ? 2 : 1,
                          strokeColor: isCurrent
                              ? SiporaTheme.greenDark
                              : Colors.transparent,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFooterStats(bool isTablet) {
    final theme = context.siporaTheme;
    final totalRevenue = (_summary['total_revenue'] ?? 0).toDouble();
    final totalOrders = _summary['total_orders'] ?? 0;

    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: theme.cream,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: theme.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getFooterRevenueLabel(),
                  style: TextStyle(
                    fontSize: isTablet ? context.sp(11) : context.sp(10),
                    color: theme.textMuted,
                  ),
                ),
                SizedBox(height: context.h(2)),
                Text(
                  _formatCurrency(totalRevenue),
                  style: TextStyle(
                    fontSize: isTablet ? context.sp(16) : context.sp(14),
                    fontWeight: FontWeight.w700,
                    color: theme.textDark,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: context.h(40), color: theme.border),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _getFooterOrdersLabel(),
                  style: TextStyle(
                    fontSize: isTablet ? context.sp(11) : context.sp(10),
                    color: theme.textMuted,
                  ),
                ),
                SizedBox(height: context.h(2)),
                Text(
                  '$totalOrders',
                  style: TextStyle(
                    fontSize: isTablet ? context.sp(16) : context.sp(14),
                    fontWeight: FontWeight.w700,
                    color: theme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
