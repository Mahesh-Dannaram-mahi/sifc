import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  // Add item to cart or update quantity if it exists
  void addItem(CartItem item) {
    final existingIndex = _items.indexWhere(
      (existingItem) => existingItem.name == item.name,
    );

    if (existingIndex != -1) {
      // Update quantity of existing item
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + item.quantity,
      );
    } else {
      // Add new item
      _items.add(item);
    }
    notifyListeners();
  }

  // Update quantity of a specific item
  void updateQuantity(String itemName, int newQuantity) {
    final existingIndex = _items.indexWhere(
      (item) => item.name == itemName,
    );

    if (existingIndex != -1) {
      if (newQuantity <= 0) {
        _items.removeAt(existingIndex);
      } else {
        _items[existingIndex] = _items[existingIndex].copyWith(
          quantity: newQuantity,
        );
      }
      notifyListeners();
    }
  }

  // Remove item from cart
  void removeItem(String itemName) {
    _items.removeWhere((item) => item.name == itemName);
    notifyListeners();
  }

  // Clear all items
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // Get total price calculations
  double get subtotal {
    return _items.fold(0, (sum, item) => sum + item.totalPrice);
  }

  double get totalMrp {
    return _items.fold(0, (sum, item) => sum + item.totalMrp);
  }

  double get totalSavings {
    return totalMrp - subtotal;
  }

  double get deliveryFee => subtotal > 500 ? 0 : 20;

  double get finalTotal => subtotal + deliveryFee;

  // Get item count
  int get itemCount {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Check if cart is empty
  bool get isEmpty => _items.isEmpty;

  bool get isNotEmpty => _items.isNotEmpty;
}
