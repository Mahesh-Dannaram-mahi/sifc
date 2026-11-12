import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/sipora_theme.dart';
import '../../utils/responsive_constants.dart';
import 'terms_and_conditions.dart';

class TermsBottomSheet extends StatefulWidget {
  const TermsBottomSheet({super.key});

  @override
  State<TermsBottomSheet> createState() => _TermsBottomSheetState();
}

class _TermsBottomSheetState extends State<TermsBottomSheet>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  String _activeSection = 'welcome';

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
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
    final responsive = _ResponsiveValues.fromContext(context);

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 100 * (1 - _slideAnimation.value)),
          child: Opacity(
            opacity: _slideAnimation.value,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                color: theme.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: SiporaTheme.shadowMedium,
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildHeader(responsive),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(child: _buildMainContent(responsive)),
                        _buildBottomNavigation(responsive),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(_ResponsiveValues responsive) {
    final theme = context.siporaTheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.screenPadding,
        vertical: responsive.gridSpacing * 2,
      ),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(bottom: BorderSide(color: theme.border, width: 1)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.greenMid.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: responsive.gridSpacing * 2),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [SiporaTheme.greenDark, SiporaTheme.greenMid],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: SiporaTheme.greenDark.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: responsive.gridSpacing * 1.5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        fontSize: responsive.titleFontSize,
                        fontWeight: FontWeight.w700,
                        color: theme.textDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: responsive.gridSpacing / 2),
                    Text(
                      TermsAndConditions.lastUpdated,
                      style: TextStyle(
                        fontSize: responsive.fontSize - 1,
                        color: theme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await _animationController.reverse();
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(responsive.gridSpacing),
                  decoration: BoxDecoration(
                    color: theme.greenBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: theme.greenMid,
                    size: responsive.iconSize - 4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(_ResponsiveValues responsive) {
    final theme = context.siporaTheme;

    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: theme.cream,
        border: Border(top: BorderSide(color: theme.border, width: 1)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: responsive.gridSpacing * 1.5,
          vertical: responsive.gridSpacing * 1.25,
        ),
        itemCount: TermsAndConditions.sectionIds.length,
        itemBuilder: (context, index) {
          final sectionId = TermsAndConditions.sectionIds[index];
          final section = TermsAndConditions.sections[sectionId];
          final isActive = sectionId == _activeSection;

          return Container(
            width: 110,
            margin: EdgeInsets.symmetric(
              horizontal: responsive.gridSpacing / 2,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (isActive) {
                    Navigator.of(context).pop();
                  } else {
                    setState(() {
                      _activeSection = sectionId;
                    });
                    _scrollToSection(sectionId);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.gridSpacing,
                    vertical: responsive.gridSpacing,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? theme.greenBg : theme.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive ? theme.greenMid : theme.border,
                      width: isActive ? 2 : 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: theme.greenDark.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: SiporaTheme.shadowLight,
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(responsive.gridSpacing / 2),
                        decoration: BoxDecoration(
                          color: isActive
                              ? theme.greenDark.withValues(alpha: 0.1)
                              : theme.greenBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getSectionIcon(sectionId),
                          size: responsive.iconSize - 9,
                          color: isActive
                              ? theme.greenMid
                              : SiporaTheme.greenLight,
                        ),
                      ),
                      SizedBox(height: responsive.gridSpacing / 4),
                      Text(
                        section['title'] ?? '',
                        style: TextStyle(
                          fontSize: responsive.fontSize - 4,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isActive ? theme.greenMid : theme.textDark,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent(_ResponsiveValues responsive) {
    final theme = context.siporaTheme;
    final section = TermsAndConditions.sections[_activeSection];
    final details = TermsAndConditions.getSectionDetails(_activeSection);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.all(responsive.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(responsive.cardPadding + 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [SiporaTheme.greenDark, SiporaTheme.greenMid],
              ),
              borderRadius: BorderRadius.circular(responsive.cardRadius + 2),
              boxShadow: [
                BoxShadow(
                  color: SiporaTheme.greenDark.withValues(alpha: 0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getSectionIcon(_activeSection),
                        color: Colors.white,
                        size: responsive.iconSize,
                      ),
                    ),
                    SizedBox(width: responsive.gridSpacing * 1.75),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section['title'] ?? '',
                            style: TextStyle(
                              fontSize: responsive.titleFontSize + 2,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: responsive.gridSpacing / 2),
                          Text(
                            section['summary'] ?? '',
                            style: TextStyle(
                              fontSize: responsive.fontSize,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: responsive.gridSpacing * 3),
          ...details.map((detail) {
            return Container(
              margin: EdgeInsets.only(bottom: responsive.gridSpacing * 2.5),
              padding: EdgeInsets.all(responsive.cardPadding),
              decoration: BoxDecoration(
                color: theme.white,
                borderRadius: BorderRadius.circular(responsive.cardRadius),
                border: Border.all(color: theme.border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: SiporaTheme.shadowLight,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (detail.title != null) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.gridSpacing * 1.25,
                        vertical: responsive.gridSpacing,
                      ),
                      decoration: BoxDecoration(
                        color: theme.greenBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        detail.title!,
                        style: TextStyle(
                          fontSize: responsive.fontSize + 1,
                          fontWeight: FontWeight.w700,
                          color: theme.greenMid,
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.gridSpacing * 1.75),
                  ],
                  ...detail.points.map((point) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: responsive.gridSpacing * 1.25,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: EdgeInsets.only(
                              top: responsive.gridSpacing,
                              right: responsive.gridSpacing * 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: theme.greenMid,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              point,
                              style: TextStyle(
                                fontSize: responsive.fontSize + 1,
                                height: 1.6,
                                color: theme.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (detail.note != null) ...[
                    SizedBox(height: responsive.gridSpacing * 1.75),
                    Container(
                      padding: EdgeInsets.all(responsive.gridSpacing * 1.75),
                      decoration: BoxDecoration(
                        color: theme.greenBg.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.greenMid.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(responsive.gridSpacing / 2),
                            decoration: BoxDecoration(
                              color: theme.greenMid.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.info_outline_rounded,
                              size: responsive.iconSize - 6,
                              color: theme.greenMid,
                            ),
                          ),
                          SizedBox(width: responsive.gridSpacing * 1.25),
                          Expanded(
                            child: Text(
                              detail.note!,
                              style: TextStyle(
                                fontSize: responsive.fontSize,
                                color: theme.greenMid,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          SizedBox(height: responsive.gridSpacing * 4),
        ],
      ),
    );
  }

void _scrollToSection(String sectionId) {
  // Check if controller is still attached and mounted
  if (!mounted || !_scrollController.hasClients) return;
  
  try {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ).catchError((error) {
      // Handle any errors during animation
      if (mounted) {
      }
    });
  } catch (e) {
    // Prevent crashes if animation fails
    if (mounted) {
    }
  }
}

  IconData _getSectionIcon(String sectionId) {
    switch (sectionId) {
      case 'welcome':
        return Icons.waving_hand_rounded;
      case 'introduction':
        return Icons.info_outline_rounded;
      case 'definitions':
        return Icons.menu_book_rounded;
      case 'registration':
        return Icons.person_add_rounded;
      case 'merchant':
        return Icons.store_rounded;
      case 'payments':
        return Icons.payment_rounded;
      case 'refunds':
        return Icons.replay_rounded;
      case 'loyalty':
        return Icons.card_giftcard_rounded;
      case 'rights':
        return Icons.shield_rounded;
      case 'privacy':
        return Icons.lock_rounded;
      case 'legal':
        return Icons.balance_rounded;
      default:
        return Icons.article_rounded;
    }
  }
}

class _ResponsiveValues {
  final double screenPadding;
  final double gridSpacing;
  final double iconSize;
  final double fontSize;
  final double titleFontSize;
  final double cardRadius;
  final double cardPadding;

  _ResponsiveValues({
    required this.screenPadding,
    required this.gridSpacing,
    required this.iconSize,
    required this.fontSize,
    required this.titleFontSize,
    required this.cardRadius,
    required this.cardPadding,
  });

  factory _ResponsiveValues.fromContext(BuildContext context) {
    return _ResponsiveValues(
      screenPadding: ResponsiveConstants.getScreenPadding(context),
      gridSpacing: ResponsiveConstants.getGridSpacing(context),
      iconSize: ResponsiveConstants.getIconSize(context),
      fontSize: ResponsiveConstants.getFontSize(context),
      titleFontSize: ResponsiveConstants.getTitleFontSize(context),
      cardRadius: ResponsiveConstants.getCardBorderRadius(context),
      cardPadding: ResponsiveConstants.getCardPadding(context),
    );
  }
}
