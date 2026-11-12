// lib/Setting_page/widgets/product_analytics_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';
import '../../services/storage_service.dart';
import '../../theme/sipora_theme.dart';
import '../../utils/responsive_constants.dart';
import 'receipts_of_ordered_products.dart';

// ─────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────

enum ProductAnalyticsView { weekly, monthly, yearly, daily }

class OverallAnalytics {
  final int quantity;
  final double unitAmount;
  final double unitCgst;
  final double unitSgst;
  final double unitGstRate;
  final double totalAmount;
  final double totalCgst;
  final double totalSgst;
  final double itemTotal;
  final double discount;

  OverallAnalytics({
    required this.quantity,
    required this.unitAmount,
    required this.unitCgst,
    required this.unitSgst,
    required this.unitGstRate,
    required this.totalAmount,
    required this.totalCgst,
    required this.totalSgst,
    required this.itemTotal,
    required this.discount,
  });

  factory OverallAnalytics.fromJson(Map<String, dynamic> json) =>
      OverallAnalytics(
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        unitAmount: (json['unit_amount'] as num?)?.toDouble() ?? 0,
        unitCgst: (json['unit_cgst'] as num?)?.toDouble() ?? 0,
        unitSgst: (json['unit_sgst'] as num?)?.toDouble() ?? 0,
        unitGstRate: (json['unit_gst_rate'] as num?)?.toDouble() ?? 0,
        totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
        totalCgst: (json['total_cgst'] as num?)?.toDouble() ?? 0,
        totalSgst: (json['total_sgst'] as num?)?.toDouble() ?? 0,
        itemTotal: (json['item_total'] as num?)?.toDouble() ?? 0,
        discount: (json['discount'] as num?)?.toDouble() ?? 0,
      );
}

class ProductBreakdown {
  final String period;
  final int quantity;
  final double unitAmount;
  final double unitCgst;
  final double unitSgst;
  final double unitGstRate;
  final double totalAmount;
  final double totalCgst;
  final double totalSgst;
  final double itemTotal;
  final double discount;

  ProductBreakdown({
    required this.period,
    required this.quantity,
    required this.unitAmount,
    required this.unitCgst,
    required this.unitSgst,
    required this.unitGstRate,
    required this.totalAmount,
    required this.totalCgst,
    required this.totalSgst,
    required this.itemTotal,
    required this.discount,
  });

  factory ProductBreakdown.fromJson(Map<String, dynamic> json) =>
      ProductBreakdown(
        period: json['period']?.toString() ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        unitAmount: (json['unit_amount'] as num?)?.toDouble() ?? 0,
        unitCgst: (json['unit_cgst'] as num?)?.toDouble() ?? 0,
        unitSgst: (json['unit_sgst'] as num?)?.toDouble() ?? 0,
        unitGstRate: (json['unit_gst_rate'] as num?)?.toDouble() ?? 0,
        totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
        totalCgst: (json['total_cgst'] as num?)?.toDouble() ?? 0,
        totalSgst: (json['total_sgst'] as num?)?.toDouble() ?? 0,
        itemTotal: (json['item_total'] as num?)?.toDouble() ?? 0,
        discount: (json['discount'] as num?)?.toDouble() ?? 0,
      );
}

class ProductSummary {
  final String productId;
  final String productName;
  final OverallAnalytics summary;
  final List<ProductBreakdown> breakdown;

  ProductSummary({
    required this.productId,
    required this.productName,
    required this.summary,
    required this.breakdown,
  });

  factory ProductSummary.fromJson(Map<String, dynamic> json) => ProductSummary(
    productId: json['product_id']?.toString() ?? '',
    productName: json['product_name']?.toString() ?? '',
    summary: OverallAnalytics.fromJson(json['summary'] ?? {}),
    breakdown: (json['breakdown'] as List? ?? [])
        .map((item) => ProductBreakdown.fromJson(item))
        .toList(),
  );
}

class ProductAnalyticsResponse {
  final bool success;
  final String franchiseId;
  final String view;
  final String startDate;
  final String endDate;
  final OverallAnalytics overall;
  final List<ProductSummary> products;

