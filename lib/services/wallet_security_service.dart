import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../theme/sipora_theme.dart';
import 'jwt_service.dart';
import 'storage_service.dart';

class WalletSecuritySettings {
  final bool walletSecurityEnabled;
  final bool walletPinEnabled;

  const WalletSecuritySettings({
    required this.walletSecurityEnabled,
    required this.walletPinEnabled,
  });

  factory WalletSecuritySettings.fromJson(Map<String, dynamic> json) {
    return WalletSecuritySettings(
      walletSecurityEnabled: json['wallet_security_enabled'] == true,
      walletPinEnabled: json['wallet_pin_enabled'] == true,
    );
  }
}

class WalletSecurityService {
  static const String _base =
      '${ApiConfig.baseUrl}/api/customer_wallet/wallet/security';
  static const String _authBase = '${ApiConfig.baseUrl}/api/auth';
  static const int pinLength = 6;

  static Future<String?> resolveUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = await StorageService.getUserId();
    userId ??= prefs.getString('user_id');
    final token =
        await StorageService.getToken() ?? prefs.getString('tea_app_token');
    if ((userId == null || userId.isEmpty) && token != null) {
      userId = JwtService.extractUserId(token);
    }
    return userId;
  }

  static Future<WalletSecuritySettings> fetchSettings() async {
    final userId = await resolveUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception('Please login again');
    }

    final response = await http.get(
      Uri.parse('$_base/$userId'),
      headers: {'accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Could not load wallet security settings');
    }

    return WalletSecuritySettings.fromJson(jsonDecode(response.body));
  }

  static Future<void> _post(String endpoint, Map<String, dynamic> body) async {
    final userId = await resolveUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception('Please login again');
    }

    final response = await http.post(
      Uri.parse('$_base/$endpoint'),
      headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'user_id': userId, ...body}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Wallet security request failed';
      try {
        final decoded = jsonDecode(response.body);
        message = decoded['detail']?.toString() ?? message;
      } catch (_) {}
      throw Exception(message);
    }
  }

  static Future<void> setupPin(String pin) => _post('setup-pin', {'pin': pin});

  static Future<void> changePin(String currentPin, String newPin) =>
      _post('change-pin', {'current_pin': currentPin, 'new_pin': newPin});

  static Future<void> resetPin({required String otp, required String newPin}) =>
      _post('reset-pin', {'otp': otp, 'new_pin': newPin});

  static Future<void> verifyPin(String pin) =>
      _post('verify-pin', {'pin': pin});

  static Future<void> disablePin(String pin) =>
      _post('disable-pin', {'pin': pin});

  static Future<void> enableSecurity(String pin) =>
      _post('enable', {'pin': pin});

  static Future<void> disableSecurity(String pin) =>
      _post('disable', {'pin': pin});

  static Future<String?> resolveUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_phone');
  }

  static Future<String> _encodeJwt(Map<String, dynamic> payload) async {
    final response = await http
        .post(
          Uri.parse('$_authBase/encode-jwt'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Could not start PIN reset');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final token = decoded['token']?.toString();
    if (token == null || token.isEmpty) {
      throw Exception('Could not start PIN reset');
    }
    return token;
  }

  static Future<void> sendPinResetOtp() async {
    final phone = await resolveUserPhone();
    if (phone == null || phone.trim().isEmpty) {
      throw Exception('Phone number not found. Please login again');
    }

    final token = await _encodeJwt({'phone_number': phone.trim()});
    final response = await http
        .post(
          Uri.parse('$_authBase/send-otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'payload': token}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      String message = 'Could not send OTP';
      try {
        final decoded = jsonDecode(response.body);
        message = decoded['detail']?.toString() ?? message;
      } catch (_) {}
      throw Exception(message);
    }
  }

  static Future<bool> authenticateForWalletAction(
    BuildContext context, {
    String reason = 'Authenticate to continue wallet transaction',
  }) async {
    final settings = await fetchSettings();
    if (!settings.walletSecurityEnabled) return true;

    if (!context.mounted) return false;
    return WalletPinDialog.show(context, reason: reason);
  }
}

class WalletPinDialog extends StatefulWidget {
  final String reason;

  const WalletPinDialog({super.key, required this.reason});

  static Future<bool> show(
    BuildContext context, {
    String reason = 'Enter your 6-digit wallet PIN',
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => WalletPinDialog(reason: reason),
        ) ??
        false;
  }

  @override
  State<WalletPinDialog> createState() => _WalletPinDialogState();
}

class _WalletPinDialogState extends State<WalletPinDialog> {
  String _pin = '';
  bool _loading = false;
  String? _error;

  void _onDigit(String digit) {
    if (_loading || _pin.length >= WalletSecurityService.pinLength) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
    if (_pin.length == WalletSecurityService.pinLength) {
      _verify();
    }
  }

  void _onBackspace() {
    if (_loading || _pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  Future<void> _verify() async {
    if (_pin.length != WalletSecurityService.pinLength) {
      setState(() => _error = 'Enter your 6-digit wallet PIN');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await WalletSecurityService.verifyPin(_pin);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _loading = false;
        _pin = '';
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Wallet PIN',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              widget.reason,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            _PinDots(
              length: WalletSecurityService.pinLength,
              filled: _pin.length,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            _NumericKeypad(
              enabled: !_loading,
              onDigit: _onDigit,
              onBackspace: _onBackspace,
              onConfirm: _verify,
              showConfirm: true,
              loading: _loading,
            ),
            TextButton(
              onPressed: _loading ? null : () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  final int length;
  final int filled;

  const _PinDots({required this.length, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final active = index < filled;
        return Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? SiporaTheme.greenDark : Colors.transparent,
            border: Border.all(
              color: active ? SiporaTheme.greenDark : Colors.grey,
              width: 2,
            ),
          ),
        );
      }),
    );
  }
}

class _NumericKeypad extends StatelessWidget {
  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onConfirm;
  final bool showConfirm;
  final bool loading;

  const _NumericKeypad({
    required this.enabled,
    required this.onDigit,
    required this.onBackspace,
    this.onConfirm,
    this.showConfirm = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];
    return Column(
      children: [
        for (int row = 0; row < 3; row++)
          Row(
            children: [
              for (int col = 0; col < 3; col++)
                Expanded(
                  child: _KeypadButton(
                    label: keys[row * 3 + col],
                    enabled: enabled,
                    onTap: () => onDigit(keys[row * 3 + col]),
                  ),
                ),
            ],
          ),
        Row(
          children: [
            Expanded(
              child: _KeypadButton(
                icon: Icons.backspace_outlined,
                enabled: enabled,
                onTap: onBackspace,
              ),
            ),
            Expanded(
              child: _KeypadButton(
                label: '0',
                enabled: enabled,
                onTap: () => onDigit('0'),
              ),
            ),
            Expanded(
              child: showConfirm
                  ? _KeypadButton(
                      icon: Icons.check,
                      enabled: enabled && onConfirm != null,
                      filled: true,
                      loading: loading,
                      onTap: onConfirm,
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final bool enabled;
  final bool filled;
  final bool loading;
  final VoidCallback? onTap;

  const _KeypadButton({
    this.label,
    this.icon,
    required this.enabled,
    this.filled = false,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: filled
            ? (enabled ? SiporaTheme.greenDark : Colors.grey.shade300)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(40),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(40),
          child: SizedBox(
            height: 52,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : icon != null
                      ? Icon(
                          icon,
                          color: filled
                              ? Colors.white
                              : (enabled
                                  ? Colors.black87
                                  : Colors.grey),
                        )
                      : Text(
                          label ?? '',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: enabled ? Colors.black87 : Colors.grey,
                          ),
                        ),
            ),
          ),
        ),
      ),
    );
  }
}
