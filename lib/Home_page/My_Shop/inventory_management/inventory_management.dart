import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/sipora_theme.dart';
import '../../../utils/screen_utils.dart';
import '../../../services/storage_service.dart';
import '../../../config/api_config.dart';

// ─── Models ────────────────────────────────────────────────────────────────

class StockProduct {
  final String id;
  final String? franchiseId;
  final String? warehouseId;
  final String productName;
  final String category;
  final String subCategory;
  final String brand;
  final String productsImages;
  final int? quantity;
  final bool stock;
  final String source;

  StockProduct({
    required this.id,
    this.franchiseId,
    this.warehouseId,
    required this.productName,
    required this.category,
    required this.subCategory,
    required this.brand,
    required this.productsImages,
    this.quantity,
    required this.stock,
    required this.source,
  });

  factory StockProduct.fromJson(Map<String, dynamic> json) {
    return StockProduct(
      id: json['id'] ?? '',
      franchiseId: json['franchise_id'],
      warehouseId: json['warehouse_id'],
      productName: json['product_name'] ?? '',
      category: json['category'] ?? '',
      subCategory: json['sub_category'] ?? '',
      brand: json['brand'] ?? '',
      productsImages: json['products_images'] ?? '',
      quantity: json['quantity'],
      stock: json['stock'] ?? true,
      source: json['source'] ?? 'franchise',
    );
  }
}

class UserStockResponse {
  final bool success;
  final String message;
  final String userId;
  final String? franchiseId;
  final String? warehouseId;
  final List<StockProduct> franchiseProducts;
  final List<StockProduct> warehouseProducts;
  final int totalProducts;
  final Map<String, int> counts;

  UserStockResponse({
    required this.success,
    required this.message,
    required this.userId,
    this.franchiseId,
    this.warehouseId,
    required this.franchiseProducts,
    required this.warehouseProducts,
    required this.totalProducts,
    required this.counts,
  });

  factory UserStockResponse.fromJson(Map<String, dynamic> json) {
    final franchiseList =
        (json['franchise_products'] as List?)
            ?.map((e) => StockProduct.fromJson(e))
            .toList() ??
        [];
    final warehouseList =
        (json['warehouse_products'] as List?)
            ?.map((e) => StockProduct.fromJson(e))
            .toList() ??
        [];
    return UserStockResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      userId: json['user_id'] ?? '',
      franchiseId: json['franchise_id'],
      warehouseId: json['warehouse_id'],
      franchiseProducts: franchiseList,
      warehouseProducts: warehouseList,
      totalProducts: json['total_products'] ?? 0,
      counts: Map<String, int>.from(json['counts'] ?? {}),
    );
  }
}

class UpdateStockRequest {
  final String productId;
  final int? quantity;
  final bool stock;

  UpdateStockRequest({
    required this.productId,
    this.quantity,
    required this.stock,
  });

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'quantity': quantity,
    'stock': stock,
  };
}

// ─── Content Widget ────────────────────────────────────────────────────────

class InventoryManagementContent extends StatefulWidget {
  const InventoryManagementContent({super.key});

  @override
  State<InventoryManagementContent> createState() =>
      _InventoryManagementContentState();
}

