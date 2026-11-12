import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import '../theme/sipora_theme.dart';
import '../services/shop_service.dart';
import '../utils/screen_utils.dart';

class Shop {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String status;
  final String pincode;
  final String? avatarIcons;
  final String? userId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phoneNumber;

  Shop({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.status,
    this.pincode = '',
    this.avatarIcons,
    this.userId,
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    final lat =
        double.tryParse(
          json['latitude']?.toString() ??
              json['Latitude']?.toString() ??
              json['lat']?.toString() ??
              '0',
        ) ??
        0.0;
    final lng =
        double.tryParse(
          json['longitude']?.toString() ??
              json['Longitude']?.toString() ??
              json['lng']?.toString() ??
              '0',
        ) ??
        0.0;

    final addressParts = [
      json['house']?.toString(),
      json['streetarea']?.toString() ?? json['streetArea']?.toString(),
      json['landmark']?.toString(),
      json['city']?.toString(),
      json['state']?.toString(),
      json['country']?.toString(),
      json['pincode']?.toString(),
    ].where((part) => part != null && part.isNotEmpty).toList();

    final constructedAddress = addressParts.isNotEmpty
        ? addressParts.join(', ')
        : json['fullAddress']?.toString() ??
              json['address']?.toString() ??
              'Address not available';

    return Shop(
      id:
          json['franchise_id']?.toString() ??
          json['user_id']?.toString() ??
          json['id']?.toString() ??
          '',
      name:
          json['shop_name']?.toString() ??
          json['name']?.toString() ??
          'Unknown Shop',
      address: constructedAddress,
      lat: lat,
      lng: lng,
      status: json['status']?.toString() ?? 'Open',
      pincode: json['pincode']?.toString() ?? '',
      avatarIcons: json['avataricons']?.toString(),
      userId: json['user_id']?.toString(),
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      email: json['email']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
    );
  }

  String get ownerFullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName'.trim();
    }
    return firstName ?? lastName ?? 'Shop Owner';
  }

  String get initials {
    if (firstName != null && lastName != null) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
    }
    if (firstName != null && firstName!.isNotEmpty) {
      return firstName![0].toUpperCase();
    }
    if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return 'S';
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MapPage(),
    );
  }
}

class _MapPageState extends State<MapPage> {
  List<Shop> _shops = [];
  List<Shop> _filteredShops = [];
  String _query = '';
  String _statusFilter = 'All';

  bool _locationLoading = false;
  Position? _userLocation;
  String _address = '';
  String _pincode = '';
  bool _isLoadingShops = true;
  Shop? _selectedShop;

  // Distance filter state
  int _maxDistanceKm = 20; // Default 20KM
  final int _distanceStep = 20; // Step increment/decrement

  @override
  void initState() {
    super.initState();
    _fetchShops();
    _getCurrentLocation();
    _loadSelectedShop();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSelectedShop();
  }

