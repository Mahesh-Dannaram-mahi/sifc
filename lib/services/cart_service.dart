import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/cart_item.dart';
import 'jwt_service.dart';
import 'storage_service.dart';

class CartService {
  static final List<CartItem> _items = [];
  static final List<VoidCallback> _listeners = [];

  static List<CartItem> get items => List.unmodifiable(_items);

  static void addItem(CartItem item, {bool syncRemote = true}) {
    final existingIndex = _items.indexWhere(
      (existingItem) => existingItem.name == item.name,
    );
    if (existingIndex != -1) {
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + item.quantity,
        productId: _items[existingIndex].productId.isEmpty
            ? item.productId
            : _items[existingIndex].productId,
        isFreeCupEligible:
            _items[existingIndex].isFreeCupEligible || item.isFreeCupEligible,
      );
    } else {
      _items.add(item);
    }
    _notifyListeners();
    if (syncRemote) {
      _updateRemoteCart(item.productId, item.quantity, item.itemType);
    }
  }

  static void updateQuantity(
    String itemName,
    int newQuantity, {
    bool syncRemote = true,
  }) {
    final existingIndex = _items.indexWhere((item) => item.name == itemName);
    if (existingIndex != -1) {
      final item = _items[existingIndex];
      final previousQuantity = item.quantity;
      if (newQuantity <= 0) {
        _items.removeAt(existingIndex);
      } else {
        _items[existingIndex] = _items[existingIndex].copyWith(
          quantity: newQuantity,
        );
      }
      if (syncRemote) {
        _syncRemoteQuantity(
          item.productId,
          item.itemType,
          previousQuantity,
          newQuantity,
        );
      }
    }
    _notifyListeners();
  }

  static void removeItem(String itemName, {bool syncRemote = true}) {
    final existingItems = _items
        .where((item) => item.name == itemName)
        .toList();
    _items.removeWhere((item) => item.name == itemName);
    _notifyListeners();
    if (syncRemote) {
      for (final item in existingItems) {
        _deleteRemoteCartItem(item.productId, item.itemType);
      }
    }
  }

  static void clearCart({bool syncRemote = true}) {
    _items.clear();
    _notifyListeners();
    if (syncRemote) {
      _clearRemoteCart();
    }
  }

  static void replaceItems(List<CartItem> items, {bool notify = true}) {
    _items
      ..clear()
      ..addAll(items);
    if (notify) _notifyListeners();
  }

  static double get subtotal {
    return _items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  static double get totalMrp {
    return _items.fold(0, (sum, item) => sum + (item.mrp * item.quantity));
  }

  static double get totalSavings {
    return totalMrp - subtotal;
  }

  static double get deliveryFee => subtotal > 500 ? 0 : 20;

  static double get finalTotal => subtotal + deliveryFee;

  static double get subtotalWithoutDelivery => subtotal;

  static bool get isEmpty => _items.isEmpty;

  static bool get isNotEmpty => _items.isNotEmpty;

  static int getQuantity(String itemName) {
    final item = _items.firstWhere(
      (item) => item.name == itemName,
      orElse: () => CartItem(
        productId: '',
        name: '',
        image: '',
        weight: '',
        price: 0,
        mrp: 0,
        discount: '',
        quantity: 0,
      ),
    );
    return item.quantity;
  }

  static bool isInCart(String itemName) {
    return _items.any((item) => item.name == itemName);
  }

  static bool isInCartById(String productId) {
    return _items.any((item) => item.productId == productId);
  }

  static int getQuantityById(String productId) {
    final item = _items.firstWhere(
      (item) => item.productId == productId,
      orElse: () => CartItem(
        productId: '',
        name: '',
        image: '',
        weight: '',
        price: 0,
        mrp: 0,
        discount: '',
        quantity: 0,
      ),
    );
    return item.quantity;
  }

  static void updateQuantityById(
    String productId,
    int newQuantity, {
    bool syncRemote = true,
  }) {
    final existingIndex = _items.indexWhere(
      (item) => item.productId == productId,
    );
    if (existingIndex != -1) {
      final item = _items[existingIndex];
      final previousQuantity = item.quantity;
      if (newQuantity <= 0) {
        _items.removeAt(existingIndex);
      } else {
        _items[existingIndex] = _items[existingIndex].copyWith(
          quantity: newQuantity,
        );
      }
      if (syncRemote) {
        _syncRemoteQuantity(
          item.productId,
          item.itemType,
          previousQuantity,
          newQuantity,
        );
      }
    }
    _notifyListeners();
  }

  static void removeItemById(String productId, {bool syncRemote = true}) {
    final existingItem = _items.firstWhere(
      (item) => item.productId == productId,
      orElse: () => CartItem(
        productId: '',
        name: '',
        image: '',
        weight: '',
        price: 0,
        mrp: 0,
        discount: '',
        quantity: 0,
      ),
    );
    _items.removeWhere((item) => item.productId == productId);
    _notifyListeners();
    if (syncRemote && existingItem.productId.isNotEmpty) {
      _deleteRemoteCartItem(existingItem.productId, existingItem.itemType);
    }
  }

  static bool hasEligibleProductForFreeCup() {
    return _items.any((item) => item.isFreeCupEligible);
  }

  static int getEligibleProductCount() {
    return _items.fold(
      0,
      (sum, item) => sum + (item.isFreeCupEligible ? item.quantity : 0),
    );
  }

  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  static void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  static Future<String?> _getCurrentUserId() async {
    final token = await StorageService.getToken();
    if (token != null) {
      final tokenUserId = JwtService.extractUserId(token);
      if (tokenUserId != null && tokenUserId.isNotEmpty) return tokenUserId;
    }
    return StorageService.getUserId();
  }

  static Future<void> _postCartEndpoint(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final userId = await _getCurrentUserId();
    if (userId == null || userId.isEmpty) return;

    final requestBody = {'user_id': userId, ...body};
    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/cart/$endpoint'),
      headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );
  }

  static Future<void> _updateRemoteCart(
    String productId,
    int quantity,
    String itemType,
  ) async {
    if (productId.isEmpty || quantity <= 0) return;
    try {
      await _postCartEndpoint('update-cart', {
        'item_id': productId,
        'item_type': itemType,
        'quantity': quantity,
      });
    } catch (_) {}
  }

  static Future<void> _removeRemoteCartItem(
    String productId,
    String itemType,
  ) async {
    if (productId.isEmpty) return;
    try {
      await _postCartEndpoint('remove-cart-item', {
        'item_id': productId,
        'item_type': itemType,
      });
    } catch (_) {}
  }

  static Future<void> _deleteRemoteCartItem(
    String productId,
    String itemType,
  ) async {
    if (productId.isEmpty) return;
    try {
      await _postCartEndpoint('clear-cart-item', {
        'item_id': productId,
        'item_type': itemType,
      });
    } catch (_) {}
  }

  static Future<void> _clearRemoteCart() async {
    try {
      await _postCartEndpoint('clear-cart', {});
    } catch (_) {}
  }

  static Future<void> _syncRemoteQuantity(
    String productId,
    String itemType,
    int previousQuantity,
    int newQuantity,
  ) async {
    if (productId.isEmpty) return;
    if (newQuantity <= 0) {
      await _deleteRemoteCartItem(productId, itemType);
      return;
    }

    final difference = newQuantity - previousQuantity;
    if (difference > 0) {
      await _updateRemoteCart(productId, difference, itemType);
    } else if (difference == -1) {
      await _removeRemoteCartItem(productId, itemType);
    } else if (difference < 0) {
      await _deleteRemoteCartItem(productId, itemType);
      await _updateRemoteCart(productId, newQuantity, itemType);
    }
  }

  static Future<List<CartItem>> fetchRemoteCartItems() async {
    final userId = await _getCurrentUserId();
    if (userId == null || userId.isEmpty) return [];

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/cart/fetch-cart/$userId'),
      headers: {'accept': 'application/json'},
    );

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    final List<dynamic> rows = data['items'] ?? [];

    // debugPrint('🛒 Remote cart items count: ${rows.length}');

    // Preserve local prices - only update quantities from remote
    final remoteItems = rows
        .map((row) => _cartItemFromRemote(Map<String, dynamic>.from(row)))
        .where((item) => item.productId.isNotEmpty && item.name.isNotEmpty)
        .toList();

    // debugPrint('🛒 Local cart items count: ${_items.length}');
    // for (final item in _items) {
    //   debugPrint('🛒 Local item: ${item.name}, price: ${item.price}, mrp: ${item.mrp}');
    // }

    // Merge with local items, preserving local prices
    final mergedItems = <CartItem>[];
    for (final remoteItem in remoteItems) {
      final localItem = _items.firstWhere(
        (item) => item.productId == remoteItem.productId,
        orElse: () => remoteItem,
      );
      // Use local price if exists, otherwise use remote price
      if (localItem.productId == remoteItem.productId) {
        // debugPrint(
        //   '🛒 Merging: ${remoteItem.name} - Local price: ${localItem.price}, Remote price: ${remoteItem.price} -> Using local price',
        // );
        mergedItems.add(localItem.copyWith(quantity: remoteItem.quantity));
      } else {
        // debugPrint(
        //   '🛒 New item from remote: ${remoteItem.name}, price: ${remoteItem.price}',
        // );
        mergedItems.add(remoteItem);
      }
    }

    // debugPrint('🛒 Final merged items count: ${mergedItems.length}');
    // for (final item in mergedItems) {
    //   debugPrint(
    //     '🛒 Final item: ${item.name}, price: ${item.price}, quantity: ${item.quantity}',
    //   );
    // }

    return mergedItems;
  }

  static CartItem _cartItemFromRemote(Map<String, dynamic> row) {
    // debugPrint('🛒 Cart API response row: $row');

    final images = (row['product_image'] ?? '').toString();
    final parsedImages = images
        .split(',')
        .map((image) => image.trim())
        .where((image) => image.isNotEmpty)
        .cast<String>()
        .toList();
    final firstImage = parsedImages.isNotEmpty ? parsedImages.first : '';

    final weightKg = _parseDouble(row['weight_kg']);
    final grams = _parseDouble(row['grams_g']);
    final weight = weightKg > 0
        ? '$weightKg kg'
        : '${grams.toStringAsFixed(0)} g';

    // Use same price field priority as home_page.dart: Total → Amount → Price → price
    // Check both uppercase and lowercase field names
    double price = 0.0;
    if (row['Total'] != null) {
      price = _parseDouble(row['Total']);
    } else if (row['total'] != null) {
      price = _parseDouble(row['total']);
    } else if (row['Amount'] != null) {
      price = _parseDouble(row['Amount']);
    } else if (row['amount'] != null) {
      price = _parseDouble(row['amount']);
    } else if (row['Price'] != null) {
      price = _parseDouble(row['Price']);
    } else if (row['price'] != null) {
      price = _parseDouble(row['price']);
    }

    // debugPrint('🛒 Parsed price: $price');

    // Use same MRP field priority as home_page.dart: MRP → mrp → price
    // Check both uppercase and lowercase field names
    double mrp = 0.0;
    if (row['MRP'] != null) {
      mrp = _parseDouble(row['MRP']);
    } else if (row['mrp'] != null) {
      mrp = _parseDouble(row['mrp']);
    } else {
      mrp = price;
    }

    final rawItemType = row['item_type']?.toString().toLowerCase() ?? 'product';

    return CartItem(
      productId: row['item_id']?.toString() ?? '',
      name: row['product_name']?.toString() ?? '',
      image: firstImage,
      weight: weight,
      price: price,
      mrp: mrp,
      discount: '',
      isFreeCupEligible: row['free_cup_eligibility'] == true,
      itemType: rawItemType.contains('warehouse') ? 'warehouse' : 'product',
      quantity: _parseInt(row['quantity'], fallback: 1),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static int _parseInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }
}
