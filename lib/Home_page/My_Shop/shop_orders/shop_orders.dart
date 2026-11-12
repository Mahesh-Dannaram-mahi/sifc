import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/sipora_theme.dart';
import '../../../utils/screen_utils.dart';
import '../../../services/storage_service.dart';
import '../../../config/api_config.dart';
import '../widgets/shop_dashboard_header.dart';
import '../widgets/shop_bottom_nav.dart';
import '../widgets/universal_filter.dart';
import 'shop_orders_content.dart';

class ShopOrdersPage extends StatefulWidget {
  const ShopOrdersPage({super.key});

  @override
  State<ShopOrdersPage> createState() => _ShopOrdersPageState();
}

class _ShopOrdersPageState extends State<ShopOrdersPage> {
  // Bottom nav state
  int _selectedNavIndex = 2; // Orders tab

  // Filter state - default to Day
  DateViewMode _dateViewMode = DateViewMode.day;
  DateTime _selectedDate = DateTime.now();
  DateTime? _weekStart;
  DateTime? _weekEnd;

  // Franchise info
  String? _franchiseId;
  String _shopName = 'My Shop';

  // Franchises list
  List<Map<String, dynamic>> _franchises = [];
  bool _isLoadingFranchises = true;

  @override
  void initState() {
    super.initState();
    _calculateWeekRange();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _franchiseId = prefs.getString('selected_franchise_id');
    _shopName = prefs.getString('selected_shop_name') ?? 'My Shop';

    // Fetch franchises list
    await _fetchFranchises();
  }

  Future<void> _fetchFranchises() async {
    setState(() {
      _isLoadingFranchises = true;
    });

    try {
      final token = await StorageService.getToken();
      if (token == null) {
        setState(() {
          _isLoadingFranchises = false;
        });
        return;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/franchise/list');
      final response = await http.get(
        uri,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final franchises =
              (data['franchises'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ??
              [];
          setState(() {
            _franchises = franchises;
            _isLoadingFranchises = false;
          });
        } else {
          setState(() {
            _isLoadingFranchises = false;
          });
        }
      } else {
        setState(() {
          _isLoadingFranchises = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingFranchises = false;
      });
    }
  }

  void _onFilterChanged(DateViewMode mode, DateTime date) {
    DateTime? weekStart;
    DateTime? weekEnd;

    if (mode == DateViewMode.week) {
      final weekday = date.weekday;
      weekStart = date.subtract(Duration(days: weekday - 1));
      weekEnd = weekStart.add(Duration(days: 6));
    }

    setState(() {
      _dateViewMode = mode;
      _selectedDate = date;
      _weekStart = weekStart;
      _weekEnd = weekEnd;
    });
  }

  void _calculateWeekRange() {
    if (_dateViewMode == DateViewMode.week) {
      final weekday = _selectedDate.weekday;
      final start = _selectedDate.subtract(Duration(days: weekday - 1));
      final end = start.add(Duration(days: 6));
      _weekStart = DateTime(start.year, start.month, start.day);
      _weekEnd = DateTime(end.year, end.month, end.day);
    }
  }

  void _handleNavTap(int index) {
    setState(() {
      _selectedNavIndex = index;
    });

    switch (index) {
      case 0:
        // Navigate back to Dashboard
        Navigator.pop(context);
        break;
      case 1:
        // Navigate to Analytics
        _showComingSoon('Analytics page navigation');
        break;
      case 2:
        // Already on Orders page
        break;
      case 3:
        _showComingSoon('Products Management');
        break;
      case 4:
        _showComingSoon('Settlements page navigation');
        break;
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: SiporaTheme.greenDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;

    return Scaffold(
      backgroundColor: theme.cream,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Custom Header ──────────────────────────────────────────
            ShopDashboardHeader(
              shopName: _shopName,
              onMyAppTap: () {
                Navigator.pop(context);
              },
            ),

            // ─── Universal Filter ──────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(16),
                vertical: context.h(8),
              ),
              child: UniversalFilter(
                initialMode: _dateViewMode,
                initialDate: _selectedDate,
                onFilterChanged: _onFilterChanged,
              ),
            ),

            // ─── Main Content ──────────────────────────────────────────
            Expanded(
              child: _isLoadingFranchises
                  ? _buildLoading(isTablet)
                  : ShopOrdersContent(
                      franchises: _franchises,
                      selectedFranchiseId: _franchiseId,
                      initialDateViewMode: _dateViewMode,
                      initialSelectedDate: _selectedDate,
                      initialWeekStart: _weekStart,
                      initialWeekEnd: _weekEnd,
                      onFilterChanged: _onFilterChanged,
                    ),
            ),
          ],
        ),
      ),
      // ─── Bottom Navigation ──────────────────────────────────────────
      bottomNavigationBar: ShopBottomNav(
        selectedIndex: _selectedNavIndex,
        onItemTapped: _handleNavTap,
      ),
    );
  }

  Widget _buildLoading(bool isTablet) {
    return Center(
      child: CircularProgressIndicator(color: SiporaTheme.greenDark),
    );
  }
}
