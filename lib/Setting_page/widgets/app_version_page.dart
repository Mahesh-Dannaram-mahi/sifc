import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/api_config.dart';
import '../../../theme/sipora_theme.dart';
import '../../../utils/responsive_constants.dart';

class AppVersionPage extends StatefulWidget {
  const AppVersionPage({super.key});

  @override
  State<AppVersionPage> createState() => _AppVersionPageState();
}

class _AppVersionPageState extends State<AppVersionPage>
    with SingleTickerProviderStateMixin {
  String _appVersion = 'Loading...';
  DateTime? _buildTime;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _getAppInfo();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _getAppInfo() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();

      setState(() {
        _appVersion = packageInfo.version;
      });

      try {
        final String pubspecString = await rootBundle.loadString(
          'pubspec.yaml',
        );
        final List<String> lines = pubspecString.split('\n');
        for (final String line in lines) {
          if (line.startsWith('version:')) {
            final String versionLine = line.substring(8).trim();
            final List<String> parts = versionLine.split('+');
            setState(() {
              _appVersion = parts[0];
            });
            break;
          }
        }
      } catch (e) {}

      setState(() {
        _buildTime = DateTime(2026, 6, 10);
      });
    } catch (e) {
      setState(() {
        _appVersion = '1.0.0';
        _buildTime = DateTime(2026, 6, 10);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;

    return Scaffold(
      backgroundColor: theme.cream,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              ResponsiveConstants.getScreenPadding(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLogoAndVersionSection(),
                SizedBox(
                  height: ResponsiveConstants.responsive(
                    context,
                    defaultValue: 24.0,
                    tablet: 32.0,
                  ),
                ),
                _buildSectionHeader(
                  title: 'What\'s New in Version $_appVersion',
                  icon: Icons.new_releases_rounded,
                ),
                SizedBox(
                  height: ResponsiveConstants.responsive(
                    context,
                    defaultValue: 16.0,
                    tablet: 20.0,
                  ),
                ),
                _buildVersionUpdatesCard(),
                SizedBox(
                  height: ResponsiveConstants.responsive(
                    context,
                    defaultValue: 24.0,
                    tablet: 28.0,
                  ),
                ),
                _buildSectionHeader(
                  title: 'Legal Information',
                  icon: Icons.gavel_rounded,
                ),
                SizedBox(
                  height: ResponsiveConstants.responsive(
                    context,
                    defaultValue: 16.0,
                    tablet: 20.0,
                  ),
                ),
                _buildLegalCard(),
                SizedBox(
                  height: ResponsiveConstants.responsive(
                    context,
                    defaultValue: 24.0,
                    tablet: 28.0,
                  ),
                ),
                _buildSectionHeader(
                  title: 'Support',
                  icon: Icons.support_agent_rounded,
                ),
                SizedBox(
                  height: ResponsiveConstants.responsive(
                    context,
                    defaultValue: 16.0,
                    tablet: 20.0,
                  ),
                ),
                _buildSupportCard(),
                SizedBox(
                  height: ResponsiveConstants.responsive(
                    context,
                    defaultValue: 24.0,
                    tablet: 28.0,
                  ),
                ),
                _buildSectionHeader(
                  title: 'App Information',
                  icon: Icons.info_outline_rounded,
                ),
                SizedBox(
                  height: ResponsiveConstants.responsive(
                    context,
                    defaultValue: 16.0,
                    tablet: 20.0,
                  ),
                ),
                _buildAppInfoCard(),
                SizedBox(
                  height: ResponsiveConstants.responsive(
                    context,
                    defaultValue: 28.0,
                    tablet: 36.0,
                  ),
                ),
                _buildCopyright(),
                SizedBox(
                  height: ResponsiveConstants.responsive(
                    context,
                    defaultValue: 16.0,
                    tablet: 24.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final theme = context.siporaTheme;
    final avatarSize = ResponsiveConstants.getAvatarSize(context);
    final iconSize = ResponsiveConstants.getIconSize(context);
    final titleFontSize = ResponsiveConstants.getTitleFontSize(context);

    return AppBar(
      backgroundColor: theme.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: theme.border),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
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
        'App Details',
        style: TextStyle(
          fontSize: titleFontSize,
          fontWeight: FontWeight.w700,
          color: theme.textDark,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildLogoAndVersionSection() {
    final theme = context.siporaTheme;
    final productImageSize = ResponsiveConstants.getProductImageSize(context);
    final headingFontSize = ResponsiveConstants.getHeadingFontSize(context);
    final fontSize = ResponsiveConstants.getFontSize(context);

    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  SiporaTheme.gold.withValues(alpha: 0.3),
                  SiporaTheme.greenMid.withValues(alpha: 0.3),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.white,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/sipora_logo.png',
                  width: productImageSize * 1.2,
                  height: productImageSize,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: productImageSize * 1.2,
                      height: productImageSize,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [SiporaTheme.gold, SiporaTheme.greenMid],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          'S',
                          style: TextStyle(
                            fontSize: headingFontSize * 1.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveConstants.responsive(
                context,
                defaultValue: 20.0,
                small: 16.0,
                tablet: 24.0,
              ),
              vertical: ResponsiveConstants.responsive(
                context,
                defaultValue: 10.0,
                small: 8.0,
                tablet: 12.0,
              ),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [SiporaTheme.goldBg, SiporaTheme.greenBg],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              'Version $_appVersion',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: SiporaTheme.greenMid,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required IconData icon}) {
    final screenType = SiporaTheme.getScreenType(context);
    final isTablet = screenType == ScreenType.tablet;
    final iconSize = ResponsiveConstants.getIconSize(context);
    final fontSize = ResponsiveConstants.getFontSize(context);

    return Row(
      children: [
        Container(
          width: 4,
          height: isTablet ? 26 : 22,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [SiporaTheme.gold, SiporaTheme.greenMid],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: EdgeInsets.all(isTablet ? 8 : 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                SiporaTheme.gold.withValues(alpha: 0.1),
                SiporaTheme.greenMid.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
          ),
          child: Icon(icon, size: iconSize, color: SiporaTheme.greenMid),
        ),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: SiporaTheme.greenMid,
          ),
        ),
      ],
    );
  }

  Widget _buildVersionUpdatesCard() {
    final theme = context.siporaTheme;
    final iconSize = ResponsiveConstants.getIconSize(context);
    final fontSize = ResponsiveConstants.getFontSize(context);

    return Container(
      padding: EdgeInsets.all(
        ResponsiveConstants.responsive(
          context,
          defaultValue: 20.0,
          tablet: 28.0,
        ),
      ),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(
          ResponsiveConstants.responsive(
            context,
            defaultValue: 20.0,
            tablet: 24.0,
          ),
        ),
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
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  ResponsiveConstants.responsive(
                    context,
                    defaultValue: 6.0,
                    tablet: 8.0,
                  ),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      SiporaTheme.greenMid.withValues(alpha: 0.2),
                      SiporaTheme.greenMid.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_rounded,
                  size: iconSize,
                  color: SiporaTheme.greenMid,
                ),
              ),
              SizedBox(
                width: ResponsiveConstants.responsive(
                  context,
                  defaultValue: 12.0,
                  tablet: 16.0,
                ),
              ),
              Expanded(
                child: Text(
                  'Version $_appVersion Updates',
                  style: TextStyle(
                    fontSize: fontSize - 1, // REDUCED from fontSize
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6, // REDUCED from 0.8
                    color: SiporaTheme.greenMid,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: ResponsiveConstants.responsive(
              context,
              defaultValue: 12.0, // REDUCED from 16.0
              tablet: 16.0, // REDUCED from 20.0
            ),
          ),
          Text(
            '• Resolved various bugs and performance issues\n'
            '• Updated Sipora with a fresh, modern UI/UX design\n'
            '• Introduced CupQuest tracker to monitor your rewards\n'
            '• Implemented coupons section in cart for easy savings\n'
            '• Enhanced product search and filtering experience\n'
            '• Improved payment flow\n'
            '• Optimized app performance and loading times',
            style: TextStyle(
              fontSize: fontSize - 2, // REDUCED from fontSize (was fontSize)
              color: theme.textDark,
              height: 1.5, // REDUCED from 1.6
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalCard() {
    final theme = context.siporaTheme;

    return Container(
      padding: EdgeInsets.all(
        ResponsiveConstants.responsive(
          context,
          defaultValue: 20.0,
          tablet: 28.0,
        ),
      ),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(
          ResponsiveConstants.responsive(
            context,
            defaultValue: 20.0,
            tablet: 24.0,
          ),
        ),
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
          _buildClickableRow(
            icon: Icons.privacy_tip_rounded,
            label: 'Privacy Policy',
            onTap: () => _showPrivacyPolicyDialog(context),
          ),
          Divider(
            height: ResponsiveConstants.responsive(
              context,
              defaultValue: 24.0,
              tablet: 28.0,
            ),
            color: theme.border,
          ),
          _buildClickableRow(
            icon: Icons.description_rounded,
            label: 'Terms of Service',
            onTap: () => _showTermsOfServiceDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard() {
    final theme = context.siporaTheme;

    return Container(
      padding: EdgeInsets.all(
        ResponsiveConstants.responsive(
          context,
          defaultValue: 20.0,
          tablet: 28.0,
        ),
      ),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(
          ResponsiveConstants.responsive(
            context,
            defaultValue: 20.0,
            tablet: 24.0,
          ),
        ),
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
          _buildClickableRow(
            icon: Icons.email_rounded,
            label: 'Email Support',
            onTap: () => _showEmailDialog(context),
          ),
          Divider(
            height: ResponsiveConstants.responsive(
              context,
              defaultValue: 24.0,
              tablet: 28.0,
            ),
            color: theme.border,
          ),
          _buildClickableRow(
            icon: Icons.language_rounded,
            label: 'Website',
            onTap: () => _showWebsiteDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoCard() {
    final theme = context.siporaTheme;

    return Container(
      padding: EdgeInsets.all(
        ResponsiveConstants.responsive(
          context,
          defaultValue: 20.0,
          tablet: 28.0,
        ),
      ),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(
          ResponsiveConstants.responsive(
            context,
            defaultValue: 20.0,
            tablet: 24.0,
          ),
        ),
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
          _buildInfoRow(
            'Build Date',
            _buildTime != null
                ? '${_buildTime!.day}/${_buildTime!.month}/${_buildTime!.year}'
                : 'Unknown',
          ),
          Divider(
            height: ResponsiveConstants.responsive(
              context,
              defaultValue: 24.0,
              tablet: 28.0,
            ),
            color: theme.border,
          ),
          _buildClickableInfoRowWithBothOptions(
            'Developed by',
            'AMDV Technologies Private Limited',
          ),

          // For And uncommit

          // Divider(
          //   height: ResponsiveConstants.responsive(
          //     context,
          //     defaultValue: 24.0,
          //     tablet: 28.0,
          //   ),
          //   color: theme.border,
          // ),
          // _buildInfoRow('Platform', 'Flutter'),
          // Divider(
          //   height: ResponsiveConstants.responsive(
          //     context,
          //     defaultValue: 24.0,
          //     tablet: 28.0,
          //   ),
          //   color: theme.border,
          // ),
          // _buildInfoRow('Target Platforms', 'Android & IOS'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = context.siporaTheme;
    final screenType = SiporaTheme.getScreenType(context);
    final isTablet = screenType == ScreenType.tablet;
    final fontSize = ResponsiveConstants.getFontSize(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? fontSize + 2 : fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: SiporaTheme.greenMid,
          ),
        ),
        SizedBox(
          height: ResponsiveConstants.responsive(
            context,
            defaultValue: 4.0,
            tablet: 6.0,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize + 2,
            fontWeight: FontWeight.w500,
            color: theme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildClickableInfoRowWithBothOptions(String label, String value) {
    final screenType = SiporaTheme.getScreenType(context);
    final isTablet = screenType == ScreenType.tablet;
    final fontSize = ResponsiveConstants.getFontSize(context);
    final iconSize = ResponsiveConstants.getIconSize(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? fontSize + 2 : fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: SiporaTheme.greenMid,
          ),
        ),
        SizedBox(
          height: ResponsiveConstants.responsive(
            context,
            defaultValue: 4.0,
            tablet: 6.0,
          ),
        ),
        GestureDetector(
          onTap: () => _showAMDVOptionsDialog(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: fontSize + 2,
                  fontWeight: FontWeight.w500,
                  color: SiporaTheme.greenMid,
                  decoration: TextDecoration.underline,
                  decorationColor: SiporaTheme.greenMid,
                ),
              ),
              SizedBox(
                width: ResponsiveConstants.responsive(
                  context,
                  defaultValue: 6.0,
                  tablet: 8.0,
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                size: iconSize * 0.8,
                color: SiporaTheme.greenMid,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClickableRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final iconSize = ResponsiveConstants.getIconSize(context);
    final fontSize = ResponsiveConstants.getFontSize(context);

    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(
              ResponsiveConstants.responsive(
                context,
                defaultValue: 8.0,
                tablet: 10.0,
              ),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  SiporaTheme.gold.withValues(alpha: 0.1),
                  SiporaTheme.greenMid.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(
                ResponsiveConstants.responsive(
                  context,
                  defaultValue: 10.0,
                  tablet: 12.0,
                ),
              ),
            ),
            child: Icon(icon, size: iconSize, color: SiporaTheme.greenMid),
          ),
          SizedBox(
            width: ResponsiveConstants.responsive(
              context,
              defaultValue: 12.0,
              tablet: 16.0,
            ),
          ),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: SiporaTheme.greenMid,
              ),
            ),
          ),
          Icon(
            Icons.open_in_new_rounded,
            size: iconSize * 0.9,
            color: SiporaTheme.greenMid,
          ),
        ],
      ),
    );
  }

  Widget _buildCopyright() {
    final theme = context.siporaTheme;
    final iconSize = ResponsiveConstants.getIconSize(context);
    final fontSize = ResponsiveConstants.getFontSize(context);

    return Center(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveConstants.responsive(
                context,
                defaultValue: 20.0,
                tablet: 28.0,
              ),
              vertical: ResponsiveConstants.responsive(
                context,
                defaultValue: 12.0,
                tablet: 14.0,
              ),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [SiporaTheme.goldBg, SiporaTheme.greenBg],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.copyright_rounded,
                  size: iconSize * 0.8,
                  color: SiporaTheme.greenMid,
                ),
                SizedBox(
                  width: ResponsiveConstants.responsive(
                    context,
                    defaultValue: 8.0,
                    tablet: 10.0,
                  ),
                ),
                Text(
                  '2026 Sipora',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: SiporaTheme.greenMid,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: ResponsiveConstants.responsive(
              context,
              defaultValue: 8.0,
              tablet: 10.0,
            ),
          ),
          Text(
            'All rights reserved',
            style: TextStyle(fontSize: fontSize, color: theme.textMuted),
          ),
        ],
      ),
    );
  }

  void _showWebsiteDialog(BuildContext context) {
    final theme = context.siporaTheme;
    final String websiteUrl = ApiConfig.privacyPolicyUrl.replaceAll(
      '/privacy',
      '',
    );
    final fontSize = ResponsiveConstants.getFontSize(context);
    final iconSize = ResponsiveConstants.getIconSize(context);
    final buttonHeight = ResponsiveConstants.getButtonHeight(context);
    final buttonFontSize = ResponsiveConstants.getButtonFontSize(context);
    final cardRadius = ResponsiveConstants.getCardBorderRadius(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
          backgroundColor: theme.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SiporaTheme.greenBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.language_rounded,
                  color: SiporaTheme.greenMid,
                  size: iconSize,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Open Website',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: SiporaTheme.greenMid,
                ),
              ),
            ],
          ),
          content: Text(
            'This will open your browser to view the website. Do you want to proceed?',
            style: TextStyle(
              fontSize: fontSize,
              color: theme.textMuted,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(fontSize: fontSize, color: theme.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final Uri uri = Uri.parse(websiteUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              style: SiporaTheme.primaryButtonStyle(height: buttonHeight),
              child: Text(
                'Proceed',
                style: TextStyle(fontSize: buttonFontSize),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEmailDialog(BuildContext context) {
    final theme = context.siporaTheme;
    const String emailAddress = 'pavan.admin@siporagroups.com';
    final fontSize = ResponsiveConstants.getFontSize(context);
    final iconSize = ResponsiveConstants.getIconSize(context);
    final buttonHeight = ResponsiveConstants.getButtonHeight(context);
    final buttonFontSize = ResponsiveConstants.getButtonFontSize(context);
    final cardRadius = ResponsiveConstants.getCardBorderRadius(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
          backgroundColor: theme.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SiporaTheme.greenBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.email_rounded,
                  color: SiporaTheme.greenMid,
                  size: iconSize,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Open Email',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: SiporaTheme.greenMid,
                ),
              ),
            ],
          ),
          content: Text(
            'This will open your email app to send a message. Do you want to proceed?',
            style: TextStyle(
              fontSize: fontSize,
              color: theme.textMuted,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(fontSize: fontSize, color: theme.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final Uri uri = Uri(scheme: 'mailto', path: emailAddress);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              style: SiporaTheme.primaryButtonStyle(height: buttonHeight),
              child: Text(
                'Proceed',
                style: TextStyle(fontSize: buttonFontSize),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    final theme = context.siporaTheme;
    final fontSize = ResponsiveConstants.getFontSize(context);
    final iconSize = ResponsiveConstants.getIconSize(context);
    final buttonHeight = ResponsiveConstants.getButtonHeight(context);
    final buttonFontSize = ResponsiveConstants.getButtonFontSize(context);
    final cardRadius = ResponsiveConstants.getCardBorderRadius(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
          backgroundColor: theme.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SiporaTheme.greenBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.privacy_tip_rounded,
                  color: SiporaTheme.greenMid,
                  size: iconSize,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: SiporaTheme.greenMid,
                ),
              ),
            ],
          ),
          content: Text(
            'This will open your browser to view the Privacy Policy. Do you want to proceed?',
            style: TextStyle(
              fontSize: fontSize,
              color: theme.textMuted,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(fontSize: fontSize, color: theme.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final Uri uri = Uri.parse(ApiConfig.privacyPolicyUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              style: SiporaTheme.primaryButtonStyle(height: buttonHeight),
              child: Text(
                'Proceed',
                style: TextStyle(fontSize: buttonFontSize),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showTermsOfServiceDialog(BuildContext context) {
    final theme = context.siporaTheme;
    final String termsUrl =
        '${ApiConfig.privacyPolicyUrl.replaceAll('/privacy', '')}/terms';
    final fontSize = ResponsiveConstants.getFontSize(context);
    final iconSize = ResponsiveConstants.getIconSize(context);
    final buttonHeight = ResponsiveConstants.getButtonHeight(context);
    final buttonFontSize = ResponsiveConstants.getButtonFontSize(context);
    final cardRadius = ResponsiveConstants.getCardBorderRadius(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
          backgroundColor: theme.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SiporaTheme.greenBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.description_rounded,
                  color: SiporaTheme.greenMid,
                  size: iconSize,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Terms of Service',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: SiporaTheme.greenMid,
                ),
              ),
            ],
          ),
          content: Text(
            'This will open your browser to view the Terms of Service. Do you want to proceed?',
            style: TextStyle(
              fontSize: fontSize,
              color: theme.textMuted,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(fontSize: fontSize, color: theme.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final Uri uri = Uri.parse(termsUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              style: SiporaTheme.primaryButtonStyle(height: buttonHeight),
              child: Text(
                'Proceed',
                style: TextStyle(fontSize: buttonFontSize),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAMDVOptionsDialog(BuildContext context) {
    final theme = context.siporaTheme;
    const String websiteUrl = 'https://www.amdvnextzen.com/';
    const String linkedinUrl =
        'https://www.linkedin.com/company/amdv-technologies-private-limited/about/';
    final fontSize = ResponsiveConstants.getFontSize(context);
    final iconSize = ResponsiveConstants.getIconSize(context);
    final buttonFontSize = ResponsiveConstants.getButtonFontSize(context);
    final cardRadius = ResponsiveConstants.getCardBorderRadius(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
          backgroundColor: theme.white,
          child: Container(
            padding: EdgeInsets.all(
              ResponsiveConstants.responsive(
                context,
                defaultValue: 20.0,
                tablet: 24.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: SiporaTheme.greenBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.business_center_rounded,
                            color: SiporaTheme.greenMid,
                            size: iconSize,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'AMDV Technologies',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: SiporaTheme.greenMid,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: SiporaTheme.greenBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: iconSize * 0.9,
                          color: theme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Choose an option to learn more about AMDV Technologies:',
                  style: TextStyle(
                    fontSize: fontSize,
                    color: theme.textMuted,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          final Uri uri = Uri.parse(websiteUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        icon: Icon(
                          Icons.language_rounded,
                          size: iconSize * 0.9,
                        ),
                        label: Text(
                          'Visit Website',
                          style: TextStyle(
                            fontSize:
                                buttonFontSize -
                                2, // REDUCED from buttonFontSize
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SiporaTheme.greenMid,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(cardRadius),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          final Uri uri = Uri.parse(linkedinUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        icon: Icon(
                          Icons.business_center_rounded,
                          size: iconSize * 0.9,
                        ),
                        label: Text(
                          'Visit LinkedIn',
                          style: TextStyle(
                            fontSize:
                                buttonFontSize -
                                2, // REDUCED from buttonFontSize
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: SiporaTheme.greenMid,
                          side: BorderSide(color: SiporaTheme.greenMid),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(cardRadius),
                          ),
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
}
