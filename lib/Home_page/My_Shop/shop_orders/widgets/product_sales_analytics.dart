import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../theme/sipora_theme.dart';
import '../../../../utils/screen_utils.dart';
import '../../../../services/product_sales_api.dart';
import '../../widgets/universal_filter.dart';

class ProductSalesAnalytics extends StatefulWidget {
  final List<Map<String, dynamic>> franchises;
  final String? initialFranchiseId;
  final DateViewMode? initialDateViewMode;
  final DateTime? initialSelectedDate;
  final DateTime? initialWeekStart;
  final DateTime? initialWeekEnd;
  final Function(DateViewMode mode, DateTime date)? onFilterChanged;

  const ProductSalesAnalytics({
    super.key,
    required this.franchises,
    this.initialFranchiseId,
    this.initialDateViewMode,
    this.initialSelectedDate,
    this.initialWeekStart,
    this.initialWeekEnd,
    this.onFilterChanged,
  });

  @override
  State<ProductSalesAnalytics> createState() => _ProductSalesAnalyticsState();
}

class _ProductSalesAnalyticsState extends State<ProductSalesAnalytics> {
  // ---------- State ----------
  String? _selectedFranchiseId;
  DateViewMode _dateViewMode = DateViewMode.day;
  DateTime _selectedDate = DateTime.now();
  DateTime? _weekStart;
  DateTime? _weekEnd;

  bool _isLoading = false;
  String? _error;
  ProductSalesResponse? _data;

  // Product table
  String _searchQuery = '';
  String _sortKey = 'item_total';
  bool _sortAscending = false;
  int _currentPage = 1;
  int _pageSize = 8;
  final List<int> _pageSizeOptions = [8, 12, 20];

  List<ProductSummary> _filteredProducts = [];

  // ---------- Init ----------
  @override
  void initState() {
    super.initState();
    _selectedFranchiseId =
        widget.initialFranchiseId ??
        (widget.franchises.isNotEmpty
            ? widget.franchises.first['franchise_id']
            : null);

    // Initialize filter state from widget params or defaults
    _dateViewMode = widget.initialDateViewMode ?? DateViewMode.day;
    _selectedDate = widget.initialSelectedDate ?? DateTime.now();
    _weekStart = widget.initialWeekStart;
    _weekEnd = widget.initialWeekEnd;
    
    // Calculate week range if needed
    _calculateWeekRange();

    _fetchData();
  }

  // ---------- Handle Parent Widget Updates ----------
  @override
  void didUpdateWidget(ProductSalesAnalytics oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync with parent filter changes
    if (oldWidget.initialDateViewMode != widget.initialDateViewMode ||
        oldWidget.initialSelectedDate != widget.initialSelectedDate ||
        oldWidget.initialWeekStart != widget.initialWeekStart ||
        oldWidget.initialWeekEnd != widget.initialWeekEnd ||
        oldWidget.initialFranchiseId != widget.initialFranchiseId) {
      setState(() {
        _dateViewMode = widget.initialDateViewMode ?? DateViewMode.day;
        _selectedDate = widget.initialSelectedDate ?? DateTime.now();
        _weekStart = widget.initialWeekStart;
        _weekEnd = widget.initialWeekEnd;
        _selectedFranchiseId = widget.initialFranchiseId;
        _calculateWeekRange();
      });
      _fetchData();
    }
  }

