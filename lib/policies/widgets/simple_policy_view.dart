import 'package:flutter/material.dart';
import '../../theme/sipora_theme.dart';
import '../../utils/responsive_constants.dart';

/// Model class for policy section details
class PolicySectionDetail {
  final String? title;
  final List<String> points;
  final String? note;

  const PolicySectionDetail({this.title, required this.points, this.note});

  factory PolicySectionDetail.fromMap(Map<String, dynamic> map) {
    return PolicySectionDetail(
      title: map['title'] as String?,
      points: List<String>.from(map['points'] as List),
      note: map['note'] as String?,
    );
  }
}

class SimplePolicyView extends StatefulWidget {
  final String title;
  final String lastUpdated;
  final Map<String, dynamic> sections;
  final List<String> sectionIds;
  final String Function(String) getSectionTitle;
  final String Function(String) getSectionSummary;
  final List<PolicySectionDetail> Function(String) getSectionDetails;
  final IconData Function(String) getSectionIcon;

  const SimplePolicyView({
    super.key,
    required this.title,
    required this.lastUpdated,
    required this.sections,
    required this.sectionIds,
    required this.getSectionTitle,
    required this.getSectionSummary,
    required this.getSectionDetails,
    required this.getSectionIcon,
  });

  @override
  State<SimplePolicyView> createState() => _SimplePolicyViewState();
}

