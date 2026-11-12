import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../config/api_config.dart';
import '../../../services/jwt_service.dart';
import '../../../services/storage_service.dart';
import '../../../theme/sipora_theme.dart';
import '../../../utils/responsive_constants.dart';

class ShippingAddressesPage extends StatefulWidget {
  const ShippingAddressesPage({super.key});

  @override
  State<ShippingAddressesPage> createState() => _ShippingAddressesPageState();
}

class _ShippingAddressesPageState extends State<ShippingAddressesPage>
    with SingleTickerProviderStateMixin {
  List<Address> addresses = [];
  late AnimationController _animationController;
  bool _isLoading = true;
  String? _errorMessage;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animationController.forward();
    _initializeAndLoadAddresses();
  }

  Future<void> _initializeAndLoadAddresses() async {
    await _getUserId();
    if (_userId != null) {
      await _loadAddresses();
    }
  }

  Future<void> _getUserId() async {
    try {
      _userId = await StorageService.getUserId();
      if (_userId == null) {
        final prefs = await SharedPreferences.getInstance();
        _userId = prefs.getString('user_id');
        if (_userId == null) {
          final token = prefs.getString('tea_app_token');
          if (token != null) {
            _userId = JwtService.extractUserId(token);
          }
        }
      }
    } catch (e) {
    }
  }

  Future<void> _loadAddresses() async {
    if (_userId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load addresses. Please login again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = '${ApiConfig.baseUrl}/api/user/user-address-list/$_userId';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          final List<dynamic> addressesData = data['data'] ?? [];
          setState(() {
            addresses = addressesData
                .map((addr) => Address.fromApiJson(addr))
                .toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to load addresses';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load addresses. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _addAddress(Address address) async {
    if (_userId == null) {
      _showSnackBar('Please login to add address', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = '${ApiConfig.baseUrl}/api/user/user-address-create';

      final requestBody = {
        'user_id': _userId,
        'type': address.name,
        'country': address.country.isNotEmpty ? address.country : null,
        'state': address.state.isNotEmpty ? address.state : null,
        'pincode': address.zipCode.isNotEmpty ? address.zipCode : null,
        'house': address.addressLine1.isNotEmpty ? address.addressLine1 : null,
        'streetArea': address.addressLine2.isNotEmpty
            ? address.addressLine2
            : null,
        'landmark': address.landmark?.isNotEmpty == true
            ? address.landmark
            : null,
        'city': address.city.isNotEmpty ? address.city : null,
        'fullAddress': address.formattedAddress.isNotEmpty
            ? address.formattedAddress
            : null,
        'latitude': address.latitude?.isNotEmpty == true
            ? address.latitude
            : null,
        'longitude': address.longitude?.isNotEmpty == true
            ? address.longitude
            : null,
        'is_default': address.isDefault,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          await _loadAddresses();
          _showSnackBar('Address added successfully', isError: false);
        } else {
          _showSnackBar(
            data['message'] ?? 'Failed to add address',
            isError: true,
          );
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        _showSnackBar(
          'Failed to add address. Please try again.',
          isError: true,
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showSnackBar('Network error. Please try again.', isError: true);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateAddress(Address address) async {
    if (_userId == null) {
      _showSnackBar('Please login to update address', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = '${ApiConfig.baseUrl}/api/user/user-address-update';

      final requestBody = {
        'address_id': address.id,
        'type': address.name,
        'country': address.country.isNotEmpty ? address.country : null,
        'state': address.state.isNotEmpty ? address.state : null,
        'pincode': address.zipCode.isNotEmpty ? address.zipCode : null,
        'house': address.addressLine1.isNotEmpty ? address.addressLine1 : null,
        'streetArea': address.addressLine2.isNotEmpty
            ? address.addressLine2
            : null,
        'landmark': address.landmark?.isNotEmpty == true
            ? address.landmark
            : null,
        'city': address.city.isNotEmpty ? address.city : null,
        'fullAddress': address.formattedAddress.isNotEmpty
            ? address.formattedAddress
            : null,
        'latitude': address.latitude?.isNotEmpty == true
            ? address.latitude
            : null,
        'longitude': address.longitude?.isNotEmpty == true
            ? address.longitude
            : null,
      };

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          await _loadAddresses();
          _showSnackBar('Address updated successfully', isError: false);
        } else {
          _showSnackBar(
            data['message'] ?? 'Failed to update address',
            isError: true,
          );
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        _showSnackBar(
          'Failed to update address. Please try again.',
          isError: true,
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showSnackBar('Network error. Please try again.', isError: true);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _setDefaultAddress(String addressId) async {
    if (_userId == null) {
      _showSnackBar('Please login to set default address', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = '${ApiConfig.baseUrl}/api/user/user-address-set-default';

      final requestBody = {'address_id': addressId};

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          await _loadAddresses();
          _showSnackBar('Default address updated', isError: false);
        } else {
          _showSnackBar(
            data['message'] ?? 'Failed to set default address',
            isError: true,
          );
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        _showSnackBar(
          'Failed to set default address. Please try again.',
          isError: true,
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showSnackBar('Network error. Please try again.', isError: true);
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;

    return Scaffold(
      backgroundColor: theme.cream,
      appBar: _buildProfessionalAppBar(),
      body: FadeTransition(
        opacity: _animationController,
        child: _isLoading && addresses.isEmpty
            ? _buildLoadingState()
            : Column(
                children: [
                  _buildAddAddressButton(),
                  Expanded(
                    child: _errorMessage != null
                        ? _buildErrorState()
                        : addresses.isEmpty
                        ? _buildEmptyState()
                        : _buildAddressesList(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final theme = context.siporaTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(SiporaTheme.greenDark),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading addresses...',
            style: TextStyle(
              fontSize: ResponsiveConstants.getFontSize(context),
              color: theme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = context.siporaTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: theme.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: ResponsiveConstants.getFontSize(context),
              color: theme.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadAddresses,
            style: ElevatedButton.styleFrom(
              backgroundColor: SiporaTheme.greenMid,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildProfessionalAppBar() {
    final theme = context.siporaTheme;

    return AppBar(
      backgroundColor: theme.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.cream,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: theme.textDark,
          ),
        ),
      ),
      title: Text(
        'Shipping Addresses',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: theme.textDark,
          letterSpacing: -0.5,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildAddAddressButton() {
    final theme = context.siporaTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _showAddAddressPage,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text(
            'Add New Address',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: SiporaTheme.greenMid,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = context.siporaTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: SiporaTheme.greenBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_off_outlined,
              size: 56,
              color: SiporaTheme.greenMid.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No addresses saved',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: theme.textDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first shipping address',
            style: TextStyle(fontSize: 14, color: theme.textMuted),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _showAddAddressPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: SiporaTheme.greenMid,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Add Address',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: addresses.length,
      itemBuilder: (context, index) {
        final address = addresses[index];
        return _buildAddressCard(address, index);
      },
    );
  }

  Widget _buildAddressCard(Address address, int index) {
    final theme = context.siporaTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.border.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _editAddressPage(index),
            splashColor: SiporaTheme.greenMid.withValues(alpha: 0.05),
            highlightColor: SiporaTheme.greenMid.withValues(alpha: 0.02),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: address.isDefault
                                ? [SiporaTheme.greenMid, SiporaTheme.greenDark]
                                : [SiporaTheme.greenBg, SiporaTheme.greenBg],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          address.isDefault
                              ? Icons.home_rounded
                              : Icons.location_on_outlined,
                          color: address.isDefault
                              ? Colors.white
                              : SiporaTheme.greenMid,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    address.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: theme.textDark,
                                      letterSpacing: -0.3,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (address.isDefault) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          SiporaTheme.greenMid,
                                          SiporaTheme.greenDark,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'DEFAULT',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              address.formattedAddress,
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.textMuted,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editAddressPage(index);
                          } else if (value == 'set_default') {
                            _setDefaultAddress(address.id);
                          }
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.cream,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.more_horiz_rounded,
                            color: theme.textMuted,
                            size: 18,
                          ),
                        ),
                        itemBuilder: (context) => [
                          if (!address.isDefault)
                            const PopupMenuItem(
                              value: 'set_default',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.star_outline_rounded,
                                    size: 18,
                                    color: SiporaTheme.gold,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Set as Default',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: SiporaTheme.greenMid,
                                ),
                                SizedBox(width: 12),
                                Text('Edit', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddAddressPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressFormPage(
          onSave: (address) async {
            await _addAddress(address);
          },
        ),
      ),
    );
  }

  void _editAddressPage(int index) {
    final address = addresses[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressFormPage(
          initialAddress: address,
          onSave: (updatedAddress) async {
            await _updateAddress(updatedAddress);
          },
        ),
      ),
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : SiporaTheme.greenDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class Address {
  String id;
  String name;
  String addressLine1;
  String addressLine2;
  String city;
  String state;
  String zipCode;
  String country;
  bool isDefault;
  String? landmark;
  String? latitude;
  String? longitude;
  String? fullAddress;

  Address({
    required this.id,
    required this.name,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    this.isDefault = false,
    this.landmark,
    this.latitude,
    this.longitude,
    this.fullAddress,
  });

  String get formattedAddress {
    if (fullAddress != null && fullAddress!.isNotEmpty) {
      return fullAddress!;
    }
    String address = addressLine1;
    if (addressLine2.isNotEmpty) address += ', $addressLine2';
    if (landmark != null && landmark!.isNotEmpty) address += ', $landmark';
    address += ', $city, $state $zipCode';
    address += ', $country';
    return address;
  }

  factory Address.fromApiJson(Map<String, dynamic> json) {
    return Address(
      id: json['address_id']?.toString() ?? '',
      name: json['type'] ?? 'Home',
      addressLine1: json['house'] ?? '',
      addressLine2: json['streetArea'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['pincode'] ?? '',
      country: json['country'] ?? '',
      isDefault: json['is_default'] == true || json['is_default'] == 1,
      landmark: json['landmark'],
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      fullAddress: json['fullAddress'],
    );
  }
}

// Full Page Address Form with Left-aligned Title
class AddressFormPage extends StatefulWidget {
  final Address? initialAddress;
  final Function(Address) onSave;

  const AddressFormPage({super.key, this.initialAddress, required this.onSave});

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _houseController = TextEditingController();
  final _streetAreaController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _countryController = TextEditingController();

  String? _selectedLabel;
  final TextEditingController _customLabelController = TextEditingController();
  bool _isCustomLabel = false;
  bool _isDefault = false;
  bool _isAutoFetching = false;
  bool _showLocationDetected = false;

  String _latitude = '';
  String _longitude = '';

  final List<String> _predefinedLabels = [
    'Home',
    'Office',
    'Friends',
    'Relatives',
    'Parents',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    if (widget.initialAddress != null) {
      final existingLabel = widget.initialAddress!.name;
      if (_predefinedLabels.contains(existingLabel)) {
        _selectedLabel = existingLabel;
        _isCustomLabel = false;
      } else {
        _selectedLabel = 'Other';
        _customLabelController.text = existingLabel;
        _isCustomLabel = true;
      }
      _houseController.text = widget.initialAddress!.addressLine1;
      _streetAreaController.text = widget.initialAddress!.addressLine2;
      _landmarkController.text = widget.initialAddress!.landmark ?? '';
      _cityController.text = widget.initialAddress!.city;
      _stateController.text = widget.initialAddress!.state;
      _zipCodeController.text = widget.initialAddress!.zipCode;
      _countryController.text = widget.initialAddress!.country;
      _isDefault = widget.initialAddress!.isDefault;

      _latitude = widget.initialAddress!.latitude ?? '';
      _longitude = widget.initialAddress!.longitude ?? '';
      _showLocationDetected = false;
    } else {
      _selectedLabel = 'Home';
      _isCustomLabel = false;
      _isDefault = false;
      _showLocationDetected = false;
    }
  }

  Future<void> _autoFillAddress() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
      if (!status.isGranted) {
        _showSnackBar(
          'Location permission is required for auto-fill',
          isError: true,
        );
        return;
      }
    }

    setState(() {
      _isAutoFetching = true;
    });

    _showSnackBar('Getting your location...', isError: false);

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final lat = position.latitude;
      final lng = position.longitude;

      setState(() {
        _latitude = lat.toString();
        _longitude = lng.toString();
      });

      final placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        final placemark = placemarks[0];

        setState(() {
          _houseController.text =
              placemark.subThoroughfare ?? placemark.thoroughfare ?? '';
          _streetAreaController.text = placemark.thoroughfare ?? '';
          _landmarkController.text = placemark.subLocality ?? '';
          _cityController.text =
              placemark.locality ?? placemark.subAdministrativeArea ?? '';
          _stateController.text = placemark.administrativeArea ?? '';
          _zipCodeController.text = placemark.postalCode ?? '';
          _countryController.text = placemark.country ?? '';
          _showLocationDetected = true;
        });

        _showSnackBar('Address auto-filled successfully!', isError: false);
      } else {
        setState(() {
          _showLocationDetected = false;
        });
        _showSnackBar('Address not found for your location', isError: true);
      }
    } catch (e) {
      setState(() {
        _showLocationDetected = false;
      });
      _showSnackBar(
        'Failed to get your location. Please enable GPS.',
        isError: true,
      );
    } finally {
      setState(() {
        _isAutoFetching = false;
      });
    }
  }

  String _getAddressLabel() {
    if (_isCustomLabel) {
      return _customLabelController.text.trim().isEmpty
          ? 'Other'
          : _customLabelController.text.trim();
    }
    return _selectedLabel ?? 'Home';
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : SiporaTheme.greenDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearLocationDetection() {
    setState(() {
      _showLocationDetected = false;
      _latitude = '';
      _longitude = '';
    });
  }

  @override
  void dispose() {
    _houseController.dispose();
    _streetAreaController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    _customLabelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;

    return Scaffold(
      backgroundColor: theme.cream,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          color: theme.white,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.cream,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: theme.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title - Now on the left
                  Expanded(
                    child: Text(
                      widget.initialAddress == null
                          ? 'Add New Address'
                          : 'Edit Address',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: theme.textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  // Auto-Fill Button on the right
                  GestureDetector(
                    onTap: _isAutoFetching ? null : _autoFillAddress,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            SiporaTheme.greenBg,
                            SiporaTheme.greenBg.withValues(alpha: 0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: SiporaTheme.greenMid.withValues(alpha: 0.3),
                        ),
                      ),
                      child: _isAutoFetching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  SiporaTheme.greenMid,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.my_location_rounded,
                                  size: 16,
                                  color: SiporaTheme.greenMid,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Auto-Fill',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: SiporaTheme.greenMid,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location detected banner
              if (_showLocationDetected)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: SiporaTheme.greenBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: SiporaTheme.greenMid.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.gps_fixed,
                        size: 18,
                        color: SiporaTheme.greenMid,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Location detected successfully',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: SiporaTheme.greenMid,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _clearLocationDetection,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: SiporaTheme.greenMid.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: SiporaTheme.greenMid,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Address Label Field
              _buildAddressLabelField(),
              const SizedBox(height: 20),

              // Custom Label Field
              if (_isCustomLabel) ...[
                _buildTextField(
                  controller: _customLabelController,
                  label: 'Custom Label',
                  hint: 'Enter custom address label',
                  icon: Icons.label_outline_rounded,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a custom label' : null,
                ),
                const SizedBox(height: 20),
              ],

              // House/Flat No.
              _buildTextField(
                controller: _houseController,
                label: 'House / Flat No.',
                hint: 'House number, building name',
                icon: Icons.home_outlined,
                validator: (value) =>
                    value!.isEmpty ? 'House/Flat is required' : null,
              ),
              const SizedBox(height: 20),

              // Area/Street/Sector
              _buildTextField(
                controller: _streetAreaController,
                label: 'Area / Street / Sector',
                hint: 'Street name, area',
                icon: Icons.streetview_rounded,
                validator: (value) =>
                    value!.isEmpty ? 'Street/Area is required' : null,
              ),
              const SizedBox(height: 20),

              // Landmark
              _buildTextField(
                controller: _landmarkController,
                label: 'Landmark',
                hint: 'Nearby landmark (Optional)',
                icon: Icons.place_rounded,
                isOptional: true,
              ),
              const SizedBox(height: 20),

              // City and State Row
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _cityController,
                      label: 'City',
                      hint: 'City/Town',
                      icon: Icons.location_city_rounded,
                      validator: (value) =>
                          value!.isEmpty ? 'City is required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _stateController,
                      label: 'State',
                      hint: 'State',
                      icon: Icons.map_rounded,
                      validator: (value) =>
                          value!.isEmpty ? 'State is required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Pincode and Country Row
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _zipCodeController,
                      label: 'Pincode',
                      hint: 'Postal code',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Pincode is required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _countryController,
                      label: 'Country',
                      hint: 'Country',
                      icon: Icons.public_rounded,
                      validator: (value) =>
                          value!.isEmpty ? 'Country is required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Set as Default Checkbox (Only for Add mode)
              if (widget.initialAddress == null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: SiporaTheme.greenBg.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _isDefault,
                        onChanged: (value) {
                          setState(() {
                            _isDefault = value ?? false;
                          });
                        },
                        activeColor: SiporaTheme.greenMid,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Set as default address',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: theme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SiporaTheme.greenMid,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  widget.initialAddress == null
                      ? 'Save Address'
                      : 'Update Address',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressLabelField() {
    final theme = context.siporaTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Address Label',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedLabel,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: SiporaTheme.greenMid,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            filled: true,
            fillColor: theme.white,
          ),
          items: _predefinedLabels.map((String label) {
            return DropdownMenuItem<String>(
              value: label,
              child: Row(
                children: [
                  Icon(
                    _getIconForLabel(label),
                    size: 20,
                    color: SiporaTheme.greenMid,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      color: theme.textDark,
                      fontWeight: _selectedLabel == label
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedLabel = newValue;
              _isCustomLabel = newValue == 'Other';
              if (!_isCustomLabel) {
                _customLabelController.clear();
              }
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a label';
            }
            if (value == 'Other' &&
                _customLabelController.text.trim().isEmpty) {
              return 'Please enter a custom label';
            }
            return null;
          },
          dropdownColor: theme.white,
          style: const TextStyle(fontSize: 15),
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            color: SiporaTheme.greenMid,
            size: 24,
          ),
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
        ),
      ],
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return Icons.home_rounded;
      case 'office':
        return Icons.business_center_rounded;
      case 'friends':
        return Icons.people_rounded;
      case 'relatives':
        return Icons.family_restroom_rounded;
      case 'parents':
        return Icons.favorite_rounded;
      default:
        return Icons.label_outline_rounded;
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isOptional = false,
    String? Function(String?)? validator,
  }) {
    final theme = context.siporaTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 14, color: theme.textMuted),
            prefixIcon: Icon(icon, size: 20, color: theme.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: SiporaTheme.greenMid,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            filled: true,
            fillColor: theme.white,
          ),
          validator: isOptional ? null : validator,
          style: const TextStyle(fontSize: 15),
        ),
      ],
    );
  }

  void _saveAddress() {
    if (_formKey.currentState!.validate()) {
      final addressLabel = _getAddressLabel();

      final address = Address(
        id: widget.initialAddress?.id ?? '',
        name: addressLabel,
        addressLine1: _houseController.text.trim(),
        addressLine2: _streetAreaController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        zipCode: _zipCodeController.text.trim(),
        country: _countryController.text.trim(),
        isDefault: widget.initialAddress?.isDefault ?? _isDefault,
        landmark: _landmarkController.text.trim().isEmpty
            ? null
            : _landmarkController.text.trim(),
        latitude: _latitude.isEmpty ? null : _latitude,
        longitude: _longitude.isEmpty ? null : _longitude,
      );
      widget.onSave(address);
      Navigator.of(context).pop();
    }
  }
}