  ProductAnalyticsResponse({
    required this.success,
    required this.franchiseId,
    required this.view,
    required this.startDate,
    required this.endDate,
    required this.overall,
    required this.products,
  });

  factory ProductAnalyticsResponse.fromJson(Map<String, dynamic> json) =>
      ProductAnalyticsResponse(
        success: json['success'] ?? false,
        franchiseId: json['franchise_id']?.toString() ?? '',
        view: json['view']?.toString() ?? 'monthly',
        startDate: json['start_date']?.toString() ?? '',
        endDate: json['end_date']?.toString() ?? '',
        overall: OverallAnalytics.fromJson(json['overall'] ?? {}),
        products: (json['products'] as List? ?? [])
            .map((item) => ProductSummary.fromJson(item))
            .toList(),
      );
}

class FranchiseOwner {
  final String franchiseId;
  final String userId;
  final String shopName;
  final String city;
  final String fullAddress;

  FranchiseOwner({
    required this.franchiseId,
    required this.userId,
    required this.shopName,
    required this.city,
    required this.fullAddress,
  });

  factory FranchiseOwner.fromJson(Map<String, dynamic> json) => FranchiseOwner(
    franchiseId: json['franchise_id']?.toString() ?? '',
    userId: json['user_id']?.toString() ?? '',
    shopName: json['shop_name']?.toString() ?? '',
    city: json['city']?.toString() ?? '',
    fullAddress: json['fullAddress']?.toString() ?? '',
  );
}

class PeriodAnalyticsPoint {
  final String period;
  final int quantity;
  final double unitAmount;
  final double totalAmount;
  final double totalCgst;
  final double totalSgst;
  final double gst;
  final double itemTotal;
  final double discount;

  PeriodAnalyticsPoint({
    required this.period,
    required this.quantity,
    required this.unitAmount,
    required this.totalAmount,
    required this.totalCgst,
    required this.totalSgst,
    required this.gst,
    required this.itemTotal,
    required this.discount,
  });
}

// ─────────────────────────────────────────────
//  API SERVICE
// ─────────────────────────────────────────────

class ProductAnalyticsService {
  static Future<List<FranchiseOwner>> fetchFranchiseOwners(
    String userId,
  ) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/product/owner-data?user_id=$userId'),
      headers: {'accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch franchise owners');
    }

    final data = json.decode(response.body);
    final List<dynamic> owners = data['franchise_owners'] ?? [];
    return owners
        .map((item) => FranchiseOwner.fromJson(item))
        .where((owner) => owner.userId == userId)
        .toList();
  }

  static Future<ProductAnalyticsResponse> fetchProductSales({
    required String franchiseId,
    required String startDate,
    required String endDate,
    required String view,
  }) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/franchise-invoices/franchise-product-sales/$franchiseId',
      ).replace(
        queryParameters: {
          'start_date': startDate,
          'end_date': endDate,
          'view': view,
        },
      ),
      headers: {'accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch product sales analytics');
    }

    final data = json.decode(response.body);
    return ProductAnalyticsResponse.fromJson(data);
  }
}

// ─────────────────────────────────────────────
//  MAIN PAGE
// ─────────────────────────────────────────────

class ProductAnalyticsPage extends StatefulWidget {
  const ProductAnalyticsPage({super.key});

  @override
  State<ProductAnalyticsPage> createState() => _ProductAnalyticsPageState();
}

