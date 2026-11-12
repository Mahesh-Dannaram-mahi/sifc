class CartItem {
  final String productId;
  final String name;
  final String image;
  final String weight;
  final double price;
  final double mrp;
  final String discount;
  final bool isFreeCupEligible;
  final String itemType;
  int quantity;

  CartItem({
    this.productId = '',
    required this.name,
    required this.image,
    required this.weight,
    required this.price,
    required this.mrp,
    this.discount = '',
    this.isFreeCupEligible = false,
    this.itemType = 'product',
    this.quantity = 1,
  });

  String get invoiceProductId => productId;

  double get totalPrice => price * quantity;
  double get totalMrp => mrp * quantity;
  double get savings => totalMrp - totalPrice;

  CartItem copyWith({
    int? quantity,
    String? productId,
    bool? isFreeCupEligible,
    String? itemType,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name,
      image: image,
      weight: weight,
      price: price,
      mrp: mrp,
      discount: discount,
      isFreeCupEligible: isFreeCupEligible ?? this.isFreeCupEligible,
      itemType: itemType ?? this.itemType,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'image': image, // Make sure image is included
      'weight': weight,
      'price': price,
      'mrp': mrp,
      'discount': discount,
      'isFreeCupEligible': isFreeCupEligible,
      'itemType': itemType,
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    final rawItemType =
        (map['itemType'] ??
                map['item_type'] ??
                map['source_table'] ??
                'product')
            .toString()
            .toLowerCase();
    return CartItem(
      productId:
          (map['productId'] ??
                  map['product_id'] ??
                  map['products_id'] ??
                  map['id'])
              ?.toString() ??
          '',
      name:
          map['name']?.toString() ??
          '', // ✅ Add null safety with default empty string
      image:
          map['image']?.toString() ??
          '', // ✅ Add null safety with default empty string
      weight: map['weight']?.toString() ?? '', // ✅ Add null safety
      price: (map['price'] ?? map['Price'] ?? 0.0).toDouble(),
      mrp: (map['mrp'] ?? map['MRP'] ?? 0.0).toDouble(),
      discount: map['discount']?.toString() ?? '',
      isFreeCupEligible:
          map['isFreeCupEligible'] ?? map['free_cup_eligibility'] ?? false,
      itemType: rawItemType.contains('warehouse') ? 'warehouse' : 'product',
      quantity: (map['quantity'] ?? 1).toInt(),
    );
  }
}
