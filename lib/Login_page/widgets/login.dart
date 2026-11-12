import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:pinput/pinput.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Home_page/home_page.dart';
import '../../Home_page/My_Shop/my_shop_page.dart'; // ✅ Add this import
import 'register.dart';
import '../../services/storage_service.dart';
import '../../services/location_service.dart';
import '../../theme/sipora_theme.dart';
import '../../utils/responsive_constants.dart';

// ==================== Services ====================
class AuthService {
  final http.Client _client;
  final String _platform = LocationService.getPlatform();

  // Cache location to avoid repeated calls
  LocationInfo? _cachedLocation;

  AuthService({http.Client? client}) : _client = client ?? http.Client();

  Future<LocationInfo?> _getLocation() async {
    if (_cachedLocation != null) return _cachedLocation;
    _cachedLocation = await LocationService.getLocation();
    return _cachedLocation;
  }

  Future<String> generateJwtToken(Map<String, dynamic> payload) async {
    try {
      // Get location if available
      LocationInfo? location = await _getLocation();

      final completePayload = {
        ...payload,
        'platform': _platform,
        if (location != null) ...{
          'city': location.city,
          'country': location.country,
          'region': location.region,
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
      };

      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/encode-jwt'),
            headers: {
              'Content-Type': 'application/json',
              'x-platform': _platform,
            },
            body: jsonEncode(completePayload),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw AuthException.fromResponse(response);
      }

      final data = jsonDecode(response.body);
      final token = data['token'];

      if (token == null) {
        throw AuthException('Token not found in response');
      }

      return token;
    } on http.ClientException catch (e) {
      throw NetworkException('Connection failed: ${e.message}');
    } on TimeoutException catch (_) {
      throw NetworkException('Request timeout. Please check your connection.');
    }
  }

  Future<Map<String, dynamic>> sendOtp(
    String phoneNumber,
    bool rememberMe,
  ) async {
    try {
      // ✅ Include remember_me in the payload for send_otp
      final jwtToken = await generateJwtToken({
        'phone_number': phoneNumber,
        'remember_me': rememberMe, // ✅ Add remember_me here
      });

      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/send-otp'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'x-platform': _platform,
            },
            body: jsonEncode({'payload': jwtToken}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw AuthException.fromResponse(response);
      }

      return jsonDecode(response.body);
    } on http.ClientException catch (e) {
      throw NetworkException('Connection failed: ${e.message}');
    } on TimeoutException catch (_) {
      throw NetworkException('Request timeout. Please try again.');
    }
  }

  Future<Map<String, dynamic>> verifyOtp(
    String phoneNumber,
    String otp,
    bool rememberMe,
  ) async {
    try {
      // Get fresh location for verification
      LocationInfo? location = await LocationService.getLocation();

      final payload = {
        'phone_number': phoneNumber,
        'otp': otp,
        'remember_me': rememberMe,
        'platform': _platform,
      };

      // Add location to payload if available
      if (location != null) {
        payload['city'] = location.city;
        payload['country'] = location.country;
        payload['region'] = location.region;
        payload['latitude'] = location.latitude;
        payload['longitude'] = location.longitude;
      }

      final jwtToken = await generateJwtToken(payload);

      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/verify-otp'),
            headers: {
              'Content-Type': 'application/json',
              'x-platform': _platform,
            },
            body: jsonEncode({'payload': jwtToken}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw AuthException.fromResponse(response);
      }

      final data = jsonDecode(response.body);

      if (data['token'] == null &&
          data['data'] != null &&
          data['data']['token'] != null) {
        data['token'] = data['data']['token'];
      }

      if (data['data'] != null && data['data']['user'] != null) {
        final user = data['data']['user'];
        data['first_name'] = user['first_name'] ?? user['firstName'];
        data['last_name'] = user['last_name'] ?? user['lastName'];
        data['email'] = user['email'];
        data['role'] = user['role'];
      }

      // ✅ Log the role for debugging
      debugPrint('📱 Role from verification: ${data['role']}');

      return data;
    } on http.ClientException catch (e) {
      throw NetworkException('Connection failed: ${e.message}');
    } on TimeoutException catch (_) {
      throw NetworkException('Request timeout. Please try again.');
    }
  }

  void dispose() {
    _client.close();
  }
}

