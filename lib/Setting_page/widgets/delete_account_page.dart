import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';
import '../../providers/user_provider.dart';
import '../../services/jwt_service.dart';
import '../../services/storage_service.dart';
import '../../theme/sipora_theme.dart';
import '../../Login_page/widgets/login.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  bool _isDeleting = false;

  Future<void> _showDeleteConfirmation() async {
    if (_isDeleting) return;

    final theme = context.siporaTheme;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: SiporaTheme.redBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: SiporaTheme.red,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Delete Account?',
                  style: TextStyle(
                    color: theme.textDark,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'This will permanently delete your Sipora account and associated account data. '
            'This action cannot be undone.\n\nAre you sure you want to continue?',
            style: TextStyle(color: theme.textMuted, fontSize: 14, height: 1.5),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: theme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: SiporaTheme.dangerButtonStyle(),
              child: const Text(
                'Yes, I am sure',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    if (_isDeleting) return;

    setState(() => _isDeleting = true);

    try {
      final token = await StorageService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Your session has expired. Please log in again.');
      }

      final userId = JwtService.extractUserId(token);

      if (userId == null || userId.isEmpty) {
        throw Exception('Unable to identify your account.');
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/delete/$userId'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      Map<String, dynamic>? responseData;
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          responseData = decoded;
        }
      } catch (_) {
        // The API may return an empty/non-JSON response on success.
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        if (!mounted) return;

        Provider.of<UserProvider>(context, listen: false).clearUser();

        SiporaTheme.showSnackBar(
          context,
          responseData?['message']?.toString() ??
              'Your account has been permanently deleted.',
          isError: false,
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
        return;
      }

      final message = responseData?['message']?.toString();
      throw Exception(
        message?.isNotEmpty == true
            ? message!
            : 'Unable to delete your account. Please try again.',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isDeleting = false);

      var message = e.toString().replaceFirst('Exception: ', '');
      if (message.toLowerCase().contains('socket') ||
          message.toLowerCase().contains('connection')) {
        message = 'Network error. Please check your internet connection.';
      } else if (message.toLowerCase().contains('timeout')) {
        message = 'Request timed out. Please try again.';
      }

      SiporaTheme.showSnackBar(context, message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: theme.cream,
      appBar: AppBar(
        backgroundColor: theme.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.textDark,
            size: isTablet ? 20 : 18,
          ),
          onPressed: _isDeleting ? null : () => Navigator.pop(context),
        ),
        title: Text(
          'Delete Account',
          style: TextStyle(
            color: theme.textDark,
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: theme.border),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(isTablet ? 28 : 20),
          children: [
            const SizedBox(height: 16),
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: SiporaTheme.redBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: SiporaTheme.red.withValues(alpha: 0.18),
                ),
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: SiporaTheme.red,
                size: 38,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Permanently delete your account',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textDark,
                fontSize: isTablet ? 25 : 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Deleting your account is permanent. You will not be able to recover this account after it has been deleted.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textMuted,
                fontSize: isTablet ? 15 : 13,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(isTablet ? 22 : 18),
              decoration: BoxDecoration(
                color: theme.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: SiporaTheme.red.withValues(alpha: 0.22),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Before you continue',
                    style: TextStyle(
                      color: theme.textDark,
                      fontSize: isTablet ? 17 : 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _WarningItem(
                    text: 'Your Sipora account will be permanently deleted.',
                  ),
                  _WarningItem(
                    text: 'You will be signed out immediately after deletion.',
                  ),
                  _WarningItem(text: 'This action cannot be undone.'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: isTablet ? 54 : 50,
              child: ElevatedButton.icon(
                onPressed: _isDeleting ? null : _showDeleteConfirmation,
                icon: _isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.delete_forever_rounded),
                label: Text(
                  _isDeleting
                      ? 'Deleting Account...'
                      : 'Delete My Account Permanently',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: SiporaTheme.dangerButtonStyle(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: isTablet ? 50 : 46,
              child: OutlinedButton(
                onPressed: _isDeleting ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.textDark,
                  side: BorderSide(color: theme.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningItem extends StatelessWidget {
  final String text;

  const _WarningItem({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(
              Icons.error_outline_rounded,
              color: SiporaTheme.red,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: theme.textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
