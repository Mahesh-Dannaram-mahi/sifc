import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:provider/provider.dart';
import '../../../theme/sipora_theme.dart';
import '../../../providers/user_provider.dart';
import '../../../utils/screen_utils.dart';
// ✅ Import HomePage instead of ProfileInformationPage
import '../../../Home_page/home_page.dart';

class ShopDashboardHeader extends StatelessWidget {
  final String shopName;
  final VoidCallback? onMyAppTap;

  const ShopDashboardHeader({
    super.key,
    required this.shopName,
    this.onMyAppTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.userData;
    final firstName = user?['first_name'] ?? '';
    final lastName = user?['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final displayName = fullName.isEmpty ? 'Sipora User' : fullName;
    final avatarUrl = user?['avataricons'];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(12),
      ),
      decoration: BoxDecoration(
        color: SiporaTheme.greenDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // User Avatar
          Container(
            width: isTablet ? context.w(50) : context.w(42),
            height: isTablet ? context.w(50) : context.w(42),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: SiporaTheme.gold.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: avatarUrl != null && avatarUrl.isNotEmpty
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderAvatar(
                            context,
                            displayName,
                            isTablet,
                          ),
                    )
                  : _buildPlaceholderAvatar(context, displayName, isTablet),
            ),
          ),
          SizedBox(width: context.w(12)),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: isTablet ? context.sp(20) : context.sp(17),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'My Shop Dashboard',
                  style: TextStyle(
                    fontSize: isTablet ? context.sp(14) : context.sp(12),
                    color: SiporaTheme.greenPill,
                  ),
                ),
              ],
            ),
          ),
          // Switch to My App Button - Navigates to HomePage
          GestureDetector(
            onTap:
                onMyAppTap ??
                () {
                  // ✅ Navigate to HomePage (main app UI)
                  // Use pushReplacement to replace current route
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
                },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(12),
                vertical: context.h(8),
              ),
              decoration: BoxDecoration(
                color: SiporaTheme.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(context.r(20)),
                border: Border.all(
                  color: SiporaTheme.gold.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.home_rounded,
                    color: SiporaTheme.gold,
                    size: isTablet ? context.w(18) : context.w(14),
                  ),
                  SizedBox(width: context.w(4)),
                  Text(
                    'My App',
                    style: TextStyle(
                      color: SiporaTheme.gold,
                      fontSize: isTablet ? context.sp(14) : context.sp(11),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: context.w(2)),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: SiporaTheme.gold,
                    size: isTablet ? context.w(16) : context.w(14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderAvatar(
    BuildContext context,
    String displayName,
    bool isTablet,
  ) {
    return Container(
      color: SiporaTheme.greenMid,
      child: Center(
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
          style: TextStyle(
            fontSize: isTablet ? context.sp(24) : context.sp(20),
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
