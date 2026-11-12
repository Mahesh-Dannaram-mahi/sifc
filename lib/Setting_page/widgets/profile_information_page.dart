import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import './help_center_page.dart';
import './image_picker_page.dart';
import '../../config/api_config.dart';
import '../../services/jwt_service.dart';
import '../../services/storage_service.dart';
import '../../services/profile_service.dart';
import '../../theme/sipora_theme.dart';
import '../../utils/responsive_constants.dart';
import '../../providers/user_provider.dart';
// ✅ ADD THIS IMPORT for MyShopPage
import '../../Home_page/My_Shop/my_shop_page.dart';

class ProfileInformationPage extends StatefulWidget {
  const ProfileInformationPage({super.key});

  @override
  State<ProfileInformationPage> createState() => _ProfileInformationPageState();
}

class _ProfileInformationPageState extends State<ProfileInformationPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? errorMessage;
  bool isEditing = false;
  bool isSaving = false;
  bool _isUploadingImage = false;

  // Cache version tracker
  String _imageCacheVersion = '';

  // Image picker states
  File? _selectedAvatarFile;
  bool _isImagePicking = false;

  // Form controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _avatarController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Store user role
  String _userRole = '';

  // ✅ UPDATED: Check if user is franchise owner with better role detection
  bool get _isFranchiseOwner {
    // Check from userData first
    final String roleFromData = userData?['role']?.toString() ?? '';

    // Check from stored _userRole
    final String roleFromStorage = _userRole.toString();

    // Check from token if available via StorageService
    // Since getUserRole() is async, we can't call it here directly.
    // We'll use the stored _userRole which is set during init.
    final String roleFromService = _userRole;

    // Combine all roles and check
    final String combinedRole =
        '$roleFromData $roleFromStorage $roleFromService'.toLowerCase().trim();

    // Debug: print the role to see what's being returned
    debugPrint('📱 Role from userData: "$roleFromData"');
    debugPrint('📱 Role from storage (_userRole): "$roleFromStorage"');
    debugPrint('📱 Combined role: "$combinedRole"');

    // Check for various franchise-related role values
    final bool isFranchise =
        combinedRole.contains('franchise') ||
        combinedRole.contains('franchise_owner') ||
        combinedRole.contains('franchiseowner') ||
        combinedRole.contains('admin') ||
        combinedRole.contains('superadmin') ||
        combinedRole.contains('warehouse');

    debugPrint('📱 Is franchise owner: $isFranchise');
    return isFranchise;
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  // Method to get valid image URL with cache busting
  String _getValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';

    String baseUrl = url;

    // If the URL already has http/https, use as is
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      // If it's a relative path, prepend the base URL
      if (url.startsWith('/')) {
        baseUrl = '${ApiConfig.baseUrl}$url';
      } else {
        baseUrl = url;
      }
    }

    // Add cache busting parameter
    String cacheBuster = '';
    if (userData != null && userData!['updated_at'] != null) {
      cacheBuster = 'v=${userData!['updated_at']}';
    } else if (_imageCacheVersion.isNotEmpty) {
      cacheBuster = 'v=$_imageCacheVersion';
    } else {
      cacheBuster = 'ts=${DateTime.now().millisecondsSinceEpoch}';
    }

    final uri = Uri.parse(baseUrl);
    final newUri = uri.replace(
      queryParameters: {...uri.queryParameters, 'cache': cacheBuster},
    );

    return newUri.toString();
  }

  // Method to clear image cache for a specific URL
  Future<void> _clearImageCache(String? url) async {
    if (url == null || url.isEmpty) return;

    try {
      await CachedNetworkImage.evictFromCache(url);

      final baseUrl = _getBaseUrl(url);
      if (baseUrl != url) {
        await CachedNetworkImage.evictFromCache(baseUrl);
      }

      setState(() {
        _imageCacheVersion = DateTime.now().millisecondsSinceEpoch.toString();
      });

      // debugPrint('Cache cleared for: $url');
    } catch (e) {
      // debugPrint('Error clearing cache: $e');
    }
  }

  String _getBaseUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return Uri(scheme: uri.scheme, host: uri.host, path: uri.path).toString();
    } catch (e) {
      return url;
    }
  }

  Future<void> _fetchUserData() async {
    try {
      String? token = await StorageService.getToken();

      if (token == null) {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('tea_app_token');

        if (token != null) {
          await StorageService.saveToken(token);
        } else {
          if (mounted) {
            setState(() {
              errorMessage = 'Please login again.';
              isLoading = false;
            });
          }
          return;
        }
      }

      // Load user role from storage
      String? savedRole = await StorageService.getUserRole();
      if (savedRole == null || savedRole.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        savedRole = prefs.getString('user_role');
      }
      _userRole = savedRole ?? '';
      debugPrint('📱 Loaded user role from storage: "$_userRole"');

      final userId = JwtService.extractUserId(token);

      if (userId == null) {
        if (mounted) {
          setState(() {
            errorMessage =
                'Failed to extract user ID from token. Token may be invalid.';
            isLoading = false;
          });
        }
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
          final newUserData = data['user'];

          // Extract role from user data if available
          if (newUserData?['role'] != null) {
            final roleFromData = newUserData['role'].toString();
            debugPrint('📱 Role from user data API: "$roleFromData"');
            // Update role if we got it from API
            if (roleFromData.isNotEmpty) {
              _userRole = roleFromData;
              // Save to storage for future use
              await StorageService.saveUserRole(roleFromData);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('user_role', roleFromData);
            }
          }

          final oldAvatarUrl = userData?['avataricons'];
          final newAvatarUrl = newUserData?['avataricons'];

          if (oldAvatarUrl != null && oldAvatarUrl != newAvatarUrl) {
            await _clearImageCache(oldAvatarUrl);
          }

          if (newAvatarUrl != null && newAvatarUrl.isNotEmpty) {
            await _clearImageCache(newAvatarUrl);
          }

          if (mounted) {
            setState(() {
              userData = newUserData;
              isLoading = false;
              _imageCacheVersion = DateTime.now().millisecondsSinceEpoch
                  .toString();
              if (newUserData?['updated_at'] != null) {
                _imageCacheVersion = newUserData!['updated_at'].toString();
              }
            });
          }
        } else {
          if (mounted) {
            setState(() {
              errorMessage =
                  'Failed to load user data: ${data['message'] ?? 'Unknown error'}';
              isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = 'Error: ${response.statusCode}';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Network error: $e';
          isLoading = false;
        });
      }
    }
  }

  // ============================================
  // OPEN IMAGE PICKER - UPDATED
  // Uses the updated ImagePickerPage with system picker
  // ============================================
  Future<void> _openImagePicker() async {
    if (_isImagePicking) return;

    setState(() => _isImagePicking = true);

    try {
      // Get the current avatar URL
      final String? currentAvatarUrl = userData?['avataricons'];
      final String validAvatarUrl = _getValidImageUrl(currentAvatarUrl);

      final File? result = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (context) => ImagePickerPage(
            currentImage: _selectedAvatarFile,
            currentImageUrl: validAvatarUrl.isNotEmpty ? validAvatarUrl : null,
            onImageSelected: (File? image) {
              if (image != null) {
                setState(() {
                  _selectedAvatarFile = image;
                  _avatarController.clear();
                });
              } else {
                // Image was removed
                setState(() {
                  _selectedAvatarFile = null;
                  _avatarController.clear();
                });
              }
            },
          ),
        ),
      );

      if (result != null && mounted) {
        setState(() {
          _selectedAvatarFile = result;
          _avatarController.clear();
        });
        SiporaTheme.showSnackBar(
          context,
          'Image selected! Tap Save to update your profile.',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        SiporaTheme.showSnackBar(
          context,
          'Error: ${e.toString().replaceFirst('Exception: ', '')}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImagePicking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final detailedType = ResponsiveConstants.getScreenTypeDetailed(context);
    final isSmallScreen =
        detailedType == ScreenTypeDetailed.small ||
        detailedType == ScreenTypeDetailed.extraSmall;
    final isTablet =
        detailedType == ScreenTypeDetailed.large ||
        detailedType == ScreenTypeDetailed.extraLarge;

    return Scaffold(
      backgroundColor: theme.cream,
      appBar: _buildAppBar(isEditing, isTablet),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: isLoading
              ? _buildLoadingIndicator(isTablet)
              : errorMessage != null
              ? _buildErrorWidget(isTablet)
              : _buildProfileContent(isTablet, isSmallScreen),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isEditing, bool isTablet) {
    final theme = context.siporaTheme;
    final iconSize = ResponsiveConstants.getIconSize(context);
    final avatarSize = ResponsiveConstants.getAvatarSize(context);

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
                size: iconSize - 7,
                color: theme.textDark,
              ),
            ),
          ),
        ),
      ),
      title: Text(
        isEditing ? 'Edit Profile' : 'Profile Information',
        style: TextStyle(
          fontSize: ResponsiveConstants.getTitleFontSize(context),
          fontWeight: FontWeight.w700,
          color: theme.textDark,
        ),
      ),
      actions: [
        if (!isEditing && userData != null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _startEditing,
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: theme.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.border, width: 1.5),
                ),
                child: Icon(
                  Icons.edit_rounded,
                  color: SiporaTheme.greenDark,
                  size: iconSize - 4,
                ),
              ),
            ),
          ),
        if (isEditing)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: _cancelEditing,
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: ResponsiveConstants.getFontSize(context) - 2,
                      color: theme.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SiporaTheme.greenDark,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(55, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: isSaving || _isUploadingImage
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save',
                          style: TextStyle(
                            fontSize:
                                ResponsiveConstants.getButtonFontSize(context) -
                                4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingIndicator(bool isTablet) {
    final theme = context.siporaTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: SiporaTheme.greenBg,
              shape: BoxShape.circle,
            ),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: SiporaTheme.greenDark,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading profile...',
            style: TextStyle(
              fontSize: isTablet ? 14 : 13,
              color: theme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(bool isTablet) {
    final theme = context.siporaTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: SiporaTheme.redBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: ResponsiveConstants.getIconSize(context) * 3,
                color: SiporaTheme.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              errorMessage!,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: theme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Please check your internet connection and try again.',
              style: TextStyle(
                fontSize: isTablet ? 13 : 12,
                color: theme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _fetchUserData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SiporaTheme.greenDark,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/signup', (route) => false),
                  child: const Text('Login Again'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(bool isTablet, bool isSmallScreen) {
    if (userData == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(isTablet, isSmallScreen),
          const SizedBox(height: 24),

          if (isEditing) ...[
            _buildEditableNameTile(isTablet),
            const SizedBox(height: 10),
            _buildEditableEmailTile(isTablet),
            const SizedBox(height: 10),
            _buildPhoneTile(isTablet),
            const SizedBox(height: 20),
          ],

          if (!isEditing) ...[
            _buildSectionHeader('Account Status'),
            const SizedBox(height: 14),
            _buildStatusTile(
              icon: Icons.verified_user_rounded,
              title: 'Verification Status',
              value: userData!['verified'] == true
                  ? 'Verified'
                  : 'Not Verified',
              isVerified: userData!['verified'] == true,
              isTablet: isTablet,
            ),
            const SizedBox(height: 10),
            _buildInfoTile(
              icon: Icons.account_circle_rounded,
              title: 'Account Status',
              value: userData!['account_status'] ?? 'Active',
              isTablet: isTablet,
            ),
            const SizedBox(height: 10),
            _buildInfoTile(
              icon: Icons.calendar_today_rounded,
              title: 'Member Since',
              value: SiporaTheme.formatDate(userData!['created_at']),
              isTablet: isTablet,
            ),

            // ✅ SHOW "MY SHOP DASHBOARD" BUTTON ONLY IF USER IS FRANCHISE OWNER
            if (_isFranchiseOwner) ...[
              const SizedBox(height: 20),
              _buildMyShopButton(isTablet),
            ],
          ],
        ],
      ),
    );
  }

  // ─── My Shop Button ─────────────────────────────────────────────
  Widget _buildMyShopButton(bool isTablet) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyShopPage()),
          );
        },
        icon: Icon(Icons.storefront_rounded, size: isTablet ? 24 : 20),
        label: Text(
          'My Shop Dashboard',
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: SiporaTheme.gold,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
          color: SiporaTheme.greenMid,
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isTablet, bool isSmallScreen) {
    final theme = context.siporaTheme;
    final firstName = userData!['first_name'] ?? '';
    final lastName = userData!['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final email = userData!['email'] ?? 'No email';
    final phoneNumber = userData!['phone_number'] ?? 'No phone number';

    final String? avatarUrl = userData!['avataricons'];
    final String validAvatarUrl = _getValidImageUrl(avatarUrl);

    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;
    final isMediumScreen = screenWidth > 400 && screenWidth <= 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatarWidget(
            isTablet,
            isSmallScreen,
            firstName,
            validAvatarUrl,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExpandableText(
                  text: fullName.isEmpty ? 'Sipora User' : fullName,
                  isLargeScreen: isLargeScreen,
                  isMediumScreen: isMediumScreen,
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w700,
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: isTablet ? 14 : 12,
                      color: theme.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!isLargeScreen && phoneNumber.length > 25) {
                            _showFullTextDialog('Phone Number', phoneNumber);
                          }
                        },
                        child: Text(
                          phoneNumber,
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 13,
                            color: theme.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _buildExpandableText(
                  text: email,
                  isLargeScreen: isLargeScreen,
                  isMediumScreen: isMediumScreen,
                  fontSize: isTablet ? 14 : 13,
                  fontWeight: FontWeight.w400,
                  icon: Icons.email_outlined,
                  isEmail: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarWidget(
    bool isTablet,
    bool isSmallScreen,
    String firstName,
    String validAvatarUrl,
  ) {
    final size = isTablet ? 80 : (isSmallScreen ? 70 : 75);
    final imageSize = isTablet ? 80 : (isSmallScreen ? 70 : 75);

    return GestureDetector(
      onTap: isEditing ? _openImagePicker : null,
      child: Stack(
        children: [
          Container(
            width: size.toDouble(),
            height: size.toDouble(),
            decoration: BoxDecoration(
              color: SiporaTheme.greenBg,
              shape: BoxShape.circle,
              border: Border.all(color: SiporaTheme.greenLight, width: 2),
            ),
            child: _selectedAvatarFile != null && isEditing
                ? ClipOval(
                    child: Image.file(
                      _selectedAvatarFile!,
                      width: size.toDouble(),
                      height: size.toDouble(),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            firstName.isNotEmpty
                                ? firstName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontSize: isTablet
                                  ? 34
                                  : (isSmallScreen ? 28 : 30),
                              fontWeight: FontWeight.bold,
                              color: SiporaTheme.greenDark,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : ClipOval(
                    child: validAvatarUrl.isNotEmpty
                        ? CachedNetworkImage(
                            key: ValueKey(
                              'avatar_${_imageCacheVersion}_$validAvatarUrl',
                            ),
                            imageUrl: validAvatarUrl,
                            width: imageSize.toDouble(),
                            height: imageSize.toDouble(),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                color: SiporaTheme.greenDark,
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Text(
                                firstName.isNotEmpty
                                    ? firstName[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  fontSize: isTablet
                                      ? 34
                                      : (isSmallScreen ? 28 : 30),
                                  fontWeight: FontWeight.bold,
                                  color: SiporaTheme.greenDark,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              firstName.isNotEmpty
                                  ? firstName[0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                fontSize: isTablet
                                    ? 34
                                    : (isSmallScreen ? 28 : 30),
                                fontWeight: FontWeight.bold,
                                color: SiporaTheme.greenDark,
                              ),
                            ),
                          ),
                  ),
          ),
          // Edit icon overlay
          if (isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: isTablet ? 28 : 24,
                height: isTablet ? 28 : 24,
                decoration: BoxDecoration(
                  color: SiporaTheme.greenDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: isTablet ? 14 : 12,
                ),
              ),
            ),
          // Selected image indicator
          if (isEditing && _selectedAvatarFile != null)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
            ),
          // Loading overlay
          if (_isUploadingImage)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpandableText({
    required String text,
    required bool isLargeScreen,
    required bool isMediumScreen,
    required double fontSize,
    required FontWeight fontWeight,
    required IconData icon,
    bool isEmail = false,
  }) {
    final theme = context.siporaTheme;
    int maxChars = isLargeScreen ? 50 : (isMediumScreen ? 35 : 25);
    bool needsTruncation = !isLargeScreen && text.length > maxChars;

    if (!needsTruncation) {
      return Row(
        children: [
          Icon(icon, size: fontSize - 2, color: theme.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: fontWeight,
                color: theme.textDark,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(icon, size: fontSize - 2, color: theme.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: GestureDetector(
            onTap: () => _showFullTextDialog(
              isEmail ? 'Email Address' : 'Full Name',
              text,
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: fontWeight,
                color: theme.textDark,
                letterSpacing: -0.3,
                decoration: TextDecoration.underline,
                decorationColor: theme.textMuted.withValues(alpha: 0.5),
                decorationThickness: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  void _showFullTextDialog(String title, String content) {
    final theme = context.siporaTheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
                  color: SiporaTheme.greenBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  title.contains('Name')
                      ? Icons.person_outline_rounded
                      : Icons.email_outlined,
                  color: SiporaTheme.greenDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: ResponsiveConstants.getTitleFontSize(context),
                  fontWeight: FontWeight.w600,
                  color: theme.textDark,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Divider(color: theme.border),
              const SizedBox(height: 8),
              Text(
                content,
                style: TextStyle(
                  fontSize: ResponsiveConstants.getFontSize(context) + 1,
                  color: theme.textDark,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  fontSize: ResponsiveConstants.getFontSize(context) - 1,
                  color: theme.textMuted,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditableNameTile(bool isTablet) {
    final theme = context.siporaTheme;
    final fontSize = ResponsiveConstants.getFontSize(context);
    final titleFontSize = ResponsiveConstants.getTitleFontSize(context);

    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 14),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(14),
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: SiporaTheme.greenBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: SiporaTheme.greenMid,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Full Name',
                style: TextStyle(
                  fontSize: titleFontSize - 2,
                  fontWeight: FontWeight.w600,
                  color: theme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    labelStyle: TextStyle(
                      color: theme.textMuted,
                      fontSize: fontSize - 3,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: SiporaTheme.greenDark,
                        width: 1.5,
                      ),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 12,
                    color: theme.textDark,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    labelStyle: TextStyle(
                      color: theme.textMuted,
                      fontSize: fontSize - 3,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: SiporaTheme.greenDark,
                        width: 1.5,
                      ),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 12,
                    color: theme.textDark,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableEmailTile(bool isTablet) {
    final theme = context.siporaTheme;
    final fontSize = ResponsiveConstants.getFontSize(context);
    final titleFontSize = ResponsiveConstants.getTitleFontSize(context);

    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 14),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(14),
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: SiporaTheme.greenBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.email_outlined,
                  color: SiporaTheme.greenMid,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Email Address',
                style: TextStyle(
                  fontSize: titleFontSize - 2,
                  fontWeight: FontWeight.w600,
                  color: theme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: TextStyle(
                color: theme.textMuted,
                fontSize: fontSize - 3,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: SiporaTheme.greenDark,
                  width: 1.5,
                ),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            style: TextStyle(
              fontSize: isTablet ? 13 : 12,
              color: theme.textDark,
            ),
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneTile(bool isTablet) {
    final theme = context.siporaTheme;
    final titleFontSize = ResponsiveConstants.getTitleFontSize(context);
    final iconSize = ResponsiveConstants.getIconSize(context);

    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 14),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(14),
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: SiporaTheme.greenBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.phone_outlined,
                  color: SiporaTheme.greenMid,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Phone Number',
                style: TextStyle(
                  fontSize: titleFontSize - 2,
                  fontWeight: FontWeight.w600,
                  color: theme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SiporaTheme.greenBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.border, width: 0.5),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.phone_android_rounded,
                  size: isTablet ? 18 : 16,
                  color: SiporaTheme.greenDark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    userData!['phone_number'] ?? 'Not available',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 13,
                      fontWeight: FontWeight.w600,
                      color: theme.textDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [SiporaTheme.greenBg, theme.white],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: SiporaTheme.greenMid.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: SiporaTheme.greenMid.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.security_rounded,
                        size: 14,
                        color: SiporaTheme.greenMid,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Security Protected',
                        style: TextStyle(
                          fontSize: isTablet ? 11 : 10,
                          fontWeight: FontWeight.w600,
                          color: SiporaTheme.greenDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'For your account security, phone number cannot be changed directly.',
                  style: TextStyle(
                    fontSize: isTablet ? 10 : 9,
                    color: theme.textMuted,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 1,
                  color: theme.border.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.support_agent_rounded,
                      size: iconSize - 12,
                      color: SiporaTheme.greenMid,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Need to update your phone number?',
                        style: TextStyle(
                          fontSize: isTablet ? 10 : 9,
                          fontWeight: FontWeight.w500,
                          color: theme.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpCenterPage(),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.headset_mic_rounded,
                      size: isTablet ? 14 : 12,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Raise a Support Ticket',
                      style: TextStyle(
                        fontSize: isTablet ? 11 : 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SiporaTheme.greenDark,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Our support team will assist you with phone number update after verification.',
                  style: TextStyle(
                    fontSize: isTablet ? 8 : 7,
                    color: theme.textMuted,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    required bool isTablet,
  }) {
    final theme = context.siporaTheme;
    final fontSize = ResponsiveConstants.getFontSize(context);

    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 14),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(14),
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
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: SiporaTheme.greenBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: SiporaTheme.greenMid, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: fontSize - 3,
                    fontWeight: FontWeight.w600,
                    color: theme.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 13,
                    fontWeight: FontWeight.w600,
                    color: theme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTile({
    required IconData icon,
    required String title,
    required String value,
    required bool isVerified,
    required bool isTablet,
  }) {
    final theme = context.siporaTheme;
    final statusColor = isVerified ? SiporaTheme.greenDark : theme.textMuted;
    final fontSize = ResponsiveConstants.getFontSize(context);

    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 14),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(14),
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
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: SiporaTheme.greenBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: statusColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: fontSize - 3,
                    fontWeight: FontWeight.w600,
                    color: theme.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 13,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified_rounded,
                        color: SiporaTheme.greenDark,
                        size: 14,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startEditing() {
    setState(() {
      isEditing = true;
      _firstNameController.text = userData!['first_name'] ?? '';
      _lastNameController.text = userData!['last_name'] ?? '';
      _emailController.text = userData!['email'] ?? '';
      _avatarController.text = userData!['avataricons'] ?? '';
      _selectedAvatarFile = null;
    });
  }

  void _cancelEditing() {
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _avatarController.clear();
    _selectedAvatarFile = null;

    if (mounted) {
      setState(() {
        isEditing = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_firstNameController.text.trim().isEmpty) {
      if (mounted) {
        SiporaTheme.showSnackBar(
          context,
          'First name is required',
          isError: true,
        );
      }
      return;
    }

    if (_lastNameController.text.trim().isEmpty) {
      if (mounted) {
        SiporaTheme.showSnackBar(
          context,
          'Last name is required',
          isError: true,
        );
      }
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      if (mounted) {
        SiporaTheme.showSnackBar(context, 'Email is required', isError: true);
      }
      return;
    }

    if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(_emailController.text.trim())) {
      if (mounted) {
        SiporaTheme.showSnackBar(
          context,
          'Please enter a valid email',
          isError: true,
        );
      }
      return;
    }

    if (mounted) {
      setState(() => isSaving = true);
    }

    try {
      String? token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final userId = JwtService.extractUserId(token);
      if (userId == null) {
        throw Exception('Failed to extract user ID');
      }

      final oldAvatarUrl = userData?['avataricons'];

      final String? avatarUrl = _avatarController.text.trim().isNotEmpty
          ? _avatarController.text.trim()
          : null;

      final File? avatarFile = _selectedAvatarFile;

      if (avatarFile != null) {
        setState(() => _isUploadingImage = true);
      }

      final response = await ProfileService.updateProfile(
        userId: userId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        avatarFile: avatarFile,
        avatarUrl: avatarUrl,
      );

      if (mounted) {
        setState(() => _isUploadingImage = false);

        if (response['success'] == true) {
          if (oldAvatarUrl != null &&
              oldAvatarUrl != response['user']?['avataricons']) {
            await _clearImageCache(oldAvatarUrl);
          }

          final newAvatarUrl = response['user']?['avataricons'];
          if (newAvatarUrl != null && newAvatarUrl.isNotEmpty) {
            await _clearImageCache(newAvatarUrl);
          }

          await _fetchUserData();

          setState(() {
            isEditing = false;
            isSaving = false;
            _selectedAvatarFile = null;
            _imageCacheVersion = DateTime.now().millisecondsSinceEpoch
                .toString();
          });

          final userProvider = Provider.of<UserProvider>(
            context,
            listen: false,
          );
          if (response['user'] != null) {
            userProvider.updateUser(response['user']);
          }

          if (mounted) {
            SiporaTheme.showSnackBar(
              context,
              'Profile updated successfully!',
              isError: false,
            );
          }
        } else {
          throw Exception(response['message'] ?? 'Failed to update profile');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isSaving = false;
          _isUploadingImage = false;
        });

        String errorMsg = e.toString();
        if (errorMsg.contains('socket') || errorMsg.contains('connection')) {
          errorMsg = 'Network error. Please check your internet connection.';
        } else if (errorMsg.contains('timeout')) {
          errorMsg = 'Request timed out. Please try again.';
        }

        if (mounted) {
          SiporaTheme.showSnackBar(context, 'Error: $errorMsg', isError: true);
        }
      }
    }
  }
}
