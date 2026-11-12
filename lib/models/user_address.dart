// lib/models/user_address.dart
class UserAddress {
  final String addressId;
  final String userId;
  final String type;
  final String country;
  final String state;
  final String pincode;
  final String house;
  final String streetArea;
  final String landmark;
  final String city;
  final String fullAddress;
  final String? latitude;
  final String? longitude;
  final bool isDefault;

  const UserAddress({
    required this.addressId,
    required this.userId,
    required this.type,
    required this.country,
    required this.state,
    required this.pincode,
    required this.house,
    required this.streetArea,
    required this.landmark,
    required this.city,
    required this.fullAddress,
    this.latitude,
    this.longitude,
    required this.isDefault,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      addressId:  json['address_id']?.toString() ?? '',
      userId:     json['user_id']?.toString() ?? '',
      type:       json['type']?.toString() ?? 'home',
      country:    json['country']?.toString() ?? 'India',
      state:      json['state']?.toString() ?? '',
      pincode:    json['pincode']?.toString() ?? '',
      house:      json['house']?.toString() ?? '',
      streetArea: json['streetArea']?.toString() ?? '',
      landmark:   json['landmark']?.toString() ?? '',
      city:       json['city']?.toString() ?? '',
      fullAddress: json['fullAddress']?.toString() ?? '',
      latitude:   json['latitude']?.toString(),
      longitude:  json['longitude']?.toString(),
      isDefault:  json['is_default'] == true || json['is_default'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type, 'country': country, 'state': state, 'pincode': pincode,
    'house': house, 'streetArea': streetArea, 'landmark': landmark,
    'city': city, 'fullAddress': fullAddress,
    'latitude': latitude, 'longitude': longitude, 'is_default': isDefault,
  };

  String get displayText =>
      fullAddress.isNotEmpty ? fullAddress : '$house, $city, $state - $pincode';
}
