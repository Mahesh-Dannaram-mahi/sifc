import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import '../../theme/sipora_theme.dart';
import '../../utils/screen_utils.dart';

/// A widget that displays recent searches and popular searches sections
class RecentPopularSearches extends StatelessWidget {
  final List<String> recentSearches;
  final List<String> popularSearches;
  final Function(String) onSearchTap;
  final Function(String) onRemoveRecent;
  final VoidCallback onClearAllRecent;

  const RecentPopularSearches({
    super.key,
    required this.recentSearches,
    required this.popularSearches,
    required this.onSearchTap,
    required this.onRemoveRecent,
    required this.onClearAllRecent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;

    return Column(
      children: [
        if (recentSearches.isNotEmpty)
          _buildRecentSearchesSection(context, theme),
        _buildPopularSearchesSection(context, theme),
      ],
    );
  }

  Widget _buildRecentSearchesSection(
    BuildContext context,
    SiporaThemeExtension theme,
  ) {
    final isTablet = context.isTablet;
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: TextStyle(
                  fontSize: isTablet ? context.sp(18) : context.sp(16),
                  fontWeight: FontWeight.w700,
                  color: theme.textDark,
                ),
              ),
              TextButton(
                onPressed: onClearAllRecent,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Clear all',
                  style: TextStyle(
                    color: SiporaTheme.greenPill,
                    fontSize: isTablet ? context.sp(13) : context.sp(12),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(12)),
          SizedBox(
            height: context.h(82),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: screenWidth - context.w(40),
                ),
                child: Wrap(
                  spacing: context.w(8),
                  runSpacing: context.h(8),
                  children: recentSearches.map((term) {
                    return _RecentChip(
                      label: term,
                      icon: Icons.access_time_rounded,
                      onTap: () => onSearchTap(term),
                      onRemove: () => onRemoveRecent(term),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularSearchesSection(
    BuildContext context,
    SiporaThemeExtension theme,
  ) {
    if (popularSearches.isEmpty) return const SizedBox.shrink();

    final isTablet = context.isTablet;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Searches',
            style: TextStyle(
              fontSize: isTablet ? context.sp(18) : context.sp(16),
              fontWeight: FontWeight.w700,
              color: theme.textDark,
            ),
          ),
          SizedBox(height: context.h(12)),
          SizedBox(
            height: context.h(82),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: (popularSearches.length / 2).ceil(),
              itemBuilder: (context, columnIndex) {
                final firstIndex = columnIndex * 2;
                final secondIndex = firstIndex + 1;

                return Padding(
                  padding: EdgeInsets.only(right: context.w(8)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (firstIndex < popularSearches.length)
                        _PopularChip(
                          label: popularSearches[firstIndex],
                          icon: Icons.trending_up_rounded,
                          onTap: () => onSearchTap(popularSearches[firstIndex]),
                        )
                      else
                        const SizedBox.shrink(),
                      SizedBox(height: context.h(8)),
                      if (secondIndex < popularSearches.length)
                        _PopularChip(
                          label: popularSearches[secondIndex],
                          icon: Icons.trending_up_rounded,
                          onTap: () =>
                              onSearchTap(popularSearches[secondIndex]),
                        )
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Premium UI Components for Popular and Recent Chips
// ════════════════════════════════════════════════════════════════════════════

class _PopularChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PopularChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(12),
          vertical: context.h(6),
        ),
        decoration: BoxDecoration(
          color: theme.white,
          borderRadius: BorderRadius.circular(context.r(20)),
          boxShadow: [
            BoxShadow(
              color: SiporaTheme.shadowLight,
              blurRadius: 4.r,
              offset: Offset(0, 1.h),
            ),
          ],
          border: Border.all(color: theme.border, width: 1.w),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isTablet ? context.w(14) : context.w(12),
              color: SiporaTheme.greenDark,
            ),
            SizedBox(width: context.w(4)),
            Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? context.sp(13) : context.sp(12),
                fontWeight: FontWeight.w600,
                color: theme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _RecentChip({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(12),
          vertical: context.h(6),
        ),
        decoration: BoxDecoration(
          color: theme.white,
          borderRadius: BorderRadius.circular(context.r(20)),
          boxShadow: [
            BoxShadow(
              color: SiporaTheme.shadowLight,
              blurRadius: 4.r,
              offset: Offset(0, 1.h),
            ),
          ],
          border: Border.all(color: theme.border, width: 1.w),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isTablet ? context.w(14) : context.w(12),
              color: SiporaTheme.greenDark,
            ),
            SizedBox(width: context.w(4)),
            Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? context.sp(13) : context.sp(12),
                fontWeight: FontWeight.w600,
                color: theme.textDark,
              ),
            ),
            SizedBox(width: context.w(6)),
            GestureDetector(
              onTap: onRemove,
              child: Icon(
                Icons.close_rounded,
                size: isTablet ? context.w(16) : context.w(14),
                color: theme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