// ==================== Custom Exceptions ====================
abstract class AppException implements Exception {
  final String message;
  AppException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException(super.message);
}

class AuthException extends AppException {
  AuthException(super.message);

  factory AuthException.fromResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      final message =
          data['detail'] ?? data['message'] ?? 'Authentication failed';

      if (response.statusCode == 404 ||
          message.toLowerCase().contains('not registered')) {
        return UserNotFoundException(message);
      }

      return AuthException(message);
    } catch (_) {
      return AuthException('Server error (${response.statusCode})');
    }
  }
}

class UserNotFoundException extends AuthException {
  UserNotFoundException(super.message);
}

// ==================== Login Page Widget ====================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with CodeAutoFill, SingleTickerProviderStateMixin {
  // Controllers
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // Services
  late final AuthService _authService;

  // State
  bool _rememberMe = false;
  bool _agreeToTerms = false;
  bool _isLoading = false;
  bool _showOtpSection = false;
  bool _canResend = true;
  int _resendTimer = 30;
  int _failedAttempts = 0;
  String? _mobileError;

  // Prevent double submission
  bool _isVerifying = false;

  // For custom top notification
  OverlayEntry? _notificationOverlayEntry;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _mobileController.addListener(_onMobileChanged);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _loadRememberMePreference();
  }

  void _onMobileChanged() {
    setState(() {
      _mobileError = _validateMobile(_mobileController.text);
    });
  }

  String? _validateMobile(String value) {
    if (value.isEmpty) return null;
    if (value.length != 10) {
      return 'Please enter a valid 10-digit mobile number';
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
      return 'Please enter a valid Indian mobile number';
    }
    return null;
  }

  @override
  void dispose() {
    _hideTopNotification();
    _mobileController.removeListener(_onMobileChanged);
    _mobileController.dispose();
    _otpController.dispose();
    _authService.dispose();
    SmsAutoFill().unregisterListener();
    _animationController.dispose();
    super.dispose();
  }

  // ==================== Load Remember Me Preference ====================
  Future<void> _loadRememberMePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool('remember_me') ?? false;
      if (mounted) {
        setState(() {
          _rememberMe = rememberMe;
        });
      }
    } catch (_) {
      // Ignore error
    }
  }

  // ==================== SMS Auto-Fill Methods ====================
  @override
  void codeUpdated() {
    if (code != null && code!.isNotEmpty && !_isVerifying) {
      final extractedCode = code!.replaceAll(RegExp(r'[^0-9]'), '');
      if (extractedCode.length == 6) {
        setState(() {
          _otpController.text = extractedCode;
        });
        _handleVerifyOtp(extractedCode);
      }
    }
  }

  void _startSmsListener() {
    if (_showOtpSection) {
      listenForCode();
    }
  }

  // ==================== Top Notification Methods ====================
  void _showTopNotification(
    String message, {
    Color backgroundColor = Colors.orange,
  }) {
    if (!mounted) return;

    _hideTopNotification();

    final overlay = Overlay.of(context);
    final offsetAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            bottom: false,
            child: SlideTransition(
              position: offsetAnimation,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      backgroundColor == Colors.green
                          ? Icons.check_circle
                          : backgroundColor == Colors.red
                          ? Icons.error
                          : Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        _animationController.reverse().then((_) {
                          _hideTopNotification();
                        });
                      },
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    _notificationOverlayEntry = overlayEntry;
    overlay.insert(overlayEntry);
    _animationController.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _notificationOverlayEntry != null) {
        _animationController.reverse().then((_) {
          _hideTopNotification();
        });
      }
    });
  }

  void _hideTopNotification() {
    _notificationOverlayEntry?.remove();
    _notificationOverlayEntry = null;
  }

  // ==================== Navigation Helpers ====================
  void _navigateToRegisterWithPhone() {
    final phone = _mobileController.text.replaceAll(RegExp(r'\D'), '');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterPage(prefilledPhone: phone),
      ),
    );
  }

  // ✅ NEW: Navigate to Home for regular users
  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  // ✅ NEW: Navigate to MyShop for franchise owners
  void _navigateToMyShop() {
    if (!mounted) return;
    debugPrint('🚀 Navigating to MyShopPage for franchise owner');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MyShopPage()),
      (route) => false,
    );
  }

  // ==================== API Calls ====================
  Future<void> _handleSendOtp() async {
    final mobile = _mobileController.text.replaceAll(RegExp(r'\D'), '');
    final error = _validateMobile(mobile);

    if (error != null) {
      _showTopNotification(error, backgroundColor: SiporaTheme.red);
      return;
    }

    if (!_agreeToTerms) {
      _showTopNotification(
        'Please agree to the Terms and Conditions',
        backgroundColor: SiporaTheme.red,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ Pass rememberMe to sendOtp
      final response = await _authService.sendOtp(mobile, _rememberMe);

      if (response['success'] == true && mounted) {
        setState(() {
          _showOtpSection = true;
          _canResend = false;
          _resendTimer = 30;
          _isLoading = false;
          _failedAttempts = 0;
          _isVerifying = false;
        });

        _startResendTimer();
        _startSmsListener();
        _showTopNotification(
          'OTP sent successfully!',
          backgroundColor: Colors.green,
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context).requestFocus();
        });
      }
    } on UserNotFoundException {
      if (mounted) {
        setState(() => _isLoading = false);

        _showTopNotification(
          'No account found with this number. Please register first.',
          backgroundColor: Colors.orange,
        );

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            _navigateToRegisterWithPhone();
          }
        });
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showTopNotification(e.message, backgroundColor: SiporaTheme.red);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showTopNotification(
          'An unexpected error occurred. Please try again.',
          backgroundColor: SiporaTheme.red,
        );
      }
    }
  }

  Future<void> _startResendTimer() async {
    for (int i = 30; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendTimer = i - 1;
        });
      }
    }
    if (mounted) {
      setState(() {
        _canResend = true;
      });
    }
  }

  String? _extractUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      String payload = parts[1];
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      final bytes = base64.decode(payload);
      final jsonString = utf8.decode(bytes);
      final Map<String, dynamic> data = json.decode(jsonString);

      return data['id']?.toString() ??
          data['user_id']?.toString() ??
          data['sub']?.toString() ??
          data['userId']?.toString();
    } catch (_) {
      return null;
    }
  }

  // ✅ IMPROVED: Extract role from token
  String? _extractRoleFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      String payload = parts[1];
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      final bytes = base64.decode(payload);
      final jsonString = utf8.decode(bytes);
      final Map<String, dynamic> data = json.decode(jsonString);

      return data['role']?.toString() ??
          data['user_role']?.toString() ??
          data['userType']?.toString() ??
          data['type']?.toString() ??
          data['user_type']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleVerifyOtp(String otp) async {
    // ✅ Prevent double submission
    if (_isVerifying) {
      return;
    }

    if (otp.length != 6) {
      _showTopNotification(
        'Please enter the complete 6-digit OTP',
        backgroundColor: SiporaTheme.red,
      );
      return;
    }

    setState(() {
      _isVerifying = true;
      _isLoading = true;
    });

    try {
      final phone = _mobileController.text.replaceAll(RegExp(r'\D'), '');
      final result = await _authService.verifyOtp(phone, otp, _rememberMe);

      if (result['success'] == true && result['token'] != null) {
        final String token = result['token'];

        String? userId = _extractUserIdFromToken(token);

        if (userId == null || userId.isEmpty) {
          userId = "user_$phone";
        }

        final expiryDays = _rememberMe ? 90 : 30;

        // ✅ Extract role from response or token
        String? role = result['role']?.toString();

        // If role is not in response, try to extract from token
        if (role == null || role.isEmpty) {
          role = _extractRoleFromToken(token);
        }

        // ✅ Default role if still not found
        role = role ?? 'user';

        debugPrint('📱 Final role: "$role"');

        await StorageService.saveUserData(
          userId: userId,
          token: token,
          phone: _mobileController.text,
          name: result['first_name'] != null && result['last_name'] != null
              ? '${result['first_name']} ${result['last_name']}'.trim()
              : null,
          email: result['email'],
          role: role,
          rememberMe: _rememberMe,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', _rememberMe);
        await prefs.setInt('token_expiry_days', expiryDays);
        await prefs.setString('user_phone', _mobileController.text);
        await prefs.setString('user_role', role);

        if (mounted) {
          setState(() {
            _isLoading = false;
            _isVerifying = false;
          });

          _showTopNotification(
            '✅ Login successful!',
            backgroundColor: Colors.green,
          );

          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            // ✅ CHECK ROLE AND NAVIGATE ACCORDINGLY
            final roleLower = role.toLowerCase().trim();

            // Check if user is a franchise owner
            final isFranchiseOwner =
                roleLower.contains('franchise') ||
                roleLower.contains('franchise_owner') ||
                roleLower == 'franchise_owner' ||
                roleLower == 'franchise' ||
                roleLower == 'franchiseowner' ||
                roleLower == 'franchise-owner' ||
                roleLower.contains('franchise owner') ||
                roleLower == 'franchiseowner' ||
                roleLower.contains('shop_owner') ||
                roleLower.contains('store_owner');

            debugPrint(
              '📱 Is franchise owner? $isFranchiseOwner (role: "$roleLower")',
            );

            // Role details are diagnostic only; do not show them to users.
            if (isFranchiseOwner) {
              debugPrint('🚀 Franchise owner - navigating to MyShopPage');
              _navigateToMyShop();
            } else {
              debugPrint('🚀 Regular user - navigating to HomePage');
              _navigateToHome();
            }
          }
        }
      } else {
        _failedAttempts++;
        if (_failedAttempts >= 5) {
          _showTopNotification(
            'Too many failed attempts. Please request a new OTP.',
            backgroundColor: SiporaTheme.red,
          );
          setState(() {
            _showOtpSection = false;
            _otpController.clear();
            _isVerifying = false;
          });
        } else {
          throw AuthException(
            'Invalid OTP. ${5 - _failedAttempts} attempts remaining.',
          );
        }
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isVerifying = false;
        });
        _showTopNotification(e.message, backgroundColor: SiporaTheme.red);
        _otpController.clear();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isVerifying = false;
        });
        _showTopNotification(
          'An unexpected error occurred. Please try again.',
          backgroundColor: SiporaTheme.red,
        );
        _otpController.clear();
      }
    }
  }

  Future<void> _handleResendOtp() async {
    if (!_canResend) return;
    setState(() {
      _failedAttempts = 0;
      _otpController.clear();
      _isVerifying = false;
    });
    await _handleSendOtp();
  }

  // ==================== UI Helpers ====================
  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  Future<void> _launchTermsAndConditions() async {
    final uri = Uri.parse(ApiConfig.termsOfServiceUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        _showTopNotification(
          'Could not launch Terms and Conditions',
          backgroundColor: SiporaTheme.red,
        );
      }
    }
  }

  Future<void> _launchPrivacyPolicy() async {
    final uri = Uri.parse(ApiConfig.privacyPolicyUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        _showTopNotification(
          'Could not launch Privacy Policy',
          backgroundColor: SiporaTheme.red,
        );
      }
    }
  }

  // ==================== Build Methods ====================
  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final fontSize = ResponsiveConstants.getFontSize(context);
    final titleFontSize = ResponsiveConstants.getTitleFontSize(context);

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: TextStyle(
        fontSize: fontSize + 4,
        fontWeight: FontWeight.w600,
        color: theme.textDark,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: theme.border),
        borderRadius: BorderRadius.circular(10),
      ),
    );

    return Scaffold(
      backgroundColor: theme.cream,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/sipora_logo.png'),
            fit: BoxFit.cover,
            opacity: 0.05,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: titleFontSize + 4,
                        fontWeight: FontWeight.bold,
                        color: theme.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _showOtpSection
                          ? 'Enter the 6-digit code sent to your phone'
                          : 'Sign in to continue to your account',
                      style: TextStyle(
                        fontSize: fontSize,
                        color: theme.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 30),

                    if (!_showOtpSection) ...[
                      Text(
                        'Mobile Number *',
                        style: TextStyle(
                          fontSize: fontSize - 1,
                          fontWeight: FontWeight.w500,
                          color: theme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: theme.border),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '🇮🇳 +91',
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.w500,
                                    color: theme.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _mobileError != null
                                      ? SiporaTheme.red
                                      : theme.border,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: TextFormField(
                                controller: _mobileController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter mobile number',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                ),
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                style: TextStyle(
                                  fontSize: fontSize,
                                  color: theme.textDark,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_mobileError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _mobileError!,
                          style: TextStyle(
                            fontSize: fontSize - 2,
                            color: SiporaTheme.red,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          SizedBox(
                            height: 22,
                            width: 22,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                              activeColor: theme.greenDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Remember me on this device',
                            style: TextStyle(
                              fontSize: fontSize - 1,
                              color: theme.textDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          SizedBox(
                            height: 22,
                            width: 22,
                            child: Checkbox(
                              value: _agreeToTerms,
                              onChanged: (value) {
                                setState(() {
                                  _agreeToTerms = value ?? false;
                                });
                              },
                              activeColor: theme.greenDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                text: 'I agree to the ',
                                style: TextStyle(
                                  color: theme.textMuted,
                                  fontSize: fontSize - 2,
                                ),
                                children: [
                                  WidgetSpan(
                                    child: InkWell(
                                      onTap: _launchTermsAndConditions,
                                      child: Text(
                                        'Terms and Conditions',
                                        style: TextStyle(
                                          color: theme.greenDark,
                                          fontWeight: FontWeight.w500,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const TextSpan(text: ' and '),
                                  WidgetSpan(
                                    child: InkWell(
                                      onTap: _launchPrivacyPolicy,
                                      child: Text(
                                        'Privacy Policy',
                                        style: TextStyle(
                                          color: theme.greenDark,
                                          fontWeight: FontWeight.w500,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed:
                              _agreeToTerms &&
                                  _mobileError == null &&
                                  _mobileController.text.isNotEmpty &&
                                  !_isLoading
                              ? _handleSendOtp
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.greenDark,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Get OTP',
                                  style: TextStyle(
                                    fontSize: fontSize + 1,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],

                    if (_showOtpSection) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _showOtpSection = false;
                              _otpController.clear();
                              _canResend = true;
                              _resendTimer = 30;
                              _failedAttempts = 0;
                              _isVerifying = false;
                            });
                            SmsAutoFill().unregisterListener();
                          },
                          child: Text(
                            'Change Number',
                            style: TextStyle(
                              color: theme.greenDark,
                              fontWeight: FontWeight.w500,
                              fontSize: fontSize - 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Pinput(
                          length: 6,
                          controller: _otpController,
                          defaultPinTheme: defaultPinTheme,
                          focusedPinTheme: defaultPinTheme.copyWith(
                            decoration: defaultPinTheme.decoration!.copyWith(
                              border: Border.all(
                                color: theme.greenDark,
                                width: 2,
                              ),
                            ),
                          ),
                          autofillHints: const [AutofillHints.oneTimeCode],
                          onCompleted: (value) {
                            // Only call if not already verifying
                            if (!_isVerifying) {
                              _handleVerifyOtp(value);
                            }
                          },
                          onChanged: (value) {
                            if (value.length == 6 &&
                                !_isLoading &&
                                !_isVerifying) {
                              _handleVerifyOtp(value);
                            }
                          },
                          pinAnimationType: PinAnimationType.fade,
                          hapticFeedbackType: HapticFeedbackType.lightImpact,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: TextButton(
                          onPressed: _canResend && !_isLoading
                              ? _handleResendOtp
                              : null,
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          child: Text(
                            _canResend
                                ? 'Resend OTP'
                                : 'Resend in $_resendTimer seconds',
                            style: TextStyle(
                              fontSize: fontSize - 1,
                              color: _canResend && !_isLoading
                                  ? theme.greenDark
                                  : theme.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    if (!_showOtpSection)
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: theme.textMuted,
                                fontSize: fontSize - 1,
                              ),
                            ),
                            GestureDetector(
                              onTap: _navigateToRegister,
                              child: Text(
                                'Sign up now',
                                style: TextStyle(
                                  color: theme.greenDark,
                                  fontWeight: FontWeight.w600,
                                  fontSize: fontSize - 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
