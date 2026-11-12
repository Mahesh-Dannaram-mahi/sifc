import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import '../../models/active_discount_models.dart';
import '../../theme/sipora_theme.dart';
import '../../utils/screen_utils.dart';

class CartCouponSection extends StatefulWidget {
  final List<CartDiscountOffer> offers;
  final AppliedCartDiscount? appliedDiscount;
  final bool isLoading;
  final String? applyingCupId;
  final VoidCallback onRemove;
  final Future<void> Function(CartDiscountOffer offer) onApply;

  const CartCouponSection({
    super.key,
    required this.offers,
    required this.appliedDiscount,
    required this.isLoading,
    required this.applyingCupId,
    required this.onRemove,
    required this.onApply,
  });

  @override
  State<CartCouponSection> createState() => _CartCouponSectionState();
}

class _CartCouponSectionState extends State<CartCouponSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final cardPadding = context.w(16);
    final fontSize = context.sp(14);
    final iconSize = context.w(24);
    final gridSpacing = context.h(12);
    final cardRadius = context.r(16);
    final screenPadding = context.w(16);

    if (widget.isLoading) {
      return Container(
        margin: EdgeInsets.fromLTRB(
          screenPadding,
          0,
          screenPadding,
          gridSpacing * 1.5,
        ),
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: theme.white,
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(color: theme.border, width: 1.w),
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: SiporaTheme.greenDark,
            ),
          ),
        ),
      );
    }

    if (widget.offers.isEmpty && widget.appliedDiscount == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.fromLTRB(
        screenPadding,
        0,
        screenPadding,
        gridSpacing * 1.5,
      ),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: theme.border, width: 1.w),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(cardRadius),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: cardPadding,
                vertical: gridSpacing * 1.75,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    color: widget.appliedDiscount != null
                        ? SiporaTheme.greenDark
                        : theme.textMuted,
                    size: iconSize,
                  ),
                  SizedBox(width: gridSpacing * 1.25),
                  Expanded(
                    child: Text(
                      widget.appliedDiscount != null
                          ? 'Coupon applied: ${widget.appliedDiscount!.label}'
                          : 'Apply coupon',
                      style: TextStyle(
                        fontSize: fontSize + 2.sp,
                        fontWeight: FontWeight.w700,
                        color: widget.appliedDiscount != null
                            ? SiporaTheme.greenDark
                            : theme.textDark,
                      ),
                    ),
                  ),
                  if (widget.appliedDiscount != null)
                    TextButton(
                      onPressed: widget.onRemove,
                      style: TextButton.styleFrom(
                        foregroundColor: SiporaTheme.greenDark,
                      ),
                      child: Text(
                        'Remove',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: fontSize,
                        ),
                      ),
                    )
                  else
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: theme.textMuted,
                      size: iconSize,
                    ),
                ],
              ),
            ),
          ),
          if (widget.appliedDiscount != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                cardPadding,
                0,
                cardPadding,
                gridSpacing * 1.75,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: SiporaTheme.greenPill,
                    size: iconSize - 4.w,
                  ),
                  SizedBox(width: gridSpacing),
                  Expanded(
                    child: Text(
                      'You save ₹${widget.appliedDiscount!.discountAmount.toStringAsFixed(0)} on this order',
                      style: TextStyle(
                        fontSize: fontSize - 1.sp,
                        color: theme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_expanded && widget.appliedDiscount == null) ...[
            Divider(height: 1, color: theme.border),
            ...widget.offers.map(
              (offer) => _OfferTile(
                offer: offer,
                isApplying: widget.applyingCupId == offer.cupId,
                onApply: () => widget.onApply(offer),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OfferTile extends StatelessWidget {
  final CartDiscountOffer offer;
  final bool isApplying;
  final VoidCallback onApply;

  const _OfferTile({
    required this.offer,
    required this.isApplying,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;
    final fontSize = context.sp(14);
    final cardPadding = context.w(16);
    final gridSpacing = context.h(12);
    final iconSize = context.w(24);
    final buttonFontSize = context.sp(13);
    final cardRadius = context.r(16);

    final bool isFreeCupWithNoEligibleProducts =
        offer.type == CartDiscountType.freeCup && !offer.hasEligibleProducts;

    final bool canApply =
        offer.canApply &&
        (!isFreeCupWithNoEligibleProducts ||
            offer.type != CartDiscountType.freeCup);

    final bool showWarning = isFreeCupWithNoEligibleProducts;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        cardPadding,
        gridSpacing * 1.25,
        cardPadding,
        gridSpacing * 1.25,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.title,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: theme.textDark,
                  ),
                ),
                SizedBox(height: gridSpacing * 0.5),
                Text(
                  offer.subtitle,
                  style: TextStyle(
                    fontSize: fontSize - 2.sp,
                    color: showWarning ? theme.red : theme.textMuted,
                    height: 1.35,
                  ),
                ),
                if (showWarning)
                  Padding(
                    padding: EdgeInsets.only(top: gridSpacing * 0.75),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: fontSize - 2.sp,
                          color: theme.red,
                        ),
                        SizedBox(width: gridSpacing * 0.5),
                        Expanded(
                          child: Text(
                            'Add eligible products (marked "Free Cup Eligible") to use this coupon',
                            style: TextStyle(
                              fontSize: fontSize - 3.sp,
                              color: theme.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (offer.discountPercent != null &&
                    offer.discountPercent! > 0 &&
                    !showWarning)
                  Padding(
                    padding: EdgeInsets.only(top: gridSpacing * 0.75),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(8),
                        vertical: context.h(2),
                      ),
                      decoration: BoxDecoration(
                        color: SiporaTheme.greenDark.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(context.r(12)),
                      ),
                      child: Text(
                        '${offer.discountPercent!.toStringAsFixed(0)}% off · '
                        'Save ₹${offer.discountAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: fontSize - 3.sp,
                          fontWeight: FontWeight.w700,
                          color: SiporaTheme.greenDark,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: gridSpacing),
          SizedBox(
            height: isTablet ? context.h(42) : context.h(38),
            child: TextButton(
              onPressed: canApply && !isApplying ? onApply : null,
              style: TextButton.styleFrom(
                backgroundColor: canApply
                    ? SiporaTheme.greenDark
                    : theme.border.withValues(alpha: 0.5),
                foregroundColor: canApply ? Colors.white : theme.textMuted,
                padding: EdgeInsets.symmetric(horizontal: cardPadding * 0.875),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(cardRadius + 4.r),
                ),
              ),
              child: isApplying
                  ? SizedBox(
                      width: iconSize - 4.w,
                      height: iconSize - 4.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Apply',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: buttonFontSize - 1.sp,
                        color: canApply ? Colors.white : theme.textMuted,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
