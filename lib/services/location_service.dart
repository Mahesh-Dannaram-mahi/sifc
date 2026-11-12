import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../config/api_config.dart';

class LocationInfo {
  final String city;
  final String country;
  final String region;
  final String latitude;
  final String longitude;
  final String? formattedAddress;

  LocationInfo({
    required this.city,
    required this.country,
    required this.region,
    required this.latitude,
    required this.longitude,
    this.formattedAddress,
  });

  Map<String, dynamic> toJson() => {
    'city': city,
    'country': country,
    'region': region,
    'latitude': latitude,
    'longitude': longitude,
    'formatted_address': formattedAddress,
  };
}

class LocationService {
  // Get Google Maps API Key from ApiConfig
  static String get _googleMapsApiKey => ApiConfig.googleMapsApiKey;

  // Get platform (android/ios)
  static String getPlatform() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'android';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ios';
    } else {
      return 'mobile';
    }
  }

  // Main method to get location
  static Future<LocationInfo?> getLocation() async {
    try {
      // Try device GPS first
      LocationInfo? location = await _getDeviceLocation();
      if (location != null && location.city.isNotEmpty) {
        // debugPrint(
        //   '📍 Location from GPS: ${location.city}, ${location.country}',
        // );
        return location;
      }

      // Fallback to IP-based location
      location = await _getIPLocation();
      if (location != null) {
        // debugPrint(
        //   '📍 Location from IP: ${location.city}, ${location.country}',
        // );

        // Try to enrich with Google reverse geocode if we have coordinates
        if (location.latitude.isNotEmpty && location.longitude.isNotEmpty) {
          final enriched = await _reverseGeocode(
            double.parse(location.latitude),
            double.parse(location.longitude),
          );
          if (enriched != null) {
            return LocationInfo(
              city: enriched['city'] ?? location.city,
              country: enriched['country'] ?? location.country,
              region: enriched['region'] ?? location.region,
              latitude: location.latitude,
              longitude: location.longitude,
              formattedAddress: enriched['formatted_address'],
            );
          }
        }
        return location;
      }

      // debugPrint('⚠️ No location available from any source');
      return null;
    } catch (e) {
      // debugPrint('Error getting location: $e');
      return null;
    }
  }

  static Future<LocationInfo?> _getDeviceLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // debugPrint('Location services are disabled');
        return null;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // debugPrint('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // debugPrint('Location permissions are permanently denied');
        return null;
      }

      // Get current position using the new LocationSettings API
      LocationSettings locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      // debugPrint(
      //   '📍 GPS coordinates: ${position.latitude}, ${position.longitude}',
      // );

      // Reverse geocode using Google Maps API
      final addressInfo = await _reverseGeocode(
        position.latitude,
        position.longitude,
      );

      if (addressInfo != null) {
        // debugPrint(
        //   '📍 Reverse geocode success: ${addressInfo['city']}, ${addressInfo['country']}',
        // );
        return LocationInfo(
          city: addressInfo['city'] ?? '',
          country: addressInfo['country'] ?? '',
          region: addressInfo['region'] ?? '',
          latitude: position.latitude.toString(),
          longitude: position.longitude.toString(),
          formattedAddress: addressInfo['formatted_address'],
        );
      }

      // Return coordinates only if reverse geocode fails
      return LocationInfo(
        city: '',
        country: '',
        region: '',
        latitude: position.latitude.toString(),
        longitude: position.longitude.toString(),
      );
    } catch (e) {
      // debugPrint('Error getting device location: $e');
      return null;
    }
  }

  static Future<Map<String, String>?> _reverseGeocode(
    double lat,
    double lng,
  ) async {
    try {
      // Check if API key is configured
      if (_googleMapsApiKey.isEmpty ||
          _googleMapsApiKey == 'YOUR_GOOGLE_MAPS_API_KEY_HERE') {
        // debugPrint(
        //   '⚠️ Google Maps API key not configured. Please add your API key to ApiConfig.googleMapsApiKey',
        // );
        return null;
      }

      final response = await http
          .get(
            Uri.parse(
              'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$_googleMapsApiKey',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        // debugPrint('Geocoding API error: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body);

      if (data['status'] == 'REQUEST_DENIED') {
        // debugPrint(
        //   '❌ Google Maps API key is invalid or Geocoding API is not enabled. Status: ${data['status']}',
        // );
        // debugPrint('Error message: ${data['error_message']}');
        return null;
      }

      if (data['status'] != 'OK' || data['results'].isEmpty) {
        // debugPrint('Geocoding API returned: ${data['status']}');
        return null;
      }

      final result = data['results'][0];
      final components = result['address_components'];
      final formattedAddress = result['formatted_address'];

      String city = '';
      String region = '';
      String country = '';

      for (var component in components) {
        final types = component['types'] as List;
        if (types.contains('locality') ||
            types.contains('administrative_area_level_3')) {
          city = component['long_name'];
        }
        if (types.contains('administrative_area_level_1')) {
          region = component['long_name'];
        }
        if (types.contains('country')) {
          country = component['long_name'];
        }
      }

      // debugPrint(
      //   '📍 Reverse geocode result: City=$city, Region=$region, Country=$country',
      // );

      return {
        'city': city,
        'country': country,
        'region': region,
        'formatted_address': formattedAddress,
      };
    } catch (e) {
      // debugPrint('Reverse geocode error: $e');
      return null;
    }
  }

  static Future<LocationInfo?> _getIPLocation() async {
    try {
      final response = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        // debugPrint('IP location API error: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body);

      if (data['city'] != null) {
        return LocationInfo(
          city: data['city'] ?? '',
          country: data['country_name'] ?? data['country'] ?? '',
          region: data['region'] ?? data['region_code'] ?? '',
          latitude: data['latitude']?.toString() ?? '',
          longitude: data['longitude']?.toString() ?? '',
        );
      }
      return null;
    } catch (e) {
      // debugPrint('IP location error: $e');
      return null;
    }
  }

  // Legacy method for backward compatibility with permission_service.dart
  static Future<Position?> getCurrentLocation() async {
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

      LocationSettings locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      return await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
    } catch (e) {
      // debugPrint('Error getting current location: $e');
      return null;
    }
  }

  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }
}