  // ---------- Data Fetch ----------
  Future<void> _fetchData() async {
    if (_selectedFranchiseId == null) {
      setState(() {
        _error = 'Please select a franchise';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Calculate date range based on view mode
      String startDateStr, endDateStr;

      switch (_dateViewMode) {
        case DateViewMode.day:
          final date = _selectedDate;
          startDateStr = _formatDate(date);
          endDateStr = _formatDate(date);
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

      final response = await ProductSalesApi.fetchProductSales(
        franchiseId: _selectedFranchiseId!,
        startDate: DateTime.parse(startDateStr),
        endDate: DateTime.parse(endDateStr),
        view: _getViewModeForApi(),
      );

      if (response.success) {
        setState(() {
          _data = response;
          _applyFiltersAndSort();
          _isLoading = false;
        });
      } else {
        throw Exception('Unknown error');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getViewModeForApi() {
    switch (_dateViewMode) {
      case DateViewMode.day:
        return 'daily';
      case DateViewMode.week:
        return 'weekly';
      case DateViewMode.month:
        return 'monthly';
      case DateViewMode.year:
        return 'yearly';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ---------- Week Range Helper ----------
  void _calculateWeekRange() {
    if (_dateViewMode == DateViewMode.week) {
      final weekday = _selectedDate.weekday;
      final start = _selectedDate.subtract(Duration(days: weekday - 1));
      final end = start.add(Duration(days: 6));
      _weekStart = DateTime(start.year, start.month, start.day);
      _weekEnd = DateTime(end.year, end.month, end.day);
    }
  }

  // ---------- Filter & Sort ----------
  void _applyFiltersAndSort() {
    if (_data == null) {
      _filteredProducts = [];
      return;
    }

    final query = _searchQuery.trim().toLowerCase();
    var list = _data!.products.where((p) {
      if (query.isEmpty) return true;
      return p.productName.toLowerCase().contains(query) ||
          p.productId.toLowerCase().contains(query);
    }).toList();

    list.sort((a, b) {
      dynamic aVal, bVal;
      switch (_sortKey) {
        case 'product_name':
          aVal = a.productName.toLowerCase();
          bVal = b.productName.toLowerCase();
          break;
        case 'quantity':
          aVal = a.summary.quantity;
          bVal = b.summary.quantity;
          break;
        case 'unit_amount':
          aVal = a.summary.unitAmount;
          bVal = b.summary.unitAmount;
          break;
        case 'gst':
          aVal = a.summary.gst;
          bVal = b.summary.gst;
          break;
        case 'total_amount':
          aVal = a.summary.totalAmount;
          bVal = b.summary.totalAmount;
          break;
        case 'item_total':
          aVal = a.summary.itemTotal;
          bVal = b.summary.itemTotal;
          break;
        case 'discount':
          aVal = a.summary.discount;
          bVal = b.summary.discount;
          break;
        default:
          aVal = a.summary.itemTotal;
          bVal = b.summary.itemTotal;
      }

      if (aVal is String && bVal is String) {
        return _sortAscending ? aVal.compareTo(bVal) : bVal.compareTo(aVal);
      } else {
        final aNum = (aVal ?? 0).toDouble();
        final bNum = (bVal ?? 0).toDouble();
        return _sortAscending ? aNum.compareTo(bNum) : bNum.compareTo(aNum);
      }
    });

    _filteredProducts = list;
    _currentPage = 1;
  }

  // ---------- Helpers ----------
  String _formatCurrency(double amount) =>
      '₹${NumberFormat('#,##0.00').format(amount)}';
  String _formatNumber(int value) => NumberFormat('#,##0').format(value);

  List<ProductSummary> _getPaginated() {
    final start = (_currentPage - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, _filteredProducts.length);
    return _filteredProducts.sublist(start, end);
  }

  int get _totalPages => (_filteredProducts.length / _pageSize).ceil();

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;

    return Column(
      children: [
        // Franchise Selector
        if (widget.franchises.length > 1) _buildFranchiseSelector(isTablet),

        Expanded(
          child: _isLoading
              ? _buildLoading()
              : _error != null
              ? _buildError()
              : _data == null
              ? _buildEmpty()
              : _buildContent(isTablet),
        ),
      ],
    );
  }

  // ---------- Franchise Selector ----------
  Widget _buildFranchiseSelector(bool isTablet) {
    final theme = context.siporaTheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: theme.white,
        border: Border(bottom: BorderSide(color: theme.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.storefront_rounded,
            color: SiporaTheme.greenMid,
            size: 20.w,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFranchiseId,
                isExpanded: true,
                hint: Text(
                  'Select Franchise',
                  style: TextStyle(
                    fontSize: isTablet ? 14.sp : 13.sp,
                    color: theme.textMuted,
                  ),
                ),
                items: widget.franchises.map((franchise) {
                  final name = franchise['shop_name'] ?? 'Unknown Shop';
                  final city = franchise['city'] ?? '';
                  final displayName = city.isNotEmpty ? '$name ($city)' : name;

                  return DropdownMenuItem<String>(
                    value: franchise['franchise_id'],
                    child: Text(
                      displayName,
                      style: TextStyle(
                        fontSize: isTablet ? 14.sp : 13.sp,
                        color: theme.textDark,
                        fontWeight:
                            _selectedFranchiseId == franchise['franchise_id']
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedFranchiseId = val;
                  });
                  _fetchData();
                },
                icon: Icon(
                  Icons.arrow_drop_down_rounded,
                  color: SiporaTheme.greenMid,
                  size: 24.w,
                ),
                dropdownColor: theme.white,
                style: TextStyle(
                  fontSize: isTablet ? 14.sp : 13.sp,
                  color: theme.textDark,
                ),
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Loading / Error / Empty ----------
  Widget _buildLoading() {
    return Center(
      child: CircularProgressIndicator(color: SiporaTheme.greenDark),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 48.w),
            SizedBox(height: 12.h),
            Text(
              _error!,
              style: TextStyle(fontSize: 14.sp, color: Colors.red.shade400),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _fetchData,
              style: ElevatedButton.styleFrom(
                backgroundColor: SiporaTheme.greenDark,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64.w,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 12.h),
          Text(
            'No product data available',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ---------- Main Content ----------
  Widget _buildContent(bool isTablet) {
    if (_data == null) return _buildEmpty();

    final overall = _data!.overall;
    final kpis = [
      {
        'label': 'Total Quantity',
        'value': _formatNumber(overall.quantity),
        'color': Colors.green,
        'icon': Icons.shopping_bag_rounded,
      },
      {
        'label': 'Total Revenue',
        'value': _formatCurrency(overall.itemTotal),
        'color': Colors.blue,
        'icon': Icons.trending_up_rounded,
      },
      {
        'label': 'Total GST',
        'value': _formatCurrency(overall.gst),
        'color': Colors.orange,
        'icon': Icons.percent_rounded,
      },
      {
        'label': 'Total Discount',
        'value': _formatCurrency(overall.discount),
        'color': Colors.red,
        'icon': Icons.local_offer_rounded,
      },
      {
        'label': 'Total Amount',
        'value': _formatCurrency(overall.totalAmount),
        'color': Colors.purple,
        'icon': Icons.attach_money_rounded,
      },
      {
        'label': 'Avg GST Rate',
        'value': '${overall.unitGstRate.toStringAsFixed(1)}%',
        'color': Colors.teal,
        'icon': Icons.calculate_rounded,
      },
    ];

    return RefreshIndicator(
      color: SiporaTheme.greenDark,
      onRefresh: _fetchData,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Column(
          children: [
            // KPI Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isTablet ? 3 : 2,
                crossAxisSpacing: 8.w,
                mainAxisSpacing: 8.h,
                childAspectRatio: 1.6,
              ),
              itemCount: kpis.length,
              itemBuilder: (ctx, i) {
                final k = kpis[i];
                return Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(
                            k['icon'] as IconData,
                            color: k['color'] as Color,
                            size: 18.w,
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              k['label'] as String,
                              style: TextStyle(
                                fontSize: 9.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        k['value'] as String,
                        style: TextStyle(
                          fontSize: isTablet ? 18.sp : 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 16.h),

            // Charts
            _buildCharts(isTablet),
            SizedBox(height: 16.h),

            // Product Table
            _buildProductTable(isTablet),
            SizedBox(height: 80.h),
          ],
        ),
      ),
    );
  }

  // ---------- Charts ----------
  Widget _buildCharts(bool isTablet) {
    // Build period analytics from product breakdowns
    final periodData = _buildPeriodAnalytics();
    if (periodData.isEmpty) {
      return SizedBox(
        height: 200.h,
        child: Center(
          child: Text(
            'No chart data',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ),
      );
    }

    // Adjust chart dimensions for mobile - increase height and account for padding
    final chartHeight = isTablet ? 200.h : 180.h;
    final screenWidth = MediaQuery.of(context).size.width;
    final chartWidth = screenWidth - 32.w;
    
    // Determine if horizontal scroll is needed for mobile
    final needsHorizontalScroll = !isTablet && periodData.length > 7;

    return Column(
      children: [
        _chartCard(
          title: 'Revenue Trend',
          icon: Icons.show_chart_rounded,
          enableHorizontalScroll: needsHorizontalScroll,
          child: SizedBox(
            height: chartHeight,
            width: chartWidth,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isTablet ? 28 : 35,
                      interval: _calculateXAxisInterval(periodData.length, isTablet),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= periodData.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Text(
                            _getXAxisLabel(periodData[idx].period, idx),
                            style: TextStyle(
                              fontSize: isTablet ? 8.sp : 7.sp,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isTablet ? 40 : 50,
                      getTitlesWidget: (value, meta) => Text(
                        _formatCurrencyShort(value),
                        style: TextStyle(fontSize: isTablet ? 8.sp : 7.sp, color: Colors.grey),
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
                lineBarsData: [
                  LineChartBarData(
                    spots: periodData
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.itemTotal))
                        .toList(),
                    isCurved: true,
                    color: Colors.green.shade700,
                    barWidth: isTablet ? 3 : 2, // Thinner lines on mobile
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.shade200.withValues(alpha: 0.3),
                    ),
                    dotData: const FlDotData(show: false),
                  ),
                ],
                minY: 0,
                maxY:
                    periodData
                        .map((e) => e.itemTotal)
                        .reduce((a, b) => a > b ? a : b) *
                    1.2,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots
                        .map(
                          (s) => LineTooltipItem(
                            _formatCurrency(s.y),
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),

        // Quantity Bar Chart
        _chartCard(
          title: 'Quantity Trend',
          icon: Icons.bar_chart_rounded,
          enableHorizontalScroll: needsHorizontalScroll,
          child: SizedBox(
            height: chartHeight,
            width: chartWidth,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isTablet ? 28 : 35,
                      interval: _calculateXAxisInterval(periodData.length, isTablet),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= periodData.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Text(
                            _getXAxisLabel(periodData[idx].period, idx),
                            style: TextStyle(
                              fontSize: isTablet ? 8.sp : 7.sp,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isTablet ? 30 : 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(fontSize: isTablet ? 8.sp : 7.sp, color: Colors.grey),
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
                barGroups: periodData.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.quantity.toDouble(),
                        color: Colors.blue.shade600,
                        width: isTablet ? 12.w : 8.w, // Smaller bars on mobile
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(4.r),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                minY: 0,
                maxY:
                    periodData
                        .map((e) => e.quantity.toDouble())
                        .reduce((a, b) => a > b ? a : b) *
                    1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                        BarTooltipItem(
                          _formatNumber(rod.toY.toInt()),
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),

        // GST Line Chart
        _chartCard(
          title: 'GST Trend',
          icon: Icons.percent_rounded,
          enableHorizontalScroll: needsHorizontalScroll,
          child: SizedBox(
            height: chartHeight,
            width: chartWidth,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isTablet ? 28 : 35,
                      interval: _calculateXAxisInterval(periodData.length, isTablet),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= periodData.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Text(
                            _getXAxisLabel(periodData[idx].period, idx),
                            style: TextStyle(
                              fontSize: isTablet ? 8.sp : 7.sp,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isTablet ? 40 : 50,
                      getTitlesWidget: (value, meta) => Text(
                        _formatCurrencyShort(value),
                        style: TextStyle(fontSize: isTablet ? 8.sp : 7.sp, color: Colors.grey),
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
                lineBarsData: [
                  LineChartBarData(
                    spots: periodData
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.gst))
                        .toList(),
                    isCurved: true,
                    color: Colors.orange.shade700,
                    barWidth: isTablet ? 3 : 2, // Thinner lines on mobile
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                minY: 0,
                maxY:
                    periodData
                        .map((e) => e.gst)
                        .reduce((a, b) => a > b ? a : b) *
                    1.2,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots
                        .map(
                          (s) => LineTooltipItem(
                            _formatCurrency(s.y),
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),

        // Discount Area Chart
        _chartCard(
          title: 'Discount Trend',
          icon: Icons.local_offer_rounded,
          enableHorizontalScroll: needsHorizontalScroll,
          child: SizedBox(
            height: chartHeight,
            width: chartWidth,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isTablet ? 28 : 35,
                      interval: _calculateXAxisInterval(periodData.length, isTablet),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= periodData.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Text(
                            _getXAxisLabel(periodData[idx].period, idx),
                            style: TextStyle(
                              fontSize: isTablet ? 8.sp : 7.sp,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isTablet ? 40 : 50,
                      getTitlesWidget: (value, meta) => Text(
                        _formatCurrencyShort(value),
                        style: TextStyle(fontSize: isTablet ? 8.sp : 7.sp, color: Colors.grey),
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
                lineBarsData: [
                  LineChartBarData(
                    spots: periodData
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.discount))
                        .toList(),
                    isCurved: true,
                    color: Colors.red.shade400,
                    barWidth: isTablet ? 3 : 2, // Thinner lines on mobile
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.red.shade100.withValues(alpha: 0.4),
                    ),
                    dotData: const FlDotData(show: false),
                  ),
                ],
                minY: 0,
                maxY:
                    periodData
                        .map((e) => e.discount)
                        .reduce((a, b) => a > b ? a : b) *
                    1.2,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots
                        .map(
                          (s) => LineTooltipItem(
                            _formatCurrency(s.y),
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------- X-Axis Label Helper ----------
  String _getXAxisLabel(String period, int index) {
    // For Year view - API returns "YYYY-MM" format, show month names
    if (_dateViewMode == DateViewMode.year) {
      const monthNames = [
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
      try {
        // API returns format like "2024-01"
        final parts = period.split('-');
        if (parts.length == 2) {
          final month = int.parse(parts[1]);
          if (month >= 1 && month <= 12) {
            return monthNames[month - 1];
          }
        }
        // Fallback to DateTime parsing
        final date = DateTime.parse(period);
        return monthNames[date.month - 1];
      } catch (e) {
        return period;
      }
    }

    // For Week view - API returns daily dates, show day names
    if (_dateViewMode == DateViewMode.week) {
      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      try {
        final date = DateTime.parse(period);
        final dayOfWeek = date.weekday; // 1 = Monday, 7 = Sunday
        return dayNames[dayOfWeek - 1];
      } catch (e) {
        return period;
      }
    }

    // For Day view - API returns daily dates, show day names (since hourly data not available)
    if (_dateViewMode == DateViewMode.day) {
      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      try {
        final date = DateTime.parse(period);
        final dayOfWeek = date.weekday; // 1 = Monday, 7 = Sunday
        return dayNames[dayOfWeek - 1];
      } catch (e) {
        return period;
      }
    }

    // For Month view - API returns "Week X" format, show as-is
    if (_dateViewMode == DateViewMode.month) {
      // API returns format like "Week 1", "Week 2", etc.
      return period;
    }

    // Default fallback
    return period;
  }

  Widget _chartCard({
    required String title,
    required IconData icon,
    required Widget child,
    bool enableHorizontalScroll = false,
  }) {
    final chartContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: SiporaTheme.greenDark, size: 18.w),
            SizedBox(width: 6.w),
            Text(
              title,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        child,
      ],
    );

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: enableHorizontalScroll
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width * 1.3, // Allow horizontal scrolling
                ),
                child: chartContent,
              ),
            )
          : chartContent,
    );
  }

  String _formatCurrencyShort(double value) {
    if (value >= 100000) return '₹${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '₹${(value / 1000).toStringAsFixed(1)}K';
    return '₹${value.toStringAsFixed(0)}';
  }

  // Calculate X-axis interval to prevent overcrowding on mobile
  double _calculateXAxisInterval(int dataPointCount, bool isTablet) {
    if (isTablet) {
      // Tablet can show more labels
      if (dataPointCount <= 7) return 1;
      if (dataPointCount <= 14) return 2;
      if (dataPointCount <= 30) return 4;
      return 6;
    } else {
      // Mobile needs fewer labels to prevent overcrowding
      if (dataPointCount <= 5) return 1;
      if (dataPointCount <= 10) return 2;
      if (dataPointCount <= 20) return 3;
      if (dataPointCount <= 30) return 5;
      return 7;
    }
  }

  // Build period analytics from product breakdowns
  List<PeriodAnalyticsPoint> _buildPeriodAnalytics() {
    if (_data == null) return [];

    final periodMap = <String, PeriodAnalyticsPoint>{};

    for (final product in _data!.products) {
      for (final breakdown in product.breakdown) {
        final period = breakdown.period;
        if (periodMap.containsKey(period)) {
          final existing = periodMap[period]!;
          periodMap[period] = PeriodAnalyticsPoint(
            period: period,
            quantity: existing.quantity + breakdown.quantity,
            unitAmount: existing.unitAmount + breakdown.unitAmount,
            unitCgst: existing.unitCgst + breakdown.unitCgst,
            unitSgst: existing.unitSgst + breakdown.unitSgst,
            unitGstRate: existing.unitGstRate + breakdown.unitGstRate,
            totalAmount: existing.totalAmount + breakdown.totalAmount,
            totalCgst: existing.totalCgst + breakdown.totalCgst,
            totalSgst: existing.totalSgst + breakdown.totalSgst,
            itemTotal: existing.itemTotal + breakdown.itemTotal,
            discount: existing.discount + breakdown.discount,
          );
        } else {
          periodMap[period] = breakdown;
        }
      }
    }

    return periodMap.values.toList()
      ..sort((a, b) => a.period.compareTo(b.period));
  }

  // ---------- Product Table ----------
  Widget _buildProductTable(bool isTablet) {
    final products = _getPaginated();
    final total = _filteredProducts.length;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: Icon(Icons.search, size: 18.w),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 8.h,
                    ),
                    isDense: true,
                  ),
                  style: TextStyle(fontSize: 12.sp),
                  onChanged: (v) {
                    setState(() {
                      _searchQuery = v;
                      _applyFiltersAndSort();
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // Table - FIXED: Proper horizontal scrolling with constraints
          if (products.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Text(
                  'No products match',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 24.w,
                ),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.resolveWith(
                    (states) => Colors.grey.shade50,
                  ),
                  columnSpacing: 8.w,
                  horizontalMargin: 8.w,
                  columns: [
                    DataColumn(
                      label: _sortableHeader('Product', 'product_name'),
                    ),
                    DataColumn(
                      label: _sortableHeader('Qty', 'quantity', numeric: true),
                    ),
                    DataColumn(
                      label: _sortableHeader(
                        'Unit',
                        'unit_amount',
                        numeric: true,
                      ),
                    ),
                    DataColumn(
                      label: _sortableHeader('GST', 'gst', numeric: true),
                    ),
                    DataColumn(
                      label: _sortableHeader(
                        'Total',
                        'total_amount',
                        numeric: true,
                      ),
                    ),
                    DataColumn(
                      label: _sortableHeader(
                        'Item Total',
                        'item_total',
                        numeric: true,
                      ),
                    ),
                    DataColumn(
                      label: _sortableHeader(
                        'Disc.',
                        'discount',
                        numeric: true,
                      ),
                    ),
                  ],
                  rows: products.map((p) {
                    return DataRow(
                      cells: [
                        DataCell(
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 120.w),
                            child: Text(
                              p.productName,
                              style: TextStyle(fontSize: 11.sp),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          onTap: () => _showProductDetail(p),
                        ),
                        DataCell(
                          Text(
                            _formatNumber(p.summary.quantity),
                            style: TextStyle(fontSize: 11.sp),
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatCurrency(p.summary.unitAmount),
                            style: TextStyle(fontSize: 11.sp),
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatCurrency(p.summary.gst),
                            style: TextStyle(fontSize: 11.sp),
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatCurrency(p.summary.totalAmount),
                            style: TextStyle(fontSize: 11.sp),
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatCurrency(p.summary.itemTotal),
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: SiporaTheme.greenDark,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatCurrency(p.summary.discount),
                            style: TextStyle(fontSize: 11.sp),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          SizedBox(height: 8.h),

          // Pagination
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$total items',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
              ),
              Row(
                children: [
                  DropdownButton<int>(
                    value: _pageSize,
                    items: _pageSizeOptions.map((size) {
                      return DropdownMenuItem(
                        value: size,
                        child: Text('$size'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _pageSize = val;
                          _currentPage = 1;
                        });
                      }
                    },
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    icon: Icon(Icons.chevron_left, size: 20.w),
                    onPressed: _currentPage > 1
                        ? () => setState(() => _currentPage--)
                        : null,
                    padding: EdgeInsets.zero,
                  ),
                  Text(
                    '$_currentPage / $_totalPages',
                    style: TextStyle(fontSize: 11.sp),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right, size: 20.w),
                    onPressed: _currentPage < _totalPages
                        ? () => setState(() => _currentPage++)
                        : null,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sortableHeader(String label, String key, {bool numeric = false}) {
    final isActive = _sortKey == key;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_sortKey == key) {
            _sortAscending = !_sortAscending;
          } else {
            _sortKey = key;
            _sortAscending = numeric ? false : true;
          }
          _applyFiltersAndSort();
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isActive)
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14.sp,
            ),
        ],
      ),
    );
  }

  // ---------- Product Detail Bottom Sheet ----------
  void _showProductDetail(ProductSummary product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    product.productName,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'ID: ${product.productId}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // Summary grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8.w,
                    mainAxisSpacing: 8.h,
                    childAspectRatio: 2,
                    children: [
                      _detailItem(
                        'Quantity',
                        _formatNumber(product.summary.quantity),
                      ),
                      _detailItem(
                        'Revenue',
                        _formatCurrency(product.summary.itemTotal),
                      ),
                      _detailItem('GST', _formatCurrency(product.summary.gst)),
                      _detailItem(
                        'Discount',
                        _formatCurrency(product.summary.discount),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Period Breakdown',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: product.breakdown.length,
                      itemBuilder: (_, i) {
                        final b = product.breakdown[i];
                        return ListTile(
                          dense: true,
                          title: Text(
                            b.period,
                            style: TextStyle(fontSize: 12.sp),
                          ),
                          trailing: Text(
                            'Qty: ${b.quantity}  ₹${b.itemTotal.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 11.sp),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailItem(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
