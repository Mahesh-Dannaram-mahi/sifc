import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart'
    show openAppSettings;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../map/map_page.dart';
import '../config/api_config.dart';
import '../services/storage_service.dart';
import '../services/jwt_service.dart';
import '../theme/sipora_theme.dart';
import '../utils/responsive_constants.dart';

class ShopService {
  static const String _selectedShopIdKey = 'selected_shop_id';
  static const String _selectedShopNameKey = 'selected_shop_name';
  static const String _selectedShopAddressKey = 'selected_shop_address';
  static const String _selectedShopLatKey = 'selected_shop_lat';
  static const String _selectedShopLngKey = 'selected_shop_lng';

  static Shop? _currentSelectedShop;
  static List<Shop> _allShops = [];
  static Position? _userLocation;

  static final Map<String, double> _distanceCache = {};
  static final Map<String, String> _distanceStringCache = {};
  static final Map<String, String> _travelTimeCache = {};

  static bool _isLocationRequesting = false;
  static Completer<bool>? _locationCompleter;
  static VoidCallback? _onSettingsClosed;

  static Shop? get currentSelectedShop => _currentSelectedShop;
  static String? get selectedShopId => _currentSelectedShop?.id;
  static String get selectedShopDisplayName {
    if (_currentSelectedShop == null) return 'No Shop Selected';
    final name = _currentSelectedShop!.name.length > 20
        ? '${_currentSelectedShop!.name.substring(0, 20)}...'
        : _currentSelectedShop!.name;
    return name;
  }

  static void setOnSettingsClosed(VoidCallback callback) {
    _onSettingsClosed = callback;
  }

