import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../theme/sipora_theme.dart';
import '../../../../utils/screen_utils.dart';
import '../../../../config/api_config.dart';
import '../../../../services/storage_service.dart';
import '../widgets/shop_dashboard_header.dart';
import '../widgets/shop_bottom_nav.dart';

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
  final Set<String> paymentModes; // "platform", "cash", "qr"
  final String sortBy; // "date_desc", "date_asc", "amount_desc", "amount_asc"

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

  // ── Copy methods ──────────────────────────────────────────────────────
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

  // Required for the copy() call in the bottom sheet
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

// ─── Main Page ────────────────────────────────────────────────────────────
class MySettlementsPage extends StatefulWidget {
  const MySettlementsPage({super.key});
  @override
  State<MySettlementsPage> createState() => _MySettlementsPageState();
}

class _MySettlementsPageState extends State<MySettlementsPage> {
  int _selectedNavIndex = 4;

  // Data
  List<FranchiseSettlement> _allSettlements = [];
  List<FranchiseSettlement> _filteredSettlements = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = true;
  String? _errorMessage;

  // Filter state
  FilterState _filters = FilterState();
  bool _filterSheetVisible = false;

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

      // Build query parameters (support new filters if backend is extended)
      final params = <String, String>{
        'franchise_id': franchiseId,
        'status': _filters.statuses.contains(SettlementStatusFilter.all)
            ? 'all'
            : _filters.statuses.map((e) => e.apiValue).join(','),
      };

      if (_filters.startDate != null) {
        params['start_date'] = DateFormat(
          'yyyy-MM-dd',
        ).format(_filters.startDate!);
      }
      if (_filters.endDate != null) {
        params['end_date'] = DateFormat('yyyy-MM-dd').format(_filters.endDate!);
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

    // Status filter (if not "all")
    if (!_filters.statuses.contains(SettlementStatusFilter.all)) {
      list = list.where((s) {
        return _filters.statuses.any(
          (filter) =>
              s.status.toLowerCase().contains(
                filter.apiValue.replaceAll('-', ''),
              ) ||
              (filter == SettlementStatusFilter.done &&
                  (s.status == 'done' || s.status == 'completed')) ||
              (filter == SettlementStatusFilter.inProcess &&
                  (s.status == 'in-process' || s.status == 'processing')),
        );
      }).toList();
    }

    // Amount range
    if (_filters.minAmount != null) {
      list = list.where((s) => s.total >= _filters.minAmount!).toList();
    }
    if (_filters.maxAmount != null) {
      list = list.where((s) => s.total <= _filters.maxAmount!).toList();
    }

    // Search (settlement ID)
    if (_filters.searchQuery != null && _filters.searchQuery!.isNotEmpty) {
      final q = _filters.searchQuery!.toLowerCase();
      list = list.where((s) => s.settlementId.toString().contains(q)).toList();
    }

    // Payment mode filter (at least one of selected modes is > 0)
    if (_filters.paymentModes.isNotEmpty) {
      list = list.where((s) {
        bool hasPlatform =
            _filters.paymentModes.contains('platform') && s.platform > 0;
        bool hasCash = _filters.paymentModes.contains('cash') && s.cash > 0;
        bool hasQr = _filters.paymentModes.contains('qr') && s.qrId > 0;
        return hasPlatform || hasCash || hasQr;
      }).toList();
    }

    // Sort
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
      default: // date_desc
        list.sort((a, b) => b.windowStart.compareTo(a.windowStart));
    }

    setState(() {
      _filteredSettlements = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    return Scaffold(
      backgroundColor: theme.cream,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'My Settlements',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                SiporaTheme.greenDark,
                SiporaTheme.greenDark.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list_rounded, color: Colors.white),
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Quick date filter chips
            _buildQuickDateChips(),
            // Search bar + filter button (already in AppBar)
            _buildSearchBar(),
            // Body
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: ShopBottomNav(
        selectedIndex: _selectedNavIndex,
        onItemTapped: _handleNavTap,
      ),
    );
  }

