// invoice_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../config/api_config.dart';
import '../../../services/jwt_service.dart';
import '../../../services/storage_service.dart';
import '../../../theme/sipora_theme.dart';
import '../../../utils/responsive_constants.dart';
import '../../product_review/services/rating_service.dart';
import '../../product_review/widgets/rating_stars.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage>
    with SingleTickerProviderStateMixin {
  List<Invoice> _invoices = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _userId;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  final Map<String, Map<String, double>> _invoiceRatings = {};

  // Cache for franchise names
  final Map<String, String> _franchiseNameCache = {};

  // Cache for show_gst flag per product
  final Map<String, bool> _productShowGstCache = {};

  // Helper: Format amount with rounding for 0.01 issues
  String _formatAmount(double value) {
    // Round to 2 decimal places
    double rounded = (value * 100).round() / 100;

    // Get the decimal part as integer (cents)
    int cents = ((rounded * 100).round()) % 100;

    // If value is 0.01 or less, show as 0.00
    // This hides floating-point precision discrepancies where 0 should be 0.01
    if (value <= 0.01) {
      return '0.00';
    }

    // Only apply rounding for values > 1.0
    if (value > 1.0) {
      // If the value is within 0.01 of a whole number, round to whole number
      // This handles: 35.01 -> 35.00, 29.99 -> 30.00, 34.99 -> 35.00
      if (cents == 1) {
        // 35.01 -> 35.00 (subtract 0.01)
        rounded = rounded - 0.01;
      } else if (cents == 99) {
        // 34.99 -> 35.00 (add 0.01)
        rounded = rounded + 0.01;
      }
    }

    return NumberFormat('#,##0.00').format(rounded);
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animationController.forward();
    _initializeAndLoadInvoices();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreInvoices();
    }
  }

  Future<void> _initializeAndLoadInvoices() async {
    await _getUserId();
    if (_userId != null) {
      await _loadInvoices();
    }
  }

  Future<void> _getUserId() async {
    try {
      _userId = await StorageService.getUserId();
      if (_userId == null) {
        final prefs = await SharedPreferences.getInstance();
        _userId = prefs.getString('user_id');
        if (_userId == null) {
          final token = prefs.getString('tea_app_token');
          if (token != null) {
            _userId = JwtService.extractUserId(token);
          }
        }
      }
    } catch (e) {
      // Error getting user ID
    }
  }

  // Fetch show_gst flag for a product
  Future<bool> _getProductShowGst(String productId) async {
    // Check cache first
    if (_productShowGstCache.containsKey(productId)) {
      return _productShowGstCache[productId]!;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/product-information/$productId'),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final showGst = data['show_gst'] == 1 || data['show_gst'] == true;
        _productShowGstCache[productId] = showGst;
        return showGst;
      }
    } catch (e) {
      // If fetch fails, default to false (hide GST)
    }

    // Default to false if we can't determine
    _productShowGstCache[productId] = false;
    return false;
  }

  // Batch fetch show_gst flags
  Future<void> _fetchProductShowGstFlags(List<Invoice> invoices) async {
    final Set<String> productIds = {};
    for (var invoice in invoices) {
      for (var product in invoice.products) {
        if (product.productId.isNotEmpty &&
            !_productShowGstCache.containsKey(product.productId)) {
          productIds.add(product.productId);
        }
      }
    }

    if (productIds.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/product-show-gst'),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({'product_ids': productIds.toList()}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final showGstMap = data['data'] as Map<String, dynamic>;
          showGstMap.forEach((id, value) {
            _productShowGstCache[id] = value == 1 || value == true;
          });
        }
      }
    } catch (e) {
      // Silent fail - default to false for all
      for (var id in productIds) {
        _productShowGstCache[id] = false;
      }
    }
  }

  // Check if ALL products in the invoice have show_gst = true
  // Only show GST breakdown if ALL products have show_gst = 1
  bool _shouldShowGst(Invoice invoice) {
    if (invoice.products.isEmpty) return false;

    for (var product in invoice.products) {
      if (product.productId.isNotEmpty) {
        final showGst = _productShowGstCache[product.productId] ?? false;
        // If ANY product has show_gst = false, hide GST breakdown
        if (!showGst) {
          return false;
        }
      } else {
        // If product ID is empty, default to false
        return false;
      }
    }
    // All products have show_gst = true
    return true;
  }

  Future<void> _fetchFranchiseNames(List<Invoice> invoices) async {
    final Set<String> franchiseIds = {};
    for (var invoice in invoices) {
      if (invoice.franchiseId != null &&
          invoice.franchiseId!.isNotEmpty &&
          !_franchiseNameCache.containsKey(invoice.franchiseId)) {
        franchiseIds.add(invoice.franchiseId!);
      }
    }

    if (franchiseIds.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/franchise-names'),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({'franchise_ids': franchiseIds.toList()}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final names = data['data'] as Map<String, dynamic>;
          names.forEach((id, name) {
            _franchiseNameCache[id] = name?.toString() ?? id;
          });
        }
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _loadInvoices() async {
    if (_userId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load invoices. Please login again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _invoices = [];
      _invoiceRatings.clear();
    });

    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/customer-invoices/customer-invoice-list/$_userId'
        '?page=$_currentPage&page_size=20',
      );

      final response = await http.get(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        List<dynamic> invoicesData = [];

        if (responseData is List) {
          invoicesData = responseData;
          _totalPages = 1;
          _hasMore = false;
        } else if (responseData['data'] != null) {
          if (responseData['data'] is List) {
            invoicesData = responseData['data'];
          } else if (responseData['data']['items'] != null) {
            invoicesData = responseData['data']['items'];
            _totalPages = responseData['data']['total_pages'] ?? 1;
            _hasMore = _currentPage < _totalPages;
          } else {
            invoicesData = [];
          }
        } else if (responseData['items'] != null) {
          invoicesData = responseData['items'];
          _totalPages = responseData['total_pages'] ?? 1;
          _hasMore = _currentPage < _totalPages;
        } else {
          invoicesData = [];
        }

        final Map<String, List<dynamic>> groupedInvoices = {};
        for (var item in invoicesData) {
          final receiptId = item['receipt_id']?.toString() ?? '';
          if (receiptId.isNotEmpty) {
            if (!groupedInvoices.containsKey(receiptId)) {
              groupedInvoices[receiptId] = [];
            }
            groupedInvoices[receiptId]!.add(item);
          }
        }

        final List<Invoice> groupedInvoiceList = [];
        for (var entry in groupedInvoices.entries) {
          final items = entry.value;
          if (items.isNotEmpty) {
            final firstItem = items[0];

            List<ProductItem> allProducts = [];
            double totalAmount = 0;
            double totalCgst = 0;
            double totalSgst = 0;
            double itemTotal = 0;
            double discount = 0;

            for (var item in items) {
              allProducts.add(
                ProductItem(
                  productId: item['products_id']?.toString() ?? '',
                  productName:
                      item['product_name']?.toString() ?? 'Unknown Product',
                  quantity: (item['quantity'] as num?)?.toInt() ?? 0,
                  unitAmount: (item['unit_amount'] as num?)?.toDouble() ?? 0,
                  unitCgst: (item['unit_cgst'] as num?)?.toDouble() ?? 0,
                  unitSgst: (item['unit_sgst'] as num?)?.toDouble() ?? 0,
                  unitGstRate: (item['unit_gst_rate'] as num?)?.toDouble() ?? 0,
                ),
              );

              totalAmount += (item['total_amount'] as num?)?.toDouble() ?? 0;
              totalCgst += (item['total_cgst'] as num?)?.toDouble() ?? 0;
              totalSgst += (item['total_sgst'] as num?)?.toDouble() ?? 0;
              itemTotal += (item['item_total'] as num?)?.toDouble() ?? 0;
              discount += (item['discount'] as num?)?.toDouble() ?? 0;
            }

            DateTime timestamp;
            try {
              timestamp = DateTime.parse(
                firstItem['timestamp'].toString().replaceFirst(' ', 'T'),
              );
            } catch (e) {
              timestamp = DateTime.now();
            }

            groupedInvoiceList.add(
              Invoice(
                id: firstItem['id']?.toString() ?? '',
                userId: firstItem['user_id']?.toString() ?? '',
                franchiseId: firstItem['franchise_id']?.toString(),
                receiptId: entry.key,
                products: allProducts,
                totalAmount: totalAmount,
                totalCgst: totalCgst,
                totalSgst: totalSgst,
                itemTotal: itemTotal,
                discount: discount,
                timestamp: timestamp,
                discountPercentage:
                    (firstItem['discount_percentage'] as num?)?.toDouble() ?? 0,
              ),
            );
          }
        }

        // Fetch franchise names and show_gst flags
        await _fetchFranchiseNames(groupedInvoiceList);
        await _fetchProductShowGstFlags(groupedInvoiceList);

        setState(() {
          _invoices = groupedInvoiceList
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
          _isLoading = false;
        });
        _loadRatingsForInvoices(groupedInvoiceList);
      } else if (response.statusCode == 422) {
        setState(() {
          _errorMessage = 'Invalid user ID format. Please contact support.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load invoices. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreInvoices() async {
    if (!_hasMore || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      _currentPage++;
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/customer-invoices/customer-invoice-list/$_userId'
        '?page=$_currentPage&page_size=20',
      );

      final response = await http.get(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        List<dynamic> invoicesData = [];

        if (responseData is List) {
          invoicesData = responseData;
          _hasMore = false;
        } else if (responseData['data'] != null) {
          if (responseData['data'] is List) {
            invoicesData = responseData['data'];
          } else if (responseData['data']['items'] != null) {
            invoicesData = responseData['data']['items'];
            _hasMore =
                _currentPage < (responseData['data']['total_pages'] ?? 1);
          }
        } else if (responseData['items'] != null) {
          invoicesData = responseData['items'];
          _hasMore = _currentPage < (responseData['total_pages'] ?? 1);
        }

        final Map<String, List<dynamic>> groupedInvoices = {};
        for (var item in invoicesData) {
          final receiptId = item['receipt_id']?.toString() ?? '';
          if (receiptId.isNotEmpty) {
            if (!groupedInvoices.containsKey(receiptId)) {
              groupedInvoices[receiptId] = [];
            }
            groupedInvoices[receiptId]!.add(item);
          }
        }

        final existingReceiptIds = _invoices
            .map((inv) => inv.receiptId)
            .toSet();
        final List<Invoice> newInvoices = [];

        for (var entry in groupedInvoices.entries) {
          if (existingReceiptIds.contains(entry.key)) continue;

          final items = entry.value;
          if (items.isNotEmpty) {
            final firstItem = items[0];

            List<ProductItem> allProducts = [];
            double totalAmount = 0;
            double totalCgst = 0;
            double totalSgst = 0;
            double itemTotal = 0;
            double discount = 0;

            for (var item in items) {
              allProducts.add(
                ProductItem(
                  productId: item['products_id']?.toString() ?? '',
                  productName:
                      item['product_name']?.toString() ?? 'Unknown Product',
                  quantity: (item['quantity'] as num?)?.toInt() ?? 0,
                  unitAmount: (item['unit_amount'] as num?)?.toDouble() ?? 0,
                  unitCgst: (item['unit_cgst'] as num?)?.toDouble() ?? 0,
                  unitSgst: (item['unit_sgst'] as num?)?.toDouble() ?? 0,
                  unitGstRate: (item['unit_gst_rate'] as num?)?.toDouble() ?? 0,
                ),
              );

              totalAmount += (item['total_amount'] as num?)?.toDouble() ?? 0;
              totalCgst += (item['total_cgst'] as num?)?.toDouble() ?? 0;
              totalSgst += (item['total_sgst'] as num?)?.toDouble() ?? 0;
              itemTotal += (item['item_total'] as num?)?.toDouble() ?? 0;
              discount += (item['discount'] as num?)?.toDouble() ?? 0;
            }

            DateTime timestamp;
            try {
              timestamp = DateTime.parse(
                firstItem['timestamp'].toString().replaceFirst(' ', 'T'),
              );
            } catch (e) {
              timestamp = DateTime.now();
            }

            final invoice = Invoice(
              id: firstItem['id']?.toString() ?? '',
              userId: firstItem['user_id']?.toString() ?? '',
              franchiseId: firstItem['franchise_id']?.toString(),
              receiptId: entry.key,
              products: allProducts,
              totalAmount: totalAmount,
              totalCgst: totalCgst,
              totalSgst: totalSgst,
              itemTotal: itemTotal,
              discount: discount,
              timestamp: timestamp,
              discountPercentage:
                  (firstItem['discount_percentage'] as num?)?.toDouble() ?? 0,
            );

            newInvoices.add(invoice);
          }
        }

        await _fetchFranchiseNames(newInvoices);
        await _fetchProductShowGstFlags(newInvoices);

        setState(() {
          _invoices.addAll(newInvoices);
          _isLoadingMore = false;
          _invoices.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        });
        _loadRatingsForInvoices(newInvoices);
      } else {
        setState(() {
          _isLoadingMore = false;
          _hasMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadRatingsForInvoices(List<Invoice> invoices) async {
    final userId = _userId;
    if (userId == null || userId.isEmpty || invoices.isEmpty) return;

    final Map<String, Map<String, double>> loadedRatings = {};

    await Future.wait(
      invoices.map((invoice) async {
        final ratings = <String, double>{};
        await Future.wait(
          invoice.products.map((product) async {
            if (product.productId.isEmpty) return;
            final data = await RatingService.getProductRatingData(
              userId: userId,
              productId: product.productId,
            );
            if (data?.rating != null) {
              ratings[product.productId] = data!.rating!;
            }
          }),
        );
        loadedRatings[invoice.receiptId] = ratings;
      }),
    );

    if (!mounted) return;
    setState(() {
      _invoiceRatings.addAll(loadedRatings);
    });
  }

  bool _hasRatedInvoice(Invoice invoice) {
    final ratings = _invoiceRatings[invoice.receiptId] ?? {};
    final productIds = invoice.products
        .map((product) => product.productId)
        .where((productId) => productId.isNotEmpty)
        .toSet();
    return productIds.isNotEmpty &&
        productIds.every((productId) => ratings.containsKey(productId));
  }

  double? _invoiceRatingValue(Invoice invoice) {
    final ratings = _invoiceRatings[invoice.receiptId]?.values.toList() ?? [];
    if (ratings.isEmpty) return null;
    return ratings.reduce((total, rating) => total + rating) / ratings.length;
  }

  void _updateInvoiceRatings(Invoice invoice, Map<String, double> ratings) {
    setState(() {
      _invoiceRatings[invoice.receiptId] = {
        ...?_invoiceRatings[invoice.receiptId],
        ...ratings,
      };
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;

    return Scaffold(
      backgroundColor: theme.cream,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _animationController,
        child: _isLoading
            ? _buildLoadingState()
            : _errorMessage != null
            ? _buildErrorState()
            : _invoices.isEmpty
            ? _buildEmptyState()
            : _buildInvoicesList(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final theme = context.siporaTheme;

    return AppBar(
      backgroundColor: theme.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
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
        'Order History',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: theme.textDark,
          letterSpacing: -0.5,
        ),
      ),
      centerTitle: true,
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
            'Loading invoices...',
            style: TextStyle(
              fontSize: ResponsiveConstants.getFontSize(context),
              color: theme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = context.siporaTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: theme.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: ResponsiveConstants.getFontSize(context),
              color: theme.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadInvoices,
            style: ElevatedButton.styleFrom(
              backgroundColor: SiporaTheme.greenMid,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Retry'),
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
            'No orders found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: theme.textDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your order history will appear here',
            style: TextStyle(fontSize: 14, color: theme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _invoices.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _invoices.length) {
          return _buildLoadingMoreIndicator();
        }
        final invoice = _invoices[index];
        return _buildInvoiceCard(invoice);
      },
    );
  }

  Widget _buildLoadingMoreIndicator() {
    final theme = context.siporaTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(SiporaTheme.greenDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading more...',
              style: TextStyle(fontSize: 12, color: theme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    final theme = context.siporaTheme;
    final hasRated = _hasRatedInvoice(invoice);
    final ratingValue = _invoiceRatingValue(invoice);

    String franchiseName = 'Sipora Store';
    if (invoice.franchiseId != null && invoice.franchiseId!.isNotEmpty) {
      franchiseName =
          _franchiseNameCache[invoice.franchiseId] ?? invoice.franchiseId!;
    }

    // Check if we should show GST for this invoice
    // Only shows if ALL products have show_gst = 1
    final showGst = _shouldShowGst(invoice);

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
            onTap: () => _showInvoiceDetails(invoice, showGst),
            splashColor: SiporaTheme.greenMid.withValues(alpha: 0.05),
            highlightColor: SiporaTheme.greenMid.withValues(alpha: 0.02),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                              SiporaTheme.greenMid,
                              SiporaTheme.greenDark,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.receipt_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Shop Name with label
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [
                                  const TextSpan(text: 'Shop: '),
                                  TextSpan(
                                    text: franchiseName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: SiporaTheme.greenDark,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            // Order ID with label
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [
                                  const TextSpan(text: 'Ord ID: '),
                                  TextSpan(
                                    text: invoice.receiptId,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: theme.textDark,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            // Date
                            Text(
                              DateFormat(
                                'dd MMM yyyy, hh:mm a',
                              ).format(invoice.timestamp),
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
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: SiporaTheme.greenBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '₹${_formatAmount(invoice.itemTotal)}',
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoChip(
                        icon: Icons.shopping_bag_outlined,
                        label: '${invoice.products.length} items',
                      ),
                      if (invoice.discount > 0)
                        _buildInfoChip(
                          icon: Icons.percent_rounded,
                          label:
                              'Discount: ₹${_formatAmount(invoice.discount)}',
                        ),
                      // Show GST badge only if ALL products have show_gst = 1
                      if (showGst)
                        _buildInfoChip(
                          icon: Icons.receipt_long_rounded,
                          label: 'GST Included',
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: theme.border.withValues(alpha: 0.5)),
                  hasRated && ratingValue != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            children: [
                              Text(
                                'Your rating:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.textMuted,
                                ),
                              ),
                              const SizedBox(width: 8),
                              RatingStars(
                                rating: ratingValue,
                                size: 18,
                                activeColor: const Color(0xFFE91E63),
                              ),
                            ],
                          ),
                        )
                      : InkWell(
                          onTap: () => _showRateOrderSheet(invoice),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: Text(
                                'Rate Order',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: theme.textDark,
                                ),
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    final theme = context.siporaTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cream,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.textMuted),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: theme.textMuted)),
        ],
      ),
    );
  }

  void _showInvoiceDetails(Invoice invoice, bool showGst) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InvoiceDetailsSheet(
        invoice: invoice,
        userId: _userId,
        ratings: _invoiceRatings[invoice.receiptId] ?? {},
        onRatingsChanged: (ratings) => _updateInvoiceRatings(invoice, ratings),
        onRateOrder: () => _showRateOrderSheet(invoice),
        franchiseName:
            invoice.franchiseId != null && invoice.franchiseId!.isNotEmpty
            ? _franchiseNameCache[invoice.franchiseId] ?? invoice.franchiseId!
            : 'Sipora Store',
        showGst: showGst,
      ),
    );
  }

  void _showRateOrderSheet(Invoice invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RateOrderSheet(
        invoice: invoice,
        userId: _userId,
        ratings: _invoiceRatings[invoice.receiptId] ?? {},
        onRatingsChanged: (ratings) => _updateInvoiceRatings(invoice, ratings),
      ),
    );
  }
}

// Invoice Model
class Invoice {
  final String id;
  final String userId;
  final String? franchiseId;
  final String receiptId;
  final List<ProductItem> products;
  final double totalAmount;
  final double totalCgst;
  final double totalSgst;
  final double itemTotal;
  final double discount;
  final DateTime timestamp;
  final double discountPercentage;

  Invoice({
    required this.id,
    required this.userId,
    this.franchiseId,
    required this.receiptId,
    required this.products,
    required this.totalAmount,
    required this.totalCgst,
    required this.totalSgst,
    required this.itemTotal,
    required this.discount,
    required this.timestamp,
    required this.discountPercentage,
  });

  double get subtotal {
    return products.fold(0.0, (sum, product) => sum + product.grandTotal);
  }
}

class ProductItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitAmount;
  final double unitCgst;
  final double unitSgst;
  final double unitGstRate;

  ProductItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitAmount,
    required this.unitCgst,
    required this.unitSgst,
    required this.unitGstRate,
  });

  double get totalAmount => unitAmount * quantity;
  double get totalCgst => unitCgst * quantity;
  double get totalSgst => unitSgst * quantity;
  double get totalGst => totalCgst + totalSgst;
  double get grandTotal => totalAmount + totalGst;
}

// Invoice Details Bottom Sheet
class InvoiceDetailsSheet extends StatelessWidget {
  final Invoice invoice;
  final String? userId;
  final Map<String, double> ratings;
  final ValueChanged<Map<String, double>> onRatingsChanged;
  final VoidCallback onRateOrder;
  final String franchiseName;
  final bool showGst;

  const InvoiceDetailsSheet({
    super.key,
    required this.invoice,
    required this.userId,
    required this.ratings,
    required this.onRatingsChanged,
    required this.onRateOrder,
    required this.franchiseName,
    this.showGst = false,
  });

  // Helper: Format amount with rounding for 0.01 issues
  String _formatAmount(double value) {
    // Round to 2 decimal places
    double rounded = (value * 100).round() / 100;

    // Get the decimal part as integer (cents)
    int cents = ((rounded * 100).round()) % 100;

    // If value is 0.01 or less, show as 0.00
    // This hides floating-point precision discrepancies where 0 should be 0.01
    if (value <= 0.01) {
      return '0.00';
    }

    // Only apply rounding for values > 1.0
    if (value > 1.0) {
      // If the value is within 0.01 of a whole number, round to whole number
      // This handles: 35.01 -> 35.00, 29.99 -> 30.00, 34.99 -> 35.00
      if (cents == 1) {
        // 35.01 -> 35.00 (subtract 0.01)
        rounded = rounded - 0.01;
      } else if (cents == 99) {
        // 34.99 -> 35.00 (add 0.01)
        rounded = rounded + 0.01;
      }
    }

    return NumberFormat('#,##0.00').format(rounded);
  }

  bool get _hasRatedOrder {
    final productIds = invoice.products
        .map((product) => product.productId)
        .where((productId) => productId.isNotEmpty)
        .toSet();
    return productIds.isNotEmpty &&
        productIds.every((productId) => ratings.containsKey(productId));
  }

  double? get _orderRating {
    if (ratings.isEmpty) return null;
    final values = ratings.values.toList();
    return values.reduce((total, rating) => total + rating) / values.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.border.withValues(alpha: 0.5)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [SiporaTheme.greenMid, SiporaTheme.greenDark],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: theme.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        franchiseName,
                        style: TextStyle(
                          fontSize: 12,
                          color: SiporaTheme.greenMid,
                        ),
                      ),
                      Text(
                        'Order Id: ${invoice.receiptId}',
                        style: TextStyle(fontSize: 13, color: theme.textMuted),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.cream,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: theme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and Time
                  _buildInfoRow(
                    context,
                    'Date & Time',
                    DateFormat(
                      'dd MMM yyyy, hh:mm a',
                    ).format(invoice.timestamp),
                  ),
                  const SizedBox(height: 16),

                  // Products Section
                  Text(
                    'Products',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.cream,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Product',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textMuted,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Qty',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textMuted,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Amount',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: theme.border),
                        ...invoice.products.asMap().entries.map((entry) {
                          final index = entry.key;
                          final product = entry.value;
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.productName,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: theme.textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          // Only show GST rate if showGst is true
                                          if (showGst)
                                            Text(
                                              'GST: ${product.unitGstRate}%',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: theme.textMuted,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        '${product.quantity}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: theme.textDark,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        // Use formatted amount with rounding
                                        '₹${_formatAmount(product.grandTotal)}',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: SiporaTheme.greenDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (index < invoice.products.length - 1)
                                Divider(height: 1, color: theme.border),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildRatingSection(context),
                  const SizedBox(height: 20),

                  // Pricing Summary - Only show GST breakdown if ALL products have show_gst = 1
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cream,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow(
                          context,
                          'Subtotal',
                          '₹${_formatAmount(invoice.subtotal)}',
                        ),
                        if (invoice.discount > 0) ...[
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            context,
                            'Discount',
                            '- ₹${_formatAmount(invoice.discount)}',
                            isNegative: true,
                          ),
                        ],
                        // Only show GST breakdown if ALL products have show_gst = 1
                        if (showGst) ...[
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            context,
                            'CGST (${(invoice.totalCgst / (invoice.totalAmount + invoice.totalCgst + invoice.totalSgst) * 100).toStringAsFixed(1)}%)',
                            '₹${_formatAmount(invoice.totalCgst)}',
                          ),
                          const SizedBox(height: 4),
                          _buildSummaryRow(
                            context,
                            'SGST (${(invoice.totalSgst / (invoice.totalAmount + invoice.totalCgst + invoice.totalSgst) * 100).toStringAsFixed(1)}%)',
                            '₹${_formatAmount(invoice.totalSgst)}',
                          ),
                        ],
                        const SizedBox(height: 8),
                        Divider(height: 16, color: theme.border),
                        _buildSummaryRow(
                          context,
                          'Total Amount',
                          '₹${_formatAmount(invoice.itemTotal)}',
                          isBold: true,
                          isLarge: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Footer Note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SiporaTheme.greenBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: SiporaTheme.greenMid.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: SiporaTheme.greenMid,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Thank you for shopping with Sipora!',
                            style: TextStyle(
                              fontSize: 12,
                              color: SiporaTheme.greenMid,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildRatingSection(BuildContext context) {
    final theme = context.siporaTheme;
    final rating = _orderRating;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: _hasRatedOrder && rating != null
          ? Row(
              children: [
                Expanded(
                  child: Text(
                    'Your order rating',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.textDark,
                    ),
                  ),
                ),
                RatingStars(
                  rating: rating,
                  size: 20,
                  activeColor: const Color(0xFFE91E63),
                ),
              ],
            )
          : OutlinedButton.icon(
              onPressed: onRateOrder,
              icon: const Icon(Icons.star_border_rounded, size: 18),
              label: const Text('Rate Order'),
              style: OutlinedButton.styleFrom(
                foregroundColor: SiporaTheme.greenDark,
                side: BorderSide(color: SiporaTheme.greenMid),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = context.siporaTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: theme.textMuted)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    bool isNegative = false,
    bool isBold = false,
    bool isLarge = false,
  }) {
    final theme = context.siporaTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 15 : 13,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: isLarge ? theme.textDark : theme.textMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isLarge ? 18 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: isNegative
                ? Colors.red
                : isLarge
                ? SiporaTheme.greenDark
                : theme.textDark,
          ),
        ),
      ],
    );
  }
}

// Rate Order Bottom Sheet
class RateOrderSheet extends StatefulWidget {
  final Invoice invoice;
  final String? userId;
  final Map<String, double> ratings;
  final ValueChanged<Map<String, double>> onRatingsChanged;

  const RateOrderSheet({
    super.key,
    required this.invoice,
    required this.userId,
    required this.ratings,
    required this.onRatingsChanged,
  });

  @override
  State<RateOrderSheet> createState() => _RateOrderSheetState();
}

class _RateOrderSheetState extends State<RateOrderSheet> {
  bool _isOverallRating = true;
  double _overallRating = 0;
  final Map<String, double> _individualRatings = {};
  bool _isSubmitting = false;

  // Helper: Format amount with rounding for 0.01 issues
  String _formatAmount(double value) {
    // Round to 2 decimal places
    double rounded = (value * 100).round() / 100;

    // Get the decimal part as integer (cents)
    int cents = ((rounded * 100).round()) % 100;

    // If value is 0.01 or less, show as 0.00
    // This hides floating-point precision discrepancies where 0 should be 0.01
    if (value <= 0.01) {
      return '0.00';
    }

    // Only apply rounding for values > 1.0
    if (value > 1.0) {
      // If the value is within 0.01 of a whole number, round to whole number
      // This handles: 35.01 -> 35.00, 29.99 -> 30.00, 34.99 -> 35.00
      if (cents == 1) {
        // 35.01 -> 35.00 (subtract 0.01)
        rounded = rounded - 0.01;
      } else if (cents == 99) {
        // 34.99 -> 35.00 (add 0.01)
        rounded = rounded + 0.01;
      }
    }

    return NumberFormat('#,##0.00').format(rounded);
  }

  @override
  void initState() {
    super.initState();
    for (var product in widget.invoice.products) {
      _individualRatings[product.productId] =
          widget.ratings[product.productId] ?? 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.border.withValues(alpha: 0.5)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [SiporaTheme.greenMid, SiporaTheme.greenDark],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rate your order',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Order Id: ${widget.invoice.receiptId}',
                        style: TextStyle(fontSize: 13, color: theme.textMuted),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.cream,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: theme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.invoice.products.length > 1)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.cream,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _isOverallRating = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _isOverallRating
                                      ? theme.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: _isOverallRating
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  'Overall Rating',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: _isOverallRating
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: _isOverallRating
                                        ? theme.textDark
                                        : theme.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _isOverallRating = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: !_isOverallRating
                                      ? theme.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: !_isOverallRating
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  'Rate Individually',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: !_isOverallRating
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: !_isOverallRating
                                        ? theme.textDark
                                        : theme.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (_isOverallRating) ...[
                    _buildOverallRatingSection(context),
                  ] else ...[
                    ...widget.invoice.products.map(
                      (product) => _buildProductRatingSection(context, product),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRatings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SiporaTheme.greenMid,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Submit Rating',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
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

  Widget _buildOverallRatingSection(BuildContext context) {
    final theme = context.siporaTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Rate your delivery experience',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1.0;
              return GestureDetector(
                onTap: () => setState(() => _overallRating = starValue),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    starValue <= _overallRating
                        ? Icons.star
                        : Icons.star_border,
                    size: 40,
                    color: starValue <= _overallRating
                        ? const Color(0xFFFFC107)
                        : theme.textMuted,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'This rating will apply to all products in this order',
            style: TextStyle(fontSize: 12, color: theme.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductRatingSection(BuildContext context, ProductItem product) {
    final theme = context.siporaTheme;
    final rating = _individualRatings[product.productId] ?? 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.productName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1.0;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _individualRatings[product.productId] = starValue;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    starValue <= rating ? Icons.star : Icons.star_border,
                    size: 36,
                    color: starValue <= rating
                        ? const Color(0xFFFFC107)
                        : theme.textMuted,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRatings() async {
    if (widget.userId == null || widget.userId!.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      if (_isOverallRating) {
        final futures = widget.invoice.products.map((product) async {
          if (product.productId.isEmpty) return;
          await RatingService.rateProduct(
            userId: widget.userId!,
            productId: product.productId,
            rating: _overallRating,
          );
        });
        await Future.wait(futures);

        final updatedRatings = <String, double>{};
        for (var product in widget.invoice.products) {
          if (product.productId.isNotEmpty) {
            updatedRatings[product.productId] = _overallRating;
          }
        }
        widget.onRatingsChanged(updatedRatings);
      } else {
        final futures = _individualRatings.entries.map((entry) async {
          if (entry.value > 0 && entry.key.isNotEmpty) {
            await RatingService.rateProduct(
              userId: widget.userId!,
              productId: entry.key,
              rating: entry.value,
            );
          }
        });
        await Future.wait(futures);
        widget.onRatingsChanged(_individualRatings);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