class _InventoryManagementContentState
    extends State<InventoryManagementContent> {
  bool _isLoading = true;
  String? _error;
  String? _userId;
  List<StockProduct> _allProducts = [];
  List<StockProduct> _filteredProducts = [];
  bool _hasBothSources = false;

  // Search and filter
  String _searchQuery = '';
  String _activeFilter =
      'all'; // 'all', 'in_stock', 'out_of_stock', 'low_stock'

  int _currentPage = 1;
  final int _itemsPerPage = 10;
  int _totalPages = 1;

  String? _editingId;
  int? _editQuantity;
  bool _editStock = true;
  bool _isSaving = false;

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetch();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserIdAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    print('📱 Inventory: Retrieved userId from prefs: $userId');
    if (userId == null || userId.isEmpty) {
      if (mounted) {
        setState(() {
          _error = 'User not found. Please login again.';
          _isLoading = false;
        });
      }
      return;
    }
    setState(() => _userId = userId);
    await _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    if (_userId == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await StorageService.getToken();
      print(
        '📱 Inventory: Token retrieved: ${token != null ? '✅ present' : '❌ null'}',
      );
      if (token == null) {
        if (mounted) {
          setState(() {
            _error = 'Please login again';
            _isLoading = false;
          });
        }
        return;
      }

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/product/stock/user/${_userId}',
      );
      print('📱 Inventory: Fetching from URL: $url');

      final response = await http.get(
        url,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📱 Inventory: Response status: ${response.statusCode}');
      print('📱 Inventory: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('📱 Inventory: Parsed data: $data');

        if (data['success'] == true) {
          final userStock = UserStockResponse.fromJson(data);
          final allProducts = [
            ...userStock.franchiseProducts,
            ...userStock.warehouseProducts,
          ];
          final hasBoth =
              userStock.franchiseProducts.isNotEmpty &&
              userStock.warehouseProducts.isNotEmpty;

          print('📱 Inventory: Found ${allProducts.length} products');
          print(
            '📱 Inventory: Franchise count: ${userStock.franchiseProducts.length}',
          );
          print(
            '📱 Inventory: Warehouse count: ${userStock.warehouseProducts.length}',
          );

          if (mounted) {
            setState(() {
              _allProducts = allProducts;
              _filteredProducts = allProducts;
              _hasBothSources = hasBoth;
              _activeFilter = 'all';
              _searchQuery = '';
              _isLoading = false;
              _currentPage = 1;
              _updatePagination();
            });
          }
        } else {
          final errorMsg = data['message'] ?? 'Unknown error from server';
          print('📱 Inventory: API returned success=false: $errorMsg');
          if (mounted) {
            setState(() {
              _error = errorMsg;
              _isLoading = false;
            });
          }
        }
      } else if (response.statusCode == 404) {
        print('📱 Inventory: 404 - No products found for user');
        if (mounted) {
          setState(() {
            _allProducts = [];
            _filteredProducts = [];
            _isLoading = false;
            _error = null;
          });
        }
      } else {
        print('📱 Inventory: HTTP error ${response.statusCode}');
        if (mounted) {
          setState(() {
            _error = 'Failed to load stock data (${response.statusCode})';
            _isLoading = false;
          });
        }
      }
    } catch (e, stack) {
      print('📱 Inventory: Exception: $e');
      print('📱 Inventory: Stack trace: $stack');
      if (mounted) {
        setState(() {
          _error = 'Network error: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _updatePagination() {
    final total = _filteredProducts.length;
    _totalPages = total > 0 ? (total / _itemsPerPage).ceil() : 1;
    if (_currentPage > _totalPages) _currentPage = 1;
  }

  List<StockProduct> _getPaginatedData() {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _filteredProducts.length);
    return _filteredProducts.sublist(start, end);
  }

  // ── Filtering ──────────────────────────────────────────────────────────

  void _applyFilters() {
    final query = _searchQuery.toLowerCase().trim();
    final filter = _activeFilter;

    setState(() {
      _filteredProducts = _allProducts.where((p) {
        // Search filter
        final matchesSearch = p.productName.toLowerCase().contains(query);

        // Stat filter
        bool matchesFilter = true;
        switch (filter) {
          case 'in_stock':
            matchesFilter = p.stock == true;
            break;
          case 'out_of_stock':
            matchesFilter = p.stock == false;
            break;
          case 'low_stock':
            matchesFilter =
                p.stock == true && (p.quantity != null && p.quantity! < 10);
            break;
          case 'all':
          default:
            matchesFilter = true;
            break;
        }

        return matchesSearch && matchesFilter;
      }).toList();
      _currentPage = 1;
      _updatePagination();
    });
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _searchQuery = value;
      _applyFilters();
    });
  }

  void _setFilter(String filter) {
    if (_activeFilter == filter) return;
    setState(() {
      _activeFilter = filter;
      _applyFilters();
    });
  }

  // ── Edit handlers ──────────────────────────────────────────────────────

  void _startEdit(StockProduct product) {
    setState(() {
      _editingId = product.id;
      _editQuantity = product.quantity;
      _editStock = product.stock;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingId = null;
      _editQuantity = null;
      _editStock = true;
    });
  }

  Future<void> _saveEdit(String productId) async {
    if (_editingId != productId) return;
    setState(() => _isSaving = true);

    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final payload = UpdateStockRequest(
        productId: productId,
        quantity: _editQuantity,
        stock: _editStock,
      );

      final url = Uri.parse('${ApiConfig.baseUrl}/api/product/stock/update');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final updated = data['product'];
          if (updated != null) {
            final newProduct = StockProduct.fromJson(updated);
            setState(() {
              final index = _allProducts.indexWhere((p) => p.id == productId);
              if (index != -1) {
                _allProducts[index] = newProduct;
              }
              // Re-apply filters to update the displayed list
              _applyFilters();
              _editingId = null;
              _editQuantity = null;
              _editStock = true;
              _isSaving = false;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Stock updated successfully!'),
                  backgroundColor: SiporaTheme.greenMid,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        } else {
          throw Exception(data['message'] ?? 'Update failed');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  List<String> _parseImages(String images) {
    if (images.isEmpty) return ['/placeholder.png'];
    try {
      if (images.startsWith('[')) {
        final List<dynamic> list = json.decode(images);
        return list.map((e) => e.toString()).toList();
      }
      return images
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (_) {
      return [images];
    }
  }

  String _getStockBadgeText(bool stock) => stock ? 'In Stock' : 'Out of Stock';
  Color _getStockBadgeColor(bool stock) =>
      stock ? SiporaTheme.greenMid : Colors.red.shade400;
  Color _getStockBadgeBgColor(bool stock) => stock
      ? SiporaTheme.greenMid.withValues(alpha: 0.1)
      : Colors.red.shade400.withValues(alpha: 0.1);

  String _getSourceLabel(String source) =>
      source == 'warehouse' ? 'Warehouse' : 'Franchise';
  Color _getSourceColor(String source) =>
      source == 'warehouse' ? Colors.purple.shade600 : Colors.blue.shade600;
  IconData _getSourceIcon(String source) =>
      source == 'warehouse' ? Icons.warehouse : Icons.storefront;

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade400, size: 48.w),
              SizedBox(height: 16.h),
              Text(
                _error!,
                style: TextStyle(fontSize: 14.sp, color: Colors.red.shade400),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _fetchProducts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SiporaTheme.greenDark,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_allProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64.w,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16.h),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'You don\'t have any products in your inventory.',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade500),
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: _fetchProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SiporaTheme.greenDark,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return _buildContent(theme, isTablet);
  }

  Widget _buildContent(SiporaThemeExtension theme, bool isTablet) {
    final totalProducts = _allProducts.length;
    final inStock = _allProducts.where((p) => p.stock).length;
    final outOfStock = _allProducts.where((p) => !p.stock).length;
    final lowStock = _allProducts
        .where((p) => p.quantity != null && p.quantity! < 10 && p.stock)
        .length;

    return Column(
      children: [
        // ── Clickable Stats cards ──────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            children: [
              _buildStatCard(
                label: 'Total',
                value: totalProducts.toString(),
                color: Colors.blue,
                filter: 'all',
                isActive: _activeFilter == 'all',
              ),
              _buildStatCard(
                label: 'In Stock',
                value: inStock.toString(),
                color: Colors.green,
                filter: 'in_stock',
                isActive: _activeFilter == 'in_stock',
              ),
              _buildStatCard(
                label: 'Out of Stock',
                value: outOfStock.toString(),
                color: Colors.red,
                filter: 'out_of_stock',
                isActive: _activeFilter == 'out_of_stock',
              ),
              _buildStatCard(
                label: 'Low Stock',
                value: lowStock.toString(),
                color: Colors.orange,
                filter: 'low_stock',
                isActive: _activeFilter == 'low_stock',
              ),
            ],
          ),
        ),

        // ── Search bar + Refresh ──────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: theme.white,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: theme.border, width: 0.5),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: Icon(Icons.search, size: 18.w),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 0,
                      ),
                    ),
                    style: TextStyle(fontSize: 13.sp),
                    onChanged: _onSearchChanged,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _fetchProducts,
                color: SiporaTheme.greenDark,
              ),
            ],
          ),
        ),

        // ── Product list ──────────────────────────────────────────────────
        Expanded(
          child: _filteredProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _searchQuery.isNotEmpty
                            ? Icons.search_off_outlined
                            : Icons.inventory_2_outlined,
                        size: 48.w,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No products match "$_searchQuery"'
                            : _activeFilter != 'all'
                            ? 'No products in this category'
                            : 'No products available',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  children: [
                    ..._getPaginatedData().map(
                      (product) => _buildProductCard(product, isTablet, theme),
                    ),
                    if (_filteredProducts.length > _itemsPerPage)
                      _buildPagination(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
    required String filter,
    required bool isActive,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _setFilter(filter),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.15) : Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isActive ? color : Colors.grey.shade200,
              width: isActive ? 2 : 0.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: isActive ? color : Colors.grey.shade700,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: isActive ? color : Colors.grey.shade600,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── PRODUCT CARD ────────────────────────────────────────────────────────

  Widget _buildProductCard(
    StockProduct product,
    bool isTablet,
    SiporaThemeExtension theme,
  ) {
    final isEditing = _editingId == product.id;
    final images = _parseImages(product.productsImages);
    final sourceColor = _getSourceColor(product.source);
    final stockColor = _getStockBadgeColor(product.stock);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isEditing ? SiporaTheme.gold : theme.border,
          width: isEditing ? 1.5 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100.withValues(alpha: 0.5),
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Row: Image + Details + Stock Badge ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.network(
                  images.isNotEmpty ? images.first : '',
                  width: 44.w,
                  height: 44.w,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 44.w,
                    height: 44.w,
                    color: Colors.grey.shade200,
                    child: Icon(Icons.image, color: Colors.grey.shade400),
                  ),
                ),
              ),
              SizedBox(width: 8.w),

              // Middle: Product info
              Flexible(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${product.category} • ${product.brand}',
                      style: TextStyle(fontSize: 10.sp, color: theme.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_hasBothSources)
                      Container(
                        margin: EdgeInsets.only(top: 3.h),
                        padding: EdgeInsets.symmetric(
                          horizontal: 5.w,
                          vertical: 1.h,
                        ),
                        decoration: BoxDecoration(
                          color: sourceColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4.r),
                          border: Border.all(
                            color: sourceColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getSourceIcon(product.source),
                              size: 10.w,
                              color: sourceColor,
                            ),
                            SizedBox(width: 3.w),
                            Text(
                              _getSourceLabel(product.source),
                              style: TextStyle(
                                fontSize: 8.sp,
                                color: sourceColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Stock badge
              Flexible(
                flex: 0,
                fit: FlexFit.loose,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: _getStockBadgeBgColor(product.stock),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    _getStockBadgeText(product.stock),
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                      color: stockColor,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          // ── Bottom Row: Quantity + Controls ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Quantity section
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quantity',
                      style: TextStyle(fontSize: 9.sp, color: theme.textMuted),
                    ),
                    if (isEditing)
                      Container(
                        width: 60.w,
                        height: 28.h,
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.border),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: TextFormField(
                          initialValue: _editQuantity?.toString() ?? '',
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 6),
                          ),
                          style: TextStyle(fontSize: 12.sp),
                          onChanged: (val) {
                            if (val.isEmpty) {
                              _editQuantity = null;
                            } else {
                              _editQuantity = int.tryParse(val);
                            }
                          },
                        ),
                      )
                    else
                      Text(
                        product.quantity?.toString() ?? 'N/A',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: theme.textDark,
                        ),
                      ),
                  ],
                ),
              ),

              // Stock toggle (only when editing)
              if (isEditing)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock',
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: theme.textMuted,
                        ),
                      ),
                      Row(
                        children: [
                          Transform.scale(
                            scale: 0.7,
                            child: Switch(
                              value: _editStock,
                              onChanged: (val) =>
                                  setState(() => _editStock = val),
                              activeTrackColor: SiporaTheme.greenMid.withValues(
                                alpha: 0.4,
                              ),
                              inactiveThumbColor: Colors.red.shade300,
                              activeColor: SiporaTheme.greenMid,
                            ),
                          ),
                          Text(
                            _editStock ? 'In Stock' : 'Out of Stock',
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w500,
                              color: _editStock
                                  ? SiporaTheme.greenMid
                                  : Colors.red.shade400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isEditing) ...[
                    ElevatedButton(
                      onPressed: _isSaving ? null : () => _saveEdit(product.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SiporaTheme.greenDark,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 4.h,
                        ),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save, size: 14),
                    ),
                    SizedBox(width: 4.w),
                    TextButton(
                      onPressed: _cancelEdit,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 2.h,
                        ),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  ] else
                    OutlinedButton.icon(
                      onPressed: () => _startEdit(product),
                      icon: const Icon(Icons.edit, size: 12),
                      label: const Text('Edit', style: TextStyle(fontSize: 10)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SiporaTheme.greenDark,
                        side: BorderSide(color: SiporaTheme.greenDark),
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 4.h,
                        ),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.first_page),
            onPressed: _currentPage > 1
                ? () => setState(() {
                    _currentPage = 1;
                  })
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () => setState(() {
                    _currentPage--;
                  })
                : null,
          ),
          Text(
            'Page $_currentPage of $_totalPages',
            style: TextStyle(fontSize: 13.sp),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages
                ? () => setState(() {
                    _currentPage++;
                  })
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.last_page),
            onPressed: _currentPage < _totalPages
                ? () => setState(() {
                    _currentPage = _totalPages;
                  })
                : null,
          ),
        ],
      ),
    );
  }
}
