import 'package:flutter/material.dart';

import '../../services/wallet_security_service.dart';
import '../../theme/sipora_theme.dart';
import 'wallet_pin_page.dart';

class WalletSecurityPage extends StatefulWidget {
  const WalletSecurityPage({super.key});

  @override
  State<WalletSecurityPage> createState() => _WalletSecurityPageState();
}

class _WalletSecurityPageState extends State<WalletSecurityPage> {
  WalletSecuritySettings? _settings;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final settings = await WalletSecurityService.fetchSettings();
      if (mounted) setState(() => _settings = settings);
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

  Future<void> _openPinPage() async {
    if (_settings == null) return;

    final isChanging = _settings!.walletPinEnabled;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SetWalletPinPage(
          isChanging: isChanging,
          enableSecurityAfterSetup: false,
        ),
      ),
    );
    if (changed == true) _load();
  }

  Future<String?> _collectPin({
    required String title,
    required String subtitle,
  }) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PinEntryDialog(title: title, subtitle: subtitle),
    );
  }

  Future<void> _onSecurityToggle(bool value) async {
    if (_settings == null) return;

    setState(() => _saving = true);
    try {
      if (value && !_settings!.walletPinEnabled) {
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const SetWalletPinPage(enableSecurityAfterSetup: true),
          ),
        );
        if (changed == true) await _load();
        return;
      }

      final pin = await _collectPin(
        title: value
            ? 'Enable Wallet Protection'
            : 'Disable Wallet Protection',
        subtitle: value
            ? 'Enter your 6-digit wallet PIN'
            : 'Enter your 6-digit wallet PIN to disable',
      );
      if (pin == null || pin.isEmpty) return;

      if (value) {
        await WalletSecurityService.enableSecurity(pin);
      } else {
        await WalletSecurityService.disableSecurity(pin);
      }
      await _load();
    } catch (e) {
      if (mounted) {
        SiporaTheme.showSnackBar(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final settings = _settings;

    return Scaffold(
      backgroundColor: theme.cream,
      appBar: AppBar(
        backgroundColor: theme.white,
        title: const Text('Wallet Security'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: theme.greenDark))
          : settings == null
              ? const Center(child: Text('Unable to load wallet security'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _SecurityCard(
                      title: 'Enable Wallet Protection',
                      subtitle:
                          'Require 6-digit PIN for wallet transactions',
                      icon: Icons.shield_outlined,
                      trailing: Switch(
                        value: settings.walletSecurityEnabled,
                        onChanged:
                            _saving ? null : (value) => _onSecurityToggle(value),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    _SecurityCard(
                      title: 'Wallet PIN',
                      subtitle: settings.walletPinEnabled
                          ? '6-digit PIN is set (Tap to change)'
                          : 'Set a 6-digit PIN for wallet protection',
                      icon: Icons.pin_outlined,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            settings.walletPinEnabled ? 'Enabled' : 'Disabled',
                            style: TextStyle(
                              color: settings.walletPinEnabled
                                  ? SiporaTheme.greenDark
                                  : Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey[400],
                            size: 16,
                          ),
                        ],
                      ),
                      onTap: _saving ? null : _openPinPage,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Wallet PIN will keep your account secure from unauthorized access. Do not share this PIN with anyone.',
                      style: TextStyle(
                        color: theme.textMuted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _PinEntryDialog extends StatefulWidget {
  final String title;
  final String subtitle;

  const _PinEntryDialog({required this.title, required this.subtitle});

  @override
  State<_PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<_PinEntryDialog> {
  String _pin = '';

  void _onDigit(String digit) {
    if (_pin.length >= WalletSecurityService.pinLength) return;
    setState(() => _pin += digit);
    if (_pin.length == WalletSecurityService.pinLength) {
      Navigator.pop(context, _pin);
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
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
              onDigit: _onDigit,
              onBackspace: _onBackspace,
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SecurityCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: SiporaTheme.greenDark),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: theme.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            trailing,
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
          width: 28,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 6),
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
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  const _NumericKeypad({
    required this.onDigit,
    required this.onBackspace,
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
                onTap: onBackspace,
              ),
            ),
            Expanded(
              child: _KeypadButton(
                label: '0',
                onTap: () => onDigit('0'),
              ),
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;

  const _KeypadButton({this.label, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(40),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: SizedBox(
            height: 52,
            child: Center(
              child: icon != null
                  ? Icon(icon, color: Colors.black87)
                  : Text(
                      label ?? '',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
