import 'package:flutter/material.dart';

import '../../services/wallet_security_service.dart';
import '../../theme/sipora_theme.dart';

enum _PinStep { enter, confirm, current }

class SetWalletPinPage extends StatefulWidget {
  final bool enableSecurityAfterSetup;
  final bool isChanging;

  const SetWalletPinPage({
    super.key,
    this.enableSecurityAfterSetup = false,
    this.isChanging = false,
  });

  @override
  State<SetWalletPinPage> createState() => _SetWalletPinPageState();
}

class _SetWalletPinPageState extends State<SetWalletPinPage> {
  static const _pinLength = WalletSecurityService.pinLength;

  String _pin = '';
  String? _firstPin;
  String? _currentPin;
  _PinStep _step = _PinStep.enter;
  bool _loading = false;
  String? _error;

  String get _instruction {
    if (widget.isChanging && _step == _PinStep.current) {
      return 'ENTER 6-DIGIT CURRENT WALLET PIN';
    }
    if (_step == _PinStep.confirm) {
      return 'RE-ENTER 6-DIGIT WALLET PIN';
    }
    return widget.isChanging
        ? 'ENTER 6-DIGIT NEW WALLET PIN'
        : 'ENTER 6-DIGIT NEW WALLET PIN';
  }

  @override
  void initState() {
    super.initState();
    if (widget.isChanging) {
      _step = _PinStep.current;
    }
  }

  void _onDigit(String digit) {
    if (_loading || _pin.length >= _pinLength) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
    if (_pin.length == _pinLength) {
      _onPinComplete();
    }
  }

  void _onBackspace() {
    if (_loading || _pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  void _onPinComplete() {
    switch (_step) {
      case _PinStep.current:
        setState(() {
          _currentPin = _pin;
          _pin = '';
          _step = _PinStep.enter;
        });
        break;
      case _PinStep.enter:
        setState(() {
          _firstPin = _pin;
          _pin = '';
          _step = _PinStep.confirm;
        });
        break;
      case _PinStep.confirm:
        if (_pin != _firstPin) {
          setState(() {
            _error = 'PINs do not match';
            _pin = '';
            _firstPin = null;
            _step = _PinStep.enter;
          });
          return;
        }
        _save();
        break;
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      if (widget.isChanging) {
        await WalletSecurityService.changePin(_currentPin!, _pin);
      } else {
        await WalletSecurityService.setupPin(_pin);
        if (widget.enableSecurityAfterSetup) {
          await WalletSecurityService.enableSecurity(_pin);
        }
      }
      if (!mounted) return;
      SiporaTheme.showSnackBar(
        context,
        widget.isChanging
            ? 'Wallet PIN changed'
            : (widget.enableSecurityAfterSetup
                ? 'Wallet protection enabled'
                : 'Wallet PIN saved'),
        isError: false,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
          _pin = '';
          if (widget.isChanging) {
            _currentPin = null;
            _firstPin = null;
            _step = _PinStep.current;
          } else {
            _firstPin = null;
            _step = _PinStep.enter;
          }
        });
      }
    }
  }

