import 'dart:convert';

class JwtService {
  /// Decode JWT token payload
  static Map<String, dynamic>? decodeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      String payload = parts[1];
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      final bytes = base64.decode(payload);
      final jsonString = utf8.decode(bytes);
      return json.decode(jsonString);
    } catch (e) {
      return null;
    }
  }

  /// Extract user ID from JWT token
  static String? extractUserId(String token) {
    final payload = decodeToken(token);
    return payload?['id']?.toString() ??
        payload?['user_id']?.toString() ??
        payload?['sub']?.toString();
  }

  /// Extract user data from JWT token
  static Map<String, dynamic>? extractUserData(String token) {
    final payload = decodeToken(token);
    if (payload == null) return null;

    return {
      'id': payload['id']?.toString() ?? payload['user_id']?.toString(),
      'first_name': payload['first_name'] ?? '',
      'last_name': payload['last_name'] ?? '',
      'phone_number': payload['phone_number'] ?? '',
      'email': payload['email'] ?? '',
      'role': payload['role'] ?? 'user',
      'verified': payload['verified'] ?? false,
      'exp': payload['exp'],
    };
  }

  /// Get token expiration as DateTime
  static DateTime? getTokenExpiry(String token) {
    final payload = decodeToken(token);
    if (payload == null) return null;

    final expiry = payload['exp'];
    if (expiry == null) return null;

    try {
      int expirySeconds;
      if (expiry is int) {
        expirySeconds = expiry;
      } else if (expiry is double) {
        expirySeconds = expiry.toInt();
      } else if (expiry is String) {
        expirySeconds = int.parse(expiry);
      } else {
        return null;
      }

      return DateTime.fromMillisecondsSinceEpoch(
        expirySeconds * 1000,
        isUtc: true,
      );
    } catch (_) {
      return null;
    }
  }

  /// ✅ FIXED: Check if token is expired
  /// Returns false if the token has no expiry claim (treat as never expires)
  static bool isTokenExpired(String token) {
    final expiry = getTokenExpiry(token);
    // ✅ If there's no expiry claim, treat token as NOT expired
    if (expiry == null) return false;
    return DateTime.now().toUtc().isAfter(expiry);
  }

  /// Check if token is expired (strict mode - treats missing expiry as expired)
  /// Use this for security-critical operations where you want to require expiry
  static bool isTokenExpiredStrict(String token) {
    final expiry = getTokenExpiry(token);
    if (expiry == null) return true; // Missing expiry = expired
    return DateTime.now().toUtc().isAfter(expiry);
  }

  /// Get remaining days until token expires
  static int getRemainingDays(String token) {
    final expiry = getTokenExpiry(token);
    if (expiry == null) return -1; // -1 = no expiry set

    final remaining = expiry.difference(DateTime.now().toUtc());
    return remaining.inDays;
  }

  /// Get remaining time as Duration
  static Duration? getRemainingTime(String token) {
    final expiry = getTokenExpiry(token);
    if (expiry == null) return null;
    return expiry.difference(DateTime.now().toUtc());
  }

  /// Check if token is about to expire (within given threshold)
  static bool isTokenAboutToExpire(String token, Duration threshold) {
    final remaining = getRemainingTime(token);
    if (remaining == null) return false; // No expiry = not about to expire
    return remaining < threshold;
  }
}