class _ProductAnalyticsPageState extends State<ProductAnalyticsPage>
    with SingleTickerProviderStateMixin {
  // ─── State ──────────────────────────────────
  List<FranchiseOwner> _franchises = [];
  String? _selectedFranchiseId;
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  ProductAnalyticsView _view = ProductAnalyticsView.monthly;
  ProductAnalyticsResponse? _response;
  List<ProductSummary> _products = [];
  bool _isLoading = true;
  String _error = '';
  String _searchTerm = '';
  String _sortKey = 'item_total';
  bool _sortAscending = false;
  int _currentPage = 1;
  int _pageSize = 10;
  late AnimationController _animationController;

  // ─── Init / Dispose ────────────────────────
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ─── Data Loading ──────────────────────────
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _error = '';

    try {
      final userId = await _getUserId();
      if (userId == null) throw Exception('User not logged in');

      final franchises = await ProductAnalyticsService.fetchFranchiseOwners(
        userId,
      );
      setState(() => _franchises = franchises);

      if (franchises.isNotEmpty) {
        final savedId = _selectedFranchiseId ?? franchises.first.franchiseId;
        _selectedFranchiseId = savedId;
        await _fetchAnalytics();
      } else {
        setState(() {
          _error = 'No franchise found for this account';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id') ?? await StorageService.getUserId();
  }

  Future<void> _fetchAnalytics() async {
    if (_selectedFranchiseId == null) return;

    setState(() => _isLoading = true);
    _error = '';

    try {
      final response = await ProductAnalyticsService.fetchProductSales(
        franchiseId: _selectedFranchiseId!,
        startDate: DateFormat('yyyy-MM-dd').format(_startDate),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate),
        view: _view.name,
      );

      setState(() {
        _response = response;
        _products = response.products;
        _isLoading = false;
        _currentPage = 1;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        _response = null;
        _products = [];
      });
    }
  }

  // ─── Computed ──────────────────────────────
  List<ProductSummary> get _filteredProducts {
    final term = _searchTerm.trim().toLowerCase();
    var list = _products;

    if (term.isNotEmpty) {
      list = list
          .where(
            (p) =>
                p.productName.toLowerCase().contains(term) ||
                p.productId.toLowerCase().contains(term),
          )
          .toList();
    }

    list.sort((a, b) {
      final key = _sortKey;
      num aVal, bVal;

      if (key == 'product_name') {
        return _sortAscending
            ? a.productName.compareTo(b.productName)
            : b.productName.compareTo(a.productName);
      } else if (key == 'quantity') {
        aVal = a.summary.quantity;
        bVal = b.summary.quantity;
      } else if (key == 'unit_amount') {
        aVal = a.summary.unitAmount;
        bVal = b.summary.unitAmount;
      } else if (key == 'total_amount') {
        aVal = a.summary.totalAmount;
        bVal = b.summary.totalAmount;
      } else if (key == 'discount') {
        aVal = a.summary.discount;
        bVal = b.summary.discount;
      } else if (key == 'gst') {
        aVal = a.summary.totalCgst + a.summary.totalSgst;
        bVal = b.summary.totalCgst + b.summary.totalSgst;
      } else {
        aVal = a.summary.itemTotal;
        bVal = b.summary.itemTotal;
      }

      return _sortAscending ? aVal.compareTo(bVal) : bVal.compareTo(aVal);
    });

    return list;
  }

  List<PeriodAnalyticsPoint> get _periodAnalytics {
    final map = <String, PeriodAnalyticsPoint>{};

    for (final product in _products) {
      for (final breakdown in product.breakdown) {
        final existing = map[breakdown.period];
        if (existing == null) {
          map[breakdown.period] = PeriodAnalyticsPoint(
            period: breakdown.period,
            quantity: breakdown.quantity,
            unitAmount: breakdown.unitAmount,
            totalAmount: breakdown.totalAmount,
            totalCgst: breakdown.totalCgst,
            totalSgst: breakdown.totalSgst,
            gst: breakdown.totalCgst + breakdown.totalSgst,
            itemTotal: breakdown.itemTotal,
            discount: breakdown.discount,
          );
        } else {
          map[breakdown.period] = PeriodAnalyticsPoint(
            period: breakdown.period,
            quantity: existing.quantity + breakdown.quantity,
            unitAmount: existing.unitAmount + breakdown.unitAmount,
            totalAmount: existing.totalAmount + breakdown.totalAmount,
            totalCgst: existing.totalCgst + breakdown.totalCgst,
            totalSgst: existing.totalSgst + breakdown.totalSgst,
            gst: existing.gst + breakdown.totalCgst + breakdown.totalSgst,
            itemTotal: existing.itemTotal + breakdown.itemTotal,
            discount: existing.discount + breakdown.discount,
          );
        }
      }
    }

    final keys = map.keys.toList();
    keys.sort((a, b) {
      final aParts = a.split('-');
      final bParts = b.split('-');
      for (int i = 0; i < aParts.length && i < bParts.length; i++) {
        final aNum = int.tryParse(aParts[i]);
        final bNum = int.tryParse(bParts[i]);
        if (aNum != null && bNum != null && aNum != bNum) {
          return aNum.compareTo(bNum);
        }
      }
      return a.compareTo(b);
    });

    return keys.map((key) => map[key]!).toList();
  }

  int get totalPages => _filteredProducts.isEmpty
      ? 1
      : (_filteredProducts.length / _pageSize).ceil();
  List<ProductSummary> get _paginatedProducts {
    if (_filteredProducts.isEmpty) return [];
    final start = (_currentPage - 1) * _pageSize;
    final end = start + _pageSize;
    return _filteredProducts.sublist(
      start,
      end > _filteredProducts.length ? _filteredProducts.length : end,
    );
  }

  double get totalGst =>
      (_response?.overall.totalCgst ?? 0) + (_response?.overall.totalSgst ?? 0);

  // ─── Helpers ───────────────────────────────
  String _formatCurrency(double amount) =>
      NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(amount);

  String _formatCurrencyFull(double amount) =>
      NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(amount);

  String _formatNumber(num value) => NumberFormat('#,##0.##').format(value);

  String _formatDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);

  String _getBreakdownLabel() {
    switch (_view) {
      case ProductAnalyticsView.monthly:
        return 'Weekly Breakdown';
      case ProductAnalyticsView.yearly:
        return 'Monthly Breakdown';
      default:
        return 'Daily Breakdown';
    }
  }

  // ─── Build ──────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final isTablet = context.isTabletScreen;

    return Scaffold(
      backgroundColor: theme.cream,
      appBar: _buildAppBar(isTablet),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterBar(),
            const SizedBox(height: 20),
            if (_isLoading)
              _buildLoadingState()
            else if (_error.isNotEmpty)
              _buildErrorState()
            else if (_response == null || _products.isEmpty)
              _buildEmptyState()
            else
              _buildDataSections(),
          ],
        ),
      ),
    );
  }

  // ─── AppBar ─────────────────────────────────
  PreferredSizeWidget _buildAppBar(bool isTablet) {
    final theme = context.siporaTheme;
    final avatarSize = ResponsiveConstants.getAvatarSize(context);
    final iconSize = ResponsiveConstants.getIconSize(context);
    final titleFontSize = ResponsiveConstants.getTitleFontSize(context);

    return AppBar(
      backgroundColor: theme.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: theme.border),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                color: theme.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.border, width: 1.5),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: iconSize - 7,
                color: theme.textDark,
              ),
            ),
          ),
        ),
      ),
      title: Text(
        'Product Analytics',
        style: TextStyle(
          fontSize: titleFontSize - 2,
          fontWeight: FontWeight.w700,
          color: theme.textDark,
          letterSpacing: -0.2,
        ),
      ),
      actions: [
        IconButton(
          onPressed: _fetchAnalytics,
          icon: Icon(Icons.refresh_rounded, color: theme.textDark),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  // ─── States ─────────────────────────────────
  Widget _buildLoadingState() {
    final theme = context.siporaTheme;
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(SiporaTheme.greenDark),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading analytics...',
              style: TextStyle(fontSize: 14, color: theme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = context.siporaTheme;
    return SizedBox(
      height: 300,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 56, color: theme.red),
              const SizedBox(height: 16),
              Text(
                _error,
                style: TextStyle(fontSize: 16, color: theme.textDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchAnalytics,
                style: SiporaTheme.primaryButtonStyle(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = context.siporaTheme;
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: theme.textMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No Analytics Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: theme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No sales data found for the selected franchise and date range.',
              style: TextStyle(fontSize: 14, color: theme.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchAnalytics,
              style: SiporaTheme.primaryButtonStyle(),
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Data Sections ─────────────────────────
  Widget _buildDataSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildKpiGrid(),
        const SizedBox(height: 24),
        _buildChartsSection(),
        const SizedBox(height: 24),
        _buildProductsSection(),
        const SizedBox(height: 24),
        _buildBreakdownSection(),
        const SizedBox(height: 20),
      ],
    );
  }

  // ─── Filter Bar ─────────────────────────────
  Widget _buildFilterBar() {
    final theme = context.siporaTheme;
    final isTablet = context.isTabletScreen;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: SiporaTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Franchise
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Franchise', style: _labelStyle(theme)),
              const SizedBox(height: 4),
              _franchises.length <= 1
                  ? _buildSingleFranchiseLabel(theme, isTablet)
                  : SizedBox(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        value: _selectedFranchiseId,
                        isExpanded: true,
                        decoration: _dropdownDecoration(theme, isTablet),
                        items: _franchises.map((f) {
                          return DropdownMenuItem<String>(
                            value: f.franchiseId,
                            child: SizedBox(
                              width: double.infinity,
                              child: Text(
                                f.shopName.isNotEmpty
                                    ? f.shopName
                                    : f.franchiseId,
                                style: TextStyle(fontSize: isTablet ? 14 : 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedFranchiseId = value);
                            _fetchAnalytics();
                          }
                        },
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Start Date & End Date
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Start Date', style: _labelStyle(theme)),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _selectDate(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: _inputDecoration(theme, isTablet),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: theme.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _formatDate(_startDate),
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 12,
                                  color: theme.textDark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('End Date', style: _labelStyle(theme)),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _selectDate(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: _inputDecoration(theme, isTablet),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: theme.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _formatDate(_endDate),
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 12,
                                  color: theme.textDark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 3: View
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('View', style: _labelStyle(theme)),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: DropdownButtonFormField<ProductAnalyticsView>(
                  value: _view,
                  isExpanded: true,
                  decoration: _dropdownDecoration(theme, isTablet),
                  items: ProductAnalyticsView.values.map((v) {
                    return DropdownMenuItem<ProductAnalyticsView>(
                      value: v,
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          v.name.toUpperCase(),
                          style: TextStyle(fontSize: isTablet ? 14 : 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _view = value);
                      _fetchAnalytics();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 4: View Order Receipts Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_selectedFranchiseId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReceiptsOfOrderedProductsPage(
                        franchiseId: _selectedFranchiseId!,
                        startDate: _startDate,
                        endDate: _endDate,
                      ),
                    ),
                  );
                } else {
                  SiporaTheme.showSnackBar(
                    context,
                    'Please select a franchise first',
                    isError: true,
                  );
                }
              },
              icon: const Icon(Icons.receipt_rounded, size: 18),
              label: const Text('View Order Receipts'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SiporaTheme.greenDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleFranchiseLabel(SiporaThemeExtension theme, bool isTablet) {
    final name = _franchises.isNotEmpty
        ? (_franchises.first.shopName.isNotEmpty
              ? _franchises.first.shopName
              : _franchises.first.franchiseId)
        : '—';

    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: isTablet ? 12 : 8,
        ),
        decoration: BoxDecoration(
          color: theme.cream,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          children: [
            Icon(Icons.storefront_rounded, size: 16, color: theme.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.w600,
                  color: theme.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _labelStyle(SiporaThemeExtension theme) => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: theme.textMuted,
    letterSpacing: 0.5,
  );

  InputDecoration _dropdownDecoration(
    SiporaThemeExtension theme,
    bool isTablet,
  ) => InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: theme.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: theme.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: SiporaTheme.greenMid, width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(
      horizontal: 12,
      vertical: isTablet ? 12 : 8,
    ),
    filled: true,
    fillColor: theme.white,
    isDense: true,
  );

  BoxDecoration _inputDecoration(SiporaThemeExtension theme, bool isTablet) =>
      BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.border),
      );

  Future<void> _selectDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: SiporaTheme.greenDark,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = date;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate;
          }
        }
      });
      _fetchAnalytics();
    }
  }

  // ─── KPI Grid ──────────────────────────────
  Widget _buildKpiGrid() {
    final overall = _response!.overall;
    final kpis = [
      {
        'label': 'Total Quantity',
        'value': _formatNumber(overall.quantity),
        'icon': Icons.shopping_bag_rounded,
        'color': SiporaTheme.greenDark,
      },
      {
        'label': 'Total Revenue',
        'value': _formatCurrency(overall.itemTotal),
        'icon': Icons.currency_rupee_rounded,
        'color': const Color(0xFF0284C7),
      },
      {
        'label': 'Total GST',
        'value': _formatCurrency(totalGst),
        'icon': Icons.percent_rounded,
        'color': const Color(0xFFD97706),
      },
      {
        'label': 'Total Discount',
        'value': _formatCurrency(overall.discount),
        'icon': Icons.discount_rounded,
        'color': const Color(0xFFE11D48),
      },
      {
        'label': 'Total Amount',
        'value': _formatCurrency(overall.totalAmount),
        'icon': Icons.receipt_rounded,
        'color': const Color(0xFF4F46E5),
      },
      {
        'label': 'Avg GST Rate',
        'value': '${_formatNumber(overall.unitGstRate)}%',
        'icon': Icons.trending_up_rounded,
        'color': const Color(0xFF059669),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.isTabletScreen ? 4 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: kpis.length,
      itemBuilder: (context, index) {
        final kpi = kpis[index];
        return _buildKpiCard(
          icon: kpi['icon'] as IconData,
          label: kpi['label'] as String,
          value: kpi['value'] as String,
          color: kpi['color'] as Color,
        );
      },
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = context.siporaTheme;
    final isTablet = context.isTabletScreen;

    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: isTablet ? 16 : 14, color: color),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isTablet ? 10 : 8,
                    color: theme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? 16 : 12,
              fontWeight: FontWeight.w800,
              color: theme.textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─── Charts Section ────────────────────────
  Widget _buildChartsSection() {
    final isTablet = context.isTabletScreen;
    final data = _periodAnalytics;

    if (data.isEmpty) {
      final theme = context.siporaTheme;
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.border),
        ),
        child: Center(
          child: Text(
            'No breakdown data for charts',
            style: TextStyle(color: theme.textMuted, fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (isTablet)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildChartCard(
                  'Revenue Trend',
                  _buildRevenueChart(data),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildChartCard(
                  'Quantity Trend',
                  _buildQuantityChart(data),
                ),
              ),
            ],
          ),
        if (isTablet) const SizedBox(height: 16),
        if (isTablet)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildChartCard('GST Trend', _buildGstChart(data)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildChartCard(
                  'Discount Trend',
                  _buildDiscountChart(data),
                ),
              ),
            ],
          ),
        if (!isTablet) ...[
          _buildChartCard('Revenue Trend', _buildRevenueChart(data)),
          const SizedBox(height: 16),
          _buildChartCard('Quantity Trend', _buildQuantityChart(data)),
          const SizedBox(height: 16),
          _buildChartCard('GST Trend', _buildGstChart(data)),
          const SizedBox(height: 16),
          _buildChartCard('Discount Trend', _buildDiscountChart(data)),
        ],
      ],
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    final theme = context.siporaTheme;
    final isTablet = context.isTabletScreen;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: SiporaTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                size: 18,
                color: SiporaTheme.greenMid,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(height: isTablet ? 220 : 180, child: chart),
        ],
      ),
    );
  }

  // ─── Revenue Chart (Area) ──────────────────
  Widget _buildRevenueChart(List<PeriodAnalyticsPoint> data) {
    final theme = context.siporaTheme;
    data.map((d) => d.itemTotal).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length)
                  return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    data[index].period,
                    style: TextStyle(fontSize: 9, color: theme.textMuted),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    '₹${(value / 1000).toStringAsFixed(0)}k',
                    style: TextStyle(fontSize: 9, color: theme.textMuted),
                  ),
                );
              },
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
        lineBarsData: [
          LineChartBarData(
            spots: data
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.itemTotal))
                .toList(),
            isCurved: true,
            color: SiporaTheme.greenDark,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: SiporaTheme.greenDark.withValues(alpha: 0.15),
            ),
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  // ─── Quantity Chart (Bar) ──────────────────
  Widget _buildQuantityChart(List<PeriodAnalyticsPoint> data) {
    final theme = context.siporaTheme;
    data.map((d) => d.quantity).reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length)
                  return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    data[index].period,
                    style: TextStyle(fontSize: 9, color: theme.textMuted),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(fontSize: 9, color: theme.textMuted),
                  ),
                );
              },
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
        barGroups: data.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.quantity.toDouble(),
                color: const Color(0xFF0284C7),
                width: 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ─── GST Chart (Line) ──────────────────────
  Widget _buildGstChart(List<PeriodAnalyticsPoint> data) {
    final theme = context.siporaTheme;
    data.map((d) => d.gst).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length)
                  return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    data[index].period,
                    style: TextStyle(fontSize: 9, color: theme.textMuted),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    '₹${(value / 1000).toStringAsFixed(0)}k',
                    style: TextStyle(fontSize: 9, color: theme.textMuted),
                  ),
                );
              },
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
        lineBarsData: [
          LineChartBarData(
            spots: data
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.gst))
                .toList(),
            isCurved: true,
            color: const Color(0xFFD97706),
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  // ─── Discount Chart (Area) ─────────────────
  Widget _buildDiscountChart(List<PeriodAnalyticsPoint> data) {
    final theme = context.siporaTheme;
    data.map((d) => d.discount).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length)
                  return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    data[index].period,
                    style: TextStyle(fontSize: 9, color: theme.textMuted),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    '₹${(value / 1000).toStringAsFixed(0)}k',
                    style: TextStyle(fontSize: 9, color: theme.textMuted),
                  ),
                );
              },
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
        lineBarsData: [
          LineChartBarData(
            spots: data
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.discount))
                .toList(),
            isCurved: true,
            color: const Color(0xFFE11D48),
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFFE11D48).withValues(alpha: 0.15),
            ),
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  // ─── Products Section ──────────────────────
  Widget _buildProductsSection() {
    final theme = context.siporaTheme;
    final isTablet = context.isTabletScreen;
    final filtered = _filteredProducts;
    final paginated = _paginatedProducts;

    return Container(
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: SiporaTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: isTablet
                ? Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Top Products',
                              style: TextStyle(
                                fontSize: isTablet ? 20 : 18,
                                fontWeight: FontWeight.w700,
                                color: theme.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Flexible(
                              child: Text(
                                'Search, sort, and inspect product-level sales performance.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(width: 200, child: _buildSearchField(theme)),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top Products',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Search, sort, and inspect product-level sales performance.',
                        style: TextStyle(fontSize: 13, color: theme.textMuted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      _buildSearchField(theme),
                    ],
                  ),
          ),

          // Table
          if (paginated.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No products found',
                  style: TextStyle(color: theme.textMuted, fontSize: 14),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 32,
                ),
                child: DataTable(
                  columnSpacing: isTablet ? 20 : 12,
                  horizontalMargin: 12,
                  headingRowColor: WidgetStateProperty.all(theme.cream),
                  headingTextStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: isTablet ? 13 : 11,
                    color: theme.textDark,
                  ),
                  dataTextStyle: TextStyle(
                    fontSize: isTablet ? 13 : 12,
                    color: theme.textDark,
                  ),
                  columns: [
                    _buildSortableColumn('Rank', 'rank'),
                    _buildSortableColumn('Product', 'product_name'),
                    _buildSortableColumn('Qty', 'quantity'),
                    _buildSortableColumn('Unit Amt', 'unit_amount'),
                    _buildSortableColumn('GST', 'gst'),
                    _buildSortableColumn('Total Amt', 'total_amount'),
                    _buildSortableColumn('Item Total', 'item_total'),
                    _buildSortableColumn('Discount', 'discount'),
                  ],
                  rows: paginated.asMap().entries.map((entry) {
                    final index = entry.key;
                    final product = entry.value;
                    final globalIndex =
                        (_currentPage - 1) * _pageSize + index + 1;
                    final gst =
                        product.summary.totalCgst + product.summary.totalSgst;

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            '$globalIndex',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                product.productName,
                                style: TextStyle(fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                product.productId,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(_formatNumber(product.summary.quantity))),
                        DataCell(
                          Text(_formatCurrencyFull(product.summary.unitAmount)),
                        ),
                        DataCell(Text(_formatCurrencyFull(gst))),
                        DataCell(
                          Text(
                            _formatCurrencyFull(product.summary.totalAmount),
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatCurrencyFull(product.summary.itemTotal),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: SiporaTheme.greenDark,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(_formatCurrencyFull(product.summary.discount)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),

          // Pagination
          if (filtered.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Showing ${paginated.length} of ${filtered.length} products',
                      style: TextStyle(fontSize: 12, color: theme.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.border),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _pageSize,
                            isDense: true,
                            itemHeight: null,
                            items: [10, 25, 50, 100, 200].map((size) {
                              return DropdownMenuItem(
                                value: size,
                                child: Text(
                                  '$size',
                                  style: TextStyle(fontSize: 10),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _pageSize = value;
                                  _currentPage = 1;
                                });
                              }
                            },
                            iconSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _currentPage > 1
                            ? () => setState(() => _currentPage--)
                            : null,
                        icon: Icon(Icons.chevron_left_rounded, size: 18),
                        color: _currentPage > 1
                            ? theme.textDark
                            : theme.textMuted,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Text(
                        '$_currentPage / $totalPages',
                        style: TextStyle(fontSize: 11, color: theme.textDark),
                      ),
                      IconButton(
                        onPressed: _currentPage < totalPages
                            ? () => setState(() => _currentPage++)
                            : null,
                        icon: Icon(Icons.chevron_right_rounded, size: 18),
                        color: _currentPage < totalPages
                            ? theme.textDark
                            : theme.textMuted,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Helper: Search Field ──────────────────
  Widget _buildSearchField(SiporaThemeExtension theme) {
    return TextField(
      onChanged: (value) {
        setState(() {
          _searchTerm = value;
          _currentPage = 1;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search products...',
        hintStyle: TextStyle(fontSize: 12, color: theme.textMuted),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 18,
          color: theme.textMuted,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.border),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        isDense: true,
        filled: true,
        fillColor: theme.cream,
      ),
      style: TextStyle(fontSize: 13, color: theme.textDark),
    );
  }

  DataColumn _buildSortableColumn(String label, String key) {
    final isSorted = _sortKey == key;
    return DataColumn(
      label: InkWell(
        onTap: () {
          setState(() {
            if (_sortKey == key) {
              _sortAscending = !_sortAscending;
            } else {
              _sortKey = key;
              _sortAscending = key == 'product_name';
            }
          });
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (isSorted) ...[
              const SizedBox(width: 4),
              Icon(
                _sortAscending
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 14,
                color: SiporaTheme.greenMid,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Breakdown Section ─────────────────────
  Widget _buildBreakdownSection() {
    final theme = context.siporaTheme;
    final isTablet = context.isTabletScreen;
    final data = _periodAnalytics;

    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: SiporaTheme.shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'No breakdown data available',
            style: TextStyle(color: theme.textMuted, fontSize: 14),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: SiporaTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: SiporaTheme.greenMid,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _getBreakdownLabel(),
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: FontWeight.w700,
                      color: theme.textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 32,
              ),
              child: DataTable(
                columnSpacing: isTablet ? 20 : 12,
                horizontalMargin: 12,
                headingRowColor: WidgetStateProperty.all(theme.cream),
                headingTextStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: isTablet ? 13 : 11,
                  color: theme.textDark,
                ),
                dataTextStyle: TextStyle(
                  fontSize: isTablet ? 13 : 12,
                  color: theme.textDark,
                ),
                columns: const [
                  DataColumn(label: Text('Period')),
                  DataColumn(label: Text('Quantity')),
                  DataColumn(label: Text('Unit Amount')),
                  DataColumn(label: Text('Total Amount')),
                  DataColumn(label: Text('GST')),
                  DataColumn(label: Text('Item Total')),
                  DataColumn(label: Text('Discount')),
                ],
                rows: data.map((row) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          row.period,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataCell(Text(_formatNumber(row.quantity))),
                      DataCell(Text(_formatCurrencyFull(row.unitAmount))),
                      DataCell(Text(_formatCurrencyFull(row.totalAmount))),
                      DataCell(Text(_formatCurrencyFull(row.gst))),
                      DataCell(
                        Text(
                          _formatCurrencyFull(row.itemTotal),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: SiporaTheme.greenDark,
                          ),
                        ),
                      ),
                      DataCell(Text(_formatCurrencyFull(row.discount))),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
