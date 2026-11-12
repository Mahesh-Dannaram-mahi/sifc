import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:http/http.dart' as http;
import '../theme/sipora_theme.dart';
import '../utils/responsive_constants.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  static ConnectivityService get instance => _instance;
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<List<ConnectivityResult>> _connectivityController =
      StreamController<List<ConnectivityResult>>.broadcast();
  final StreamController<bool> _internetStatusController =
      StreamController<bool>.broadcast();
  bool _isInitialized = false;
  bool _lastInternetStatus = true;

  Stream<List<ConnectivityResult>> get connectivityStream =>
      _connectivityController.stream;
  Stream<bool> get internetStatusStream => _internetStatusController.stream;
  bool get lastInternetStatus => _lastInternetStatus;

  Future<bool> hasInternetConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();

      if (results.contains(ConnectivityResult.none)) {
        return false;
      }

      return await _checkActualInternetConnectivity();
    } catch (e) {
      // If we can't check, assume we have internet to avoid getting stuck
      return true;
    }

    // return false;
  }

  Future<bool> _checkActualInternetConnectivity() async {
    try {
      final response = await http
          .head(
            Uri.parse('https://www.google.com'),
            headers: {'Connection': 'close'},
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  void initialize() {
    if (_isInitialized) return;

    try {
      _connectivity.onConnectivityChanged.listen((
        List<ConnectivityResult> results,
      ) {
        _connectivityController.add(results);

        final hasInternet =
            !results.contains(ConnectivityResult.none) && results.isNotEmpty;
        if (hasInternet != _lastInternetStatus) {
          _lastInternetStatus = hasInternet;
          _internetStatusController.add(hasInternet);
        }
      });
      _isInitialized = true;
    } catch (e) {
    }
  }

  void dispose() {
    _connectivityController.close();
    _internetStatusController.close();
  }

  Future<void> openWifiSettings() async {
    try {
      if (Platform.isAndroid) {
        final intent = AndroidIntent(
          action: 'android.settings.WIFI_SETTINGS',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
      } else if (Platform.isIOS) {
        final settingsUri = Uri.parse('app-settings:');
        if (await canLaunchUrl(settingsUri)) {
          await launchUrl(settingsUri);
        }
      }
    } catch (e) {
    }
  }

  Future<void> openMobileDataSettings() async {
    try {
      if (Platform.isAndroid) {
        final intent = AndroidIntent(
          action: 'android.settings.WIRELESS_SETTINGS',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
      } else if (Platform.isIOS) {
        final settingsUri = Uri.parse('app-settings:');
        if (await canLaunchUrl(settingsUri)) {
          await launchUrl(settingsUri);
        }
      }
    } catch (e) {
    }
  }

  /// Shows a dialog explaining that the user needs to manually enable connectivity.
  static void showConnectivityDialog(
    BuildContext context, {
    bool isWifi = true,
  }) {
    final theme = context.siporaTheme;
    final fontSize = ResponsiveConstants.getFontSize(context);
    final titleFontSize = ResponsiveConstants.getTitleFontSize(context);
    final cardRadius = ResponsiveConstants.getCardBorderRadius(context);
    final buttonFontSize = ResponsiveConstants.getButtonFontSize(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        title: Row(
          children: [
            Icon(
              isWifi ? Icons.wifi_off : Icons.signal_cellular_alt,
              color: SiporaTheme.gold,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              isWifi ? 'Enable WiFi' : 'Enable Mobile Data',
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w700,
                color: theme.textDark,
              ),
            ),
          ],
        ),
        content: Text(
          isWifi
              ? 'Please turn on WiFi from your device settings. The app cannot enable WiFi automatically for security reasons.'
              : 'Please turn on Mobile Data from your device settings. The app cannot enable it automatically for security reasons.',
          style: TextStyle(fontSize: fontSize, color: theme.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: theme.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (isWifi) {
                await ConnectivityService.instance.openWifiSettings();
              } else {
                await ConnectivityService.instance.openMobileDataSettings();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SiporaTheme.greenDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(cardRadius),
              ),
            ),
            child: Text(
              'Open Settings',
              style: TextStyle(fontSize: buttonFontSize),
            ),
          ),
        ],
      ),
    );
  }
}
