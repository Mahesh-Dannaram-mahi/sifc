import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/error_handler_service.dart';

class UserFriendlyErrorDialog extends StatelessWidget {
  final ErrorInfo errorInfo;

  const UserFriendlyErrorDialog({super.key, required this.errorInfo});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _getIconBackgroundColor(),
                shape: BoxShape.circle,
              ),
              child: Icon(_getIcon(), size: 40, color: _getIconColor()),
            ),

            const SizedBox(height: 20),

            // Error Title
            Text(
              errorInfo.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Error Message
            Text(
              errorInfo.message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                if (errorInfo.type == ErrorType.serviceUnavailable ||
                    errorInfo.type == ErrorType.database) ...[
                  // Support button for service/database errors
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showSupportOptions(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Contact Support',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // Primary action button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _handlePrimaryAction(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      errorInfo.action,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
  }

  Color _getIconBackgroundColor() {
    switch (errorInfo.type) {
      case ErrorType.serviceUnavailable:
      case ErrorType.database:
        return Colors.orange.shade50;
      case ErrorType.network:
        return Colors.red.shade50;
      case ErrorType.authentication:
        return Colors.blue.shade50;
      case ErrorType.notFound:
        return Colors.grey.shade50;
      default:
        return Colors.red.shade50;
    }
  }

  Color _getIconColor() {
    switch (errorInfo.type) {
      case ErrorType.serviceUnavailable:
      case ErrorType.database:
        return Colors.orange.shade400;
      case ErrorType.network:
        return Colors.red.shade400;
      case ErrorType.authentication:
        return Colors.blue.shade400;
      case ErrorType.notFound:
        return Colors.grey.shade400;
      default:
        return Colors.red.shade400;
    }
  }

  IconData _getIcon() {
    switch (errorInfo.type) {
      case ErrorType.serviceUnavailable:
        return Icons.cloud_off;
      case ErrorType.database:
        return Icons.storage;
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.authentication:
        return Icons.lock;
      case ErrorType.notFound:
        return Icons.search_off;
      default:
        return Icons.error_outline;
    }
  }

  void _handlePrimaryAction(BuildContext context) {
    switch (errorInfo.type) {
      case ErrorType.authentication:
        // Navigate to login page
        Navigator.of(context).pushReplacementNamed('/login');
        break;
      case ErrorType.notFound:
        // Go back
        Navigator.of(context).pop();
        break;
      default:
        // For other errors, just close dialog - the calling screen will handle retry
        break;
    }
  }

  void _showSupportOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email Support'),
              subtitle: const Text('pavan.admin@siporagroups.com'),
              onTap: () {
                Navigator.of(context).pop();
                // You can integrate email launcher here
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Call Support'),
              subtitle: const Text('Available during business hours'),
              onTap: () {
                Navigator.of(context).pop();
                // You can integrate phone dialer here
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
