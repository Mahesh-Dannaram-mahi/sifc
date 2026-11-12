import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sipora/services/storage_service.dart';
import 'package:sipora/services/jwt_service.dart';
import 'package:sipora/config/api_config.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static String? _currentFcmToken;
  static Timer? _retryTimer;
  static int _retryCount = 0;
  static const int maxRetries = 5;

  /// Initialize notifications (call once at app start)
  static Future<void> initialize() async {
    // Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Local notifications for foreground
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(settings: settings);

    // Request permission first
    await requestPermission();
    
    // Try to get FCM token with retry
    await getFCMTokenWithRetry();
    
    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      _retryCount = 0;
      await _sendTokenToBackend(newToken);
      await subscribeToAllTopics();
    });

    _listenForegroundMessages();
  }

  static Future<void> requestPermission() async {
    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      // Silently fail
    }
  }

  /// Get FCM token with automatic retry on SERVICE_NOT_AVAILABLE
  static Future<void> getFCMTokenWithRetry() async {
    _retryCount = 0;
    await _attemptGetToken();
  }

  static Future<void> _attemptGetToken() async {
    try {
      String? token = await _messaging.getToken();
      
      if (token != null && token.isNotEmpty) {
        if (token != _currentFcmToken) {
          _currentFcmToken = token;
          _retryCount = 0;
          
          if (_retryTimer != null) {
            _retryTimer!.cancel();
          }
          
          await _sendTokenToBackend(token);
          await subscribeToAllTopics();
        }
      } else {
        throw Exception('Token is null or empty');
      }
    } catch (e) {
      if (e.toString().contains('SERVICE_NOT_AVAILABLE')) {
        if (_retryCount < maxRetries) {
          _retryCount++;
          
          int delaySeconds = 2 * _retryCount;
          if (delaySeconds > 30) delaySeconds = 30;
          
          _retryTimer?.cancel();
          _retryTimer = Timer(Duration(seconds: delaySeconds), () async {
            await _attemptGetToken();
          });
        }
      }
    }
  }

  /// Subscribe to all topics used by the backend
  static Future<void> subscribeToAllTopics() async {
    final List<String> topics = [
      'all_users',
      'morning_users',
      'evening_users',
      'discount_users',
      'general_users',
    ];
    
    try {
      String? token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        return;
      }
      
      for (String topic in topics) {
        try {
          await _messaging.subscribeToTopic(topic);
        } catch (e) {
          // Continue with other topics even if one fails
        }
      }
    } catch (e) {
      // Silently fail
    }
  }

  static Future<bool> _sendTokenToBackend(String fcmToken) async {
    // 1. Get user ID
    String? userId;
    final authToken = await StorageService.getToken();
    if (authToken != null) {
      userId = JwtService.extractUserId(authToken);
    }
    if (userId == null) {
      userId = await StorageService.getUserId();
    }

    if (userId == null) {
      await StorageService.setPendingFcmToken(fcmToken);
      return false;
    }

    // 2. Get device name
    String deviceName = await _getDeviceName();
    
    // 3. Get platform
    String platform = '';
    if (Platform.isAndroid) platform = 'android';
    else if (Platform.isIOS) platform = 'ios';
    else platform = 'web';
    
    // 4. Get app version
    String appVersion = await _getAppVersion();

    // 5. Send to backend
    final url = Uri.parse('${ApiConfig.baseUrl}/api/notifications/register-device');
    final body = jsonEncode({
      'user_id': userId,
      'device_name': deviceName,
      'platform': platform,
      'app_version': appVersion,
      'fcm_token': fcmToken,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        await StorageService.clearPendingFcmToken();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Call after login to register any pending token
  static Future<void> registerDeviceAfterLogin() async {
    _retryTimer?.cancel();
    
    String? pendingToken = await StorageService.getPendingFcmToken();
    if (pendingToken != null) {
      await _sendTokenToBackend(pendingToken);
      await subscribeToAllTopics();
    } else {
      await getFCMTokenWithRetry();
    }
  }

  /// Force retry token generation (call when connectivity returns)
  static Future<void> forceRetryTokenGeneration() async {
    _retryCount = 0;
    _retryTimer?.cancel();
    await _attemptGetToken();
  }

  // ----- Helper methods using device_info_plus and package_info_plus -----
  static Future<String> _getDeviceName() async {
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.model;
      }
    } catch (e) {
      // Fall through
    }
    return 'Unknown Device';
  }

  static Future<String> _getAppVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      return '1.0.0';
    }
  }

  // ----- Foreground notification handling -----
  static Future<void> showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'sifc_channel',
      'SIFC Notifications',
      channelDescription: 'Notifications from SIFC app',
      importance: Importance.high,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      notificationDetails: details,
    );
  }

  static void _listenForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showLocalNotification(message);
    });
  }
  
  /// Clean up resources when app closes
  static void dispose() {
    _retryTimer?.cancel();
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background handler – no UI, just let the OS handle it
}