import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import '../../theme/sipora_theme.dart';
import '../../services/discount_service.dart';
import '../../utils/screen_utils.dart';

class CupQuestWidget extends StatelessWidget {
  final CupQuestProgress? progress;
  final bool isLoading;

  const CupQuestWidget({
    super.key,
    required this.progress,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;

    if (isLoading && progress == null) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(16),
          vertical: context.h(24),
        ),
        child: Container(
          height: isTablet ? context.h(180) : context.h(140),
          decoration: BoxDecoration(
            color: theme.white,
            borderRadius: BorderRadius.circular(context.r(16)),
            border: Border.all(color: SiporaTheme.gold.withValues(alpha: 0.2)),
          ),
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: SiporaTheme.gold,
              ),
            ),
          ),
        ),
      );
    }

    if (progress == null) return const SizedBox.shrink();

    final cupProgress = progress!;

    final usedCups = cupProgress.usedCups;
    final milestonePositions = cupProgress.milestonePositions;
    final cartCupCount = cupProgress.cartCupCount;
    final totalCupsWithCart = cupProgress.totalCupsWithCart;

    // Calculate current cycle (0-9, 10-19, 20-29, etc.)
    // A cycle shows 10 cups: if total is 11, we're in cycle 1 showing cups 11-20
    final int cycle = (totalCupsWithCart ~/ 10);
    final int cycleStart = cycle * 10 + 1;

    // For displaying cups in the current cycle
    final List<int> displayCups = List.generate(
      10,
      (index) => cycleStart + index,
    );

    // Calculate progress within current cycle (0-10)
    final int currentCycleProgress = totalCupsWithCart - cycleStart + 1;
    final double progressFraction = currentCycleProgress.clamp(0, 10) / 10.0;

    int currentMilestone = 0;
    int nextMilestone = 0;
    int milestoneIndex = -1;

    for (int i = 0; i < milestonePositions.length; i++) {
      final milestone = milestonePositions[i];
      if (totalCupsWithCart >= milestone) {
        currentMilestone = milestone;
        milestoneIndex = i;
      } else {
        nextMilestone = milestone;
        break;
      }
    }

    final bool isAtLastMilestone =
        milestoneIndex == milestonePositions.length - 1 &&
        totalCupsWithCart >= currentMilestone;

    final bool isMilestoneCompleted =
        currentMilestone > 0 && totalCupsWithCart >= currentMilestone;

    final int displayTargetMilestone = isMilestoneCompleted && nextMilestone > 0
        ? nextMilestone
        : currentMilestone;
    final int displayCurrentCups = totalCupsWithCart;

    int cupsNeededForReward;
    if (isMilestoneCompleted && nextMilestone > 0) {
      cupsNeededForReward = nextMilestone - totalCupsWithCart;
    } else if (currentMilestone > 0) {
      cupsNeededForReward = currentMilestone - totalCupsWithCart;
    } else if (nextMilestone > 0) {
      cupsNeededForReward = nextMilestone - totalCupsWithCart;
    } else {
      cupsNeededForReward = 1;
    }

    cupsNeededForReward = cupsNeededForReward.clamp(1, 999);

    final bool shouldShowCongrats =
        isMilestoneCompleted && totalCupsWithCart >= currentMilestone;

    String tierLabel = '';
    if (milestoneIndex >= 0 && !shouldShowCongrats) {
      final start = milestoneIndex > 0
          ? milestonePositions[milestoneIndex - 1] + 1
          : 1;
      final end = milestonePositions[milestoneIndex];
      tierLabel = '$start–$end cups';
    } else if (nextMilestone > 0 && shouldShowCongrats) {
      final start = currentMilestone + 1;
      final end = nextMilestone;
      tierLabel = '$start–$end cups';
    }

    String messageText;
    if (isAtLastMilestone && totalCupsWithCart >= currentMilestone) {
      messageText = '🎉 Amazing! You\'ve earned all rewards!';
    } else if (shouldShowCongrats) {
      messageText = '🎉 Congratulations! You earned a FREE Tea Cup!';
    } else {
      if (cartCupCount > 0) {
        // When cups are in cart
        if (cupsNeededForReward == 1) {
          messageText =
              '☕ +$cartCupCount Tea Cup${cartCupCount == 1 ? '' : 's'} in cart! Add 1 more Tea Cup to get your FREE Cup';
        } else {
          messageText =
              '☕ +$cartCupCount Tea Cup${cartCupCount == 1 ? '' : 's'} in cart! Add $cupsNeededForReward more Tea Cup${cupsNeededForReward == 1 ? '' : 's'} to get your FREE Cup';
        }
      } else {
        // No cups in cart
        if (cupsNeededForReward == 1) {
          messageText = '☕ Add 1 Tea Cup to get your FREE Cup';
        } else {
          messageText =
              '☕ Add $cupsNeededForReward more Tea Cup${cupsNeededForReward == 1 ? '' : 's'} to get your FREE Cup';
        }
      }
    }

    String countText;
    if (isAtLastMilestone && totalCupsWithCart >= currentMilestone) {
      countText = '$totalCupsWithCart / ∞';
    } else if (displayTargetMilestone > 0) {
      countText = '$displayCurrentCups / $displayTargetMilestone';
    } else {
      countText = '$totalCupsWithCart cups collected';
    }

    // Get available width for badges
    final double availableWidth =
        MediaQuery.of(context).size.width -
        context.w(32); // 16 padding on each side
    final double totalSpacing = context.w(8) * 9; // 9 gaps between 10 items
    final double maxBeanSize = isTablet ? context.w(40) : context.w(34);

    // Calculate the optimal size to fit all 10 badges
    double beanSize = (availableWidth - totalSpacing) / 10;

    // Ensure it doesn't exceed max size but also not too small
    beanSize = beanSize.clamp(context.w(22), maxBeanSize);

    final double iconSize = beanSize * 0.5; // Proportional icon size
    final double backgroundImageSize = isTablet
        ? context.w(140)
        : context.w(100);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(24),
      ),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(context.r(16)),
        border: Border.all(color: theme.border, width: 1.w),
        boxShadow: [
          BoxShadow(
            color: SiporaTheme.shadowLight,
            blurRadius: 10.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Opacity(
              opacity: 0.75,
              child: IgnorePointer(
                ignoring: true,
                child: _CupImage(size: backgroundImageSize),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(context.w(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: isTablet ? context.w(40) : context.w(32),
                      height: isTablet ? context.w(40) : context.w(32),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: SiporaTheme.greenDark,
                          width: 1.5.w,
                        ),
                      ),
                      child: Icon(
                        Icons.coffee_rounded,
                        color: SiporaTheme.greenDark,
                        size: isTablet ? context.w(22) : context.w(18),
                      ),
                    ),
                    SizedBox(width: context.w(12)),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            'CupQuest',
                            style: TextStyle(
                              fontSize: isTablet
                                  ? context.sp(22)
                                  : context.sp(18),
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: theme.textDark,
                            ),
                          ),
                          if (tierLabel.isNotEmpty && !shouldShowCongrats) ...[
                            SizedBox(width: context.w(12)),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.w(10),
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: SiporaTheme.goldBg,
                                borderRadius: BorderRadius.circular(
                                  context.r(10),
                                ),
                              ),
                              child: Text(
                                tierLabel,
                                style: TextStyle(
                                  fontSize: isTablet
                                      ? context.sp(14)
                                      : context.sp(12),
                                  fontWeight: FontWeight.w700,
                                  color: SiporaTheme.goldText,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(12)),
                Text(
                  messageText,
                  style: TextStyle(
                    fontSize: isTablet ? context.sp(15) : context.sp(13),
                    color: theme.textMuted,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: context.h(18)),
                Text(
                  countText,
                  style: TextStyle(
                    fontSize: isTablet ? context.sp(20) : context.sp(16),
                    fontWeight: FontWeight.w700,
                    color: theme.textDark,
                  ),
                ),
                SizedBox(height: context.h(12)),
                // Single row with auto-adjusting badge sizes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: displayCups.map((cupNumber) {
                    // Check if this cup number is a milestone in the backend
                    final bool isMilestonePosition = milestonePositions
                        .contains(cupNumber);

                    // Check if this cup is collected based on total cups
                    final bool isCollected = cupNumber <= totalCupsWithCart;

                    // Check if this is a preview cup (in cart but not yet collected)
                    final bool isPreviewCup =
                        !isMilestonePosition &&
                        cupNumber > usedCups &&
                        cupNumber <= totalCupsWithCart;

                    return _buildBeanDot(
                      context: context,
                      isCollected: isCollected,
                      isMilestone: isMilestonePosition,
                      isPreviewCup: isPreviewCup,
                      cupNumber: cupNumber,
                      beanSize: beanSize,
                      iconSize: iconSize,
                    );
                  }).toList(),
                ),
                SizedBox(height: context.h(18)),
                ClipRRect(
                  borderRadius: BorderRadius.circular(context.r(4)),
                  child: LinearProgressIndicator(
                    value: progressFraction,
                    minHeight: isTablet ? context.h(6) : context.h(4),
                    backgroundColor: theme.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      SiporaTheme.greenDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeanDot({
    required BuildContext context,
    required bool isCollected,
    required bool isMilestone,
    required bool isPreviewCup,
    required int cupNumber,
    required double beanSize,
    required double iconSize,
  }) {
    Color borderColor;
    Color fillColor;
    Widget? child;
    double borderWidth = 1.5.w;

    if (isMilestone) {
      borderWidth = 2.w;
      if (isCollected) {
        borderColor = SiporaTheme.gold;
        fillColor = SiporaTheme.gold;
        child = Icon(Icons.star_rounded, color: Colors.white, size: iconSize);
      } else {
        borderColor = SiporaTheme.greenDark;
        fillColor = Colors.white;
        child = Icon(
          Icons.star_border_rounded,
          color: SiporaTheme.gold,
          size: iconSize,
        );
      }
    } else {
      if (isPreviewCup) {
        borderColor = SiporaTheme.gold;
        fillColor = SiporaTheme.greenMid.withValues(alpha: 0.4);
        child = Icon(
          Icons.coffee_rounded,
          color: SiporaTheme.greenMid.withValues(alpha: 0.7),
          size: iconSize - 2,
        );
      } else if (isCollected) {
        borderColor = SiporaTheme.gold;
        fillColor = SiporaTheme.greenDark;
        child = Icon(
          Icons.coffee_rounded,
          color: Colors.white,
          size: iconSize - 2,
        );
      } else {
        borderColor = SiporaTheme.greenDark;
        fillColor = Colors.white;
        child = Icon(
          Icons.coffee_outlined,
          color: SiporaTheme.greenDark.withValues(alpha: 0.4),
          size: iconSize - 2,
        );
      }
    }

    return Container(
      width: beanSize,
      height: beanSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fillColor,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Center(child: child),
    );
  }
}

class _CupImage extends StatefulWidget {
  final double size;
  const _CupImage({required this.size});

  @override
  State<_CupImage> createState() => _CupImageState();
}

class _CupImageState extends State<_CupImage> {
  static const String _url =
      'https://siporaimagescollection.blob.core.windows.net/websiteimages/MobileApp/Free_Cup-removebg.png';

  bool _loaded = false;
  bool _error = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const NetworkImage(_url), context)
        .then((_) {
          if (mounted) setState(() => _loaded = true);
        })
        .catchError((e) {
          if (mounted) setState(() => _error = true);
        });
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Icon(
        Icons.coffee_rounded,
        size: widget.size * 0.6,
        color: SiporaTheme.gold,
      );
    }
    if (!_loaded) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: SiporaTheme.gold,
            ),
          ),
        ),
      );
    }
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Image(
        image: const NetworkImage(_url),
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
      ),
    );
  }
}
