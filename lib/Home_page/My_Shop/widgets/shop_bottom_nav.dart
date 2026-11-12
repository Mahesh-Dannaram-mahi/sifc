import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import '../../../theme/sipora_theme.dart';

class ShopBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const ShopBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(8),
        context.w(16),
        bottomPadding > 0 ? bottomPadding : context.h(8),
      ),
      decoration: BoxDecoration(
        color: SiporaTheme.greenDark,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.r(20)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15.r,
            offset: Offset(0, -4.h),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context,
            index: 0,
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            isActive: selectedIndex == 0,
          ),
          _buildNavItem(
            context,
            index: 1,
            icon: Icons.analytics_rounded,
            label: 'Analytics',
            isActive: selectedIndex == 1,
          ),
          _buildNavItem(
            context,
            index: 2,
            icon: Icons.receipt_long_rounded,
            label: 'Orders',
            isActive: selectedIndex == 2,
          ),
          _buildNavItem(
            context,
            index: 3,
            icon: Icons.inventory_2_rounded,
            label: 'Inventory',
            isActive: selectedIndex == 3,
          ),
          _buildNavItem(
            context,
            index: 4,
            icon: Icons.payments_rounded,
            label: 'Settlements',
            isActive: selectedIndex == 4,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    final theme = context.siporaTheme;

    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(context.w(6)),
            decoration: BoxDecoration(
              color: isActive
                  ? SiporaTheme.gold.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(context.r(10)),
            ),
            child: Icon(
              icon,
              color: isActive ? SiporaTheme.gold : Colors.white70,
              size: context.w(24),
            ),
          ),
          SizedBox(height: context.h(2)),
          Text(
            label,
            style: TextStyle(
              fontSize: context.sp(9),
              color: isActive ? SiporaTheme.gold : Colors.white60,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
