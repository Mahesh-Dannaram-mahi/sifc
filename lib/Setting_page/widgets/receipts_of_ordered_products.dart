// lib/Setting_page/widgets/receipts_of_ordered_products.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';
import '../../services/storage_service.dart';
import '../../theme/sipora_theme.dart';

// ─── Models ─────────────────────────────────────────────

enum ReceiptType { cash, qr, invoice }

class ReceiptItem {
  final int id;
  final String userId;
  final String franchiseId;
  final String receiptId;
  final String productsId;
  final String? productName;
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
  final DateTime? orderCreatedAt;
  final DateTime? timestamp;
  int delivered;
  final ReceiptType receiptType;
  final double? discountPercentage;
  final String? cupId;

  ReceiptItem({
    required this.id,
    required this.userId,
    required this.franchiseId,
    required this.receiptId,
    required this.productsId,
    this.productName,
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
    this.orderCreatedAt,
    this.timestamp,
    this.delivered = 0,
    required this.receiptType,
    this.discountPercentage,
    this.cupId,
  });

  factory ReceiptItem.fromCashReceipt(Map<String, dynamic> json) {
    return ReceiptItem(
      id: json['id'] ?? 0,
      userId: json['user_id']?.toString() ?? '',
      franchiseId: json['franchise_id']?.toString() ?? '',
      receiptId: json['receipt_id']?.toString() ?? '',
      productsId: json['products_id']?.toString() ?? '',
      productName: json['product_name'],
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
      orderCreatedAt: json['order_created_at'] != null
          ? DateTime.tryParse(json['order_created_at'])
          : null,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'])
          : null,
      delivered: (json['delivered'] as num?)?.toInt() ?? 0,
      receiptType: ReceiptType.cash,
    );
  }

  factory ReceiptItem.fromQrReceipt(Map<String, dynamic> json) {
    return ReceiptItem(
      id: json['id'] ?? 0,
      userId: json['user_id']?.toString() ?? '',
      franchiseId: json['franchise_id']?.toString() ?? '',
      receiptId: json['receipt_id']?.toString() ?? '',
      productsId: json['products_id']?.toString() ?? '',
      productName: json['product_name'],
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
      orderCreatedAt: json['order_created_at'] != null
          ? DateTime.tryParse(json['order_created_at'])
          : null,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'])
          : null,
      delivered: (json['delivered'] as num?)?.toInt() ?? 0,
      receiptType: ReceiptType.qr,
    );
  }

  factory ReceiptItem.fromInvoiceReceipt(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    return ReceiptItem(
      id: json['id'] ?? 0,
      userId: json['user_id']?.toString() ?? '',
      franchiseId: json['franchise_id']?.toString() ?? '',
      receiptId: json['receipt_id']?.toString() ?? 'INV-${json['id']}',
      productsId:
          product?['product_id']?.toString() ??
          json['products_id']?.toString() ??
          '',
      productName: product?['product_name'] ?? json['product_name'],
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
      orderCreatedAt: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'])
          : null,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'])
          : null,
      delivered: 1,
      receiptType: ReceiptType.invoice,
      discountPercentage: (json['discount_percentage'] as num?)?.toDouble(),
      cupId: json['cup_id']?.toString(),
    );
  }

  DateTime get orderDateTime => orderCreatedAt ?? timestamp ?? DateTime.now();
  bool get isDelivered => delivered == 1;
}

class GroupedReceipt {
  final String receiptId;
  final ReceiptType receiptType;
  final DateTime? orderCreatedAt;
  int delivered;
  final List<ReceiptItem> items;
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount =>
      items.fold(0, (sum, item) => sum + item.totalAmount);
  double get totalTax =>
      items.fold(0, (sum, item) => sum + item.totalCgst + item.totalSgst);
  double get grandTotal => items.fold(0, (sum, item) => sum + item.itemTotal);
  bool get isDelivered => delivered == 1;

  GroupedReceipt({
    required this.receiptId,
    required this.receiptType,
    this.orderCreatedAt,
    this.delivered = 0,
    required this.items,
  });

