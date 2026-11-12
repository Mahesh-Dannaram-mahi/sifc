// lib/utils/image_utils.dart
import 'package:flutter/material.dart';
import '../theme/sipora_theme.dart';

class ImageUtils {
  // Remove the leading slash - Flutter assets don't use leading slashes
  static const String fallbackImagePath = 'assets/images/sipora_logo.png';

  /// Network image with automatic fallback to local logo
  static Widget networkImage({
    required String url,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    double? borderRadius,
  }) {
    final effectiveUrl = (url.isEmpty || url == 'null') ? fallbackImagePath : url;
    
    // Check if it's an asset path
    if (effectiveUrl.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: borderRadius != null ? BorderRadius.circular(borderRadius) : BorderRadius.zero,
        child: Image.asset(
          effectiveUrl,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackContainer(width, height, borderRadius);
          },
        ),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius != null ? BorderRadius.circular(borderRadius) : BorderRadius.zero,
      child: Image.network(
        effectiveUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: SiporaTheme.greenBg,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: SiporaTheme.greenDark,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackContainer(width, height, borderRadius);
        },
      ),
    );
  }

  /// Asset image with fallback
  static Widget assetImage({
    required String path,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    double? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius != null ? BorderRadius.circular(borderRadius) : BorderRadius.zero,
      child: Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackContainer(width, height, borderRadius);
        },
      ),
    );
  }

  static Widget _buildFallbackContainer(double? width, double? height, double? borderRadius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: SiporaTheme.greenBg,
        borderRadius: borderRadius != null ? BorderRadius.circular(borderRadius) : BorderRadius.zero,
      ),
      child: Center(
        child: Image.asset(
          fallbackImagePath,
          width: width != null ? width * 0.6 : 40,
          height: height != null ? height * 0.6 : 40,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            width: width,
            height: height,
            color: SiporaTheme.greenBg,
            child: Icon(
              Icons.image_not_supported_outlined,
              color: SiporaTheme.greenDark.withValues(alpha: 0.5),
              size: (width ?? 40) * 0.5,
            ),
          ),
        ),
      ),
    );
  }

  /// Validate and fix image URL
  static String getValidImageUrl(String? url) {
    if (url == null || url.isEmpty || url == 'null') {
      return fallbackImagePath;
    }
    // Remove any leading/trailing whitespace
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty || trimmedUrl == 'null') {
      return fallbackImagePath;
    }
    return trimmedUrl;
  }

  /// Check if URL is valid
  static bool isValidUrl(String? url) {
    return url != null && 
           url.isNotEmpty && 
           url != 'null' && 
           !url.startsWith('assets/') &&
           (url.startsWith('http://') || url.startsWith('https://'));
  }
}