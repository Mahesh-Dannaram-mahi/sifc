import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/sipora_theme.dart';
import '../../utils/responsive_constants.dart';

class AppPreferencesPage extends StatefulWidget {
  const AppPreferencesPage({super.key});

  @override
  State<AppPreferencesPage> createState() => _AppPreferencesPageState();
}

class _AppPreferencesPageState extends State<AppPreferencesPage> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final isTablet = context.isTabletScreen;
    final gridSpacing = ResponsiveConstants.getGridSpacing(context);

    return Scaffold(
      backgroundColor: theme.cream,
      appBar: _buildAppBar(isTablet),
      body: ListView(
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? gridSpacing * 3.5 : gridSpacing * 2.5,
        ),
        children: [
          // Notifications Section
          _SectionLabel(label: 'Notifications'),
          SizedBox(height: gridSpacing),
          _buildNotificationsSection(),

          SizedBox(height: gridSpacing * 2.5),

          // Divider
          _buildSectionDivider(),

          // Appearance Section - Single Button
          _SectionLabel(label: 'Appearance'),
          SizedBox(height: gridSpacing),
          _buildAppearanceButton(),

          SizedBox(height: gridSpacing * 3),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  APP BAR
  // ─────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(bool isTablet) {
    final theme = context.siporaTheme;
    final avatarSize = ResponsiveConstants.getAvatarSize(context);
    final iconSize = ResponsiveConstants.getIconSize(context);
    final titleFontSize = ResponsiveConstants.getTitleFontSize(context);
    final screenPadding = ResponsiveConstants.getScreenPadding(context);

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
        padding: EdgeInsets.only(left: screenPadding),
        child: Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                color: theme.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.border, width: 1.5),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: iconSize - 4,
                color: theme.textDark,
              ),
            ),
          ),
        ),
      ),
      title: Text(
        'App Preferences',
        style: TextStyle(
          fontSize: titleFontSize - 2, // REDUCED
          fontWeight: FontWeight.w700,
          color: theme.textDark,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  SECTION DIVIDER
  // ─────────────────────────────────────────────
  Widget _buildSectionDivider() {
    final theme = context.siporaTheme;
    final screenPadding = ResponsiveConstants.getScreenPadding(context);
    final gridSpacing = ResponsiveConstants.getGridSpacing(context);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenPadding,
        vertical: gridSpacing,
      ),
      height: 1,
      color: theme.border.withValues(alpha: 0.5),
    );
  }

  // ─────────────────────────────────────────────
  //  NOTIFICATIONS SECTION
  // ─────────────────────────────────────────────
  Widget _buildNotificationsSection() {
    final theme = context.siporaTheme;
    final screenPadding = ResponsiveConstants.getScreenPadding(context);
    final cardRadius = ResponsiveConstants.getCardBorderRadius(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenPadding),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(cardRadius),
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
        children: [
          _NotificationTile(
            icon: Icons.notifications_none_rounded,
            title: 'Push Notifications',
            subtitle: 'Get updates & alerts',
            value: _pushNotifications,
            onChanged: (v) {
              setState(() => _pushNotifications = v);
              _showSnack('Push notifications ${v ? 'enabled' : 'disabled'}');
            },
          ),
          _NotificationTile(
            icon: Icons.email_outlined,
            title: 'Email Notifications',
            subtitle: 'Receive email updates',
            value: _emailNotifications,
            onChanged: (v) {
              setState(() => _emailNotifications = v);
              _showSnack('Email notifications ${v ? 'enabled' : 'disabled'}');
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  APPEARANCE BUTTON (Single button that opens popup)
  // ─────────────────────────────────────────────
  Widget _buildAppearanceButton() {
    final theme = context.siporaTheme;
    final isTablet = context.isTabletScreen;
    final iconSize = isTablet ? 20.0 : 16.0; // REDUCED from 22/18
    final iconContainerSize = isTablet ? 44.0 : 34.0; // REDUCED from 48/38
    final screenPadding = ResponsiveConstants.getScreenPadding(context);
    final gridSpacing = ResponsiveConstants.getGridSpacing(context);
    final cardRadius = ResponsiveConstants.getCardBorderRadius(context);

    // Get current theme mode to display
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;
    String currentTheme = 'Light Mode';
    if (themeMode == ThemeMode.dark) {
      currentTheme = 'Dark Mode';
    } else if (themeMode == ThemeMode.system) {
      currentTheme = 'System Default';
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenPadding),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: theme.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: SiporaTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showThemeDialog(),
          borderRadius: BorderRadius.circular(cardRadius),
          highlightColor: SiporaTheme.greenSurface,
          splashColor: SiporaTheme.greenBg,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenPadding,
              vertical: isTablet ? 16 : 11, // REDUCED from 18/13
            ),
            child: Row(
              children: [
                Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    color: SiporaTheme.greenBg,
                    borderRadius: BorderRadius.circular(cardRadius - 5),
                  ),
                  child: Icon(
                    Icons.palette_outlined,
                    color: SiporaTheme.greenMid,
                    size: iconSize,
                  ),
                ),
                SizedBox(width: gridSpacing * 1.5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Theme',
                        style: TextStyle(
                          fontSize: isTablet
                              ? 14.0
                              : 12.0, // REDUCED from 16/14
                          fontWeight: FontWeight.w600,
                          color: theme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentTheme,
                        style: TextStyle(
                          fontSize: isTablet
                              ? 12.0
                              : 10.0, // REDUCED from 14/12
                          color: theme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: ResponsiveConstants.getIconSize(context),
                  color: theme.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  THEME SELECTION BOTTOM SHEET (Professional looking)
  // ─────────────────────────────────────────────
  void _showThemeDialog() {
    final theme = context.siporaTheme;
    final isTablet = context.isTabletScreen;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: theme.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8), // REDUCED from 10
                    decoration: BoxDecoration(
                      color: SiporaTheme.greenBg,
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // REDUCED from 14
                    ),
                    child: Icon(
                      Icons.palette_outlined,
                      color: SiporaTheme.greenMid,
                      size: isTablet ? 22 : 18, // REDUCED from 26/22
                    ),
                  ),
                  const SizedBox(width: 12), // REDUCED from 14
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose Theme',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16, // REDUCED from 20/18
                          fontWeight: FontWeight.w700,
                          color: theme.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Select your preferred appearance',
                        style: TextStyle(
                          fontSize: isTablet ? 12 : 10, // REDUCED from 14/12
                          color: theme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Theme options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _ThemeOption(
                    icon: Icons.light_mode_rounded,
                    title: 'Light Mode',
                    description: 'Bright and clean appearance',
                    isSelected:
                        Provider.of<ThemeProvider>(ctx).themeMode ==
                        ThemeMode.light,
                    onTap: () {
                      Provider.of<ThemeProvider>(
                        ctx,
                        listen: false,
                      ).setThemeMode(ThemeMode.light);
                      _showSnack('Light theme applied');
                      if (mounted) setState(() {});
                      Navigator.pop(ctx);
                    },
                  ),
                  _ThemeOption(
                    icon: Icons.dark_mode_rounded,
                    title: 'Dark Mode',
                    description: 'Easy on the eyes, saves battery',
                    isSelected:
                        Provider.of<ThemeProvider>(ctx).themeMode ==
                        ThemeMode.dark,
                    onTap: () {
                      Provider.of<ThemeProvider>(
                        ctx,
                        listen: false,
                      ).setThemeMode(ThemeMode.dark);
                      _showSnack('Dark theme applied');
                      if (mounted) setState(() {});
                      Navigator.pop(ctx);
                    },
                  ),
                  _ThemeOption(
                    icon: Icons.settings_suggest_rounded,
                    title: 'System Default',
                    description: 'Follow your device settings',
                    isSelected:
                        Provider.of<ThemeProvider>(ctx).themeMode ==
                        ThemeMode.system,
                    onTap: () {
                      Provider.of<ThemeProvider>(
                        ctx,
                        listen: false,
                      ).setThemeMode(ThemeMode.system);
                      _showSnack('Following system theme');
                      if (mounted) setState(() {});
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20), // REDUCED from 24
          ],
        ),
      ),
    );
  }

  void _showSnack(String message) {
    SiporaTheme.showSnackBar(context, message, isError: false);
  }
}

// ─────────────────────────────────────────────
//  SECTION LABEL
// ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final screenPadding = ResponsiveConstants.getScreenPadding(context);
    final gridSpacing = ResponsiveConstants.getGridSpacing(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenPadding,
        vertical: gridSpacing,
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11, // REDUCED from 12
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7, // REDUCED from 0.8
          color: SiporaTheme.greenMid,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  NOTIFICATION TILE
// ─────────────────────────────────────────────
class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final isTablet = context.isTabletScreen;
    final iconSize = isTablet ? 20.0 : 16.0; // REDUCED from 22/18
    final iconContainerSize = isTablet ? 44.0 : 34.0; // REDUCED from 48/38
    final screenPadding = ResponsiveConstants.getScreenPadding(context);
    final gridSpacing = ResponsiveConstants.getGridSpacing(context);
    final cardRadius = ResponsiveConstants.getCardBorderRadius(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenPadding,
        vertical: isTablet ? 10 : 7, // REDUCED from 12/8
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: SiporaTheme.borderLight, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: iconContainerSize,
            height: iconContainerSize,
            decoration: BoxDecoration(
              color: SiporaTheme.greenBg,
              borderRadius: BorderRadius.circular(cardRadius - 5),
            ),
            child: Icon(icon, color: SiporaTheme.greenMid, size: iconSize),
          ),
          SizedBox(width: gridSpacing * 1.5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12, // REDUCED from 16/14
                    fontWeight: FontWeight.w600,
                    color: theme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: isTablet ? 12 : 10, // REDUCED from 14/12
                    color: theme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8, // REDUCED switch size
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: SiporaTheme.greenDark,
              activeTrackColor: SiporaTheme.greenDark.withValues(alpha: 0.25),
              inactiveThumbColor: theme.textMuted,
              inactiveTrackColor: theme.textMuted.withValues(alpha: 0.18),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  THEME OPTION (Professional Card Style)
// ─────────────────────────────────────────────
class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final isTablet = context.isTabletScreen;
    final iconSize = isTablet ? 22.0 : 18.0; // REDUCED from 26/22
    final iconContainerSize = isTablet ? 48.0 : 40.0; // REDUCED from 56/48

    return Container(
      margin: const EdgeInsets.only(bottom: 10), // REDUCED from 12
      decoration: BoxDecoration(
        color: isSelected
            ? SiporaTheme.greenBg.withValues(alpha: 0.4)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14), // REDUCED from 16
        border: Border.all(
          color: isSelected ? SiporaTheme.greenMid : theme.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          highlightColor: SiporaTheme.greenSurface,
          splashColor: SiporaTheme.greenBg,
          child: Padding(
            padding: const EdgeInsets.all(12), // REDUCED from 16
            child: Row(
              children: [
                Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? SiporaTheme.greenDark.withValues(alpha: 0.1)
                        : SiporaTheme.greenBg,
                    borderRadius: BorderRadius.circular(12), // REDUCED from 14
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? SiporaTheme.greenDark
                        : SiporaTheme.greenMid,
                    size: iconSize,
                  ),
                ),
                const SizedBox(width: 12), // REDUCED from 16
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: isTablet ? 15 : 13, // REDUCED from 17/15
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? SiporaTheme.greenDark
                              : theme.textDark,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3), // REDUCED from 4
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: isTablet ? 12 : 10, // REDUCED from 14/12
                          color: theme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(3), // REDUCED from 4
                    decoration: BoxDecoration(
                      color: SiporaTheme.greenDark,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14, // REDUCED from 16
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14, // REDUCED from 18
                    color: theme.textMuted.withValues(alpha: 0.5),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