  String get shortId => receiptId.length > 8
      ? '#${receiptId.substring(receiptId.length - 8)}'
      : '#$receiptId';
  String get typeLabel => receiptType.toString().split('.').last.toUpperCase();
}

class ReceiptSummary {
  final int totalOrders;
  final double totalRevenue;
  final double totalGst;
  final double averageOrderValue;
  final int totalItems;

  ReceiptSummary({
    this.totalOrders = 0,
    this.totalRevenue = 0,
    this.totalGst = 0,
    this.averageOrderValue = 0,
    this.totalItems = 0,
  });
}

// ─── Service ──────────────────────────────────────────

class ReceiptsService {
  static const String _baseUrl = ApiConfig.baseUrl;

  static Future<List<ReceiptItem>> fetchReceipts(String franchiseId) async {
    final List<ReceiptItem> allReceipts = [];

    try {
      // Fetch cash receipts
      final cashResponse = await http.get(
        Uri.parse(
          '$_baseUrl/api/pos-cash-receipts/pos-cash/franchise/$franchiseId/receipts',
        ),
        headers: {'accept': 'application/json'},
      );
      if (cashResponse.statusCode == 200) {
        final data = json.decode(cashResponse.body);
        final receipts = data['receipts'] as List? ?? [];
        allReceipts.addAll(receipts.map((r) => ReceiptItem.fromCashReceipt(r)));
      }

      // Fetch QR receipts
      final qrResponse = await http.get(
        Uri.parse(
          '$_baseUrl/api/pos-qr-receipts/pos-qr/franchise/$franchiseId/receipts',
        ),
        headers: {'accept': 'application/json'},
      );
      if (qrResponse.statusCode == 200) {
        final data = json.decode(qrResponse.body);
        final receipts = data['receipts'] as List? ?? [];
        allReceipts.addAll(receipts.map((r) => ReceiptItem.fromQrReceipt(r)));
      }

      // Fetch invoice receipts
      final invoiceResponse = await http.get(
        Uri.parse(
          '$_baseUrl/api/franchise-invoices/customer-invoice-list-by-franchise/$franchiseId?page=1&page_size=1000',
        ),
        headers: {'accept': 'application/json'},
      );
      if (invoiceResponse.statusCode == 200) {
        final data = json.decode(invoiceResponse.body);
        final receipts = data['data'] as List? ?? [];
        allReceipts.addAll(
          receipts.map((r) => ReceiptItem.fromInvoiceReceipt(r)),
        );
      }

      return allReceipts;
    } catch (e) {
      throw Exception('Failed to fetch receipts: $e');
    }
  }

