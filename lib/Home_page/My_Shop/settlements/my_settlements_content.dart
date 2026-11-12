import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../theme/sipora_theme.dart';
import '../../../../config/api_config.dart';
import '../../../../services/storage_service.dart';
import '../widgets/universal_filter.dart';

// ─── Model ────────────────────────────────────────────────────────────────
class FranchiseSettlement {
  final int settlementId;
  final String franchiseId;
  final double platform;
  final double cash;
  final double qrId;
  final double total;
  final double qrTableDifference;
  final double qrIdDifference;
  final String status;
  final double softwarePlatformCharges;
  final DateTime windowStart;
  final DateTime windowEnd;
  final DateTime? settlementTime;
  final double remainingAmount;
  final dynamic razorpayTransferId;

  FranchiseSettlement({
    required this.settlementId,
    required this.franchiseId,
    required this.platform,
    required this.cash,
    required this.qrId,
    required this.total,
    required this.qrTableDifference,
    required this.qrIdDifference,
    required this.status,
    required this.softwarePlatformCharges,
    required this.windowStart,
    required this.windowEnd,
    this.settlementTime,
    required this.remainingAmount,
    this.razorpayTransferId,
  });

  factory FranchiseSettlement.fromJson(Map<String, dynamic> json) {
    return FranchiseSettlement(
      settlementId: (json['settlement_id'] ?? 0).toInt(),
      franchiseId: json['franchise_id_or_warehouse_id']?.toString() ?? '',
      platform: (json['platform'] ?? 0).toDouble(),
      cash: (json['cash'] ?? 0).toDouble(),
      qrId: (json['qr_id'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      qrTableDifference: (json['qr_table_difference'] ?? 0).toDouble(),
      qrIdDifference: (json['qr_id_difference'] ?? 0).toDouble(),
      status: json['status']?.toString().toLowerCase() ?? 'pending',
      softwarePlatformCharges: (json['software_platform_charges'] ?? 0)
          .toDouble(),
      windowStart:
          DateTime.tryParse(json['window_start']?.toString() ?? '') ??
          DateTime.now(),
      windowEnd:
          DateTime.tryParse(json['window_end']?.toString() ?? '') ??
          DateTime.now(),
      settlementTime: DateTime.tryParse(
        json['settlement_time']?.toString() ?? '',
      ),
      remainingAmount: (json['remaining_amount'] ?? 0).toDouble(),
      razorpayTransferId: json['razorpay_transfer_id'],
    );
  }
}

// ─── Status Enum ──────────────────────────────────────────────────────────
enum SettlementStatusFilter { all, pending, done, failed, inProcess }

extension SettlementStatusFilterExt on SettlementStatusFilter {
  String get label {
    switch (this) {
      case SettlementStatusFilter.all:
        return 'All';
      case SettlementStatusFilter.pending:
        return 'Pending';
      case SettlementStatusFilter.done:
        return 'Done';
      case SettlementStatusFilter.failed:
        return 'Failed';
      case SettlementStatusFilter.inProcess:
        return 'In-Process';
    }
  }

  String get apiValue {
    switch (this) {
      case SettlementStatusFilter.all:
        return 'all';
      case SettlementStatusFilter.pending:
        return 'pending';
      case SettlementStatusFilter.done:
        return 'done';
      case SettlementStatusFilter.failed:
        return 'failed';
      case SettlementStatusFilter.inProcess:
        return 'in-process';
    }
  }

  Color get color {
    switch (this) {
      case SettlementStatusFilter.all:
        return SiporaTheme.greenDark;
      case SettlementStatusFilter.pending:
        return const Color(0xFFF59E0B);
      case SettlementStatusFilter.done:
        return const Color(0xFF10B981);
      case SettlementStatusFilter.failed:
        return const Color(0xFFEF4444);
      case SettlementStatusFilter.inProcess:
        return const Color(0xFF6366F1);
    }
  }

  IconData get icon {
    switch (this) {
      case SettlementStatusFilter.all:
        return Icons.grid_view_rounded;
      case SettlementStatusFilter.pending:
        return Icons.hourglass_empty_rounded;
      case SettlementStatusFilter.done:
        return Icons.check_circle_rounded;
      case SettlementStatusFilter.failed:
        return Icons.cancel_rounded;
      case SettlementStatusFilter.inProcess:
        return Icons.sync_rounded;
    }
  }
}

// ─── Filter State ──────────────────────────────────────────────────────
class FilterState {
  final DateTime? startDate;
  final DateTime? endDate;
  final Set<SettlementStatusFilter> statuses;
  final double? minAmount;
  final double? maxAmount;
  final String? searchQuery;
  final Set<String> paymentModes;
  final String sortBy;

  FilterState({
    this.startDate,
    this.endDate,
    Set<SettlementStatusFilter>? statuses,
    this.minAmount,
    this.maxAmount,
    this.searchQuery,
    Set<String>? paymentModes,
    this.sortBy = 'date_desc',
  }) : statuses = statuses ?? {SettlementStatusFilter.all},
       paymentModes = paymentModes ?? {'platform', 'cash', 'qr'};

  FilterState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    Set<SettlementStatusFilter>? statuses,
    double? minAmount,
    double? maxAmount,
    String? searchQuery,
    Set<String>? paymentModes,
    String? sortBy,
  }) {
    return FilterState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      statuses: statuses ?? this.statuses,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      searchQuery: searchQuery ?? this.searchQuery,
      paymentModes: paymentModes ?? this.paymentModes,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  FilterState copy() => FilterState(
    startDate: startDate,
    endDate: endDate,
    statuses: Set.from(statuses),
    minAmount: minAmount,
    maxAmount: maxAmount,
    searchQuery: searchQuery,
    paymentModes: Set.from(paymentModes),
    sortBy: sortBy,
  );
}

// ─── Main Content Widget ────────────────────────────────────────────────────
class MySettlementsContent extends StatefulWidget {
  final DateViewMode initialDateViewMode;
  final DateTime initialSelectedDate;
  final DateTime? initialWeekStart;
  final DateTime? initialWeekEnd;
  final Function(DateViewMode mode, DateTime date)? onFilterChanged;

