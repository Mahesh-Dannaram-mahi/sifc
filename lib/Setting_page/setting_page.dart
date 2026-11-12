import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:sipora/Setting_page/widgets/favorites_page.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Home_page/widgets/bottom_nav_text_row.dart';
import '../Login_page/widgets/login.dart';
import '../policies/policies_page.dart';
import 'widgets/app_version_page.dart';
import 'widgets/help_center_page.dart';
import 'widgets/profile_information_page.dart';
import 'widgets/support_ticket_page.dart';
import 'widgets/shipping_addresses_page.dart';
import './widgets/app_preferences_page.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../../config/api_config.dart';
import '../../services/jwt_service.dart';
import '../../services/storage_service.dart';
import '../../theme/sipora_theme.dart';
import '../../utils/responsive_constants.dart';
import 'widgets/invoice_page.dart';
import 'widgets/wallet_recharge_page.dart';
import 'widgets/wallet_security_page.dart';
import '../pages/warehouse_orders_page.dart';
// NEW: Import Product Analytics Page
import 'widgets/product_analytics_page.dart';
import 'widgets/delete_account_page.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage>
    with SingleTickerProviderStateMixin {
  String _appVersion = 'Loading...';

  // User data
  Map<String, dynamic>? _userData;
  bool _isLoadingProfile = true;
  bool _isLoadingRole = true;
  bool _isFranchiseOwner = false;
  bool _isLoggedIn = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _getAppVersion();
    _loadUserData();
    _checkUserRole(); // Check role from token

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
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

  // ─── Check User Role from Token ───
  Future<void> _checkUserRole() async {
    setState(() => _isLoadingRole = true);

    try {
      // First check if we have the role in storage
      String? role = await StorageService.getUserRole();

      // If not in storage, decrypt token to get it
      if (role == null) {
        final token = await StorageService.getToken();
        if (token != null) {
          final response = await http.post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/decrypt-token'),
            headers: {
              'Content-Type': 'application/json',
              'accept': 'application/json',
            },
            body: json.encode({'token': token}),
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final decoded = data['decoded'];
            role = decoded['role']?.toString();

            // Save role to storage for future use
            if (role != null) {
              await StorageService.saveUserRole(role);
            }
          }
        }
      }

      // Check if user is a franchise owner - check if role contains 'franchise'
      // This handles: "franchise_owner", "franchise owner", "franchise", etc.
      final roleLower = role?.toLowerCase() ?? '';
      final isFranchise = roleLower.contains('franchise');

      setState(() {
        _isFranchiseOwner = isFranchise;
        _isLoadingRole = false;
      });

      // debugPrint('✅ User role: $role, Is franchise owner: $_isFranchiseOwner');
    } catch (e) {
      // debugPrint('❌ Error checking user role: $e');
      setState(() => _isLoadingRole = false);
    }
  }

  Future<void> _getAppVersion() async {
    try {
      final String pubspecString = await rootBundle.loadString('pubspec.yaml');
      for (final String line in pubspecString.split('\n')) {
        if (line.startsWith('version:')) {
          final String versionLine = line.substring(8).trim();
          final List<String> parts = versionLine.split('+');
          setState(() => _appVersion = parts[0]);
          return;
        }
      }
      setState(() => _appVersion = '1.1.0');
    } catch (_) {
      setState(() => _appVersion = '1.1.0');
    }
  }

  Future<void> _loadUserData() async {
    try {
      String? token = await StorageService.getToken();
      if (token == null) {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('tea_app_token');
        if (token != null) {
          await StorageService.saveToken(token);
        } else {
          setState(() {
            _isLoadingProfile = false;
            _userData = null;
            _isLoggedIn = false;
          });
          return;
        }
      }

      final tokenIsValid = token.isNotEmpty &&
          await StorageService.isTokenValid();
      if (!mounted) return;
      setState(() => _isLoggedIn = tokenIsValid);
      if (!tokenIsValid) {
        setState(() {
          _isLoadingProfile = false;
          _userData = null;
        });
        return;
      }

      final userId = JwtService.extractUserId(token);
      if (userId == null) {
        setState(() {
          _isLoadingProfile = false;
          _userData = null;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/user/fetch-user-data/$userId'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _userData = data['user'];
            _isLoadingProfile = false;
          });
          return;
        }
      }
      setState(() {
        _isLoadingProfile = false;
        _userData = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingProfile = false;
        _userData = null;
        _isLoggedIn = false;
      });
    }
  }

  void _showSnack(String message) {
    SiporaTheme.showSnackBar(context, message, isError: false);
  }

  void _launchStoreForRating() async {
    final Uri uri;

    if (Platform.isAndroid) {
      uri = Uri.parse('market://details?id=com.siporagroups.sipora');
    } else if (Platform.isIOS) {
      uri = Uri.parse(
        'https://apps.apple.com/app/id YOUR_APPLE_APP_ID?action=write-review',
      );
    } else {
      uri = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.siporagroups.sipora',
      );
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _showSnack('Thank you for rating Sipora!');
      } else {
        // Fallback: Android falls back to browser Play Store, iOS to browser App Store
        final fallback = Platform.isIOS
            ? Uri.parse(
                'https://apps.apple.com/app/idYOUR_APPLE_APP_ID?action=write-review',
              )
            : Uri.parse(
                'https://play.google.com/store/apps/details?id=com.siporagroups.sipora',
              );
        await launchUrl(fallback, mode: LaunchMode.externalApplication);
        _showSnack('Thank you for rating Sipora!');
      }
    } catch (e) {
      _showSnack('Could not open store. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final isTablet = context.isTabletScreen;
    final gridSpacing = ResponsiveConstants.getGridSpacing(context);

    return Scaffold(
      backgroundColor: theme.cream,
      appBar: _buildAppBar(isTablet),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView(
          padding: EdgeInsets.symmetric(
            vertical: isTablet
                ? ResponsiveConstants.getGridSpacing(context) * 3.5
                : ResponsiveConstants.getGridSpacing(context) * 2.5,
          ),
          children: [
            // Profile hero
            _buildProfileHero(isTablet),

            SizedBox(height: gridSpacing * 2.5),

            // Sipora Experience quick grid
            _SectionLabel(label: 'Sipora Experience'),
            SizedBox(height: gridSpacing),
            _buildExperienceGrid(isTablet),

            SizedBox(height: gridSpacing * 2.5),

            // Divider before Preferences & History
            _buildSectionDivider(),

            // Preferences & History (Combined History + Preferences)
            _SectionLabel(label: 'Preferences & History'),
            SizedBox(height: gridSpacing),
            _buildAccountPreferencesTiles(),

            SizedBox(height: gridSpacing * 2.5),

            // Divider before Support & About
            _buildSectionDivider(),

            // Support & About
            _SectionLabel(label: 'Support & About'),
            SizedBox(height: gridSpacing),
            _buildSupportAboutTiles(),

            SizedBox(height: gridSpacing * 3.5),

            // Guests see Login; authenticated users see Log Out.
            if (_isLoggedIn)
              _buildLogoutButton(isTablet)
            else
              _buildLoginButton(isTablet),

            SizedBox(height: gridSpacing * 3),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavTextRow(currentPage: 'setting'),
    );
  }

  // ─────────────────────────────────────────────
  //  APP BAR
  // ─────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(bool isTablet) {
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
        padding: EdgeInsets.only(
          left: ResponsiveConstants.getScreenPadding(context),
        ),
        child: Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: isTablet ? 44 : 34,
              height: isTablet ? 44 : 34,
              decoration: BoxDecoration(
                color: theme.white,
                borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                border: Border.all(
                  color: theme.border,
                  width: isTablet ? 2 : 1.5,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: isTablet ? 18 : 15,
                color: theme.textDark,
              ),
            ),
          ),
        ),
      ),
      title: Text(
        'Settings',
        style: TextStyle(
          fontSize: ResponsiveConstants.getTitleFontSize(context),
          fontWeight: FontWeight.w700,
          color: theme.textDark,
          letterSpacing: -0.2,
        ),
      ),
      // Removed the actions section with refresh button
    );
  }

  // ─────────────────────────────────────────────
  //  SECTION DIVIDER
  // ─────────────────────────────────────────────
  Widget _buildSectionDivider() {
    final theme = context.siporaTheme;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveConstants.getScreenPadding(context),
        vertical: ResponsiveConstants.getGridSpacing(context),
      ),
      height: 1,
      color: theme.border.withValues(alpha: 0.5),
    );
  }

  // ─────────────────────────────────────────────
  //  PROFILE HERO
  // ─────────────────────────────────────────────
  Widget _buildProfileHero(bool isTablet) {
    final theme = context.siporaTheme;
    final avatarSize = isTablet ? 80.0 : 60.0;
    final iconSize = isTablet ? 44.0 : 34.0;
    final padding = ResponsiveConstants.getScreenPadding(context);

    if (_isLoadingProfile) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: padding),
        padding: EdgeInsets.all(ResponsiveConstants.getCardPadding(context)),
        decoration: BoxDecoration(
          color: theme.white,
          borderRadius: BorderRadius.circular(
            ResponsiveConstants.getCardBorderRadius(context),
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
        child: Row(
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                color: SiporaTheme.greenBg,
                borderRadius: BorderRadius.circular(
                  ResponsiveConstants.getCardBorderRadius(context),
                ),
              ),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: SiporaTheme.greenDark,
                  ),
                ),
              ),
            ),
            SizedBox(width: ResponsiveConstants.getGridSpacing(context) * 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isTablet ? 160 : 120,
                    height: isTablet ? 20 : 16,
                    color: SiporaTheme.greenBg,
                  ),
                  SizedBox(height: ResponsiveConstants.getGridSpacing(context)),
                  Container(
                    width: isTablet ? 240 : 180,
                    height: isTablet ? 16 : 12,
                    color: SiporaTheme.greenBg,
                  ),
                  SizedBox(height: ResponsiveConstants.getGridSpacing(context)),
                  Container(
                    width: isTablet ? 100 : 80,
                    height: isTablet ? 32 : 24,
                    decoration: BoxDecoration(
                      color: SiporaTheme.greenBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_userData == null) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: padding),
        padding: EdgeInsets.all(ResponsiveConstants.getCardPadding(context)),
        decoration: BoxDecoration(
          color: theme.white,
          borderRadius: BorderRadius.circular(
            ResponsiveConstants.getCardBorderRadius(context),
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
        child: Row(
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                color: SiporaTheme.greenBg,
                borderRadius: BorderRadius.circular(
                  ResponsiveConstants.getCardBorderRadius(context),
                ),
              ),
              child: Icon(
                Icons.person_outline,
                color: theme.textMuted,
                size: iconSize,
              ),
            ),
            SizedBox(width: ResponsiveConstants.getGridSpacing(context) * 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Guest User',
                    style: TextStyle(
                      fontSize: ResponsiveConstants.getTitleFontSize(context),
                      fontWeight: FontWeight.w700,
                      color: theme.textDark,
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveConstants.getGridSpacing(context) / 2,
                  ),
                  Text(
                    'Login to view profile',
                    style: TextStyle(
                      fontSize: ResponsiveConstants.getFontSize(context),
                      color: theme.textMuted,
                    ),
                  ),
                  SizedBox(height: ResponsiveConstants.getGridSpacing(context)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveConstants.getCardPadding(context),
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: SiporaTheme.goldBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: SiporaTheme.goldBorder,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 11)),
                        SizedBox(
                          width:
                              ResponsiveConstants.getGridSpacing(context) / 2,
                        ),
                        Text(
                          'Login',
                          style: TextStyle(
                            fontSize: ResponsiveConstants.getFontSize(context),
                            fontWeight: FontWeight.w600,
                            color: SiporaTheme.goldText,
                          ),
                        ),
                      ],
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
      );
    }

    final firstName = _userData!['first_name'] ?? '';
    final lastName = _userData!['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final phoneNumber = _userData!['phone_number'] ?? 'No phone number';
    final avatarUrl = _userData!['avataricons'];
    final loyaltyPoints = _userData!['loyalty_points'] ?? 0;
    final isVip =
        loyaltyPoints >= 100 || (_userData!['account_status'] == 'vip');
    final vipText = isVip ? 'VIP Member' : 'Member';

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: padding),
          decoration: BoxDecoration(
            color: theme.white,
            borderRadius: BorderRadius.circular(
              ResponsiveConstants.getCardBorderRadius(context),
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
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(
              ResponsiveConstants.getCardBorderRadius(context),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(
                ResponsiveConstants.getCardBorderRadius(context),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileInformationPage(),
                ),
              ).then((_) => _loadUserData()),
              child: Padding(
                padding: EdgeInsets.all(
                  ResponsiveConstants.getCardPadding(context),
                ),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: avatarSize,
                          height: avatarSize,
                          decoration: BoxDecoration(
                            color: SiporaTheme.greenBg,
                            borderRadius: BorderRadius.circular(
                              ResponsiveConstants.getCardBorderRadius(context),
                            ),
                            border: Border.all(
                              color: SiporaTheme.greenLight,
                              width: isTablet ? 3 : 2,
                            ),
                          ),
                          child: avatarUrl != null && avatarUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    ResponsiveConstants.getCardBorderRadius(
                                          context,
                                        ) -
                                        2,
                                  ),
                                  child: Image.network(
                                    avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Icon(
                                      Icons.person_rounded,
                                      color: SiporaTheme.greenMid,
                                      size: avatarSize * 0.6,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.person_rounded,
                                  color: SiporaTheme.greenMid,
                                  size: avatarSize * 0.6,
                                ),
                        ),
                        Positioned(
                          bottom: -4,
                          right: -4,
                          child: Container(
                            width: isTablet ? 28 : 22,
                            height: isTablet ? 28 : 22,
                            decoration: BoxDecoration(
                              color: SiporaTheme.greenDark,
                              borderRadius: BorderRadius.circular(
                                isTablet ? 10 : 8,
                              ),
                              border: Border.all(
                                color: theme.white,
                                width: isTablet ? 3 : 2,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: isTablet ? 14 : 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: ResponsiveConstants.getGridSpacing(context) * 2,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName.isEmpty ? 'Sipora User' : fullName,
                            style: TextStyle(
                              fontSize: ResponsiveConstants.getTitleFontSize(
                                context,
                              ),
                              fontWeight: FontWeight.w600,
                              color: theme.textDark,
                            ),
                          ),
                          SizedBox(
                            height:
                                ResponsiveConstants.getGridSpacing(context) / 2,
                          ),
                          Text(
                            phoneNumber,
                            style: TextStyle(
                              fontSize: ResponsiveConstants.getFontSize(
                                context,
                              ),
                              color: theme.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(
                            height: ResponsiveConstants.getGridSpacing(context),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveConstants.getCardPadding(
                                context,
                              ),
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isVip
                                  ? SiporaTheme.goldBg
                                  : SiporaTheme.greenBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isVip
                                    ? SiporaTheme.goldBorder
                                    : theme.border,
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isVip ? '⭐' : '🍃',
                                  style: TextStyle(
                                    fontSize: ResponsiveConstants.getFontSize(
                                      context,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width:
                                      ResponsiveConstants.getGridSpacing(
                                        context,
                                      ) /
                                      2,
                                ),
                                Text(
                                  vipText,
                                  style: TextStyle(
                                    fontSize: ResponsiveConstants.getFontSize(
                                      context,
                                    ),
                                    fontWeight: FontWeight.w600,
                                    color: isVip
                                        ? SiporaTheme.goldText
                                        : theme.textMuted,
                                  ),
                                ),
                              ],
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
      },
    );
  }

  // ─────────────────────────────────────────────
  //  EXPERIENCE GRID (UPDATED TO TILE STYLE)
  // ─────────────────────────────────────────────
  Widget _buildExperienceGrid(bool isTablet) {
    final tiles = <Widget>[
      _SiporaTile(
        icon: Icons.location_on_outlined,
        title: 'Address',
        subtitle: 'Manage addresses',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ShippingAddressesPage()),
        ),
      ),
      _SiporaTile(
        icon: Icons.favorite_border_rounded,
        title: 'Favorites',
        subtitle: 'Your favorite items',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FavoritesPage()),
        ),
      ),
    ];

    // Insert Product Analytics tile at position 1 (after Address) if user is franchise owner
    if (_isFranchiseOwner && !_isLoadingRole) {
      tiles.insert(
        1,
        _SiporaTile(
          icon: Icons.analytics_outlined,
          title: 'Product Analytics',
          subtitle: 'View sales performance',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductAnalyticsPage()),
          ),
        ),
      );
    }

    return _TilesGroup(tiles: tiles);
  }

  // ─────────────────────────────────────────────
  //  Preferences & History TILES (Combined)
  // ─────────────────────────────────────────────
  Widget _buildAccountPreferencesTiles() {
    return _TilesGroup(
      tiles: [
        _SiporaTile(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Wallet',
          subtitle: 'View balance & recharge',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletRechargePage()),
            );
          },
        ),
        _SiporaTile(
          icon: Icons.shield_outlined,
          title: 'Wallet Security',
          subtitle: '6-digit wallet PIN',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletSecurityPage()),
            );
          },
        ),
        _SiporaTile(
          icon: Icons.history_rounded,
          title: 'Order History',
          subtitle: 'View your past orders & invoices',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InvoicePage()),
            );
          },
        ),
        _SiporaTile(
          icon: Icons.local_shipping_outlined,
          title: 'Warehouse Orders',
          subtitle: 'Track your product deliveries',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WarehouseOrdersPage()),
            );
          },
        ),
        _SiporaTile(
          icon: Icons.tune_rounded,
          title: 'App Preferences',
          subtitle: 'Notifications & theme settings',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppPreferencesPage()),
            );
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  SUPPORT & ABOUT TILES
  // ─────────────────────────────────────────────
  Widget _buildSupportAboutTiles() {
    final theme = context.siporaTheme;

    return _TilesGroup(
      tiles: [
        _SiporaTile(
          icon: Icons.help_outline_rounded,
          title: 'Help Center',
          subtitle: 'FAQs and support',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HelpCenterPage()),
          ),
        ),
        _SiporaTile(
          icon: Icons.phone_outlined,
          title: 'My Support Tickets',
          subtitle: 'Check your all tickets',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SupportTicketPage()),
          ),
        ),
        _SiporaTile(
          icon: Icons.star_outline_rounded,
          title: 'Rate Sipora',
          subtitle: 'Share your feedback',
          onTap: _launchStoreForRating,
        ),
        _SiporaTile(
          icon: Icons.info_outline_rounded,
          title: 'Policies',
          subtitle: 'Our Policies',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PoliciesPage()),
          ),
        ),
        _SiporaTile(
          icon: Icons.delete_forever_outlined,
          title: 'Delete Account',
          subtitle: 'Permanently delete your Sipora account',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DeleteAccountPage()),
          ),
        ),
        _SiporaTile(
          icon: Icons.system_update_alt_rounded,
          title: 'App Version',
          subtitle: "You're using the latest version",
          trailingWidget: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: SiporaTheme.greenBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.border, width: 0.5),
                ),
                child: Text(
                  _appVersion,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: SiporaTheme.greenMid,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: ResponsiveConstants.getIconSize(context),
                color: theme.textMuted,
              ),
            ],
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AppVersionPage()),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  GUEST LOGIN BUTTON
  // ─────────────────────────────────────────────
  Widget _buildLoginButton(bool isTablet) {
    final theme = context.siporaTheme;
    final padding = ResponsiveConstants.getScreenPadding(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: padding),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            ).then((_) {
              _loadUserData();
              _checkUserRole();
            });
          },
          borderRadius: BorderRadius.circular(
            ResponsiveConstants.getCardBorderRadius(context),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveConstants.getScreenPadding(context),
              vertical: isTablet ? 18 : 13,
            ),
            decoration: BoxDecoration(
              color: theme.white,
              borderRadius: BorderRadius.circular(
                ResponsiveConstants.getCardBorderRadius(context),
              ),
              border: Border.all(color: theme.border, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: isTablet ? 48.0 : 38.0,
                  height: isTablet ? 48.0 : 38.0,
                  decoration: BoxDecoration(
                    color: SiporaTheme.greenBg,
                    borderRadius: BorderRadius.circular(
                      ResponsiveConstants.getCardBorderRadius(context) - 5,
                    ),
                  ),
                  child: Icon(
                    Icons.login_rounded,
                    color: SiporaTheme.greenMid,
                    size: isTablet ? 22.0 : 18.0,
                  ),
                ),
                SizedBox(
                  width: ResponsiveConstants.getGridSpacing(context) * 1.5,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Login / Register',
                        style: TextStyle(
                          fontSize: isTablet ? 16.0 : 14.0,
                          fontWeight: FontWeight.w600,
                          color: SiporaTheme.greenDark,
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveConstants.getGridSpacing(context) / 2,
                      ),
                      Text(
                        'Sign in to access your account',
                        style: TextStyle(
                          fontSize: isTablet ? 14.0 : 12.0,
                          color: theme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: ResponsiveConstants.getIconSize(context),
                  color: SiporaTheme.greenMid,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  LOGOUT BUTTON
  // ─────────────────────────────────────────────
  Widget _buildLogoutButton(bool isTablet) {
    final theme = context.siporaTheme;
    final padding = ResponsiveConstants.getScreenPadding(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: padding),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showLogoutDialog,
          borderRadius: BorderRadius.circular(
            ResponsiveConstants.getCardBorderRadius(context),
          ),
          highlightColor: SiporaTheme.red.withValues(alpha: 0.1),
          splashColor: SiporaTheme.red.withValues(alpha: 0.05),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveConstants.getScreenPadding(context),
              vertical: isTablet ? 18 : 13,
            ),
            decoration: BoxDecoration(
              color: theme.white,
              borderRadius: BorderRadius.circular(
                ResponsiveConstants.getCardBorderRadius(context),
              ),
              border: Border.all(
                color: SiporaTheme.red.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: isTablet ? 48.0 : 38.0,
                  height: isTablet ? 48.0 : 38.0,
                  decoration: BoxDecoration(
                    color: SiporaTheme.redBg,
                    borderRadius: BorderRadius.circular(
                      ResponsiveConstants.getCardBorderRadius(context) - 5,
                    ),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: SiporaTheme.red,
                    size: isTablet ? 22.0 : 18.0,
                  ),
                ),
                SizedBox(
                  width: ResponsiveConstants.getGridSpacing(context) * 1.5,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: isTablet ? 16.0 : 14.0,
                          fontWeight: FontWeight.w600,
                          color: SiporaTheme.red,
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveConstants.getGridSpacing(context) / 2,
                      ),
                      Text(
                        'Sign out from your account',
                        style: TextStyle(
                          fontSize: isTablet ? 14.0 : 12.0,
                          color: theme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: ResponsiveConstants.getIconSize(context),
                  color: SiporaTheme.red.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    final theme = context.siporaTheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveConstants.getCardBorderRadius(context),
          ),
        ),
        backgroundColor: theme.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SiporaTheme.redBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: SiporaTheme.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Confirm Logout',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: theme.textDark,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout from your account?',
          style: TextStyle(fontSize: 14, height: 1.5, color: theme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: ResponsiveConstants.getFontSize(context),
                color: theme.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);

              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                if (mounted) {
                  final userProvider = Provider.of<UserProvider>(
                    context,
                    listen: false,
                  );
                  userProvider.clearUser();

                  SiporaTheme.showSnackBar(
                    context,
                    'Logged out successfully',
                    isError: false,
                  );
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  SiporaTheme.showSnackBar(
                    context,
                    'Error during logout: $e',
                    isError: true,
                  );
                }
              }
            },
            style: SiporaTheme.dangerButtonStyle(),
            child: const Text(
              'Log Out',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  REUSABLE PRIVATE WIDGETS
// ═══════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveConstants.getScreenPadding(context),
        vertical: ResponsiveConstants.getGridSpacing(context),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: SiporaTheme.greenMid,
        ),
      ),
    );
  }
}