  static Future<bool> markAsDelivered(
    String receiptId,
    ReceiptType type,
  ) async {
    try {
      final endpoint = type == ReceiptType.qr
          ? '$_baseUrl/api/pos-qr-delivered/pos-qr/receipts/$receiptId/update-delivered'
          : '$_baseUrl/api/pos-cash-delivered/pos-cash/receipts/$receiptId/update-delivered';

      final response = await http.put(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'delivered': 1}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

// ─── Main Page ──────────────────────────────────────────

class ReceiptsOfOrderedProductsPage extends StatefulWidget {
  final String? franchiseId;
  final DateTime? startDate;
  final DateTime? endDate;

  const ReceiptsOfOrderedProductsPage({
    super.key,
    this.franchiseId,
    this.startDate,
    this.endDate,
  });

  @override
  State<ReceiptsOfOrderedProductsPage> createState() =>
      _ReceiptsOfOrderedProductsPageState();
}

class _ReceiptsOfOrderedProductsPageState
    extends State<ReceiptsOfOrderedProductsPage>
    with SingleTickerProviderStateMixin {
  // ─── State ──────────────────────────────────
  List<FranchiseOwner> _franchises = [];
  String? _selectedFranchiseId;
  List<ReceiptItem> _allReceipts = [];
  List<GroupedReceipt> _groupedReceipts = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  Set<ReceiptType> _selectedTypes = {
    ReceiptType.cash,
    ReceiptType.qr,
    ReceiptType.invoice,
  };
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String? _expandedReceiptId;
  String _sortOption = 'date_desc';

  late AnimationController _animationController;

  // ─── Init ──────────────────────────────────
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // ALWAYS default to today - ignore any passed dates
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Force set to today only - ignore widget.startDate and widget.endDate
    _startDate = today;
    _endDate = today;

    // Only use franchiseId from widget
    _selectedFranchiseId = widget.franchiseId;

    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ─── Data Loading ──────────────────────────
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = await _getUserId();
      if (userId == null) throw Exception('User not logged in');

      final franchises = await _fetchFranchiseOwners(userId);
      setState(() => _franchises = franchises);

      // If no franchiseId provided, use first one
      if (_selectedFranchiseId == null && franchises.isNotEmpty) {
        _selectedFranchiseId = franchises.first.franchiseId;
      }

      // If provided franchiseId doesn't exist in the list, use first one
      if (_selectedFranchiseId != null &&
          !franchises.any((f) => f.franchiseId == _selectedFranchiseId) &&
          franchises.isNotEmpty) {
        _selectedFranchiseId = franchises.first.franchiseId;
      }

      if (_selectedFranchiseId != null) {
        await _fetchReceipts();
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

  Future<List<FranchiseOwner>> _fetchFranchiseOwners(String userId) async {
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

  Future<void> _fetchReceipts() async {
    if (_selectedFranchiseId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final receipts = await ReceiptsService.fetchReceipts(
        _selectedFranchiseId!,
      );
      setState(() {
        _allReceipts = receipts;
        _applyFilters();
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // ─── Filtering ─────────────────────────────
  void _applyFilters() {
    final filtered = _allReceipts.where((receipt) {
      // Date filter - use the current _startDate and _endDate
      final date = receipt.orderDateTime;
      final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final end = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        23,
        59,
        59,
      );
      if (date.isBefore(start) || date.isAfter(end)) return false;

      // Type filter
      if (!_selectedTypes.contains(receipt.receiptType)) return false;

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final id = receipt.receiptId.toLowerCase();
        final product = receipt.productName?.toLowerCase() ?? '';
        if (!id.contains(query) && !product.contains(query)) return false;
      }

      return true;
    }).toList();

    // Group by receipt_id
    final Map<String, GroupedReceipt> grouped = {};
    for (final receipt in filtered) {
      final key = '${receipt.receiptType}_${receipt.receiptId}';
      if (!grouped.containsKey(key)) {
        grouped[key] = GroupedReceipt(
          receiptId: receipt.receiptId,
          receiptType: receipt.receiptType,
          orderCreatedAt: receipt.orderDateTime,
          delivered: receipt.delivered,
          items: [],
        );
      }
      grouped[key]!.items.add(receipt);
      if (receipt.delivered == 1) {
        grouped[key]!.delivered = 1;
      }
    }

    // Sort groups
    var sorted = grouped.values.toList();
    switch (_sortOption) {
      case 'date_desc':
        sorted.sort((a, b) {
          final aDate = a.orderCreatedAt ?? DateTime(2000);
          final bDate = b.orderCreatedAt ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });
        break;
      case 'date_asc':
        sorted.sort((a, b) {
          final aDate = a.orderCreatedAt ?? DateTime(2000);
          final bDate = b.orderCreatedAt ?? DateTime(2000);
          return aDate.compareTo(bDate);
        });
        break;
      case 'amount_desc':
        sorted.sort((a, b) => b.grandTotal.compareTo(a.grandTotal));
        break;
      case 'amount_asc':
        sorted.sort((a, b) => a.grandTotal.compareTo(b.grandTotal));
        break;
      case 'items_desc':
        sorted.sort((a, b) => b.totalItems.compareTo(a.totalItems));
        break;
      default:
        sorted.sort((a, b) {
          final aDate = a.orderCreatedAt ?? DateTime(2000);
          final bDate = b.orderCreatedAt ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });
    }

    setState(() {
      _groupedReceipts = sorted;
    });
  }

  ReceiptSummary _calculateSummary() {
    int totalOrders = 0;
    double totalRevenue = 0;
    double totalGst = 0;
    int totalItems = 0;

    for (final group in _groupedReceipts) {
      totalOrders++;
      totalRevenue += group.totalAmount;
      totalGst += group.totalTax;
      totalItems += group.totalItems;
    }

    return ReceiptSummary(
      totalOrders: totalOrders,
      totalRevenue: totalRevenue,
      totalGst: totalGst,
      averageOrderValue: totalOrders > 0 ? totalRevenue / totalOrders : 0,
      totalItems: totalItems,
    );
  }

  // ─── Helpers ───────────────────────────────
  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(amount);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  String _formatDateShort(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Color _getTypeColor(ReceiptType type) {
    switch (type) {
      case ReceiptType.cash:
        return const Color(0xFF22C55E);
      case ReceiptType.qr:
        return const Color(0xFFA855F7);
      case ReceiptType.invoice:
        return const Color(0xFF3B82F6);
    }
  }

  IconData _getTypeIcon(ReceiptType type) {
    switch (type) {
      case ReceiptType.cash:
        return Icons.payments_rounded;
      case ReceiptType.qr:
        return Icons.qr_code_rounded;
      case ReceiptType.invoice:
        return Icons.receipt_rounded;
    }
  }

  // ─── Build ──────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;

    return Scaffold(
      backgroundColor: theme.cream,
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
          ? _buildErrorState()
          : _franchises.isEmpty
          ? _buildNoFranchiseState()
          : Column(
              children: [
                _buildFilterBar(),
                _buildSummaryCards(),
                Expanded(
                  child: _groupedReceipts.isEmpty
                      ? _buildEmptyState()
                      : _buildReceiptsList(),
                ),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final theme = context.siporaTheme;

    return AppBar(
      backgroundColor: theme.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: theme.border),
      ),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.cream,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: theme.textDark,
          ),
        ),
      ),
      title: Text(
        'Order Receipts',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: theme.textDark,
          letterSpacing: -0.5,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: _fetchReceipts,
          icon: Icon(Icons.refresh_rounded, color: theme.textDark),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    final theme = context.siporaTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(SiporaTheme.greenDark),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading receipts...',
            style: TextStyle(fontSize: 14, color: theme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = context.siporaTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 56, color: theme.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(fontSize: 16, color: theme.textDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              style: SiporaTheme.primaryButtonStyle(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoFranchiseState() {
    final theme = context.siporaTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: SiporaTheme.greenBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.storefront_rounded,
              size: 56,
              color: SiporaTheme.greenMid.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Franchise Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: theme.textDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any franchise assigned to your account.',
            style: TextStyle(fontSize: 14, color: theme.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = context.siporaTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: SiporaTheme.greenBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_outlined,
              size: 56,
              color: SiporaTheme.greenMid.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No receipts found for today',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: theme.textDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use date filters to view other days',
            style: TextStyle(fontSize: 14, color: theme.textMuted),
          ),
        ],
      ),
    );
  }

  // ─── Filter Bar ─────────────────────────────
  Widget _buildFilterBar() {
    final theme = context.siporaTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show selected franchise
          Row(
            children: [
              Icon(Icons.storefront_rounded, size: 16, color: theme.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _franchises
                      .firstWhere(
                        (f) => f.franchiseId == _selectedFranchiseId,
                        orElse: () => _franchises.first,
                      )
                      .shopName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_franchises.length > 1)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    setState(() {
                      _selectedFranchiseId = value;
                    });
                    _fetchReceipts();
                  },
                  itemBuilder: (context) {
                    return _franchises.map((f) {
                      return PopupMenuItem<String>(
                        value: f.franchiseId,
                        child: Text(f.shopName),
                      );
                    }).toList();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.cream,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.border),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Switch',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textMuted,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 16,
                          color: theme.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Date Range - showing today by default with green highlight
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _selectDate(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _isToday(_startDate)
                              ? SiporaTheme.greenBg
                              : theme.cream,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isToday(_startDate)
                                ? SiporaTheme.greenMid
                                : theme.border,
                            width: _isToday(_startDate) ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: _isToday(_startDate)
                                  ? SiporaTheme.greenMid
                                  : theme.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _formatDateShort(_startDate),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _isToday(_startDate)
                                      ? SiporaTheme.greenMid
                                      : theme.textDark,
                                  fontWeight: _isToday(_startDate)
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              size: 16,
                              color: _isToday(_startDate)
                                  ? SiporaTheme.greenMid
                                  : theme.textMuted,
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
                    Text(
                      'To',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _selectDate(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _isToday(_endDate)
                              ? SiporaTheme.greenBg
                              : theme.cream,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isToday(_endDate)
                                ? SiporaTheme.greenMid
                                : theme.border,
                            width: _isToday(_endDate) ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: _isToday(_endDate)
                                  ? SiporaTheme.greenMid
                                  : theme.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _formatDateShort(_endDate),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _isToday(_endDate)
                                      ? SiporaTheme.greenMid
                                      : theme.textDark,
                                  fontWeight: _isToday(_endDate)
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              size: 16,
                              color: _isToday(_endDate)
                                  ? SiporaTheme.greenMid
                                  : theme.textMuted,
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

          // Quick Date Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickDateChip('Today', () {
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  setState(() {
                    _startDate = today;
                    _endDate = today;
                  });
                  _applyFilters();
                }, isActive: _isToday(_startDate) && _isToday(_endDate)),
                const SizedBox(width: 8),
                _buildQuickDateChip('This Week', () {
                  final now = DateTime.now();
                  final start = now.subtract(Duration(days: now.weekday - 1));
                  final end = now.add(Duration(days: 7 - now.weekday));
                  setState(() {
                    _startDate = DateTime(start.year, start.month, start.day);
                    _endDate = DateTime(end.year, end.month, end.day);
                  });
                  _applyFilters();
                }, isActive: false),
                const SizedBox(width: 8),
                _buildQuickDateChip('This Month', () {
                  final now = DateTime.now();
                  setState(() {
                    _startDate = DateTime(now.year, now.month, 1);
                    _endDate = DateTime(now.year, now.month + 1, 0);
                  });
                  _applyFilters();
                }, isActive: false),
                const SizedBox(width: 8),
                _buildQuickDateChip('Last Month', () {
                  final now = DateTime.now();
                  setState(() {
                    _startDate = DateTime(now.year, now.month - 1, 1);
                    _endDate = DateTime(now.year, now.month, 0);
                  });
                  _applyFilters();
                }, isActive: false),
                const SizedBox(width: 8),
                _buildQuickDateChip('Clear', () {
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  setState(() {
                    _startDate = today;
                    _endDate = today;
                  });
                  _applyFilters();
                }, isActive: false),
                // Show applied filter info with today highlight
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (_isToday(_startDate) && _isToday(_endDate))
                        ? SiporaTheme.greenBg
                        : theme.cream,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (_isToday(_startDate) && _isToday(_endDate))
                          ? SiporaTheme.greenMid.withValues(alpha: 0.3)
                          : theme.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isToday(_startDate) && _isToday(_endDate))
                        Icon(
                          Icons.today_rounded,
                          size: 12,
                          color: SiporaTheme.greenMid,
                        ),
                      if (_isToday(_startDate) && _isToday(_endDate))
                        const SizedBox(width: 4),
                      Text(
                        _isToday(_startDate) && _isToday(_endDate)
                            ? 'Today'
                            : '${_formatDateShort(_startDate)} - ${_formatDateShort(_endDate)}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: _isToday(_startDate) && _isToday(_endDate)
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: _isToday(_startDate) && _isToday(_endDate)
                              ? SiporaTheme.greenMid
                              : theme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search & Sort Row
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cream,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.border),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      _applyFilters();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search receipts...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: theme.textMuted,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: theme.textMuted,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                setState(() => _searchQuery = '');
                                _applyFilters();
                              },
                              icon: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: theme.textMuted,
                              ),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      isDense: true,
                    ),
                    style: TextStyle(fontSize: 13, color: theme.textDark),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: theme.cream,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortOption,
                    icon: Icon(
                      Icons.sort_rounded,
                      size: 18,
                      color: theme.textMuted,
                    ),
                    style: TextStyle(fontSize: 12, color: theme.textDark),
                    items: const [
                      DropdownMenuItem(
                        value: 'date_desc',
                        child: Text('Newest'),
                      ),
                      DropdownMenuItem(
                        value: 'date_asc',
                        child: Text('Oldest'),
                      ),
                      DropdownMenuItem(
                        value: 'amount_desc',
                        child: Text('Highest'),
                      ),
                      DropdownMenuItem(
                        value: 'amount_asc',
                        child: Text('Lowest'),
                      ),
                      DropdownMenuItem(
                        value: 'items_desc',
                        child: Text('Most Items'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _sortOption = value);
                        _applyFilters();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Type Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTypeChip(
                  ReceiptType.cash,
                  'Cash',
                  const Color(0xFF22C55E),
                ),
                const SizedBox(width: 8),
                _buildTypeChip(ReceiptType.qr, 'QR', const Color(0xFFA855F7)),
                const SizedBox(width: 8),
                _buildTypeChip(
                  ReceiptType.invoice,
                  'Invoice',
                  const Color(0xFF3B82F6),
                ),
              ],
            ),
          ),

          // Filter info summary
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${_groupedReceipts.length} orders',
                style: TextStyle(fontSize: 11, color: theme.textMuted),
              ),
              if (_isToday(_startDate) && _isToday(_endDate))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: SiporaTheme.greenBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'TODAY',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: SiporaTheme.greenMid,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDateChip(
    String label,
    VoidCallback onTap, {
    required bool isActive,
  }) {
    final theme = context.siporaTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? SiporaTheme.greenBg : theme.cream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? SiporaTheme.greenMid : theme.border,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? SiporaTheme.greenMid : theme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(ReceiptType type, String label, Color color) {
    final isSelected = _selectedTypes.contains(type);
    final theme = context.siporaTheme;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getTypeIcon(type),
            size: 14,
            color: isSelected ? Colors.white : color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : theme.textDark,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedTypes.add(type);
          } else {
            _selectedTypes.remove(type);
            if (_selectedTypes.isEmpty) {
              _selectedTypes = {
                ReceiptType.cash,
                ReceiptType.qr,
                ReceiptType.invoice,
              };
            }
          }
          _applyFilters();
        });
      },
      backgroundColor: theme.white,
      selectedColor: color,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? Colors.transparent : theme.border,
        width: 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    );
  }

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
          _startDate = DateTime(date.year, date.month, date.day);
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = DateTime(date.year, date.month, date.day);
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate;
          }
        }
      });
      _applyFilters();
    }
  }

  // ─── Summary Cards ──────────────────────────
  Widget _buildSummaryCards() {
    final summary = _calculateSummary();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildSummaryCard(
            label: 'Orders',
            value: '${summary.totalOrders}',
            icon: Icons.receipt_rounded,
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(width: 12),
          _buildSummaryCard(
            label: 'Revenue',
            value: _formatCurrency(summary.totalRevenue),
            icon: Icons.currency_rupee_rounded,
            color: const Color(0xFF22C55E),
          ),
          const SizedBox(width: 12),
          _buildSummaryCard(
            label: 'Items',
            value: '${summary.totalItems}',
            icon: Icons.shopping_bag_rounded,
            color: const Color(0xFFA855F7),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = context.siporaTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: theme.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.border.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(icon, size: 12, color: color),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: theme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Receipts List ──────────────────────────
  Widget _buildReceiptsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _groupedReceipts.length,
      itemBuilder: (context, index) {
        final group = _groupedReceipts[index];
        return _buildReceiptCard(group);
      },
    );
  }

  Widget _buildReceiptCard(GroupedReceipt group) {
    final theme = context.siporaTheme;
    final isExpanded = _expandedReceiptId == group.receiptId;
    final typeColor = _getTypeColor(group.receiptType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.border.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _expandedReceiptId = isExpanded ? null : group.receiptId;
              });
            },
            splashColor: typeColor.withValues(alpha: 0.05),
            highlightColor: typeColor.withValues(alpha: 0.02),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              typeColor,
                              typeColor.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getTypeIcon(group.receiptType),
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  group.shortId,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: theme.textDark,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: typeColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    group.typeLabel,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: typeColor,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                // Show TODAY badge for today's orders
                                if (group.orderCreatedAt != null &&
                                    _isToday(group.orderCreatedAt!))
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: SiporaTheme.greenBg,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: SiporaTheme.greenMid.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'Today',
                                      style: TextStyle(
                                        fontSize: 7,
                                        fontWeight: FontWeight.w700,
                                        color: SiporaTheme.greenMid,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(group.orderCreatedAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: SiporaTheme.greenBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatCurrency(group.grandTotal),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: SiporaTheme.greenDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: theme.border.withValues(alpha: 0.5)),
                  const SizedBox(height: 8),
                  // Bottom row: items count, status, actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 14,
                            color: theme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${group.totalItems} items',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Only show "Served" badge when delivered
                          if (group.isDelivered)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF22C55E,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 12,
                                    color: const Color(0xFF22C55E),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Served',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF22C55E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // No "Ready" button here - it's shown in expanded section
                          const SizedBox(width: 8),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: theme.textMuted,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Expanded details
                  if (isExpanded) ...[
                    const SizedBox(height: 16),
                    Divider(color: theme.border.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    // Items list
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.cream,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: group.items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    item.productName ?? 'N/A',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: theme.textDark,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '×${item.quantity}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _formatCurrency(item.itemTotal),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: SiporaTheme.greenDark,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Total breakdown
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.cream,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildTotalRow('Subtotal', group.totalAmount, theme),
                          const SizedBox(height: 4),
                          _buildTotalRow(
                            'Tax (CGST+SGST)',
                            group.totalTax,
                            theme,
                          ),
                          const SizedBox(height: 8),
                          Divider(color: theme.border.withValues(alpha: 0.5)),
                          const SizedBox(height: 8),
                          _buildTotalRow(
                            'Grand Total',
                            group.grandTotal,
                            theme,
                            isBold: true,
                            isLarge: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // "Ready" button - shown at bottom after Grand Total, only when expanded and not delivered
                    if (!group.isDelivered &&
                        group.receiptType != ReceiptType.invoice)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _markAsDelivered(group),
                          icon: Icon(
                            Icons.check_circle_outline_rounded,
                            size: 18,
                          ),
                          label: Text(
                            'Mark as Served',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SiporaTheme.greenMid,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Print button for served items
                    if (group.isDelivered)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Print functionality
                          },
                          icon: Icon(
                            Icons.print_rounded,
                            size: 18,
                            color: theme.textMuted,
                          ),
                          label: Text(
                            'Print Receipt',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.textDark,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: theme.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    double amount,
    SiporaThemeExtension theme, {
    bool isBold = false,
    bool isLarge = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 14 : 12,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: isLarge ? theme.textDark : theme.textMuted,
          ),
        ),
        Text(
          _formatCurrency(amount),
          style: TextStyle(
            fontSize: isLarge ? 18 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isLarge ? SiporaTheme.greenDark : theme.textDark,
          ),
        ),
      ],
    );
  }

  Future<void> _markAsDelivered(GroupedReceipt group) async {
    final success = await ReceiptsService.markAsDelivered(
      group.receiptId,
      group.receiptType,
    );

    if (success && mounted) {
      setState(() {
        for (final item in group.items) {
          item.delivered = 1;
        }
        group.delivered = 1;
      });
      SiporaTheme.showSnackBar(
        context,
        'Order marked as served',
        isError: false,
      );
    } else if (mounted) {
      SiporaTheme.showSnackBar(
        context,
        'Failed to update status',
        isError: true,
      );
    }
  }
}

// ─── Franchise Owner Model ─────────────────────────────

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
