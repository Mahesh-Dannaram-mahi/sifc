import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/sipora_theme.dart';
import '../../utils/responsive_constants.dart';

class PolicyBottomSheet extends StatefulWidget {
  final String title;
  final String lastUpdated;
  final Map<String, dynamic> sections;
  final List<String> sectionIds;
  final String Function(String) getSectionTitle;
  final String Function(String) getSectionSummary;
  final List<Map<String, dynamic>> Function(String) getSectionDetails;
  final IconData Function(String) getSectionIcon;

  const PolicyBottomSheet({
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
  State<PolicyBottomSheet> createState() => _PolicyBottomSheetState();
}

class _PolicyBottomSheetState extends State<PolicyBottomSheet> {
  final ScrollController _scrollController = ScrollController();
  String _activeSection = '';

  @override
  void initState() {
    super.initState();
    _activeSection = widget.sectionIds.isNotEmpty
        ? widget.sectionIds.first
        : '';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.9,
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildMainContent(context)),
                _buildBottomNavigation(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = context.siporaTheme;
    final screenPadding = ResponsiveConstants.getScreenPadding(context);
    final gridSpacing = ResponsiveConstants.getGridSpacing(context);
    final iconSize = ResponsiveConstants.getIconSize(context);
    final titleFontSize = ResponsiveConstants.getTitleFontSize(context);
    final fontSize = ResponsiveConstants.getFontSize(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenPadding,
        vertical: gridSpacing * 1.5,
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
              color: theme.textMuted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: iconSize + 4,
                height: iconSize + 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [SiporaTheme.greenDark, SiporaTheme.greenMid],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: Colors.white,
                  size: iconSize - 4,
                ),
              ),
              SizedBox(width: gridSpacing * 1.5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w700,
                        color: theme.textDark,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      widget.lastUpdated,
                      style: TextStyle(
                        fontSize: fontSize - 1,
                        color: theme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: EdgeInsets.all(gridSpacing),
                  decoration: BoxDecoration(
                    color: SiporaTheme.greenBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: SiporaTheme.greenMid,
                    size: iconSize - 4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    final theme = context.siporaTheme;
    final gridSpacing = ResponsiveConstants.getGridSpacing(context);
    final iconSize = ResponsiveConstants.getIconSize(context);
    final fontSize = ResponsiveConstants.getFontSize(context);
    final cardRadius = ResponsiveConstants.getCardBorderRadius(context);

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: theme.cream,
        border: Border(top: BorderSide(color: theme.border, width: 1)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: gridSpacing,
          vertical: gridSpacing,
        ),
        itemCount: widget.sectionIds.length,
        itemBuilder: (context, index) {
          final sectionId = widget.sectionIds[index];
          final isActive = sectionId == _activeSection;

          return Container(
            width: ResponsiveConstants.responsive(
              context,
              defaultValue: 120.0,
              tablet: 140.0,
            ),
            margin: EdgeInsets.symmetric(horizontal: gridSpacing * 0.5),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(cardRadius - 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(cardRadius - 4),
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
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: gridSpacing * 0.75,
                    vertical: gridSpacing * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? SiporaTheme.greenBg : theme.white,
                    borderRadius: BorderRadius.circular(cardRadius - 4),
                    border: Border.all(
                      color: isActive ? SiporaTheme.greenMid : theme.border,
                      width: isActive ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.getSectionIcon(sectionId),
                        size: iconSize - 4,
                        color: isActive
                            ? SiporaTheme.greenMid
                            : theme.textMuted,
                      ),
                      SizedBox(height: gridSpacing * 0.5),
                      Text(
                        widget.getSectionTitle(sectionId),
                        style: TextStyle(
                          fontSize: fontSize - 2,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isActive
                              ? SiporaTheme.greenMid
                              : theme.textDark,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
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

  Widget _buildMainContent(BuildContext context) {
    final theme = context.siporaTheme;
    final details = widget.getSectionDetails(_activeSection);
    final screenPadding = ResponsiveConstants.getScreenPadding(context);
    final gridSpacing = ResponsiveConstants.getGridSpacing(context);
    final iconSize = ResponsiveConstants.getIconSize(context);
    final fontSize = ResponsiveConstants.getFontSize(context);
    final titleFontSize = ResponsiveConstants.getTitleFontSize(context);
    final cardRadius = ResponsiveConstants.getCardBorderRadius(context);
    final cardPadding = ResponsiveConstants.getCardPadding(context);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.all(screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [SiporaTheme.greenDark, SiporaTheme.greenMid],
              ),
              borderRadius: BorderRadius.circular(cardRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: iconSize + 10,
                      height: iconSize + 10,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(cardRadius - 4),
                      ),
                      child: Icon(
                        widget.getSectionIcon(_activeSection),
                        color: Colors.white,
                        size: iconSize,
                      ),
                    ),
                    SizedBox(width: gridSpacing * 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.getSectionTitle(_activeSection),
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: gridSpacing * 0.5),
                          Text(
                            widget.getSectionSummary(_activeSection),
                            style: TextStyle(
                              fontSize: fontSize - 1,
                              color: Colors.white.withValues(alpha: 0.9),
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

          SizedBox(height: gridSpacing * 3),

          ...details.asMap().entries.map((entry) {
            final detail = entry.value;

            return Container(
              margin: EdgeInsets.only(bottom: gridSpacing * 2.5),
              child: Material(
                elevation: 0,
                borderRadius: BorderRadius.circular(cardRadius - 4),
                color: theme.white,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(cardRadius - 4),
                  child: Container(
                    padding: EdgeInsets.all(cardPadding),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.border),
                      borderRadius: BorderRadius.circular(cardRadius - 4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (detail['title'] != null) ...[
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: gridSpacing * 1.25,
                              vertical: gridSpacing * 0.5,
                            ),
                            decoration: BoxDecoration(
                              color: SiporaTheme.greenBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              detail['title'],
                              style: TextStyle(
                                fontSize: fontSize - 1,
                                fontWeight: FontWeight.w600,
                                color: SiporaTheme.greenMid,
                              ),
                            ),
                          ),
                          SizedBox(height: gridSpacing * 1.5),
                        ],

                        ...(detail['points'] as List<String>).map((point) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: gridSpacing),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: EdgeInsets.only(
                                    top: gridSpacing,
                                    right: gridSpacing * 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: SiporaTheme.greenMid,
                                    borderRadius: BorderRadius.circular(3),
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
                        }),

                        if (detail['note'] != null) ...[
                          SizedBox(height: gridSpacing * 1.5),
                          Container(
                            padding: EdgeInsets.all(gridSpacing * 1.5),
                            decoration: BoxDecoration(
                              color: SiporaTheme.greenBg.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: SiporaTheme.greenMid.withValues(
                                  alpha: 0.2,
                                ),
                              ),
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
                                    'Note: ${detail['note']}',
                                    style: TextStyle(
                                      fontSize: fontSize - 2,
                                      color: SiporaTheme.greenMid,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          SizedBox(height: gridSpacing * 5),
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
}
