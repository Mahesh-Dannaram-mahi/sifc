import 'package:flutter/material.dart';
import '../widgets/user_friendly_error_dialog.dart';

class ErrorHandlerService {

  static ErrorInfo handleError(dynamic error, {String? context}) {

    // Handle specific error types
    if (error.toString().contains('503') || error.toString().contains('Service Unavailable')) {
      return ErrorInfo(
        title: 'Service Temporarily Unavailable',
        message: 'Our servers are currently experiencing high traffic or maintenance. Please try again in a few moments.',
        type: ErrorType.serviceUnavailable,
        action: 'Retry',
      );
    }

    // Handle network/connection errors
    if (error.toString().toLowerCase().contains('connection') ||
        error.toString().toLowerCase().contains('network') ||
        error.toString().toLowerCase().contains('timeout')) {
      return ErrorInfo(
        title: 'Connection Error',
        message: 'Unable to connect to our servers. Please check your internet connection and try again.',
        type: ErrorType.network,
        action: 'Retry',
      );
    }

    // Handle SQL Server connection errors (like the one in logs)
    if (error.toString().contains('SQL Server') || 
        error.toString().contains('database') ||
        error.toString().contains('firewall')) {
      return ErrorInfo(
        title: 'Database Connection Issue',
        message: 'We\'re experiencing technical difficulties with our database. Our team has been notified and is working on a fix.',
        type: ErrorType.database,
        action: 'Try Again Later',
      );
    }

    // Handle authentication errors
    if (error.toString().toLowerCase().contains('unauthorized') ||
        error.toString().toLowerCase().contains('authentication') ||
        error.toString().toLowerCase().contains('token')) {
      return ErrorInfo(
        title: 'Authentication Required',
        message: 'Please log in again to continue using the app.',
        type: ErrorType.authentication,
        action: 'Login',
      );
    }

    // Handle not found errors
    if (error.toString().contains('404') || error.toString().toLowerCase().contains('not found')) {
      return ErrorInfo(
        title: 'Content Not Available',
        message: 'The requested content is not available at the moment.',
        type: ErrorType.notFound,
        action: 'Go Back',
      );
    }

    // Default error handling
    return ErrorInfo(
      title: 'Something Went Wrong',
      message: 'We encountered an unexpected issue. Please try again or contact support if the problem persists.',
      type: ErrorType.unknown,
      action: 'Retry',
    );
  }

  static Future<void> showErrorDialog(BuildContext context, dynamic error, {String? operationContext}) async {
    final errorInfo = handleError(error, context: operationContext);
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UserFriendlyErrorDialog(errorInfo: errorInfo),
    );
  }

  static String getErrorMessage(dynamic error) {
    final errorInfo = handleError(error);
    return errorInfo.message;
  }
}

class ErrorInfo {
  final String title;
  final String message;
  final ErrorType type;
  final String action;

  ErrorInfo({
    required this.title,
    required this.message,
    required this.type,
    required this.action,
  });
}

enum ErrorType {
  serviceUnavailable,
  network,
  database,
  authentication,
  notFound,
  unknown,
}
