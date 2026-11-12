import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../services/location_service.dart';
import '../../providers/user_provider.dart';
import '../../Setting_page/widgets/profile_information_page.dart';
import '../../theme/sipora_theme.dart';
import '../../utils/responsive_constants.dart';

class AppHeader extends StatefulWidget {
  const AppHeader({super.key});

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  String get _greetingEmoji {
    final hour = DateTime.now().hour;
    if (hour < 12) return '👋';
    if (hour < 17) return '☀️';
    return '🌙';
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _getCurrentLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    final isTablet = screenType == ScreenType.tablet;
    final isSmall = screenType == ScreenType.small;
    final responsive = _ResponsiveValues.fromContext(context);

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.userData;
        final firstName = user?['first_name'] ?? '';
        final lastName = user?['last_name'] ?? '';
        final fullName = '$firstName $lastName'.trim();
        final displayName = fullName.isEmpty ? 'Sipora User' : fullName;
        final avatarUrl = user?['avataricons'];

        return Container(
          color: SiporaTheme.greenDark,
          padding: EdgeInsets.symmetric(
            horizontal: responsive.screenPadding,
            vertical: responsive.verticalPadding,
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                GestureDetector(
                  onTap: () {
                    // Optional: Navigate to home or do nothing
                  },
                  child: Image.asset(
                    'assets/images/sipora_logo.png',
                    width: responsive.logoSize,
                    height: responsive.logoSize,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: responsive.logoSize,
                        height: responsive.logoSize,
                        decoration: BoxDecoration(
                          color: SiporaTheme.gold,
                          borderRadius: BorderRadius.circular(
                            isTablet ? 12 : 8,
                          ),
                        ),
                        child: Icon(
                          Icons.local_cafe,
                          color: SiporaTheme.greenDark,
                          size: responsive.logoSize * 0.55,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: isSmall ? 8 : (isTablet ? 16 : 12)),

                // Greeting & name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$_greeting ',
                            style: TextStyle(
                              fontSize: responsive.greetingFontSize,
                              color: SiporaTheme.greenPill,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            _greetingEmoji,
                            style: TextStyle(
                              fontSize: responsive.greetingFontSize,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: responsive.nameFontSize,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Fuel your day with Sipora ',
                            style: TextStyle(
                              fontSize: responsive.taglineFontSize,
                              color: SiporaTheme.greenLight,
                            ),
                          ),
                          Text(
                            '☕',
                            style: TextStyle(
                              fontSize: responsive.taglineFontSize,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Notifications + Avatar
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: () {
                            // Notifications feature - to be implemented in future
                          },
                          icon: Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: responsive.iconSize + 4,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: isSmall ? 28 : 32,
                            minHeight: isSmall ? 28 : 32,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: isSmall ? 6 : 8,
                            height: isSmall ? 6 : 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF5722),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: isSmall ? 4 : 8),

                    // Avatar - Navigate to Profile Information when tapped
                    GestureDetector(
                      onTap: () {
                        // Navigate to Profile Information Page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ProfileInformationPage(),
                          ),
                        ).then((_) {
                          // Refresh user data when coming back from profile page
                          userProvider.refreshUser();
                        });
                      },
                      child: Container(
                        width: responsive.avatarSize,
                        height: responsive.avatarSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: SiporaTheme.greenLight,
                            width: isSmall ? 1.5 : 2.0,
                          ),
                        ),
                        child: ClipOval(
                          child: avatarUrl != null && avatarUrl.isNotEmpty
                              ? Image.network(
                                  avatarUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      _buildPlaceholderAvatar(
                                        responsive.avatarSize,
                                      ),
                                )
                              : _buildPlaceholderAvatar(responsive.avatarSize),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderAvatar(double size) {
    return Container(
      color: SiporaTheme.greenMid,
      child: Icon(
        Icons.person,
        color: SiporaTheme.greenLight,
        size: size * 0.6,
      ),
    );
  }

  // ------------------------------------------------------------------
  // Location methods with theme-aware snackbars
  // ------------------------------------------------------------------
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await LocationService.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationServiceDialog();
      return;
    }

    LocationPermission permission = await LocationService.checkPermission();
    if (permission == LocationPermission.denied) {
      _showPermissionDialog();
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      _showSettingsDialog();
      return;
    }

    // ✅ Fixed: Now getCurrentLocation is defined in LocationService
    Position? position = await LocationService.getCurrentLocation().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        return null;
      },
    );

    if (position != null) {
      // Location obtained successfully
    } else {
      if (mounted) {
        SiporaTheme.showSnackBar(
          context,
          'Failed to get location',
          isError: true,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  void _showLocationServiceDialog() {
    final theme = context.siporaTheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _buildStyledAlertDialog(
        title: 'Location Service Disabled',
        content: 'Please enable location services to use this app.',
        onConfirm: () {
          Navigator.pop(ctx);
          Geolocator.openLocationSettings();
        },
        onCancel: () {
          _closeApp();
        },
        theme: theme,
      ),
    );
  }

  void _showPermissionDialog() {
    final theme = context.siporaTheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _buildStyledAlertDialog(
        title: 'Location Permission Required',
        content: 'Grant location permission to use this app.',
        onConfirm: () async {
          Navigator.pop(ctx);
          await Geolocator.requestPermission();
          _getCurrentLocation();
        },
        onCancel: () {
          _closeApp();
        },
        theme: theme,
      ),
    );
  }

  void _showSettingsDialog() {
    final theme = context.siporaTheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _buildStyledAlertDialog(
        title: 'Location Permission Denied',
        content:
            'Please enable location permission in app settings to use this app.',
        onConfirm: () {
          Navigator.pop(ctx);
          Geolocator.openAppSettings();
        },
        onCancel: () {
          _closeApp();
        },
        theme: theme,
      ),
    );
  }

  void _closeApp() {
    exit(0);
  }

  Widget _buildStyledAlertDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
    required SiporaThemeExtension theme,
  }) {
    return AlertDialog(
      title: Text(
        title,
        style: TextStyle(
          fontSize: ResponsiveConstants.getTitleFontSize(context),
          fontWeight: FontWeight.w700,
          color: theme.textDark,
        ),
      ),
      content: Text(
        content,
        style: TextStyle(
          fontSize: ResponsiveConstants.getFontSize(context),
          color: theme.textDark,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(
            'Cancel',
            style: TextStyle(
              fontSize: ResponsiveConstants.getFontSize(context),
              fontWeight: FontWeight.w600,
              color: theme.textMuted,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: SiporaTheme.greenDark,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Enable'),
        ),
      ],
    );
  }
}

/// Helper class to cache responsive values for better performance
class _ResponsiveValues {
  final double screenPadding;
  final double gridSpacing;
  final double iconSize;
  final double fontSize;
  final double titleFontSize;
  final double cardRadius;
  final double cardPadding;
  final double avatarSize;
  final double logoSize;
  final double verticalPadding;
  final double greetingFontSize;
  final double nameFontSize;
  final double taglineFontSize;

  _ResponsiveValues({
    required this.screenPadding,
    required this.gridSpacing,
    required this.iconSize,
    required this.fontSize,
    required this.titleFontSize,
    required this.cardRadius,
    required this.cardPadding,
    required this.avatarSize,
    required this.logoSize,
    required this.verticalPadding,
    required this.greetingFontSize,
    required this.nameFontSize,
    required this.taglineFontSize,
  });

  factory _ResponsiveValues.fromContext(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    final isTablet = screenType == ScreenType.tablet;
    final isSmall = screenType == ScreenType.small;

    return _ResponsiveValues(
      screenPadding: ResponsiveConstants.getScreenPadding(context),
      gridSpacing: ResponsiveConstants.getGridSpacing(context),
      iconSize: ResponsiveConstants.getIconSize(context),
      fontSize: ResponsiveConstants.getFontSize(context),
      titleFontSize: ResponsiveConstants.getTitleFontSize(context),
      cardRadius: ResponsiveConstants.getCardBorderRadius(context),
      cardPadding: ResponsiveConstants.getCardPadding(context),
      avatarSize: ResponsiveConstants.getAvatarSize(context),
      logoSize: isTablet ? 68.0 : (isSmall ? 44.0 : 52.0),
      verticalPadding: isSmall ? 6.0 : (isTablet ? 14.0 : 10.0),
      greetingFontSize: isSmall ? 11.0 : (isTablet ? 15.0 : 13.0),
      nameFontSize: isSmall ? 15.0 : (isTablet ? 22.0 : 18.0),
      taglineFontSize: isSmall ? 10.0 : (isTablet ? 14.0 : 12.0),
    );
  }
}