  Future<void> _disablePin() async {
    setState(() {
      _pin = '';
      _error = null;
      _step = _PinStep.current;
    });

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PinPromptDialog(
        title: 'Disable Wallet PIN',
        subtitle: 'Enter your 6-digit current PIN',
        onPin: (pin) async {
          Navigator.pop(ctx);
          setState(() => _loading = true);
          try {
            await WalletSecurityService.disablePin(pin);
            if (!mounted) return;
            SiporaTheme.showSnackBar(
              context,
              'Wallet PIN disabled',
              isError: false,
            );
            Navigator.pop(context, true);
          } catch (e) {
            if (mounted) {
              SiporaTheme.showSnackBar(
                context,
                e.toString().replaceFirst('Exception: ', ''),
                isError: true,
              );
              setState(() => _loading = false);
            }
          }
        },
      ),
    );
  }

  Future<void> _resetForgottenPin() async {
    setState(() => _loading = true);
    try {
      await WalletSecurityService.sendPinResetOtp();
    } catch (e) {
      if (mounted) {
        SiporaTheme.showSnackBar(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
      if (mounted) setState(() => _loading = false);
      return;
    }

    if (!mounted) return;
    setState(() => _loading = false);

    final reset = await _showResetPinDialog();
    if (reset == null || !mounted) return;

    final otp = reset['otp'] ?? '';
    final newPin = reset['pin'] ?? '';
    final confirmPin = reset['confirm'] ?? '';

    if (otp.length != 6) {
      SiporaTheme.showSnackBar(context, 'Enter the 6-digit OTP', isError: true);
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(newPin)) {
      SiporaTheme.showSnackBar(
        context,
        'Wallet PIN must be exactly 6 digits',
        isError: true,
      );
      return;
    }

    if (newPin != confirmPin) {
      SiporaTheme.showSnackBar(context, 'PINs do not match', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await WalletSecurityService.resetPin(otp: otp, newPin: newPin);
      if (!mounted) return;
      SiporaTheme.showSnackBar(
        context,
        'Wallet PIN reset successfully',
        isError: false,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        SiporaTheme.showSnackBar(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Map<String, String>?> _showResetPinDialog() async {
    final otpController = TextEditingController();
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Reset Wallet PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the OTP sent to your registered phone and create a new 6-digit wallet PIN.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'OTP',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'New 6-digit PIN',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Confirm new PIN',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'otp': otpController.text.trim(),
              'pin': pinController.text.trim(),
              'confirm': confirmController.text.trim(),
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: SiporaTheme.greenDark,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset PIN'),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      otpController.dispose();
      pinController.dispose();
      confirmController.dispose();
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;

    return Scaffold(
      backgroundColor: theme.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: theme.white,
        elevation: 0,
        title: Text(
          widget.isChanging ? 'Change Wallet PIN' : 'Set Wallet PIN',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.isChanging)
            TextButton(
              onPressed: _loading ? null : _disablePin,
              child: const Text(
                'Disable',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            Icon(Icons.account_balance_wallet_outlined,
                size: 40, color: SiporaTheme.greenDark),
            const SizedBox(height: 12),
            Text(
              'Wallet Security',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              _instruction,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
                color: theme.textMuted,
              ),
            ),
            const SizedBox(height: 28),
            _PinSlots(length: _pinLength, filled: _pin.length),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Wallet PIN will keep your account secure from unauthorized access. Do not share this PIN with anyone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textMuted,
                  height: 1.4,
                ),
              ),
            ),
            const Spacer(),
            _NumericKeypad(
              enabled: !_loading,
              onDigit: _onDigit,
              onBackspace: _onBackspace,
              onConfirm: _pin.length == _pinLength ? _onPinComplete : null,
              loading: _loading,
            ),
            if (widget.isChanging) ...[
              TextButton(
                onPressed: _loading ? null : _resetForgottenPin,
                child: const Text('Forgot PIN? Reset with OTP'),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _PinPromptDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final Future<void> Function(String pin) onPin;

  const _PinPromptDialog({
    required this.title,
    required this.subtitle,
    required this.onPin,
  });

  @override
  State<_PinPromptDialog> createState() => _PinPromptDialogState();
}

class _PinPromptDialogState extends State<_PinPromptDialog> {
  String _pin = '';
  bool _loading = false;

  void _onDigit(String digit) {
    if (_loading || _pin.length >= WalletSecurityService.pinLength) return;
    setState(() => _pin += digit);
    if (_pin.length == WalletSecurityService.pinLength) {
      _submit();
    }
  }

  void _onBackspace() {
    if (_loading || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    await widget.onPin(_pin);
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
            Text(
              widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            _PinSlots(
              length: WalletSecurityService.pinLength,
              filled: _pin.length,
            ),
            const SizedBox(height: 16),
            _NumericKeypad(
              enabled: !_loading,
              onDigit: _onDigit,
              onBackspace: _onBackspace,
              loading: _loading,
            ),
            TextButton(
              onPressed: _loading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinSlots extends StatelessWidget {
  final int length;
  final int filled;

  const _PinSlots({required this.length, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final active = index < filled;
        return Container(
          width: 32,
          height: 3,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: active ? SiporaTheme.greenDark : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
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
  final bool loading;

  const _NumericKeypad({
    required this.enabled,
    required this.onDigit,
    required this.onBackspace,
    this.onConfirm,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
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
                child: _KeypadButton(
                  icon: Icons.check,
                  enabled: enabled && onConfirm != null,
                  filled: true,
                  loading: loading,
                  onTap: onConfirm,
                ),
              ),
            ],
          ),
        ],
      ),
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
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(40),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(40),
          child: SizedBox(
            height: 56,
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
                              : (enabled ? Colors.black87 : Colors.grey),
                        )
                      : Text(
                          label ?? '',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
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