  static Future<bool> requestLocationOnce(BuildContext context) async {
    if (_isLocationRequesting) {
      return _locationCompleter?.future ?? false;
    }

    _isLocationRequesting = true;
    _locationCompleter = Completer<bool>();

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!context.mounted) {
          _locationCompleter?.complete(false);
          _isLocationRequesting = false;
          return false;
        }
        final enabled = await _showLocationServiceDialog(context);
        if (!enabled) {
          _locationCompleter?.complete(false);
          _isLocationRequesting = false;
          return false;
        }
        // Wait a moment for settings to close
        await Future.delayed(const Duration(milliseconds: 500));
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          _locationCompleter?.complete(false);
          _isLocationRequesting = false;
          return false;
        }
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!context.mounted) {
            _locationCompleter?.complete(false);
            _isLocationRequesting = false;
            return false;
          }
          final granted = await _showPermissionDialog(context);
          if (!granted) {
            _locationCompleter?.complete(false);
            _isLocationRequesting = false;
            return false;
          }
          // Wait a moment for settings to close
          await Future.delayed(const Duration(milliseconds: 500));
          permission = await Geolocator.checkPermission();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!context.mounted) {
          _locationCompleter?.complete(false);
          _isLocationRequesting = false;
          return false;
        }
        await _showSettingsDialog(context);
        _locationCompleter?.complete(false);
        _isLocationRequesting = false;
        return false;
      }

      // Get current location
      _userLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _clearCaches();

      if (_allShops.isNotEmpty) {
        _sortShopsByDistance();
      }

      _locationCompleter?.complete(true);
      _isLocationRequesting = false;
      return true;
    } catch (e) {
      _locationCompleter?.complete(false);
      _isLocationRequesting = false;
      return false;
    }
  }

  static Future<bool> _showLocationServiceDialog(BuildContext context) async {
    final completer = Completer<bool>();
    final theme =
        Theme.of(context).extension<SiporaThemeExtension>() ??
        SiporaThemeExtension.light;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off_rounded,
              color: SiporaTheme.gold,
              size: ResponsiveConstants.getIconSize(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Location Services Off',
                style: TextStyle(
                  fontSize: ResponsiveConstants.getTitleFontSize(context),
                  fontWeight: FontWeight.w700,
                  color: theme.textDark,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Please enable location services to find nearby shops and get accurate delivery options.',
          style: TextStyle(
            fontSize: ResponsiveConstants.getFontSize(context),
            color: theme.textDark,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              completer.complete(false);
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: ResponsiveConstants.getFontSize(context),
                fontWeight: FontWeight.w600,
                color: theme.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Geolocator.openLocationSettings();
              _onSettingsClosed?.call();
              completer.complete(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SiporaTheme.greenDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Enable'),
          ),
        ],
      ),
    );

    return completer.future;
  }

  static Future<bool> _showPermissionDialog(BuildContext context) async {
    final completer = Completer<bool>();
    final theme =
        Theme.of(context).extension<SiporaThemeExtension>() ??
        SiporaThemeExtension.light;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SiporaTheme.goldBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: SiporaTheme.gold,
                size: ResponsiveConstants.getIconSize(context) - 4,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Location Permission Needed',
                style: TextStyle(
                  fontSize: ResponsiveConstants.getTitleFontSize(context),
                  fontWeight: FontWeight.w700,
                  color: theme.textDark,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sipora uses your location to:',
              style: TextStyle(
                fontSize: ResponsiveConstants.getFontSize(context),
                fontWeight: FontWeight.w600,
                color: theme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            _buildBulletPoint(
              context,
              'Find nearby Sipora shops',
              Icons.store_rounded,
            ),
            const SizedBox(height: 8),
            _buildBulletPoint(
              context,
              'Show accurate delivery options',
              Icons.delivery_dining_rounded,
            ),
            const SizedBox(height: 8),
            _buildBulletPoint(
              context,
              'Calculate travel time to shops',
              Icons.access_time_rounded,
            ),
            const SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SiporaTheme.goldBg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: SiporaTheme.goldText,
                    size: ResponsiveConstants.getIconSize(context) - 4,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can still browse products without location, but nearby shop features will be limited.',
                      style: TextStyle(
                        fontSize: ResponsiveConstants.getFontSize(context) - 1,
                        color: SiporaTheme.goldText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              completer.complete(false);
            },
            child: Text(
              'Not Now',
              style: TextStyle(
                fontSize: ResponsiveConstants.getFontSize(context),
                fontWeight: FontWeight.w600,
                color: theme.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await openAppSettings();
              _onSettingsClosed?.call();
              completer.complete(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SiporaTheme.greenDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );

    return completer.future;
  }

  static Future<void> _showSettingsDialog(BuildContext context) async {
    final theme =
        Theme.of(context).extension<SiporaThemeExtension>() ??
        SiporaThemeExtension.light;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off_rounded,
              color: SiporaTheme.gold,
              size: ResponsiveConstants.getIconSize(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Location Permission Denied',
                style: TextStyle(
                  fontSize: ResponsiveConstants.getTitleFontSize(context),
                  fontWeight: FontWeight.w700,
                  color: theme.textDark,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Please enable location permission in app settings to use location features.',
          style: TextStyle(
            fontSize: ResponsiveConstants.getFontSize(context),
            color: theme.textDark,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: ResponsiveConstants.getFontSize(context),
                fontWeight: FontWeight.w600,
                color: theme.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await openAppSettings();
              _onSettingsClosed?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SiporaTheme.greenDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  static Widget _buildBulletPoint(
    BuildContext context,
    String text,
    IconData icon,
  ) {
    final theme =
        Theme.of(context).extension<SiporaThemeExtension>() ??
        SiporaThemeExtension.light;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: ResponsiveConstants.getIconSize(context) - 6,
          color: SiporaTheme.greenMid,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: ResponsiveConstants.getFontSize(context),
              color: theme.textDark,
            ),
          ),
        ),
      ],
    );
  }

  static bool hasUserLocation() => _userLocation != null;
  static Position? getUserLocation() => _userLocation;

  static Future<void> loadSelectedShop() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shopId = prefs.getString(_selectedShopIdKey);
      final shopName = prefs.getString(_selectedShopNameKey);
      final shopAddress = prefs.getString(_selectedShopAddressKey);
      final shopLat = prefs.getDouble(_selectedShopLatKey) ?? 0.0;
      final shopLng = prefs.getDouble(_selectedShopLngKey) ?? 0.0;

      if (shopId != null && shopName != null && shopAddress != null) {
        _currentSelectedShop = Shop(
          id: shopId,
          name: shopName,
          address: shopAddress,
          lat: shopLat,
          lng: shopLng,
          status: 'Open',
        );
      }
    } catch (e) {}
  }

  static Future<void> selectShop(Shop shop) async {
    _currentSelectedShop = shop;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedShopIdKey, shop.id);
      await prefs.setString(_selectedShopNameKey, shop.name);
      await prefs.setString(_selectedShopAddressKey, shop.address);
      await prefs.setDouble(_selectedShopLatKey, shop.lat);
      await prefs.setDouble(_selectedShopLngKey, shop.lng);
    } catch (e) {}
  }

  static Future<void> clearSelectedShop() async {
    _currentSelectedShop = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_selectedShopIdKey);
      await prefs.remove(_selectedShopNameKey);
      await prefs.remove(_selectedShopAddressKey);
      await prefs.remove(_selectedShopLatKey);
      await prefs.remove(_selectedShopLngKey);
    } catch (e) {}
  }

  static bool hasSelectedShop() => _currentSelectedShop != null;

  static Future<Shop?> getSelectedShopWithLocation() async {
    await loadSelectedShop();
    if (_currentSelectedShop == null) return null;
    if (_currentSelectedShop!.lat != 0.0 && _currentSelectedShop!.lng != 0.0) {
      return _currentSelectedShop;
    }

    await fetchAllShops(forceRefresh: _allShops.isEmpty);
    final selectedId = _currentSelectedShop!.id;
    for (final shop in _allShops) {
      if (shop.id == selectedId) {
        await selectShop(shop);
        return shop;
      }
    }

    return _currentSelectedShop;
  }

  static Future<void> updateUserLocation(Position position) async {
    _userLocation = position;
    _clearCaches();
    if (_allShops.isNotEmpty) {
      _sortShopsByDistance();
    }
  }

  static Future<void> fetchAllShops({bool forceRefresh = false}) async {
    if (_allShops.isNotEmpty && !forceRefresh) {
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/user/get-franchise-owners'),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          final List<dynamic> data = responseData['data'] ?? [];

          _allShops = data
              .map((shopJson) {
                try {
                  return Shop.fromJson(shopJson);
                } catch (e) {
                  return null;
                }
              })
              .where((s) => s != null && s.lat != 0 && s.lng != 0)
              .cast<Shop>()
              .toList();

          _clearCaches();

          if (_userLocation != null) {
            _sortShopsByDistance();
          }
        } else {}
      } else {}
    } catch (e) {}
  }

  static void _sortShopsByDistance() {
    if (_userLocation == null) return;

    _allShops.sort((a, b) {
      double distanceA = Geolocator.distanceBetween(
        _userLocation!.latitude,
        _userLocation!.longitude,
        a.lat,
        a.lng,
      );
      double distanceB = Geolocator.distanceBetween(
        _userLocation!.latitude,
        _userLocation!.longitude,
        b.lat,
        b.lng,
      );
      return distanceA.compareTo(distanceB);
    });
  }

  static void _clearCaches() {
    _distanceCache.clear();
    _distanceStringCache.clear();
    _travelTimeCache.clear();
  }

  static Future<Position?> getCurrentLocation({
    bool forceRefresh = false,
  }) async {
    if (_userLocation != null && !forceRefresh) {
      return _userLocation;
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      _userLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _clearCaches();

      if (_allShops.isNotEmpty) {
        _sortShopsByDistance();
      }

      return _userLocation;
    } catch (e) {
      return null;
    }
  }

  static Shop? getNearestShop() {
    if (_allShops.isEmpty) {
      return null;
    }

    if (_userLocation == null) {
      return null;
    }

    Shop? nearest;
    double minDistance = double.infinity;

    for (var shop in _allShops) {
      if (shop.lat == 0.0 || shop.lng == 0.0) continue;

      double distance = Geolocator.distanceBetween(
        _userLocation!.latitude,
        _userLocation!.longitude,
        shop.lat,
        shop.lng,
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearest = shop;
      }
    }

    if (nearest != null) {}

    return nearest;
  }

  static List<Shop> getAllShops() => _allShops;

  static double? calculateDistanceToShop(Shop shop) {
    if (_userLocation == null) {
      return null;
    }

    if (shop.lat == 0.0 || shop.lng == 0.0) {
      return null;
    }

    return Geolocator.distanceBetween(
      _userLocation!.latitude,
      _userLocation!.longitude,
      shop.lat,
      shop.lng,
    );
  }

  static String getDistanceString(Shop shop) {
    // Clear cache for this shop to force recalculation
    _distanceStringCache.remove(shop.id);
    _distanceCache.remove(shop.id);

    final distance = calculateDistanceToShop(shop);
    if (distance == null) {
      return 'Unknown';
    }

    final km = distance / 1000;
    String result;

    if (km < 0.1) {
      result = '${distance.round()}m';
    } else if (km < 1) {
      result = '${distance.round()}m';
    } else {
      result = '${km.toStringAsFixed(1)}km';
    }

    _distanceStringCache[shop.id] = result;
    _distanceCache[shop.id] = distance;

    return result;
  }

  static String getTravelTimeString(Shop shop) {
    // Clear cache for this shop to force recalculation
    _travelTimeCache.remove(shop.id);

    final distance = calculateDistanceToShop(shop);
    if (distance == null) {
      return 'Unknown';
    }

    final km = distance / 1000;

    double avgSpeedKmPerHour;
    if (km < 2) {
      avgSpeedKmPerHour = 20;
    } else if (km < 10) {
      avgSpeedKmPerHour = 30;
    } else {
      avgSpeedKmPerHour = 40;
    }

    final minutes = ((km / avgSpeedKmPerHour) * 60).round();

    String result;
    if (minutes < 1) {
      result = '<1 min';
    } else if (minutes == 1) {
      result = '1 min';
    } else if (minutes < 60) {
      result = '$minutes mins';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        result = '$hours hr';
      } else {
        result = '$hours hr $remainingMinutes min';
      }
    }

    _travelTimeCache[shop.id] = result;
    return result;
  }

  static Future<void> refreshAll() async {
    _clearCaches();
    await getCurrentLocation(forceRefresh: true);
    await fetchAllShops(forceRefresh: true);
  }

  // ✅ UPDATED: fetchProductsByFranchise with better error handling
  static Future<Map<String, dynamic>> fetchProductsByFranchise(
    String franchiseId,
  ) async {
    try {
      String? userId;
      final token = await StorageService.getToken();
      if (token != null) {
        userId = JwtService.extractUserId(token);
      }

      userId ??= await StorageService.getUserId();

      final queryParameters = <String, String>{'franchise_id': franchiseId};
      if (userId != null && userId.isNotEmpty) {
        queryParameters['user_id'] = userId;
      }
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/product/get-products-for-mobile',
      ).replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {'accept': 'application/json'},
      );

      // ✅ Handle successful response (200)
      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);

          // ✅ Check if response has success flag
          if (responseData['success'] == true) {
            // ✅ Get grouped products (could be empty)
            final Map<String, dynamic> groupedProducts =
                responseData['grouped_products'] ?? {};
            final Map<String, dynamic> groupedWarehouseProducts =
                responseData['grouped_warehouse_products'] ?? {};

            // ✅ Extract all products
            final List<Map<String, dynamic>> allProducts = [];

            // Parse franchise products
            groupedProducts.forEach((category, subcategories) {
              if (subcategories is Map<String, dynamic>) {
                subcategories.forEach((subCategory, products) {
                  if (products is List) {
                    for (var product in products) {
                      if (product is Map<String, dynamic>) {
                        allProducts.add(product);
                      }
                    }
                  }
                });
              }
            });

            // Parse warehouse products
            groupedWarehouseProducts.forEach((category, subcategories) {
              if (subcategories is Map<String, dynamic>) {
                subcategories.forEach((subCategory, products) {
                  if (products is List) {
                    for (var product in products) {
                      if (product is Map<String, dynamic>) {
                        allProducts.add(product);
                      }
                    }
                  }
                });
              }
            });

            // ✅ Always return success, even if no products
            return {
              'success': true,
              'product_information': allProducts,
              'grouped_products': groupedProducts,
              'grouped_warehouse_products': groupedWarehouseProducts,
              'message':
                  responseData['message'] ?? 'Products fetched successfully',
              'counts':
                  responseData['counts'] ??
                  {
                    'franchise_products': allProducts.length,
                    'warehouse_products': 0,
                    'categories': groupedProducts.length,
                    'warehouse_categories': groupedWarehouseProducts.length,
                  },
            };
          } else {
            // ✅ API returned success: false
            return {
              'success': false,
              'error': responseData['detail'] ?? 'Failed to fetch products',
              'message': responseData['message'] ?? 'No products available',
            };
          }
        } catch (e) {
          // ✅ JSON parsing error
          return {
            'success': false,
            'error': 'Invalid response format',
            'message': 'Unable to parse product data',
          };
        }
      }
      // ✅ Handle HTTP error status codes
      else if (response.statusCode == 404) {
        return {
          'success': false,
          'error': 'Shop not found',
          'message': 'The selected shop could not be found',
        };
      } else if (response.statusCode == 500) {
        return {
          'success': false,
          'error': 'Server error',
          'message': 'Unable to fetch products at this time',
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'message': 'Failed to fetch products',
        };
      }
    } catch (e) {
      // ✅ Network or other errors
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Network error. Please check your connection.',
      };
    }
  }
}