class _TilesGroup extends StatelessWidget {
  final List<Widget> tiles;
  const _TilesGroup({required this.tiles});

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveConstants.getScreenPadding(context),
      ),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(
          ResponsiveConstants.getCardBorderRadius(context),
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
      child: Column(children: tiles),
    );
  }
}

class _SiporaTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailingWidget;
  final VoidCallback? onTap;

  const _SiporaTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingWidget,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final isTablet = context.isTabletScreen;
    final iconSize = isTablet ? 22.0 : 18.0;
    final iconContainerSize = isTablet ? 48.0 : 38.0;
    final titleFontSize = isTablet ? 16.0 : 14.0;
    final subtitleFontSize = isTablet ? 14.0 : 12.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          ResponsiveConstants.getCardBorderRadius(context),
        ),
        highlightColor: SiporaTheme.greenSurface,
        splashColor: SiporaTheme.greenBg,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveConstants.getScreenPadding(context),
            vertical: isTablet ? 18 : 13,
          ),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: theme.border, width: 0.8)),
          ),
          child: Row(
            children: [
              Container(
                width: iconContainerSize,
                height: iconContainerSize,
                decoration: BoxDecoration(
                  color: SiporaTheme.greenBg,
                  borderRadius: BorderRadius.circular(
                    ResponsiveConstants.getCardBorderRadius(context) - 5,
                  ),
                ),
                child: Icon(icon, color: SiporaTheme.greenMid, size: iconSize),
              ),
              SizedBox(
                width: ResponsiveConstants.getGridSpacing(context) * 1.5,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: theme.textDark,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(
                        height: ResponsiveConstants.getGridSpacing(context) / 2,
                      ),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          color: theme.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailingWidget ??
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: ResponsiveConstants.getIconSize(context),
                    color: theme.textMuted,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