  MySettlementsContent({
    super.key,
    this.initialDateViewMode = DateViewMode.month,
    DateTime? initialSelectedDate,
    this.initialWeekStart,
    this.initialWeekEnd,
    this.onFilterChanged,
  }) : initialSelectedDate = initialSelectedDate ?? DateTime.now();

  @override
  State<MySettlementsContent> createState() => _MySettlementsContentState();
}

class _MySettlementsContentState extends State<MySettlementsContent> {
  // Data
  List<FranchiseSettlement> _allSettlements = [];
  List<FranchiseSettlement> _filteredSettlements = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = true;
  String? _errorMessage;

  // Filter state from parent
  DateViewMode _dateViewMode = DateViewMode.month;
  DateTime _selectedDate = DateTime.now();
  DateTime? _weekStart;
  DateTime? _weekEnd;

  // Internal filter state
  FilterState _filters = FilterState();

  // Status filter state
  SettlementStatusFilter? _selectedStatusFilter;

  // For expandable cards
  int? _expandedCardId;

  // ─── Helpers ──────────────────────────────────────────────────────────────
  double _d(dynamic v) => (v ?? 0) is num ? (v as num).toDouble() : 0.0;
  String _formatCurrency(double v) => '₹${NumberFormat('#,##0.00').format(v)}';
  String _formatDate(DateTime dt) => DateFormat('dd MMM yyyy').format(dt);
  String _formatDateTime(DateTime dt) =>
      DateFormat('dd MMM, h:mm a').format(dt);

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'done':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'failed':
        return const Color(0xFFEF4444);
      case 'in-process':
        return const Color(0xFF6366F1);
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'done':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.hourglass_empty_rounded;
      case 'failed':
        return Icons.cancel_rounded;
      case 'in-process':
        return Icons.sync_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  // ─── API Call ─────────────────────────────────────────────────────────────
  Future<void> _fetchSettlements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await StorageService.getToken();
      final prefs = await SharedPreferences.getInstance();
      final franchiseId = prefs.getString('selected_franchise_id');