  Future<void> _fetchShops() async {
    if (mounted) {
      setState(() => _isLoadingShops = true);
    }
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/user/get-franchise-owners'),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        List<dynamic> data = [];

        if (responseData is Map<String, dynamic>) {
          if (responseData['data'] != null && responseData['data'] is List) {
            data = responseData['data'];
          } else if (responseData['franchises'] != null &&
              responseData['franchises'] is List) {
            data = responseData['franchises'];
          } else if (responseData['shops'] != null &&
              responseData['shops'] is List) {
            data = responseData['shops'];
          } else {
            final values = responseData.values;
            if (values.isNotEmpty && values.first is List) {
              data = values.first as List<dynamic>;
            }
          }
        } else if (responseData is List) {
          data = responseData;
        }

        final shops = data.map((shop) => Shop.fromJson(shop)).toList();
        final validShops = shops
            .where((s) => s.lat != 0 && s.lng != 0)
            .toList();

        if (mounted) {
          setState(() {
            _shops = validShops;
            _applyFilters();
            _isLoadingShops = false;
          });
        }

        await _autoSelectNearestShop();
      } else {
        if (mounted) {
          setState(() => _isLoadingShops = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingShops = false);
      }
    }
  }

  void _applyFilters() {
    final hasLocation = _userLocation != null;

    // First filter by max distance
    List<Shop> filtered = _shops.where((shop) {
      if (!hasLocation) return true;
      final distance = _calculateDistance(shop.lat, shop.lng);
      if (distance == null) return true;
      return distance <= _maxDistanceKm;
    }).toList();

    // Then apply search query and status filter
    filtered = filtered.where((shop) {
      final matchesQuery =
          _query.isEmpty ||
          shop.name.toLowerCase().contains(_query) ||
          shop.address.toLowerCase().contains(_query) ||
          shop.ownerFullName.toLowerCase().contains(_query);
      final matchesStatus =
          _statusFilter == 'All' || shop.status == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();

    // Sort by distance (nearest first)
    if (hasLocation) {
      filtered.sort((a, b) {
        final distanceA = _calculateDistance(a.lat, a.lng);
        final distanceB = _calculateDistance(b.lat, b.lng);
        if (distanceA == null && distanceB == null) return 0;
        if (distanceA == null) return 1;
        if (distanceB == null) return -1;
        return distanceA.compareTo(distanceB);
      });
    }

    setState(() {
      _filteredShops = filtered;
    });
  }

  void _increaseDistance() {
    setState(() {
      _maxDistanceKm += _distanceStep;
    });
    _applyFilters();
  }

  void _decreaseDistance() {
    if (_maxDistanceKm > _distanceStep) {
      setState(() {
        _maxDistanceKm -= _distanceStep;
      });
      _applyFilters();
    }
  }

  Future<void> _getCurrentLocation() async {
    if (mounted) {
      setState(() => _locationLoading = true);
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locationLoading = false;
            _address = 'Location services disabled';
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _locationLoading = false;
              _address = 'Location permissions denied';
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationLoading = false;
            _address = 'Location permissions permanently denied';
          });
        }
        return;
      }

      final locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        if (mounted) {
          setState(() {
            _userLocation = position;
            _address =
                '${place.street}, ${place.locality}, ${place.administrativeArea}';
            _pincode = place.postalCode ?? 'Not Found';
            _locationLoading = false;
          });
        }

        _applyFilters();
        await _autoSelectNearestShop();
      } else {
        if (mounted) {
          setState(() {
            _userLocation = position;
            _address = 'Address not found';
            _pincode = 'Not Found';
            _locationLoading = false;
          });
        }

        _applyFilters();
        await _autoSelectNearestShop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationLoading = false;
          _address = 'Error getting location';
          _pincode = 'Not Found';
        });
      }
    }
  }

  Future<void> _loadSelectedShop() async {
    await ShopService.loadSelectedShop();
    if (mounted) {
      setState(() {
        _selectedShop = ShopService.currentSelectedShop;
      });
    }
  }

  Future<void> _autoSelectNearestShop() async {
    if (ShopService.hasSelectedShop()) {
      return;
    }

    if (_filteredShops.isEmpty) {
      return;
    }

    Shop? nearestShop;
    double minDistance = double.infinity;

    if (_userLocation != null) {
      for (Shop shop in _filteredShops) {
        final distance = _calculateDistance(shop.lat, shop.lng);
        if (distance != null && distance < minDistance) {
          minDistance = distance;
          nearestShop = shop;
        }
      }
    } else {
      nearestShop = _filteredShops.first;
    }

    if (nearestShop != null) {
      await _selectShop(nearestShop);
    }
  }

  Future<void> _selectShop(Shop shop) async {
    if (mounted) {
      setState(() {
        _selectedShop = shop;
      });
    }
    await ShopService.selectShop(shop);

    if (mounted) {
      SiporaTheme.showSnackBar(
        context,
        'Selected: ${shop.name}',
        isError: false,
        duration: const Duration(seconds: 2),
      );
    }
  }

  double? _calculateDistance(double lat, double lng) {
    if (_userLocation == null) return null;
    return Geolocator.distanceBetween(
          _userLocation!.latitude,
          _userLocation!.longitude,
          lat,
          lng,
        ) /
        1000;
  }

  void _filterShops(String query) {
    _query = query.toLowerCase();
    _applyFilters();
  }

  void _filterByStatus(String status) {
    _statusFilter = status;
    _applyFilters();
  }

  Future<void> _openInGoogleMaps(Shop shop) async {
    try {
      if (shop.lat == 0 && shop.lng == 0) {
        if (mounted) {
          SiporaTheme.showSnackBar(
            context,
            'Location coordinates not available for this shop',
            isError: true,
          );
        }
        return;
      }

      final String googleMapsUrl;

      if (_userLocation != null) {
        googleMapsUrl =
            'https://www.google.com/maps/dir/${_userLocation!.latitude},${_userLocation!.longitude}/${shop.lat},${shop.lng}';
      } else {
        googleMapsUrl =
            'https://www.google.com/maps/search/?api=1&query=${shop.lat},${shop.lng}';
      }

      final Uri uri = Uri.parse(googleMapsUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        final String fallbackUrl =
            'https://www.google.com/maps/search/?api=1&query=${shop.lat},${shop.lng}';
        final Uri fallbackUri = Uri.parse(fallbackUrl);

        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            SiporaTheme.showSnackBar(
              context,
              'Could not open Google Maps. Please install the app.',
              isError: true,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        SiporaTheme.showSnackBar(
          context,
          'Error opening Google Maps: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = screenHeight * 0.9;
    final isTablet = context.isTablet;
    final hasLocation = _userLocation != null;
    final showLessButton = _maxDistanceKm > _distanceStep;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: true,
        bottom: false,
        child: Container(
          height: sheetHeight,
          decoration: BoxDecoration(
            color: theme.cream,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(
                isTablet ? context.r(28) : context.r(24),
              ),
              topRight: Radius.circular(
                isTablet ? context.r(28) : context.r(24),
              ),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: context.h(12)),
                  width: context.w(40),
                  height: context.h(4),
                  decoration: BoxDecoration(
                    color: theme.border,
                    borderRadius: BorderRadius.circular(context.r(2)),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.w(16),
                  context.h(12),
                  context.w(16),
                  context.h(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasLocation ? 'Shops Near You' : 'Shop Locator',
                          style: TextStyle(
                            fontSize: isTablet
                                ? context.sp(24)
                                : context.sp(20),
                            fontWeight: FontWeight.w700,
                            color: theme.textDark,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (_selectedShop != null)
                          Text(
                            'Selected: ${_selectedShop!.name.length > 25 ? '${_selectedShop!.name.substring(0, 25)}...' : _selectedShop!.name}',
                            style: TextStyle(
                              fontSize: context.sp(13),
                              color: theme.textMuted,
                            ),
                          ),
                        if (hasLocation)
                          Container(
                            margin: EdgeInsets.only(top: context.h(4)),
                            padding: EdgeInsets.symmetric(
                              horizontal: context.w(10),
                              vertical: context.h(3),
                            ),
                            decoration: BoxDecoration(
                              color: theme.greenBg,
                              borderRadius: BorderRadius.circular(
                                context.r(12),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: context.w(12),
                                  color: theme.greenDark,
                                ),
                                SizedBox(width: context.w(4)),
                                Text(
                                  'Showing shops within $_maxDistanceKm KM',
                                  style: TextStyle(
                                    fontSize: context.sp(11),
                                    color: theme.greenDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: context.w(36),
                        height: context.w(36),
                        decoration: BoxDecoration(
                          color: theme.white,
                          borderRadius: BorderRadius.circular(context.r(12)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              blurRadius: 4.r,
                              offset: Offset(0, 2.h),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.close,
                          size: context.w(20),
                          color: theme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Location Card
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(16),
                  vertical: context.h(8),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.white,
                    borderRadius: BorderRadius.circular(context.r(16)),
                    border: Border.all(color: theme.border, width: 0.5.w),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.05),
                        blurRadius: 8.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(context.w(14)),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(context.w(10)),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [theme.greenDark, theme.greenMid],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(context.r(11)),
                        ),
                        child: Icon(
                          Icons.navigation,
                          color: Colors.white,
                          size: context.w(22),
                        ),
                      ),
                      SizedBox(width: context.w(12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Location',
                              style: TextStyle(
                                fontSize: context.sp(13),
                                fontWeight: FontWeight.w600,
                                color: theme.textDark,
                              ),
                            ),
                            SizedBox(height: context.h(2)),
                            _locationLoading
                                ? Row(
                                    children: [
                                      SizedBox(
                                        width: context.w(14),
                                        height: context.w(14),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                theme.greenDark,
                                              ),
                                        ),
                                      ),
                                      SizedBox(width: context.w(8)),
                                      Text(
                                        'Detecting...',
                                        style: TextStyle(
                                          fontSize: context.sp(12),
                                          color: theme.textMuted,
                                        ),
                                      ),
                                    ],
                                  )
                                : _userLocation != null
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _address,
                                        style: TextStyle(
                                          fontSize: context.sp(13),
                                          color: theme.textDark,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: context.h(2)),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: context.w(8),
                                          vertical: context.h(2),
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.goldBg,
                                          borderRadius: BorderRadius.circular(
                                            context.r(8),
                                          ),
                                        ),
                                        child: Text(
                                          'PIN: $_pincode',
                                          style: TextStyle(
                                            fontSize: context.sp(11),
                                            fontWeight: FontWeight.w600,
                                            color: theme.goldText,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    _address,
                                    style: TextStyle(
                                      fontSize: context.sp(13),
                                      color: theme.textDark,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.cream,
                          borderRadius: BorderRadius.circular(context.r(10)),
                        ),
                        child: IconButton(
                          onPressed: _getCurrentLocation,
                          icon: Icon(
                            Icons.refresh,
                            color: theme.greenMid,
                            size: context.w(20),
                          ),
                          tooltip: 'Refresh location',
                          padding: EdgeInsets.all(context.w(8)),
                          constraints: BoxConstraints(
                            minWidth: context.w(36),
                            minHeight: context.w(36),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search and Filter Section
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(16),
                  vertical: context.h(8),
                ),
                child: Column(
                  children: [
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: theme.white,
                        borderRadius: BorderRadius.circular(context.r(16)),
                        border: Border.all(color: theme.border, width: 1.w),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.04),
                            blurRadius: 4.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: _filterShops,
                        style: TextStyle(
                          color: theme.textDark,
                          fontSize: context.sp(14),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search shops or owners...',
                          hintStyle: TextStyle(
                            fontSize: context.sp(13),
                            color: theme.textMuted,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: context.w(18),
                            color: theme.textMuted,
                          ),
                          suffixIcon: Icon(
                            Icons.filter_list,
                            size: context.w(18),
                            color: theme.textMuted,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: context.w(14),
                            vertical: context.h(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: context.h(12)),

                    // Status Filter Chips and Distance Control
                    Row(
                      children: [
                        // Status Filter Chips
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: ['All', 'Open', 'Closed'].map((status) {
                                final isSelected = _statusFilter == status;
                                return Padding(
                                  padding: EdgeInsets.only(right: context.w(8)),
                                  child: FilterChip(
                                    label: Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: context.sp(12),
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? Colors.white
                                            : theme.textDark,
                                      ),
                                    ),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      if (selected) _filterByStatus(status);
                                    },
                                    backgroundColor: theme.cream,
                                    selectedColor: status == 'Open'
                                        ? theme.greenDark
                                        : status == 'Closed'
                                        ? theme.red
                                        : theme.greenDark,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        context.r(20),
                                      ),
                                      side: isSelected
                                          ? BorderSide.none
                                          : BorderSide(
                                              color: theme.border,
                                              width: 0.5.w,
                                            ),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: context.w(14),
                                      vertical: context.h(6),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        // Distance Control Buttons
                        if (hasLocation) ...[
                          SizedBox(width: context.w(8)),
                          // Less Button (hidden when at 20KM)
                          if (showLessButton)
                            GestureDetector(
                              onTap: _decreaseDistance,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.w(10),
                                  vertical: context.h(6),
                                ),
                                decoration: BoxDecoration(
                                  color: theme.cream,
                                  borderRadius: BorderRadius.circular(
                                    context.r(20),
                                  ),
                                  border: Border.all(
                                    color: theme.border,
                                    width: 0.5.w,
                                  ),
                                ),
                                child: Text(
                                  'Less',
                                  style: TextStyle(
                                    fontSize: context.sp(11),
                                    fontWeight: FontWeight.w600,
                                    color: theme.greenDark,
                                  ),
                                ),
                              ),
                            ),
                          if (showLessButton) SizedBox(width: context.w(6)),
                          // More Button
                          GestureDetector(
                            onTap: _increaseDistance,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.w(10),
                                vertical: context.h(6),
                              ),
                              decoration: BoxDecoration(
                                color: theme.greenDark,
                                borderRadius: BorderRadius.circular(
                                  context.r(20),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.greenDark.withValues(
                                      alpha: 0.25,
                                    ),
                                    blurRadius: 4.r,
                                    offset: Offset(0, 2.h),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'More',
                                    style: TextStyle(
                                      fontSize: context.sp(11),
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: context.w(3)),
                                  Icon(
                                    Icons.add,
                                    size: context.w(14),
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Shops List with Selected Shop Pinned at Top
              Expanded(
                child: _isLoadingShops
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.greenDark,
                          ),
                        ),
                      )
                    : _filteredShops.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              hasLocation
                                  ? Icons.storefront_outlined
                                  : Icons.location_off_rounded,
                              size: isTablet ? context.w(80) : context.w(64),
                              color: theme.textMuted,
                            ),
                            SizedBox(height: context.h(16)),
                            Text(
                              hasLocation
                                  ? 'No Shops Within ${_maxDistanceKm}KM'
                                  : 'Enable Location',
                              style: TextStyle(
                                fontSize: isTablet
                                    ? context.sp(20)
                                    : context.sp(18),
                                fontWeight: FontWeight.w700,
                                color: theme.textDark,
                              ),
                            ),
                            SizedBox(height: context.h(8)),
                            Text(
                              hasLocation
                                  ? 'Try increasing the distance or adjusting filters'
                                  : 'Please enable location to find nearby shops',
                              style: TextStyle(
                                fontSize: context.sp(14),
                                color: theme.textMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (hasLocation) SizedBox(height: context.h(16)),
                            if (hasLocation)
                              ElevatedButton(
                                onPressed: _increaseDistance,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.greenDark,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      context.r(12),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Increase Distance to ${_maxDistanceKm + _distanceStep}KM',
                                  style: TextStyle(
                                    fontSize: context.sp(13),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.all(context.w(16)),
                        itemCount: _filteredShops.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: context.h(12)),
                        itemBuilder: (context, index) {
                          final shop = _filteredShops[index];
                          final distance = _calculateDistance(
                            shop.lat,
                            shop.lng,
                          );
                          final isSelected = _selectedShop?.id == shop.id;

                          // Pin selected shop at top
                          if (isSelected && index > 0) {
                            final selectedShop = _filteredShops.removeAt(index);
                            _filteredShops.insert(0, selectedShop);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) setState(() {});
                            });
                            return const SizedBox.shrink();
                          }

                          return _buildShopCard(
                            shop: shop,
                            distance: distance,
                            isSelected: isSelected,
                            theme: theme,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShopCard({
    required Shop shop,
    required double? distance,
    required bool isSelected,
    required SiporaThemeExtension theme,
  }) {
    final isTablet = context.isTablet;

    return Container(
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(context.r(16)),
        border: Border.all(
          color: isSelected ? theme.greenDark : theme.border,
          width: isSelected ? 2.w : 0.5.w,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: theme.greenDark.withValues(alpha: 0.12),
                  blurRadius: 16.r,
                  offset: Offset(0, 4.h),
                  spreadRadius: 2.r,
                ),
                BoxShadow(
                  color: theme.greenLight.withValues(alpha: 0.15),
                  blurRadius: 8.r,
                  offset: Offset(0, 2.h),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.04),
                  blurRadius: 8.r,
                  offset: Offset(0, 2.h),
                ),
              ],
      ),
      child: Padding(
        padding: EdgeInsets.all(context.w(14)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop Avatar Column with Status Badge Above
            Column(
              children: [
                // Status Badge Above Image
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(10),
                    vertical: context.h(3),
                  ),
                  decoration: BoxDecoration(
                    color: shop.status == 'Open' ? theme.greenDark : theme.red,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(context.r(8)),
                      topRight: Radius.circular(context.r(8)),
                      bottomLeft: Radius.circular(context.r(4)),
                      bottomRight: Radius.circular(context.r(4)),
                    ),
                  ),
                  child: Text(
                    shop.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: context.sp(7),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                SizedBox(height: context.h(4)),
                // Shop Avatar
                Container(
                  width: context.w(50),
                  height: context.w(50),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.greenDark.withValues(alpha: 0.08)
                        : shop.status == 'Open'
                        ? theme.greenBg
                        : theme.redBg,
                    borderRadius: BorderRadius.circular(context.r(12)),
                    border: Border.all(
                      color: isSelected
                          ? theme.greenDark.withValues(alpha: 0.2)
                          : Colors.transparent,
                      width: 1.5.w,
                    ),
                  ),
                  child:
                      shop.avatarIcons != null && shop.avatarIcons!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(context.r(12)),
                          child: Image.network(
                            shop.avatarIcons!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildAvatarFallback(
                                shop,
                                theme,
                                isSelected,
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: SizedBox(
                                  width: context.w(20),
                                  height: context.w(20),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.greenDark,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : _buildAvatarFallback(shop, theme, isSelected),
                ),
              ],
            ),
            SizedBox(width: context.w(12)),

            // Shop Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          shop.name,
                          style: TextStyle(
                            fontSize: isTablet
                                ? context.sp(15)
                                : context.sp(13),
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isSelected
                                ? theme.greenDark
                                : theme.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.w(6),
                            vertical: context.h(2),
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [theme.greenDark, theme.greenMid],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(context.r(10)),
                            boxShadow: [
                              BoxShadow(
                                color: theme.greenDark.withValues(alpha: 0.25),
                                blurRadius: 4.r,
                                offset: Offset(0, 2.h),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: context.w(10),
                                color: Colors.white,
                              ),
                              SizedBox(width: context.w(3)),
                              Text(
                                'SELECTED',
                                style: TextStyle(
                                  fontSize: context.sp(7),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  // Show owner name if available
                  if (shop.ownerFullName.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: context.h(2)),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: context.w(12),
                            color: theme.textMuted,
                          ),
                          SizedBox(width: context.w(4)),
                          Expanded(
                            child: Text(
                              shop.ownerFullName,
                              style: TextStyle(
                                fontSize: isTablet
                                    ? context.sp(11)
                                    : context.sp(10),
                                color: theme.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: context.h(2)),
                  Text(
                    shop.address,
                    style: TextStyle(
                      fontSize: isTablet ? context.sp(12) : context.sp(11),
                      color: isSelected ? theme.textDark : theme.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: context.h(4)),
                  // Use Wrap for badges (no overflow)
                  Wrap(
                    spacing: context.w(6),
                    runSpacing: context.h(2),
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Pincode
                      if (shop.pincode.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.w(6),
                            vertical: context.h(2),
                          ),
                          decoration: BoxDecoration(
                            color: theme.goldBg,
                            borderRadius: BorderRadius.circular(context.r(8)),
                          ),
                          child: Text(
                            'PIN: ${shop.pincode}',
                            style: TextStyle(
                              fontSize: context.sp(9),
                              fontWeight: FontWeight.w500,
                              color: theme.goldText,
                            ),
                          ),
                        ),
                      // Distance
                      if (distance != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.w(8),
                            vertical: context.h(2),
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.greenDark.withValues(alpha: 0.08)
                                : theme.greenBg,
                            borderRadius: BorderRadius.circular(context.r(10)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: context.w(10),
                                color: isSelected
                                    ? theme.greenDark
                                    : theme.greenDark,
                              ),
                              SizedBox(width: context.w(3)),
                              Text(
                                '${distance.toStringAsFixed(1)} km',
                                style: TextStyle(
                                  fontSize: context.sp(9),
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? theme.greenDark
                                      : theme.greenDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Action Buttons Column
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // SELECT Button with improved styling
                if (!isSelected)
                  ElevatedButton(
                    onPressed: () async {
                      await _selectShop(shop);
                      if (mounted) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.greenDark,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(10),
                        vertical: context.h(6),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.r(10)),
                      ),
                      minimumSize: Size(context.w(60), context.h(32)),
                      elevation: 0,
                      shadowColor: theme.greenDark.withValues(alpha: 0.3),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: context.w(14),
                          color: Colors.white,
                        ),
                        SizedBox(width: context.w(4)),
                        Text(
                          'Select',
                          style: TextStyle(
                            fontSize: isTablet
                                ? context.sp(12)
                                : context.sp(11),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (!isSelected) SizedBox(height: context.h(6)),

                // Navigate Button with improved styling
                InkWell(
                  onTap: () => _openInGoogleMaps(shop),
                  borderRadius: BorderRadius.circular(context.r(10)),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(10),
                      vertical: context.h(6),
                    ),
                    decoration: BoxDecoration(
                      color: theme.cream,
                      borderRadius: BorderRadius.circular(context.r(10)),
                      border: Border.all(
                        color: isSelected
                            ? theme.greenDark.withValues(alpha: 0.2)
                            : theme.border,
                        width: 0.5.w,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.directions,
                          size: context.w(14),
                          color: isSelected ? theme.greenDark : theme.textMuted,
                        ),
                        SizedBox(width: context.w(4)),
                        Text(
                          'Navigate',
                          style: TextStyle(
                            fontSize: isTablet ? context.sp(10) : context.sp(9),
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? theme.greenDark
                                : theme.textMuted,
                          ),
                        ),
                      ],
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

  // Avatar fallback widget
  Widget _buildAvatarFallback(
    Shop shop,
    SiporaThemeExtension theme,
    bool isSelected,
  ) {
    final isTablet = context.isTablet;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSelected
              ? [theme.greenDark, theme.greenMid]
              : [theme.greenMid, theme.greenBg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          shop.initials,
          style: TextStyle(
            fontSize: isTablet ? context.sp(18) : context.sp(16),
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : theme.textDark,
          ),
        ),
      ),
    );
  }
}
