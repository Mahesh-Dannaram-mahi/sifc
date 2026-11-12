import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/active_discount_models.dart';
import '../services/cart_service.dart';

class CupQuestProgress {
  final int usedCups;
  final int eligibleCups;
  final int remainingCups;
  final int nextMilestoneCups;
  final String milestoneMessage;
  final bool hasEarnedFreeCup;
  final String tierLabel;
  final List<int> milestonePositions;
  final int cartCupCount;
  final int totalCupsWithCart;

  const CupQuestProgress({
    required this.usedCups,
    required this.eligibleCups,
    required this.remainingCups,
    this.nextMilestoneCups = 0,
    this.milestoneMessage = '',
    this.hasEarnedFreeCup = false,
    this.tierLabel = '',
    this.milestonePositions = const [],
    this.cartCupCount = 0,
    this.totalCupsWithCart = 0,
  });

  static const int roundSize = 10;

  int get progressInRound {
    if (usedCups <= 0) return 0;
    return usedCups % roundSize;
  }

  factory CupQuestProgress.fromJson(Map<String, dynamic> json) {
    return CupQuestProgress(
      usedCups: json['used_cups'] ?? 0,
      eligibleCups: json['eligible_cups'] ?? 0,
      remainingCups: json['remaining_cups'] ?? 0,
      nextMilestoneCups: json['next_milestone_cups'] ?? 0,
      milestoneMessage: json['milestone_message'] ?? '',
      hasEarnedFreeCup: json['has_earned_free_cup'] ?? false,
      tierLabel: json['tier_label'] ?? '',
      milestonePositions: List<int>.from(json['milestone_positions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'used_cups': usedCups,
      'eligible_cups': eligibleCups,
      'remaining_cups': remainingCups,
      'next_milestone_cups': nextMilestoneCups,
      'milestone_message': milestoneMessage,
      'has_earned_free_cup': hasEarnedFreeCup,
      'tier_label': tierLabel,
      'milestone_positions': milestonePositions,
    };
  }

  /// Check if user has an earned free cup available to redeem
  bool get hasAvailableFreeCup => hasEarnedFreeCup;

  /// Check if user is close to earning a free cup (within 3 cups)
  bool get isCloseToReward => remainingCups <= 3 && remainingCups > 0;

  /// Get progress percentage for UI
  double get progressPercentage {
    if (eligibleCups <= 0) return 0.0;
    return (totalCupsWithCart / eligibleCups).clamp(0.0, 1.0);
  }
}

class DiscountService {
  static Map<String, String> _headers(String? authToken) {
    final headers = <String, String>{'accept': 'application/json'};
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  static Future<ActiveDiscountsData?> fetchActiveDiscounts({
    required String userId,
    required String franchiseId,
    String? authToken,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/discounts/active_discounts')
        .replace(
          queryParameters: {'user_id': userId, 'franchise_id': franchiseId},
        );

    final response = await http.get(uri, headers: _headers(authToken));
    if (response.statusCode != 200) return null;

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) return null;
    return ActiveDiscountsData.fromJson(decoded);
  }

  static Future<CupQuestProgress?> fetchCupQuestProgress({
    required String userId,
    required String franchiseId,
    String? authToken,
  }) async {
    final data = await fetchActiveDiscounts(
      userId: userId,
      franchiseId: franchiseId,
      authToken: authToken,
    );
    if (data == null) return null;
    return _parseCupQuestFromData(data, franchiseId);
  }

  static Future<CupQuestProgress?> fetchCupQuestProgressWithCart({
    required String userId,
    required String franchiseId,
    String? authToken,
  }) async {
    final data = await fetchActiveDiscounts(
      userId: userId,
      franchiseId: franchiseId,
      authToken: authToken,
    );
    if (data == null) return null;
    
    final cartCupCount = CartService.items.fold(0, (sum, item) => sum + item.quantity);
    
    return _parseCupQuestFromDataWithCart(data, franchiseId, cartCupCount);
  }

  static CupQuestProgress? _parseCupQuestFromData(
    ActiveDiscountsData data,
    String franchiseId,
  ) {
    return _parseCupQuestFromDataWithCart(data, franchiseId, 0);
  }

  static CupQuestProgress? _parseCupQuestFromDataWithCart(
    ActiveDiscountsData data,
    String franchiseId,
    int cartCupCount,
  ) {
    final normalized = franchiseId.trim().toLowerCase();
    final usedCupsOnly = data.usedCups;
    final usedCupsWithCart = usedCupsOnly + cartCupCount;

    RemainingFreeCupDiscount? freeCup;
    for (final row in data.remainingFreeCups) {
      if (row.franchiseId.toLowerCase() == normalized) {
        freeCup = row;
        break;
      }
    }
    freeCup ??= data.remainingFreeCups.isNotEmpty
        ? data.remainingFreeCups.first
        : null;

    final List<int> milestonePositions = [];

    for (final free in data.remainingFreeCups) {
      if (free.franchiseId.toLowerCase() == normalized) {
        milestonePositions.add(free.eligibleNoOfCups);
      }
    }

    milestonePositions.sort();

    int eligibleCups;
    int remainingCups;
    int nextMilestoneCups = 0;
    String milestoneMessage = '';
    bool hasEarnedFreeCup = false;
    String tierLabel = '';

    if (freeCup != null) {
      final freeCupData = freeCup;
      eligibleCups = freeCupData.eligibleNoOfCups;

      final remainingForFree = (eligibleCups - usedCupsWithCart).clamp(0, eligibleCups);
      
      if (remainingForFree > 0) {
        remainingCups = remainingForFree;
        milestoneMessage = 'Your ${_getOrdinal(eligibleCups)} cup is free! 🎉';
        hasEarnedFreeCup = false;
        tierLabel = '${_getOrdinal(eligibleCups)} Cup Free';
      } else {
        remainingCups = 0;
        milestoneMessage = 'You earned a free cup! 🎉';
        hasEarnedFreeCup = true;

        final nextMilestone = milestonePositions.firstWhere(
          (m) => m > freeCupData.eligibleNoOfCups,
          orElse: () => 0,
        );
        if (nextMilestone > 0) {
          nextMilestoneCups = nextMilestone;
          tierLabel = '${freeCupData.eligibleNoOfCups + 1}-$nextMilestone cups';
        } else {
          tierLabel = 'Max rewards achieved';
        }
      }
    } else {
      if (milestonePositions.isNotEmpty) {
        final nextMilestone = milestonePositions.firstWhere(
          (m) => m > usedCupsWithCart,
          orElse: () => milestonePositions.first,
        );
        eligibleCups = nextMilestone;
        remainingCups = (eligibleCups - usedCupsWithCart).clamp(0, eligibleCups);
        milestoneMessage = 'Collect $eligibleCups cups to earn 1 free cup';
      } else {
        eligibleCups = CupQuestProgress.roundSize;
        remainingCups = eligibleCups - usedCupsWithCart;
        milestoneMessage = 'Collect $eligibleCups cups to earn 1 free cup';
      }
      hasEarnedFreeCup = false;
      tierLabel = 'Start your journey';
    }

    String bannerMessage;
    if (remainingCups <= 0 && !hasEarnedFreeCup) {
      if (nextMilestoneCups > 0) {
        bannerMessage =
            'Collect $nextMilestoneCups cups to earn your next reward';
      } else {
        bannerMessage = 'You earned a reward! Apply at checkout ☕';
        hasEarnedFreeCup = true;
      }
    } else {
      bannerMessage = milestoneMessage;
    }

    final safeRemainingCups = remainingCups.clamp(0, eligibleCups);

    return CupQuestProgress(
      usedCups: usedCupsOnly,
      eligibleCups: eligibleCups,
      remainingCups: safeRemainingCups,
      nextMilestoneCups: nextMilestoneCups,
      milestoneMessage: bannerMessage,
      hasEarnedFreeCup: hasEarnedFreeCup,
      tierLabel: tierLabel,
      milestonePositions: milestonePositions,
      cartCupCount: cartCupCount,
      totalCupsWithCart: usedCupsWithCart,
    );
  }

  static String _getOrdinal(int n) {
    if (n >= 11 && n <= 13) {
      return '${n}th';
    }
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  static bool _hasEligibleProductForFreeCup() {
    final hasEligible = CartService.hasEligibleProductForFreeCup();
    return hasEligible;
  }

  static List<CartDiscountOffer> evaluateCartOffers({
    required ActiveDiscountsData discounts,
    required String franchiseId,
    required double cartTotal,
    required int cartCupCount,
    DateTime? now,
  }) {
    final checkTime = now ?? DateTime.now();
    final normalized = franchiseId.trim().toLowerCase();
    final offers = <CartDiscountOffer>[];
    final cupsAfterOrder = discounts.usedCups + cartCupCount;

    final hasEligibleFreeCupProduct = _hasEligibleProductForFreeCup();

    // ── Event discounts (date/time + min cart price) ──
    final activeEvents =
        discounts.eventDiscounts
            .where(
              (e) =>
                  e.franchiseId.toLowerCase() == normalized &&
                  e.isActiveAt(checkTime),
            )
            .toList()
          ..sort((a, b) => b.price.compareTo(a.price));

    if (activeEvents.isNotEmpty) {
      EventDiscount? bestMatch;
      for (final event in activeEvents) {
        if (cartTotal >= event.price) {
          bestMatch = event;
          break;
        }
      }

      if (bestMatch != null) {
        final save = bestMatch.discountPrice;
        final youPay = (cartTotal - save).clamp(0, double.infinity);
        offers.add(
          CartDiscountOffer(
            cupId: bestMatch.eventId,
            type: CartDiscountType.event,
            title: 'Event offer',
            subtitle:
                'Min order ₹${bestMatch.price.toStringAsFixed(0)} — '
                'save ₹$save (${bestMatch.discountPercent.toStringAsFixed(0)}% off). '
                'You pay ₹${youPay.toStringAsFixed(0)}.',
            canApply: true,
            minCartAmount: bestMatch.price,
            discountAmount: save,
            discountPercent: bestMatch.discountPercent,
          ),
        );
      } else {
        final next = activeEvents.last;
        final need = (next.price - cartTotal).ceil();
        offers.add(
          CartDiscountOffer(
            cupId: next.eventId,
            type: CartDiscountType.event,
            title: 'Event offer',
            subtitle:
                'Add ₹$need more (min ₹${next.price.toStringAsFixed(0)}) to save '
                '₹${next.discountPrice.toStringAsFixed(0)} '
                '(e.g. ₹${next.price.toStringAsFixed(0)} order → pay ₹${next.finalPrice.toStringAsFixed(0)}).',
            canApply: false,
            minCartAmount: next.price,
            discountAmount: next.discountPrice,
            discountPercent: next.discountPercent,
          ),
        );
      }
    }

    // ── Free cup eligibility (CupQuest) with eligibility check ──
    for (final free in discounts.remainingFreeCups) {
      if (free.franchiseId.toLowerCase() != normalized) continue;

      final cupsUnlocked = cupsAfterOrder >= free.eligibleNoOfCups;
      final canApplyFree = cupsUnlocked && 
                           cartCupCount > 0 && 
                           hasEligibleFreeCupProduct;

      final cupsStillNeeded = (free.eligibleNoOfCups - discounts.usedCups)
          .clamp(0, 999);

      String subtitle;
      if (free.remainingCups <= 0) {
        subtitle = hasEligibleFreeCupProduct
            ? 'You earned a free cup! Apply to redeem on this order ☕'
            : 'You earned a free cup, but no eligible products in cart. Add eligible products to redeem.';
      } else if (canApplyFree) {
        subtitle = hasEligibleFreeCupProduct
            ? 'This order completes your ${free.eligibleNoOfCups}-cup quest — apply for a free cup ☕'
            : 'Add eligible products (with free cup eligibility) to redeem your free cup.';
      } else if (cupsUnlocked && !hasEligibleFreeCupProduct) {
        subtitle = 'You have unlocked a free cup, but no eligible products in cart. Add eligible products to redeem.';
      } else {
        final ordinal = _getOrdinal(free.eligibleNoOfCups);
        subtitle = hasEligibleFreeCupProduct
            ? 'Buy $cupsStillNeeded more cups to get your $ordinal cup free! '
              '(${free.usedCups}/${free.eligibleNoOfCups}) ☕'
            : 'Add eligible products (with free cup eligibility) to unlock cup quest rewards.';
      }

      offers.add(
        CartDiscountOffer(
          cupId: free.cupId,
          type: CartDiscountType.freeCup,
          title: 'CupQuest free cup',
          subtitle: subtitle,
          canApply: canApplyFree,
          hasEligibleProducts: hasEligibleFreeCupProduct,
        ),
      );
    }

    // ── Cup milestone discounts ──
    final cupDiscounts =
        discounts.remainingDiscountCups
            .where((c) => c.franchiseId.toLowerCase() == normalized)
            .toList()
          ..sort((a, b) => a.requiredCups.compareTo(b.requiredCups));

    for (final cup in cupDiscounts) {
      final unlocked = cupsAfterOrder >= cup.requiredCups;
      final cartMeetsPrice = cartTotal >= cup.price;

      if (unlocked && cartMeetsPrice) {
        final save = cup.discountPrice;
        final youPay = (cartTotal - save).clamp(0, double.infinity);
        offers.add(
          CartDiscountOffer(
            cupId: cup.cupId,
            type: CartDiscountType.cupDiscount,
            title: 'Milestone discount',
            subtitle:
                '${cup.requiredCups} cups unlocked! Min order ₹${cup.price.toStringAsFixed(0)} — '
                'save ₹$save. You pay ₹${youPay.toStringAsFixed(0)}.',
            canApply: true,
            minCartAmount: cup.price,
            discountAmount: save,
            discountPercent: cup.discountPercent,
          ),
        );
      } else if (!unlocked) {
        offers.add(
          CartDiscountOffer(
            cupId: cup.cupId,
            type: CartDiscountType.cupDiscount,
            title: 'Milestone discount',
            subtitle:
                'Buy ${cup.remainingCupsToUnlock} more cups '
                '(${cup.usedCups}/${cup.requiredCups}) to unlock '
                '₹${cup.discountPrice.toStringAsFixed(0)} off.',
            canApply: false,
            minCartAmount: cup.price,
            discountAmount: cup.discountPrice,
            discountPercent: cup.discountPercent,
          ),
        );
      } else if (unlocked && !cartMeetsPrice) {
        final need = (cup.price - cartTotal).ceil();
        offers.add(
          CartDiscountOffer(
            cupId: cup.cupId,
            type: CartDiscountType.cupDiscount,
            title: 'Milestone discount',
            subtitle:
                'Cups milestone reached! Add ₹$need more (min ₹${cup.price.toStringAsFixed(0)}) '
                'to save ₹${cup.discountPrice.toStringAsFixed(0)}.',
            canApply: false,
            minCartAmount: cup.price,
            discountAmount: cup.discountPrice,
            discountPercent: cup.discountPercent,
          ),
        );
      }
    }

    // Sort offers: applyable first, then by discount amount
    offers.sort((a, b) {
      if (a.canApply && !b.canApply) return -1;
      if (!a.canApply && b.canApply) return 1;
      return b.discountAmount.compareTo(a.discountAmount);
    });

    return offers;
  }

  static Future<DiscountConfirmData?> confirmDiscount({
    required String franchiseId,
    required String cupId,
    String? authToken,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/discounts/discount/confirm',
    ).replace(queryParameters: {'franchise_id': franchiseId, 'cup_id': cupId});

    final response = await http.get(uri, headers: _headers(authToken));
    if (response.statusCode != 200) return null;

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['status'] != true) {
      return null;
    }
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) return null;
    return DiscountConfirmData.fromJson(data);
  }

  static double flatDiscountOffCart({
    required double cartSubtotal,
    required double minOrderAmount,
    required double discountPrice,
    double? discountPercent,
  }) {
    if (cartSubtotal < minOrderAmount) return 0;

    var amount = discountPrice;
    if (amount <= 0 && discountPercent != null && discountPercent > 0) {
      amount = cartSubtotal * (discountPercent / 100);
    }
    return amount.clamp(0, cartSubtotal);
  }

  static AppliedCartDiscount? buildAppliedDiscount({
    required CartDiscountOffer offer,
    required DiscountConfirmData confirm,
    required double cartSubtotal,
    double freeCupUnitPrice = 0,
  }) {
    double discountAmount = 0;
    double payable = cartSubtotal;

    switch (offer.type) {
      case CartDiscountType.event:
      case CartDiscountType.cupDiscount:
        final minOrder = confirm.price ?? offer.minCartAmount;
        discountAmount = flatDiscountOffCart(
          cartSubtotal: cartSubtotal,
          minOrderAmount: minOrder,
          discountPrice: confirm.discountPrice ?? offer.discountAmount,
          discountPercent: confirm.discountPercent ?? offer.discountPercent,
        );
        payable = (cartSubtotal - discountAmount).clamp(0, double.infinity);
        break;
      case CartDiscountType.freeCup:
        // For free cup, discount is the price of the cheapest eligible product
        discountAmount = freeCupUnitPrice > 0
            ? freeCupUnitPrice.clamp(0, cartSubtotal)
            : cartSubtotal;
        payable = (cartSubtotal - discountAmount).clamp(0, double.infinity);
        break;
    }

    return AppliedCartDiscount(
      cupId: offer.cupId,
      type: offer.type,
      label: offer.title,
      discountAmount: discountAmount,
      payableAmount: payable,
      confirmData: confirm,
    );
  }
}