      if (token == null || franchiseId == null || franchiseId.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'No franchise selected. Please go back and select a shop.';
        });
        return;
      }

      final params = <String, String>{
        'franchise_id': franchiseId,
        'status': _filters.statuses.contains(SettlementStatusFilter.all)
            ? 'all'
            : _filters.statuses.map((e) => e.apiValue).join(','),
      };

      // Use parent filter parameters for date range
      DateTime? startDate;
      DateTime? endDate;

      switch (_dateViewMode) {
        case DateViewMode.day:
          startDate = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
          );
          endDate = startDate;
          break;
        case DateViewMode.week:
          startDate = _weekStart;
          endDate = _weekEnd;
          break;
        case DateViewMode.month:
          startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
          endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
          break;
        case DateViewMode.year:
          startDate = DateTime(_selectedDate.year, 1, 1);
          endDate = DateTime(_selectedDate.year, 12, 31);
          break;
      }

      if (startDate != null) {
        params['start_date'] = DateFormat('yyyy-MM-dd').format(startDate);
      }
      if (endDate != null) {
        params['end_date'] = DateFormat('yyyy-MM-dd').format(endDate);
      }
      if (_filters.minAmount != null)
        params['min_amount'] = _filters.minAmount!.toString();
      if (_filters.maxAmount != null)
        params['max_amount'] = _filters.maxAmount!.toString();
      if (_filters.searchQuery != null && _filters.searchQuery!.isNotEmpty) {
        params['search'] = _filters.searchQuery!;
      }
      if (_filters.sortBy != 'date_desc') {
        params['sort_by'] = _filters.sortBy;
      }

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/dashboard/franchise-settlement-dashboard',
      ).replace(queryParameters: params);

      final response = await http
          .get(
            uri,
            headers: {
              'accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final rawList = (data['settlements'] as List<dynamic>?) ?? [];
          final settlements = rawList
              .map((e) => FranchiseSettlement.fromJson(e))
              .toList();

          setState(() {
            _allSettlements = settlements;
            _summary = (data['summary'] as Map<String, dynamic>?) ?? {};
            _isLoading = false;
          });
          _applyFiltersAndSort();
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = data['detail'] ?? 'Failed to load settlements';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Server error ${response.statusCode}. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Connection error: $e';
      });
    }
  }

  // ─── Local Filter & Sort ──────────────────────────────────────────────────
  void _applyFiltersAndSort() {
    List<FranchiseSettlement> list = List.from(_allSettlements);

    // Apply status filter from chips
    if (_selectedStatusFilter != null &&
        _selectedStatusFilter != SettlementStatusFilter.all) {
      list = list.where((s) {
        final status = s.status.toLowerCase();
        switch (_selectedStatusFilter) {
          case SettlementStatusFilter.pending:
            return status == 'pending' ||
                status == 'proceed' ||
                status == 'in-process' ||
                status == 'processing';
          case SettlementStatusFilter.done:
            return status == 'done' || status == 'completed';
          case SettlementStatusFilter.failed:
            return status == 'failed';
          case SettlementStatusFilter.inProcess:
            return status == 'in-process' || status == 'processing';
          default:
            return true;
        }
      }).toList();
    }

    if (_filters.minAmount != null) {
      list = list.where((s) => s.total >= _filters.minAmount!).toList();
    }
    if (_filters.maxAmount != null) {
      list = list.where((s) => s.total <= _filters.maxAmount!).toList();
    }

    if (_filters.searchQuery != null && _filters.searchQuery!.isNotEmpty) {
      final q = _filters.searchQuery!.toLowerCase();
      list = list.where((s) => s.settlementId.toString().contains(q)).toList();
    }

    if (_filters.paymentModes.isNotEmpty) {
      list = list.where((s) {
        bool hasPlatform =
            _filters.paymentModes.contains('platform') && s.platform > 0;
        bool hasCash = _filters.paymentModes.contains('cash') && s.cash > 0;
        bool hasQr = _filters.paymentModes.contains('qr') && s.qrId > 0;
        return hasPlatform || hasCash || hasQr;
      }).toList();
    }

    switch (_filters.sortBy) {
      case 'date_asc':
        list.sort((a, b) => a.windowStart.compareTo(b.windowStart));
        break;
      case 'amount_desc':
        list.sort((a, b) => b.total.compareTo(a.total));
        break;
      case 'amount_asc':
        list.sort((a, b) => a.total.compareTo(b.total));
        break;
      default:
        list.sort((a, b) => b.windowStart.compareTo(a.windowStart));
    }

    setState(() {
      _filteredSettlements = list;
    });
  }

  @override
  void initState() {
    super.initState();
    _dateViewMode = widget.initialDateViewMode;
    _selectedDate = widget.initialSelectedDate;
    _weekStart = widget.initialWeekStart;
    _weekEnd = widget.initialWeekEnd;
    _fetchSettlements();
  }

  @override
  void didUpdateWidget(MySettlementsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDateViewMode != widget.initialDateViewMode ||
        oldWidget.initialSelectedDate != widget.initialSelectedDate ||
        oldWidget.initialWeekStart != widget.initialWeekStart ||
        oldWidget.initialWeekEnd != widget.initialWeekEnd) {
      _dateViewMode = widget.initialDateViewMode;
      _selectedDate = widget.initialSelectedDate;
      _weekStart = widget.initialWeekStart;
      _weekEnd = widget.initialWeekEnd;
      _fetchSettlements();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    return Column(children: [Expanded(child: _buildBody())],
    );
  }


  // ─── Body ──────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_isLoading) return _buildShimmerSkeleton();
    if (_errorMessage != null) return _buildError();

    return RefreshIndicator(
      color: SiporaTheme.greenDark,
      onRefresh: _fetchSettlements,
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        children: [
          _buildHeroBanner(),
          SizedBox(height: 12.h),
          _buildStatCards(),
          SizedBox(height: 16.h),
          _buildBreakdownChart(),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Settlement History',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
              ),
              Text(
                '${_filteredSettlements.length} records',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: context.siporaTheme.textMuted,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          if (_filteredSettlements.isEmpty)
            _buildEmptyState()
          else
            ..._filteredSettlements.map((s) => _buildSettlementCard(s)),
        ],
      ),
    );
  }

  // ─── Hero Banner (Animated) ──────────────────────────────────────────────
  Widget _buildHeroBanner() {
    final totalPending = _d(_summary['total_pending']);
    final upcoming = _summary['upcoming_settlement_date']?.toString();
    final totalSettled = _d(_summary['total_settled']);
    final totalRemaining = _d(_summary['total_remaining']);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: totalPending),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (_, value, __) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [SiporaTheme.greenDark, const Color(0xFF0F766E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: SiporaTheme.greenDark.withOpacity(0.35),
                blurRadius: 16.r,
                offset: Offset(0, 6.h),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        totalPending > 0 ? 'Upcoming Settlement' : 'No Pending',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 44.w,
                      height: 44.w,
                      child: CircularProgressIndicator(
                        value: totalPending > 0
                            ? totalSettled / (totalSettled + totalPending)
                            : 1,
                        strokeWidth: 4.w,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  _formatCurrency(value),
                  style: TextStyle(
                    fontSize: 30.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                if (upcoming != null && totalPending > 0)
                  Text(
                    'to be settled by $upcoming (~2 days after window close)',
                    style: TextStyle(fontSize: 11.sp, color: Colors.white70),
                  ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Settled',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            _formatCurrency(totalSettled),
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (totalRemaining > 0)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Remaining',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              _formatCurrency(totalRemaining),
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFFBBF24),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Stat Cards with Sparklines ──────────────────────────────────────────
  Widget _buildStatCards() {
    final theme = context.siporaTheme;

    // Calculate status amounts from settlements data
    double settledAmount = 0;
    double pendingAmount = 0;
    double failedAmount = 0;
    double inProcessAmount = 0;

    for (final settlement in _allSettlements) {
      final status = settlement.status.toLowerCase();
      if (status == 'done' || status == 'completed') {
        settledAmount += settlement.total;
      } else if (status == 'pending' ||
          status == 'proceed' ||
          status == 'in-process' ||
          status == 'processing') {
        pendingAmount += settlement.total;
      } else if (status == 'failed') {
        failedAmount += settlement.total;
      } else if (status == 'in-process') {
        inProcessAmount += settlement.total;
      }
    }

    final categories = [
      {
        'label': 'Settled',
        'value': settledAmount,
        'color': const Color(0xFF10B981),
        'icon': Icons.check_circle_rounded,
      },
      {
        'label': 'Pending',
        'value': pendingAmount,
        'color': const Color(0xFFF59E0B),
        'icon': Icons.hourglass_empty_rounded,
      },
      {
        'label': 'Failed',
        'value': failedAmount,
        'color': const Color(0xFFEF4444),
        'icon': Icons.cancel_rounded,
      },
      {
        'label': 'In-Process',
        'value': inProcessAmount,
        'color': const Color(0xFF6366F1),
        'icon': Icons.sync_rounded,
      },
    ];

    return Column(
      children: [
        // First row: Settled and Pending
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                categories[0]['label'] as String,
                categories[0]['value'] as double,
                categories[0]['color'] as Color,
                categories[0]['icon'] as IconData,
                theme,
                SettlementStatusFilter.done,
                rightMargin: true,
              ),
            ),
            Expanded(
              child: _buildStatCard(
                categories[1]['label'] as String,
                categories[1]['value'] as double,
                categories[1]['color'] as Color,
                categories[1]['icon'] as IconData,
                theme,
                SettlementStatusFilter.pending,
                rightMargin: false,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        // Second row: Failed and In-Process
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                categories[2]['label'] as String,
                categories[2]['value'] as double,
                categories[2]['color'] as Color,
                categories[2]['icon'] as IconData,
                theme,
                SettlementStatusFilter.failed,
                rightMargin: true,
              ),
            ),
            Expanded(
              child: _buildStatCard(
                categories[3]['label'] as String,
                categories[3]['value'] as double,
                categories[3]['color'] as Color,
                categories[3]['icon'] as IconData,
                theme,
                SettlementStatusFilter.inProcess,
                rightMargin: false,
              ),
            ),
          ],
        ),
        // Clear filter button
        if (_selectedStatusFilter != null)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedStatusFilter = null;
                  });
                  _applyFiltersAndSort();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: SiporaTheme.greenDark.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: SiporaTheme.greenDark,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.clear,
                        size: 14.w,
                        color: SiporaTheme.greenDark,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Clear Filter',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: SiporaTheme.greenDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    double amount,
    Color color,
    IconData icon,
    dynamic theme,
    SettlementStatusFilter statusFilter, {
    required bool rightMargin,
  }) {
    final isSelected = _selectedStatusFilter == statusFilter;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedStatusFilter == statusFilter) {
            _selectedStatusFilter = null; // Deselect if already selected
          } else {
            _selectedStatusFilter = statusFilter;
          }
        });
        _applyFiltersAndSort();
      },
      child: Container(
        margin: EdgeInsets.only(right: rightMargin ? 8.w : 0),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? color : theme.border,
            width: isSelected ? 1.5 : 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8.r,
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
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(icon, color: color, size: 14.w),
                ),
                SizedBox(
                  width: 30.w,
                  height: 20.h,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            5,
                            (j) => FlSpot(
                              j.toDouble(),
                              (j % 2 == 0 ? 2 : 1) + j * 0.5,
                            ),
                          ),
                          isCurved: true,
                          color: color,
                          barWidth: 1.5,
                          dotData: FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              amount >= 1000
                  ? '₹${(amount / 1000).toStringAsFixed(1)}k'
                  : _formatCurrency(amount),
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.sp,
                color: theme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Status Breakdown (Donut Chart) ──────────────────────────────────────
  Widget _buildBreakdownChart() {
    final theme = context.siporaTheme;

    // Calculate status amounts
    double settledAmount = 0;
    double pendingAmount = 0;
    double failedAmount = 0;
    double inProcessAmount = 0;

    for (final settlement in _allSettlements) {
      final status = settlement.status.toLowerCase();
      if (status == 'done' || status == 'completed') {
        settledAmount += settlement.total;
      } else if (status == 'pending' ||
          status == 'proceed' ||
          status == 'in-process' ||
          status == 'processing') {
        pendingAmount += settlement.total;
      } else if (status == 'failed') {
        failedAmount += settlement.total;
      } else if (status == 'in-process') {
        inProcessAmount += settlement.total;
      }
    }

    final total =
        settledAmount + pendingAmount + failedAmount + inProcessAmount;
    final List<PieChartSectionData> sections = [];

    if (settledAmount > 0) {
      sections.add(
        PieChartSectionData(
          value: settledAmount,
          color: const Color(0xFF10B981),
          title: 'Settled',
          radius: 24.r,
          titleStyle: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          badgeWidget: Text(
            '${(settledAmount / total * 100).toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 8.sp, color: Colors.white),
          ),
        ),
      );
    }
    if (pendingAmount > 0) {
      sections.add(
        PieChartSectionData(
          value: pendingAmount,
          color: const Color(0xFFF59E0B),
          title: 'Pending',
          radius: 24.r,
          titleStyle: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          badgeWidget: Text(
            '${(pendingAmount / total * 100).toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 8.sp, color: Colors.white),
          ),
        ),
      );
    }
    if (failedAmount > 0) {
      sections.add(
        PieChartSectionData(
          value: failedAmount,
          color: const Color(0xFFEF4444),
          title: 'Failed',
          radius: 24.r,
          titleStyle: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          badgeWidget: Text(
            '${(failedAmount / total * 100).toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 8.sp, color: Colors.white),
          ),
        ),
      );
    }
    if (inProcessAmount > 0) {
      sections.add(
        PieChartSectionData(
          value: inProcessAmount,
          color: const Color(0xFF6366F1),
          title: 'In-Process',
          radius: 24.r,
          titleStyle: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          badgeWidget: Text(
            '${(inProcessAmount / total * 100).toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 8.sp, color: Colors.white),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: theme.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Breakdown',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12.h),
          if (sections.isEmpty)
            Text('No status data', style: TextStyle(color: theme.textMuted))
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 120.h,
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        sectionsSpace: 2.r,
                        centerSpaceRadius: 30.r,
                        startDegreeOffset: -90,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (settledAmount > 0)
                        _legendItem(
                          'Settled',
                          const Color(0xFF10B981),
                          settledAmount,
                        ),
                      if (pendingAmount > 0)
                        _legendItem(
                          'Pending',
                          const Color(0xFFF59E0B),
                          pendingAmount,
                        ),
                      if (failedAmount > 0)
                        _legendItem(
                          'Failed',
                          const Color(0xFFEF4444),
                          failedAmount,
                        ),
                      if (inProcessAmount > 0)
                        _legendItem(
                          'In-Process',
                          const Color(0xFF6366F1),
                          inProcessAmount,
                        ),
                      SizedBox(height: 8.h),
                      Divider(),
                      _legendItem(
                        'Grand Total',
                        Colors.black,
                        total,
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _legendItem(
    String label,
    Color color,
    double value, {
    bool bold = false,
  }) {
    final theme = context.siporaTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            _formatCurrency(value),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Settlement Card (Expandable) ────────────────────────────────────────
  Widget _buildSettlementCard(FranchiseSettlement s) {
    final theme = context.siporaTheme;
    final isExpanded = _expandedCardId == s.settlementId;
    final statusColor = _statusColor(s.status);

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: theme.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(height: 3.h, color: statusColor),
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 10.h),
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
                          'Settlement #${s.settlementId}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '${_formatDate(s.windowStart)}  →  ${_formatDate(s.windowEnd)}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: theme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _statusIcon(s.status),
                            color: statusColor,
                            size: 12.w,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            s.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    _miniStat('Platform', s.platform),
                    _divider(),
                    _miniStat('Cash', s.cash),
                    _divider(),
                    _miniStat('QR/UPI', s.qrId),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => setState(
                        () => _expandedCardId = isExpanded
                            ? null
                            : s.settlementId,
                      ),
                      child: Row(
                        children: [
                          Text(
                            isExpanded ? 'Hide details' : 'View details',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: SiporaTheme.greenDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(
                            isExpanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: SiporaTheme.greenDark,
                            size: 18.w,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatCurrency(s.total),
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: SiporaTheme.greenDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: Container(),
            secondChild: Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(height: 1.h),
                  SizedBox(height: 8.h),
                  _detailRow('QR Table Difference', s.qrTableDifference),
                  _detailRow('QR ID Difference', s.qrIdDifference),
                  _detailRow('Software Charges', s.softwarePlatformCharges),
                  if (s.remainingAmount > 0)
                    _detailRow(
                      'Remaining Amount',
                      s.remainingAmount,
                      color: const Color(0xFFF59E0B),
                    ),
                  if (s.settlementTime != null)
                    _detailRow(
                      'Settled at',
                      s.settlementTime!,
                      formatDate: true,
                    ),
                  if (s.status == 'in-process')
                    Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: LinearProgressIndicator(
                        value: 0.6,
                        backgroundColor: Colors.grey.shade200,
                        color: statusColor,
                        minHeight: 6.h,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                ],
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, double value) {
    final theme = context.siporaTheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            _formatCurrency(value),
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, color: theme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    final theme = context.siporaTheme;
    return Container(
      width: 0.5,
      height: 28.h,
      color: theme.border,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
    );
  }

  Widget _detailRow(
    String label,
    dynamic value, {
    bool formatDate = false,
    Color? color,
  }) {
    final theme = context.siporaTheme;
    final display = formatDate
        ? _formatDateTime(value as DateTime)
        : _formatCurrency(value as double);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: theme.textMuted),
          ),
          Text(
            display,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: color ?? theme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Loading Skeleton (Shimmer) ──────────────────────────────────────────
  Widget _buildShimmerSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          Container(
            height: 160.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: List.generate(
              4,
              (i) => Expanded(
                child: Container(
                  height: 72.h,
                  margin: EdgeInsets.only(right: i < 3 ? 8.w : 0),
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          ...List.generate(
            3,
            (i) => Container(
              height: 130.h,
              margin: EdgeInsets.only(bottom: 10.h),
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Error ──────────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 56.w),
            SizedBox(height: 16.h),
            Text(
              _errorMessage ?? 'Something went wrong',
              style: TextStyle(fontSize: 13.sp, color: Colors.red.shade400),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            ElevatedButton.icon(
              onPressed: _fetchSettlements,
              icon: Icon(Icons.refresh_rounded),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SiporaTheme.greenDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Empty ──────────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    final theme = context.siporaTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 40.h),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.payments_outlined, color: theme.textMuted, size: 56.w),
            SizedBox(height: 12.h),
            Text(
              'No Settlements Found',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6.h),
            Text(
              'Try adjusting your filters.',
              style: TextStyle(fontSize: 12.sp, color: theme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter Bottom Sheet Widget ──────────────────────────────────────────
class FilterBottomSheet extends StatefulWidget {
  final FilterState currentFilters;
  final Function(FilterState) onApply;
  const FilterBottomSheet({
    super.key,
    required this.currentFilters,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late FilterState _filters;
  String _selectedPreset = 'Custom';

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters.copy();
    _detectPreset();
  }

  void _detectPreset() {
    if (_filters.startDate == null && _filters.endDate == null) {
      _selectedPreset = 'All Time';
    } else {
      _selectedPreset = 'Custom';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Filters',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8.h),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date Range',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 8.w,
                    children:
                        [
                          'All Time',
                          'Today',
                          'This Week',
                          'This Month',
                          'Last 30 Days',
                          'Custom',
                        ].map((preset) {
                          return FilterChip(
                            label: Text(
                              preset,
                              style: TextStyle(fontSize: 11.sp),
                            ),
                            selected: _selectedPreset == preset,
                            onSelected: (_) {
                              setState(() {
                                _selectedPreset = preset;
                                switch (preset) {
                                  case 'Today':
                                    final now = DateTime.now();
                                    _filters = _filters.copyWith(
                                      startDate: now,
                                      endDate: now,
                                    );
                                    break;
                                  case 'This Week':
                                    final start = DateTime.now().subtract(
                                      Duration(
                                        days: DateTime.now().weekday - 1,
                                      ),
                                    );
                                    final end = start.add(
                                      const Duration(days: 6),
                                    );
                                    _filters = _filters.copyWith(
                                      startDate: start,
                                      endDate: end,
                                    );
                                    break;
                                  case 'This Month':
                                    final start = DateTime(
                                      DateTime.now().year,
                                      DateTime.now().month,
                                      1,
                                    );
                                    final end = DateTime(
                                      DateTime.now().year,
                                      DateTime.now().month + 1,
                                      0,
                                    );
                                    _filters = _filters.copyWith(
                                      startDate: start,
                                      endDate: end,
                                    );
                                    break;
                                  case 'Last 30 Days':
                                    _filters = _filters.copyWith(
                                      startDate: DateTime.now().subtract(
                                        Duration(days: 30),
                                      ),
                                      endDate: DateTime.now(),
                                    );
                                    break;
                                  case 'All Time':
                                    _filters = _filters.copyWith(
                                      startDate: null,
                                      endDate: null,
                                    );
                                    break;
                                  case 'Custom':
                                    break;
                                }
                              });
                            },
                            selectedColor: SiporaTheme.greenDark,
                            backgroundColor: Colors.white,
                            side: BorderSide(color: theme.border, width: 0.5),
                            labelStyle: TextStyle(
                              color: _selectedPreset == preset
                                  ? Colors.white
                                  : theme.textDark,
                            ),
                          );
                        }).toList(),
                  ),
                  if (_selectedPreset == 'Custom')
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      _filters.startDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null)
                                  setState(
                                    () => _filters = _filters.copyWith(
                                      startDate: date,
                                    ),
                                  );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: 10.h,
                                  horizontal: 12.w,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: theme.border),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  _filters.startDate != null
                                      ? DateFormat(
                                          'dd MMM yyyy',
                                        ).format(_filters.startDate!)
                                      : 'Start Date',
                                  style: TextStyle(fontSize: 12.sp),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      _filters.endDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null)
                                  setState(
                                    () => _filters = _filters.copyWith(
                                      endDate: date,
                                    ),
                                  );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: 10.h,
                                  horizontal: 12.w,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: theme.border),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  _filters.endDate != null
                                      ? DateFormat(
                                          'dd MMM yyyy',
                                        ).format(_filters.endDate!)
                                      : 'End Date',
                                  style: TextStyle(fontSize: 12.sp),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Divider(height: 24.h),
                  Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 8.w,
                    children: SettlementStatusFilter.values.map((status) {
                      final selected = _filters.statuses.contains(status);
                      return FilterChip(
                        label: Text(
                          status.label,
                          style: TextStyle(fontSize: 11.sp),
                        ),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            if (status == SettlementStatusFilter.all) {
                              if (selected)
                                _filters.statuses.clear();
                              else
                                _filters = _filters.copyWith(
                                  statuses: {SettlementStatusFilter.all},
                                );
                            } else {
                              _filters = _filters.copyWith(
                                statuses: _filters.statuses
                                  ..remove(SettlementStatusFilter.all),
                              );
                              if (selected)
                                _filters.statuses.remove(status);
                              else
                                _filters.statuses.add(status);
                              if (_filters.statuses.isEmpty) {
                                _filters = _filters.copyWith(
                                  statuses: {SettlementStatusFilter.all},
                                );
                              }
                            }
                          });
                        },
                        selectedColor: status.color,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: selected ? status.color : theme.border,
                          width: 0.5,
                        ),
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : theme.textDark,
                        ),
                      );
                    }).toList(),
                  ),
                  Divider(height: 24.h),
                  Text(
                    'Amount Range',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Min',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 8.h,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => _filters = _filters.copyWith(
                            minAmount: double.tryParse(v),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Max',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 8.h,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => _filters = _filters.copyWith(
                            maxAmount: double.tryParse(v),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 24.h),
                  Text(
                    'Payment Modes',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 8.w,
                    children: ['platform', 'cash', 'qr'].map((mode) {
                      final selected = _filters.paymentModes.contains(mode);
                      return ChoiceChip(
                        label: Text(
                          mode.toUpperCase(),
                          style: TextStyle(fontSize: 11.sp),
                        ),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            if (selected)
                              _filters.paymentModes.remove(mode);
                            else
                              _filters.paymentModes.add(mode);
                          });
                        },
                        selectedColor: SiporaTheme.greenDark,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: selected
                              ? SiporaTheme.greenDark
                              : theme.border,
                        ),
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : theme.textDark,
                        ),
                      );
                    }).toList(),
                  ),
                  Divider(height: 24.h),
                  Text(
                    'Sort By',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Column(
                    children: [
                      _buildRadioTile('Newest First', 'date_desc'),
                      _buildRadioTile('Oldest First', 'date_asc'),
                      _buildRadioTile('Amount (High→Low)', 'amount_desc'),
                      _buildRadioTile('Amount (Low→High)', 'amount_asc'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _filters = FilterState();
                      _selectedPreset = 'All Time';
                    });
                  },
                  child: Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_filters);
                    Navigator.pop(context);
                  },
                  child: Text('Apply'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SiporaTheme.greenDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadioTile(String label, String value) {
    final theme = context.siporaTheme;
    return RadioListTile<String>(
      title: Text(label, style: TextStyle(fontSize: 12.sp)),
      value: value,
      groupValue: _filters.sortBy,
      onChanged: (v) => setState(
        () => _filters = _filters.copyWith(sortBy: v ?? 'date_desc'),
      ),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}
