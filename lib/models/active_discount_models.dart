class EventDiscount {
  final String franchiseId;
  final String eventId;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final double price;
  final double discountPercent;
  final double discountPrice;
  final double finalPrice;

  EventDiscount({
    required this.franchiseId,
    required this.eventId,
    required this.startDateTime,
    required this.endDateTime,
    required this.price,
    required this.discountPercent,
    required this.discountPrice,
    required this.finalPrice,
  });

  factory EventDiscount.fromJson(Map<String, dynamic> json) {
    return EventDiscount(
      franchiseId: json['franchise_id']?.toString() ?? '',
      eventId: json['event_id']?.toString() ?? '',
      startDateTime: _parseDateTime(
        json['start_date']?.toString(),
        json['start_time']?.toString() ?? '00:00:00',
      ),
      endDateTime: _parseDateTime(
        json['end_date']?.toString(),
        json['end_time']?.toString() ?? '23:59:59',
      ),
      price: _toDouble(json['price']),
      discountPercent: _toDouble(json['discount']),
      discountPrice: _toDouble(json['discount_price']),
      finalPrice: _toDouble(json['final_price']),
    );
  }

  bool isActiveAt(DateTime now) =>
      !now.isBefore(startDateTime) && !now.isAfter(endDateTime);
}

class RemainingFreeCupDiscount {
  final String franchiseId;
  final String cupId;
  final int eligibleNoOfCups;
  final int usedCups;
  final int remainingCups;

  RemainingFreeCupDiscount({
    required this.franchiseId,
    required this.cupId,
    required this.eligibleNoOfCups,
    required this.usedCups,
    required this.remainingCups,
  });

  factory RemainingFreeCupDiscount.fromJson(Map<String, dynamic> json) {
    return RemainingFreeCupDiscount(
      franchiseId: json['franchise_id']?.toString() ?? '',
      cupId: json['cup_id']?.toString() ?? '',
      eligibleNoOfCups: _toInt(json['eligible_no_of_cups']),
      usedCups: _toInt(json['used_cups']),
      remainingCups: _toInt(json['remaining_cups']),
    );
  }
}

class RemainingDiscountCup {
  final String franchiseId;
  final String cupId;
  final int requiredCups;
  final int usedCups;
  final int remainingCupsToUnlock;
  final double price;
  final double discountPercent;
  final double discountPrice;
  final double finalPrice;

  RemainingDiscountCup({
    required this.franchiseId,
    required this.cupId,
    required this.requiredCups,
    required this.usedCups,
    required this.remainingCupsToUnlock,
    required this.price,
    required this.discountPercent,
    required this.discountPrice,
    required this.finalPrice,
  });

  factory RemainingDiscountCup.fromJson(Map<String, dynamic> json) {
    return RemainingDiscountCup(
      franchiseId: json['franchise_id']?.toString() ?? '',
      cupId: json['cup_id']?.toString() ?? '',
      requiredCups: _toInt(json['required_cups']),
      usedCups: _toInt(json['used_cups']),
      remainingCupsToUnlock: _toInt(json['remaining_cups_to_unlock']),
      price: _toDouble(json['price']),
      discountPercent: _toDouble(json['discount']),
      discountPrice: _toDouble(json['discount_price']),
      finalPrice: _toDouble(json['final_price']),
    );
  }
}

class ActiveDiscountsData {
  final bool status;
  final int usedCups;
  final List<EventDiscount> eventDiscounts;
  final List<RemainingFreeCupDiscount> remainingFreeCups;
  final List<RemainingDiscountCup> remainingDiscountCups;

  ActiveDiscountsData({
    required this.status,
    required this.usedCups,
    required this.eventDiscounts,
    required this.remainingFreeCups,
    required this.remainingDiscountCups,
  });

  factory ActiveDiscountsData.fromJson(Map<String, dynamic> json) {
    return ActiveDiscountsData(
      status: json['status'] == true,
      usedCups: _toInt(json['used_cups']),
      eventDiscounts: _mapList(json['event_discount'], EventDiscount.fromJson),
      remainingFreeCups:
          _mapList(json['remaining_free_cups'], RemainingFreeCupDiscount.fromJson),
      remainingDiscountCups: _mapList(
        json['remaining_discount_cups'],
        RemainingDiscountCup.fromJson,
      ),
    );
  }
}

class DiscountConfirmData {
  final String discountType;
  final String franchiseId;
  final String cupId;
  final int? numberOfCups;
  final int? noOfCups;
  final double? price;
  final double? discountPercent;
  final double? discountPrice;
  final double? finalPrice;
  final int priority;

  DiscountConfirmData({
    required this.discountType,
    required this.franchiseId,
    required this.cupId,
    this.numberOfCups,
    this.noOfCups,
    this.price,
    this.discountPercent,
    this.discountPrice,
    this.finalPrice,
    required this.priority,
  });

  factory DiscountConfirmData.fromJson(Map<String, dynamic> json) {
    return DiscountConfirmData(
      discountType: json['discount_type']?.toString() ?? '',
      franchiseId: json['franchise_id']?.toString() ?? '',
      cupId: json['cup_id']?.toString() ?? '',
      numberOfCups: json['number_of_cups'] != null
          ? _toInt(json['number_of_cups'])
          : null,
      noOfCups:
          json['no_of_cups'] != null ? _toInt(json['no_of_cups']) : null,
      price: json['price'] != null ? _toDouble(json['price']) : null,
      discountPercent:
          json['discount'] != null ? _toDouble(json['discount']) : null,
      discountPrice: json['discount_price'] != null
          ? _toDouble(json['discount_price'])
          : null,
      finalPrice:
          json['final_price'] != null ? _toDouble(json['final_price']) : null,
      priority: _toInt(json['priority']),
    );
  }
}

enum CartDiscountType { event, freeCup, cupDiscount }

class CartDiscountOffer {
  final String cupId;
  final CartDiscountType type;
  final String title;
  final String subtitle;
  final bool canApply;
  final double minCartAmount;
  final double discountAmount;
  final double? displayFinalPrice;
  final double? discountPercent;
  final bool hasEligibleProducts;

  const CartDiscountOffer({
    required this.cupId,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.canApply,
    this.minCartAmount = 0,
    this.discountAmount = 0,
    this.displayFinalPrice,
    this.discountPercent,
    this.hasEligibleProducts = true,
  });
}

class AppliedCartDiscount {
  final String cupId;
  final CartDiscountType type;
  final String label;
  final double discountAmount;
  final double payableAmount;
  final DiscountConfirmData confirmData;

  AppliedCartDiscount({
    required this.cupId,
    required this.type,
    required this.label,
    required this.discountAmount,
    required this.payableAmount,
    required this.confirmData,
  });
}

DateTime _parseDateTime(String? date, String time) {
  if (date == null || date.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
  final timePart = time.length >= 8 ? time : '$time:00';
  return DateTime.parse('${date}T$timePart');
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.round();
  return int.tryParse(v.toString()) ?? 0;
}

List<T> _mapList<T>(
  dynamic json,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (json is! List) return [];
  return json
      .whereType<Map>()
      .map((e) => fromJson(Map<String, dynamic>.from(e)))
      .toList();
}