class _SimplePolicyViewState extends State<SimplePolicyView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final screenType = SiporaTheme.getScreenType(context);
    final isTablet = screenType == ScreenType.tablet;
    final responsive = _ResponsiveValues.fromContext(context);

    return Scaffold(
      backgroundColor: theme.cream,
      appBar: _buildAppBar(responsive),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.sectionIds.isEmpty
            ? _buildEmptyState(responsive)
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  vertical: isTablet
                      ? responsive.gridSpacing * 1.5
                      : responsive.gridSpacing,
                ),
                children: [
                  _buildHeaderBanner(responsive, isTablet),
                  ...widget.sectionIds.map((sectionId) {
                    final details = widget.getSectionDetails(sectionId);
                    return _buildPolicySection(
                      sectionId: sectionId,
                      details: details,
                      responsive: responsive,
                      isTablet: isTablet,
                    );
                  }),
                  SizedBox(height: responsive.gridSpacing * 4),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState(_ResponsiveValues responsive) {
    final theme = context.siporaTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: responsive.iconSize * 2,
            color: theme.textMuted,
          ),
          SizedBox(height: responsive.gridSpacing * 2),
          Text(
            'No policy information available',
            style: TextStyle(
              fontSize: responsive.fontSize,
              color: theme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection({
    required String sectionId,
    required List<PolicySectionDetail> details,
    required _ResponsiveValues responsive,
    required bool isTablet,
  }) {
    final theme = context.siporaTheme;
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: responsive.screenPadding,
        vertical: responsive.gridSpacing,
      ),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(responsive.cardRadius - 4),
        color: theme.white,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(responsive.cardRadius - 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(responsive.cardPadding),
                decoration: BoxDecoration(
                  color: SiporaTheme.greenBg,
                  border: Border(
                    bottom: BorderSide(color: theme.border, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: responsive.iconSize + 4,
                      height: responsive.iconSize + 4,
                      decoration: BoxDecoration(
                        color: SiporaTheme.greenDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.getSectionIcon(sectionId),
                        color: Colors.white,
                        size: responsive.iconSize - 4,
                      ),
                    ),
                    SizedBox(width: responsive.gridSpacing * 1.5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.getSectionTitle(sectionId),
                            style: TextStyle(
                              fontSize: responsive.titleFontSize - 1,
                              fontWeight: FontWeight.w600,
                              color: theme.textDark,
                            ),
                          ),
                          Text(
                            widget.getSectionSummary(sectionId),
                            style: TextStyle(
                              fontSize: responsive.fontSize - 1,
                              color: theme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(responsive.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: details.map((detail) {
                    return _PolicySectionDetailWidget(
                      detail: detail,
                      gridSpacing: responsive.gridSpacing,
                      fontSize: responsive.fontSize,
                      iconSize: responsive.iconSize,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(_ResponsiveValues responsive) {
    final theme = context.siporaTheme;
    return AppBar(
      backgroundColor: theme.white,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: theme.border),
      ),
      leading: Padding(
        padding: EdgeInsets.only(left: responsive.screenPadding),
        child: Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: responsive.avatarSize,
              height: responsive.avatarSize,
              decoration: BoxDecoration(
                color: theme.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.border, width: 1.5),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: responsive.iconSize - 4,
                color: theme.textDark,
              ),
            ),
          ),
        ),
      ),
      title: Text(
        widget.title,
        style: TextStyle(
          fontSize: responsive.titleFontSize,
          fontWeight: FontWeight.w700,
          color: theme.textDark,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(_ResponsiveValues responsive, bool isTablet) {
    return Container(
      margin: EdgeInsets.all(
        isTablet ? responsive.screenPadding * 1.5 : responsive.screenPadding,
      ),
      padding: EdgeInsets.all(
        isTablet ? responsive.cardPadding + 8 : responsive.cardPadding,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SiporaTheme.greenDark, SiporaTheme.greenMid],
        ),
        borderRadius: BorderRadius.circular(responsive.cardRadius),
        boxShadow: [
          BoxShadow(
            color: SiporaTheme.greenDark.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: isTablet
                        ? responsive.titleFontSize + 4
                        : responsive.titleFontSize + 2,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: responsive.gridSpacing),
                Text(
                  widget.lastUpdated,
                  style: TextStyle(
                    fontSize: isTablet
                        ? responsive.fontSize + 1
                        : responsive.fontSize,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: responsive.gridSpacing * 2),
          Container(
            padding: EdgeInsets.all(
              isTablet ? responsive.iconSize - 4 : responsive.iconSize - 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(responsive.cardRadius - 4),
            ),
            child: Icon(
              Icons.policy_rounded,
              color: Colors.white,
              size: isTablet
                  ? responsive.iconSize + 10
                  : responsive.iconSize + 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicySectionDetailWidget extends StatelessWidget {
  final PolicySectionDetail detail;
  final double gridSpacing;
  final double fontSize;
  final double iconSize;

  const _PolicySectionDetailWidget({
    required this.detail,
    required this.gridSpacing,
    required this.fontSize,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: gridSpacing * 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (detail.title != null) ...[
            _buildTitleBadge(context),
            SizedBox(height: gridSpacing * 1.5),
          ],
          ..._buildPoints(context),
          if (detail.note != null) ...[
            SizedBox(height: gridSpacing * 1.5),
            _buildNoteSection(context),
          ],
        ],
      ),
    );
  }

  Widget _buildTitleBadge(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: gridSpacing * 1.25,
        vertical: gridSpacing * 0.5,
      ),
      decoration: BoxDecoration(
        color: SiporaTheme.greenBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        detail.title!,
        style: TextStyle(
          fontSize: fontSize - 1,
          fontWeight: FontWeight.w600,
          color: SiporaTheme.greenMid,
        ),
      ),
    );
  }

  List<Widget> _buildPoints(BuildContext context) {
    final theme = context.siporaTheme;
    return detail.points.map((point) {
      return Padding(
        padding: EdgeInsets.only(bottom: gridSpacing, left: gridSpacing),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 5,
              height: 5,
              margin: EdgeInsets.only(
                top: gridSpacing,
                right: gridSpacing * 1.25,
              ),
              decoration: BoxDecoration(
                color: SiporaTheme.greenMid,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            Expanded(
              child: Text(
                point,
                style: TextStyle(
                  fontSize: fontSize,
                  height: 1.5,
                  color: theme.textDark,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildNoteSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(gridSpacing * 1.5),
      decoration: BoxDecoration(
        color: SiporaTheme.greenBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SiporaTheme.greenMid.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: iconSize - 6,
            color: SiporaTheme.greenMid,
          ),
          SizedBox(width: gridSpacing * 1.5),
          Expanded(
            child: Text(
              'Note: ${detail.note}',
              style: TextStyle(
                fontSize: fontSize - 2,
                color: SiporaTheme.greenMid,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
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
  final double avatarSize;

  _ResponsiveValues({
    required this.screenPadding,
    required this.gridSpacing,
    required this.iconSize,
    required this.fontSize,
    required this.titleFontSize,
    required this.cardRadius,
    required this.cardPadding,
    required this.avatarSize,
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
      avatarSize: ResponsiveConstants.getAvatarSize(context),
    );
  }
}
