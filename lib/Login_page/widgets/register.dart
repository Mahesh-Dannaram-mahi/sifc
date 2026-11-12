import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Home_page/home_page.dart';
import '../../services/storage_service.dart';
import '../../services/location_service.dart';
import '../../theme/sipora_theme.dart';
import '../../utils/responsive_constants.dart';
import 'login.dart';

class RegisterPage extends StatefulWidget {
  final String? prefilledPhone;

  const RegisterPage({super.key, this.prefilledPhone});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  bool _agreeToTerms = false;
  bool _rememberMe = false;

  // OTP related state
  bool _showOtpSection = false;
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _canResend = true;
  int _resendTimer = 30;
  bool _isLoading = false;
  bool _isVerifying = false; // Prevent double submission

  late final String _platform;
  LocationInfo? _cachedLocation;

  @override
  void initState() {
    super.initState();
    _platform = LocationService.getPlatform();
    if (widget.prefilledPhone != null && widget.prefilledPhone!.isNotEmpty) {
      _mobileController.text = widget.prefilledPhone!;
    }
    // Pre-fetch location
    _getLocation();
  }

  Future<void> _getLocation() async {
    _cachedLocation = await LocationService.getLocation();
    if (_cachedLocation != null) {
      // debugPrint(
      //   '📍 Location obtained: ${_cachedLocation!.city}, ${_cachedLocation!.country}',
      // );
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<String> getJwtFromBackend() async {
    try {
      // Get fresh location if not cached
      LocationInfo? location =
          _cachedLocation ?? await LocationService.getLocation();

      final payload = {
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'email': _emailController.text,
        'phone_number': _mobileController.text.replaceAll(RegExp(r'\D'), ''),
        'remember_me': _rememberMe,
        'platform': _platform,
        if (location != null) ...{
          'city': location.city,
          'country': location.country,
          'region': location.region,
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
      };

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/encode-jwt'),
            headers: {
              'Content-Type': 'application/json',
              'x-platform': _platform,
            },
            body: jsonEncode(payload),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception(
              'Request timeout. Please check your connection.',
            ),
          );

      if (response.statusCode != 200) {
        final errorBody = response.body.isNotEmpty
            ? response.body
            : 'No error details';
        throw Exception(
          errorBody.contains('detail')
              ? jsonDecode(errorBody)['detail']
              : 'JWT generation failed',
        );
      }

      final data = jsonDecode(response.body);
      if (data['token'] == null) {
        throw Exception('Token not found in response');
      }
      return data['token'];
    } catch (e) {
      throw Exception('Error generating JWT: $e');
    }
  }

  Future<String> getJwtForOtpVerify(String phoneNumber, String otp) async {
    try {
      // Get fresh location for verification
      LocationInfo? location = await LocationService.getLocation();

      final payload = {
        'phone_number': phoneNumber,
        'otp': otp,
        'remember_me': _rememberMe,
        'platform': _platform,
        if (location != null) ...{
          'city': location.city,
          'country': location.country,
          'region': location.region,
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
      };

      // debugPrint(
      //   '📍 Sending location for verification: ${location?.city ?? "No location"}',
      // );

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/encode-jwt'),
            headers: {
              'Content-Type': 'application/json',
              'x-platform': _platform,
            },
            body: jsonEncode(payload),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception(
              'Request timeout. Please check your connection.',
            ),
          );

      if (response.statusCode != 200) {
        final errorBody = response.body.isNotEmpty
            ? response.body
            : 'No error details';
        throw Exception(
          errorBody.contains('detail')
              ? jsonDecode(errorBody)['detail']
              : 'JWT generation failed',
        );
      }

      final data = jsonDecode(response.body);
      if (data['token'] == null) {
        throw Exception('Token not found in response');
      }
      return data['token'];
    } catch (e) {
      throw Exception('Error generating OTP verify JWT: $e');
    }
  }

  Future<void> handleSendOtp() async {
    if (!areMandatoryFieldsFilled()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all mandatory fields first'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await getJwtFromBackend();

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/register-user'),
            headers: {
              'Content-Type': 'application/json',
              'x-platform': _platform,
            },
            body: jsonEncode({'payload': token}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception(
              'Request timeout. Please check your connection.',
            ),
          );

      if (response.statusCode != 200) {
        final errorBody = response.body.isNotEmpty
            ? response.body
            : 'No error details';

        if (response.statusCode == 409 ||
            (errorBody.contains('already exists') ||
                errorBody.contains('already registered'))) {
          throw Exception(
            'User already exists with this phone number. Please login instead.',
          );
        }

        throw Exception(
          errorBody.contains('message')
              ? jsonDecode(errorBody)['message']
              : 'Failed to send OTP',
        );
      }

      if (mounted) {
        setState(() {
          _showOtpSection = true;
          _canResend = false;
          _resendTimer = 30;
          _isLoading = false;
          _isVerifying = false;
        });

        _startResendTimer();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent successfully! Please check your phone.'),
          ),
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusNodes[0].requestFocus();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
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

  String? extractUserIdFromToken(String token) {
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

      return data['user_id']?.toString() ??
          data['sub']?.toString() ??
          data['id']?.toString() ??
          data['userId']?.toString();
    } catch (e) {
      return null;
    }
  }

  Future<void> handleVerifyOtpAndCreateAccount() async {
    // ✅ Prevent double submission
    if (_isVerifying) {
      // debugPrint(
      //   '⚠️ Verification already in progress, skipping duplicate call',
      // );
      return;
    }

    final enteredOtp = _otpControllers
        .map((controller) => controller.text)
        .join();

    if (enteredOtp.length != 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter the complete 6-digit OTP'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isVerifying = true;
      _isLoading = true;
    });

    try {
      final phone = _mobileController.text.replaceAll(RegExp(r'\D'), '');

      final token = await getJwtForOtpVerify(phone, enteredOtp);

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/verify-otp'),
            headers: {
              'Content-Type': 'application/json',
              'x-platform': _platform,
            },
            body: jsonEncode({'payload': token}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception(
              'Request timeout. Please check your connection.',
            ),
          );

      if (response.statusCode != 200) {
        final errorBody = response.body.isNotEmpty
            ? response.body
            : 'No error details';
        throw Exception(
          errorBody.contains('detail')
              ? jsonDecode(errorBody)['detail']
              : 'Invalid OTP. Please try again.',
        );
      }

      final data = jsonDecode(response.body);

      if (data['token'] == null) {
        throw Exception('Authentication failed. Please try again.');
      }

      final authToken = data['token'];

      await StorageService.saveToken(authToken);

      String? userId;

      if (data['user_id'] != null) {
        userId = data['user_id'].toString();
      } else if (data['userId'] != null) {
        userId = data['userId'].toString();
      } else if (data['data'] != null && data['data']['user_id'] != null) {
        userId = data['data']['user_id'].toString();
      } else if (data['user'] != null && data['user']['id'] != null) {
        userId = data['user']['id'].toString();
      }

      if (userId == null || userId.isEmpty) {
        userId = extractUserIdFromToken(authToken);
      }

      if (userId != null && userId.isNotEmpty) {
        await StorageService.saveUserId(userId);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', userId);
      } else {
        userId = "user_$phone";
        await StorageService.saveUserId(userId);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', userId);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_phone', _mobileController.text);
      await prefs.setBool('is_logged_in', true);
      await prefs.setBool('remember_me', _rememberMe);

      final fullName =
          '${_firstNameController.text} ${_lastNameController.text}'.trim();
      await StorageService.saveUserName(fullName);
      await prefs.setString('user_name', fullName);

      if (_emailController.text.isNotEmpty) {
        await StorageService.saveUserEmail(_emailController.text);
        await prefs.setString('user_email', _emailController.text);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isVerifying = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() {
        _isLoading = false;
        _isVerifying = false;
      });
    }
  }

  bool areMandatoryFieldsFilled() {
    return _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _mobileController.text.length == 10 &&
        _agreeToTerms;
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    setState(() {
      _isVerifying = false;
      _otpControllers.forEach((controller) => controller.clear());
    });
    await handleSendOtp();
  }

  Future<void> _launchTermsAndConditions() async {
    final uri = Uri.parse(ApiConfig.termsOfServiceUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch Terms and Conditions'),
            backgroundColor: Colors.red,
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch Privacy Policy'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final fontSize = ResponsiveConstants.getFontSize(context);
    final titleFontSize = ResponsiveConstants.getTitleFontSize(context);

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
                      'Create Account',
                      style: TextStyle(
                        fontSize: titleFontSize + 4,
                        fontWeight: FontWeight.bold,
                        color: theme.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Join thousands of tea lovers and discover India\'s finest teas',
                      style: TextStyle(
                        fontSize: fontSize,
                        color: theme.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Name Fields
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'First Name *',
                                style: TextStyle(
                                  fontSize: fontSize - 1,
                                  fontWeight: FontWeight.w500,
                                  color: theme.textDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  border: Border.all(color: theme.border),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: TextFormField(
                                  controller: _firstNameController,
                                  decoration: const InputDecoration(
                                    hintText: 'Abhishek',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 14,
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    color: theme.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Last Name *',
                                style: TextStyle(
                                  fontSize: fontSize - 1,
                                  fontWeight: FontWeight.w500,
                                  color: theme.textDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  border: Border.all(color: theme.border),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: TextFormField(
                                  controller: _lastNameController,
                                  decoration: const InputDecoration(
                                    hintText: 'Mandal',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 14,
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    color: theme.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Email Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email Address',
                          style: TextStyle(
                            fontSize: fontSize - 1,
                            fontWeight: FontWeight.w500,
                            color: theme.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.border),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              hintText: 'abhishek@example.com',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              fontSize: fontSize,
                              color: theme.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Mobile Number Label
                    Text(
                      'Enter your 10-digit Indian mobile number',
                      style: TextStyle(
                        fontSize: fontSize - 2,
                        color: theme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Mobile Number Row
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
                              border: Border.all(color: theme.border),
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
                    const SizedBox(height: 12),

                    // Send OTP Button (only show if OTP section not visible)
                    if (!_showOtpSection)
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : handleSendOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.greenDark,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(100, 42),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Send OTP',
                                  style: TextStyle(
                                    fontSize: fontSize - 1,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                    // OTP Section
                    if (_showOtpSection) ...[
                      const SizedBox(height: 24),

                      // OTP Input Fields
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          return SizedBox(
                            width: 48,
                            height: 52,
                            child: TextField(
                              controller: _otpControllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(1),
                              ],
                              style: TextStyle(
                                fontSize: fontSize + 4,
                                fontWeight: FontWeight.w600,
                                color: theme.textDark,
                              ),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: theme.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: theme.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: theme.greenDark,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: theme.white,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (value) => _onOtpChanged(index, value),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),

                      // Resend OTP
                      Center(
                        child: TextButton(
                          onPressed: _canResend ? _resendOtp : null,
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          child: Text(
                            _canResend
                                ? 'Resend OTP'
                                : 'Resend in $_resendTimer seconds',
                            style: TextStyle(
                              fontSize: fontSize - 2,
                              color: _canResend
                                  ? theme.greenDark
                                  : theme.textMuted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Verify OTP Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading || _isVerifying
                              ? null
                              : handleVerifyOtpAndCreateAccount,
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
                                  'Verify & Create Account',
                                  style: TextStyle(
                                    fontSize: fontSize + 1,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Remember Me Checkbox (only show if OTP section not visible)
                    if (!_showOtpSection) ...[
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
                              fontSize: fontSize - 2,
                              color: theme.textDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Terms Checkbox (only show if OTP section not visible)
                    if (!_showOtpSection) ...[
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
                    ],

                    // Create Account Button (only show if OTP section not visible)
                    if (!_showOtpSection) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed:
                              _agreeToTerms &&
                                  areMandatoryFieldsFilled() &&
                                  !_showOtpSection
                              ? () {
                                  handleSendOtp();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.greenDark,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: fontSize + 1,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Sign In Link
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: theme.textMuted,
                              fontSize: fontSize - 2,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            },
                            child: Text(
                              'Sign in',
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