  // ─── Quick Date Chips ─────────────────────────────────────────────────────
  Widget _buildQuickDateChips() {
    final theme = context.siporaTheme;
    final List<Map<String, dynamic>> presets = [
      {'label': 'Today', 'range': (DateTime.now(), DateTime.now())},
      {'label': 'This Week', 'range': _getWeekRange(DateTime.now())},
      {'label': 'This Month', 'range': _getMonthRange(DateTime.now())},
      {
        'label': 'Last 30 Days',
        'range': (DateTime.now().subtract(Duration(days: 30)), DateTime.now()),
      },
    ];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: SizedBox(
        height: 36.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: presets.length,
          separatorBuilder: (_, __) => SizedBox(width: 8.w),
          itemBuilder: (ctx, i) {
            final preset = presets[i];
            final (start, end) = preset['range'] as (DateTime, DateTime);
            final isActive =
                _filters.startDate != null &&
                _filters.endDate != null &&
                _filters.startDate!.isAtSameMomentAs(start) &&
                _filters.endDate!.isAtSameMomentAs(end);
            return FilterChip(
              label: Text(preset['label'], style: TextStyle(fontSize: 11.sp)),
              selected: isActive,
              onSelected: (_) {
                setState(() {
                  _filters = _filters.copyWith(startDate: start, endDate: end);
                });
                _fetchSettlements();
              },
              selectedColor: SiporaTheme.greenDark,
              backgroundColor: Colors.white,
              side: BorderSide(color: theme.border, width: 0.5),
              labelStyle: TextStyle(
                color: isActive ? Colors.white : theme.textDark,
              ),
            );
          },
        ),
      ),
    );
  }

  (DateTime, DateTime) _getWeekRange(DateTime date) {
    final start = date.subtract(Duration(days: date.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return (start, end);
  }

  (DateTime, DateTime) _getMonthRange(DateTime date) {
    final start = DateTime(date.year, date.month, 1);
    final end = DateTime(date.year, date.month + 1, 0);
    return (start, end);
  }

  // ─── Search Bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    final theme = context.siporaTheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by Settlement ID',
                prefixIcon: Icon(Icons.search_rounded, size: 20.w),
                suffixIcon:
                    _filters.searchQuery != null &&
                        _filters.searchQuery!.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, size: 18.w),
                        onPressed: () {
                          setState(() {
                            _filters = _filters.copyWith(searchQuery: null);
                          });
                          _applyFiltersAndSort();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: theme.border, width: 0.5),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 10.h,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _filters = _filters.copyWith(
                    searchQuery: value.trim().isEmpty ? null : value.trim(),
                  );
                });
                _applyFiltersAndSort();
              },
            ),
          ),
          // Filter button is now in AppBar, but we keep this for extra visibility
        ],
      ),
    );
  }

  // ─── Filter Bottom Sheet ──────────────────────────────────────────────────
  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => FilterBottomSheet(
        currentFilters: _filters,
        onApply: (newFilters) {
          setState(() {
            _filters = newFilters;
          });
          _fetchSettlements();
        },
      ),
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
          // Hero Banner (animated)
          _buildHeroBanner(),
          SizedBox(height: 12.h),
          // Stat cards with sparklines
          _buildStatCards(),
          SizedBox(height: 16.h),
          // Payment Breakdown (Donut Chart)
          _buildBreakdownChart(),
          SizedBox(height: 16.h),
          // List header
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
                    // Progress ring (settled vs total)
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
    final categories = [
      {
        'label': 'Settled',
        'value': _d(_summary['total_settled']),
        'color': const Color(0xFF10B981),
        'icon': Icons.check_circle_rounded,
      },
      {
        'label': 'Pending',
        'value': _d(_summary['total_pending']),
        'color': const Color(0xFFF59E0B),
        'icon': Icons.hourglass_empty_rounded,
      },
      {
        'label': 'Failed',
        'value': _d(_summary['total_failed']),
        'color': const Color(0xFFEF4444),
        'icon': Icons.cancel_rounded,
      },
      {
        'label': 'In-Process',
        'value': _d(_summary['total_in_process']),
        'color': const Color(0xFF6366F1),
        'icon': Icons.sync_rounded,
      },
    ];

    return Row(
      children: categories.asMap().entries.map((entry) {
        final i = entry.key;
        final cat = entry.value;
        final amount = cat['value'] as double;
        final color = cat['color'] as Color;
        final label = cat['label'] as String;
        final icon = cat['icon'] as IconData;

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 3 ? 8.w : 0),
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
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
                    // Tiny sparkline (dummy data – replace with real trend if available)
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
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
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
      }).toList(),
    );
  }

  // ─── Payment Breakdown (Donut Chart) ──────────────────────────────────────
  Widget _buildBreakdownChart() {
    final theme = context.siporaTheme;
    final platform = _d(_summary['platform_total']);
    final cash = _d(_summary['cash_total']);
    final qr = _d(_summary['qr_total']);
    final grand = _d(_summary['grand_total']);
    final List<PieChartSectionData> sections = [];

    if (platform > 0) {
      sections.add(
        PieChartSectionData(
          value: platform,
          color: SiporaTheme.greenDark,
          title: 'Platform',
          radius: 24.r,
          titleStyle: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          badgeWidget: Text(
            '${(platform / grand * 100).toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 8.sp, color: Colors.white),
          ),
        ),
      );
    }
    if (cash > 0) {
      sections.add(
        PieChartSectionData(
          value: cash,
          color: const Color(0xFFF59E0B),
          title: 'Cash',
          radius: 24.r,
          titleStyle: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          badgeWidget: Text(
            '${(cash / grand * 100).toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 8.sp, color: Colors.white),
          ),
        ),
      );
    }
    if (qr > 0) {
      sections.add(
        PieChartSectionData(
          value: qr,
          color: const Color(0xFF6366F1),
          title: 'QR/UPI',
          radius: 24.r,
          titleStyle: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          badgeWidget: Text(
            '${(qr / grand * 100).toStringAsFixed(0)}%',
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
            'Payment Breakdown',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12.h),
          if (sections.isEmpty)
            Text('No payment data', style: TextStyle(color: theme.textMuted))
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
                      _legendItem('Platform', SiporaTheme.greenDark, platform),
                      _legendItem('Cash', const Color(0xFFF59E0B), cash),
                      _legendItem('QR/UPI', const Color(0xFF6366F1), qr),
                      SizedBox(height: 8.h),
                      Divider(),
                      _legendItem(
                        'Grand Total',
                        Colors.black,
                        grand,
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
          // Left border indicator
          Container(height: 3.h, color: statusColor),
          // Main card
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
                // Payment split
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
                // Expand toggle + total
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
          // Expanded details
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
                        value: 0.6, // dummy – would need real progress from API
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

  // ─── Navigation ────────────────────────────────────────────────────────────
  void _handleNavTap(int index) {
    setState(() => _selectedNavIndex = index);
    if (index == 0) Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    _fetchSettlements();
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
    _filters = widget.currentFilters.copy(); // Now works
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
          // Drag handle
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
                  // Date Range Presets
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
                                    // Keep current or set default
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

                  // Status Multi-Select
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

                  // Amount Range
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

                  // Payment Mode Toggles
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

                  // Sort By
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
          // Action buttons
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
