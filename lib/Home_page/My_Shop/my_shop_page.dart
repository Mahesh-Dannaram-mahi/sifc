// lib/Home_page/My_Shop/my_shop_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/sipora_theme.dart';
import '../../utils/screen_utils.dart';
import '../../services/storage_service.dart';
import '../../config/api_config.dart';
import '../../Home_page/home_page.dart';
import '../My_Shop/settlements/my_settlements_content.dart';
import '../My_Shop/shop_analytics/shop_analytics_content.dart';
import '../My_Shop/shop_orders/shop_orders_content.dart';

import 'widgets/shop_dashboard_header.dart';
import 'dashboard/shop_dashboard_cards.dart';
import 'dashboard/shop_recent_orders.dart';
import 'widgets/shop_bottom_nav.dart';
import 'widgets/universal_filter.dart';
import 'dashboard/monthly_sales_overview.dart';
import 'inventory_management/inventory_management.dart';
import 'widgets/visitor_analytics_widget.dart';

class MyShopPage extends StatefulWidget {
  const MyShopPage({super.key});

  @override
  State<MyShopPage> createState() => _MyShopPageState();
}

class _MyShopPageState extends State<MyShopPage> {
  int _selectedNavIndex = 0;
  String _shopName = 'My Shop';
  bool _isLoading = true;
  bool _isLoadingFranchises = true;
  String? _errorMessage;
  String? _userId;

  // Franchise data
  List<Map<String, dynamic>> _franchises = [];
  String? _selectedFranchiseId;

  // Universal Filter state
  DateViewMode _dateViewMode = DateViewMode.day;
  DateTime _selectedDate = DateTime.now();
  DateTime? _weekStart;
  DateTime? _weekEnd;

  // Keys for forcing widget rebuild
  Key _dashboardCardsKey = const ValueKey('dashboard_cards');
  Key _monthlyOverviewKey = const ValueKey('monthly_overview');
  Key _recentOrdersKey = const ValueKey('recent_orders');

  @override
  void initState() {
    super.initState();
    _loadShopData();
    _fetchFranchises();
  }

  Future<void> _loadShopData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shopName = prefs.getString('selected_shop_name') ?? 'My Shop';
      if (mounted) {
        setState(() {
          _shopName = shopName;
        });
      }
    } catch (e) {
      // Use default
    }
  }

  Future<void> _fetchFranchises() async {
    setState(() {
      _isLoadingFranchises = true;
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final token = await StorageService.getToken();
      if (token == null) {
        setState(() {
          _isLoadingFranchises = false;
          _isLoading = false;
          _errorMessage = 'Please login again';
        });
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      setState(() {
        _userId = userId;
      });

      if (userId == null || userId.isEmpty) {
        setState(() {
          _isLoadingFranchises = false;
          _isLoading = false;
          _errorMessage = 'User not found';
        });
        return;
      }

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/dashboard/franchise/my-franchises'
        '?owner_user_id=$userId',
      );

      final response = await http.get(
        url,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          final List<dynamic> franchisesData = data['data'] ?? [];

          final List<Map<String, dynamic>> franchiseList = franchisesData
              .map(
                (f) => {
                  'franchise_id': f['franchise_id']?.toString() ?? '',
                  'shop_name': f['shop_name']?.toString() ?? 'Unknown Shop',
                  'city': f['city']?.toString() ?? '',
                  'state': f['state']?.toString() ?? '',
                },
              )
              .toList();

          setState(() {
            _franchises = franchiseList;
            _isLoadingFranchises = false;
          });

          if (_franchises.isNotEmpty) {
            final savedFranchiseId = prefs.getString('selected_franchise_id');
            final exists = _franchises.any(
              (f) => f['franchise_id'] == savedFranchiseId,
            );
            final selectedId = exists
                ? savedFranchiseId
                : _franchises.first['franchise_id'];

            setState(() {
              _selectedFranchiseId = selectedId;
            });

            if (_selectedFranchiseId != null) {
              await prefs.setString(
                'selected_franchise_id',
                _selectedFranchiseId!,
              );
            }

            try {
              final found = _franchises.firstWhere(
                (f) => f['franchise_id'] == _selectedFranchiseId,
                orElse: () => {'shop_name': 'My Shop', 'franchise_id': ''},
              );
              setState(() {
                _shopName = found['shop_name'] ?? 'My Shop';
              });
            } catch (e) {
              setState(() {
                _shopName = _franchises.first['shop_name'] ?? 'My Shop';
              });
            }

            await _fetchDashboardData();
          } else {
            setState(() {
              _errorMessage = 'No franchises found for this account';
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _isLoadingFranchises = false;
            _isLoading = false;
            _errorMessage = data['message'] ?? 'Failed to load franchises';
          });
        }
      } else {
        setState(() {
          _isLoadingFranchises = false;
          _isLoading = false;
          _errorMessage = 'Failed to load franchises';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingFranchises = false;
        _isLoading = false;
        _errorMessage = 'Network error: $e';
      });
    }
  }

  Future<void> _fetchDashboardData() async {
    if (_selectedFranchiseId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please select a franchise';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await StorageService.getToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please login again';
        });
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null || userId.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not found';
        });
        return;
      }

      String startDateStr, endDateStr;

      switch (_dateViewMode) {
        case DateViewMode.day:
          final date = _selectedDate;
          startDateStr = _formatDate(date);
          endDateStr = _formatDate(date);
          break;
        case DateViewMode.week:
          if (_weekStart != null && _weekEnd != null) {
            startDateStr = _formatDate(_weekStart!);
            endDateStr = _formatDate(_weekEnd!);
          } else {
            final now = DateTime.now();
            final weekday = now.weekday;
            final start = now.subtract(Duration(days: weekday - 1));
            final end = start.add(Duration(days: 6));
            startDateStr = _formatDate(start);
            endDateStr = _formatDate(end);
          }
          break;
        case DateViewMode.month:
          final startDate = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            1,
          );
          final endDate = DateTime(
            _selectedDate.year,
            _selectedDate.month + 1,
            0,
          );
          startDateStr = _formatDate(startDate);
          endDateStr = _formatDate(endDate);
          break;
        case DateViewMode.year:
          final startDate = DateTime(_selectedDate.year, 1, 1);
          final endDate = DateTime(_selectedDate.year, 12, 31);
          startDateStr = _formatDate(startDate);
          endDateStr = _formatDate(endDate);
          break;
      }

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/dashboard/franchise/summary'
        '?owner_user_id=$userId'
        '&franchise_id=$_selectedFranchiseId'
        '&start_date=$startDateStr'
        '&end_date=$endDateStr',
      );

      final response = await http.get(
        url,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = data['message'] ?? 'Failed to load data';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load dashboard data';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Network error: $e';
      });
    }
  }

  void _onFranchiseSelected(String? franchiseId) async {
    if (franchiseId == null) return;

    setState(() {
      _selectedFranchiseId = franchiseId;
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_franchise_id', franchiseId);

    try {
      final Map<String, dynamic> found = _franchises.firstWhere(
        (f) => f['franchise_id'] == franchiseId,
        orElse: () => {'shop_name': 'My Shop', 'franchise_id': ''},
      );
      setState(() {
        _shopName = found['shop_name'] ?? 'My Shop';
      });
    } catch (e) {
      setState(() {
        _shopName = _franchises.first['shop_name'] ?? 'My Shop';
      });
    }

    await _fetchDashboardData();
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
      _dashboardCardsKey = ValueKey(
        'dashboard_cards_${DateTime.now().millisecondsSinceEpoch}',
      );
      _monthlyOverviewKey = ValueKey(
        'monthly_overview_${DateTime.now().millisecondsSinceEpoch}',
      );
      _recentOrdersKey = ValueKey(
        'recent_orders_${DateTime.now().millisecondsSinceEpoch}',
      );
    });

    _fetchDashboardData();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
            // Custom Header for My Shop
            ShopDashboardHeader(
              shopName: _shopName,
              onMyAppTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
            ),

            // Franchise Selector
            if (!_isLoadingFranchises && _franchises.length > 1)
              _buildFranchiseSelector(isTablet),

            // ─── Universal Filter (for Dashboard, Analytics & Settlements) ──
            if (_selectedNavIndex == 0 ||
                _selectedNavIndex == 1 ||
                _selectedNavIndex == 4)
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

            // Main Content
            Expanded(child: _buildBody(isTablet)),
          ],
        ),
      ),
      bottomNavigationBar: ShopBottomNav(
        selectedIndex: _selectedNavIndex,
        onItemTapped: (index) {
          setState(() {
            _selectedNavIndex = index;
          });
          _handleNavTap(index);
        },
      ),
    );
  }

  Widget _buildFranchiseSelector(bool isTablet) {
    final theme = context.siporaTheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(8),
      ),
      decoration: BoxDecoration(
        color: theme.white,
        border: Border(bottom: BorderSide(color: theme.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.storefront_rounded,
            color: SiporaTheme.greenMid,
            size: context.w(20),
          ),
          SizedBox(width: context.w(8)),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFranchiseId,
                isExpanded: true,
                hint: Text(
                  'Select Franchise',
                  style: TextStyle(
                    fontSize: isTablet ? context.sp(14) : context.sp(13),
                    color: theme.textMuted,
                  ),
                ),
                items: _franchises.map((franchise) {
                  final name = franchise['shop_name'] ?? 'Unknown Shop';
                  final city = franchise['city'] ?? '';
                  final displayName = city.isNotEmpty ? '$name ($city)' : name;

                  return DropdownMenuItem<String>(
                    value: franchise['franchise_id'],
                    child: Text(
                      displayName,
                      style: TextStyle(
                        fontSize: isTablet ? context.sp(14) : context.sp(13),
                        color: theme.textDark,
                        fontWeight:
                            _selectedFranchiseId == franchise['franchise_id']
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: _onFranchiseSelected,
                icon: Icon(
                  Icons.arrow_drop_down_rounded,
                  color: SiporaTheme.greenMid,
                  size: context.w(24),
                ),
                dropdownColor: theme.white,
                style: TextStyle(
                  fontSize: isTablet ? context.sp(14) : context.sp(13),
                  color: theme.textDark,
                ),
                borderRadius: BorderRadius.circular(context.r(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isTablet) {
    if (_isLoadingFranchises) {
      return _buildSkeletonUI(isTablet);
    }

    if (_errorMessage != null && _franchises.isEmpty) {
      return _buildErrorState(isTablet);
    }

    if (_franchises.isEmpty) {
      return _buildNoFranchiseState(isTablet);
    }

    switch (_selectedNavIndex) {
      case 0:
        return _buildDashboardContent(isTablet);
      case 1:
        return _buildAnalyticsContent(isTablet);
      case 2:
        // ✅ FIXED: Orders tab - Pass filter state to ShopOrdersContent
        return ShopOrdersContent(
          franchises: _franchises,
          selectedFranchiseId: _selectedFranchiseId,
          initialDateViewMode: _dateViewMode,
          initialSelectedDate: _selectedDate,
          initialWeekStart: _weekStart,
          initialWeekEnd: _weekEnd,
          onFilterChanged: _onFilterChanged,
        );
      case 3:
        return const InventoryManagementContent();
      case 4:
        return MySettlementsContent(
          initialDateViewMode: _dateViewMode,
          initialSelectedDate: _selectedDate,
          initialWeekStart: _weekStart,
          initialWeekEnd: _weekEnd,
          onFilterChanged: (mode, date) {
            setState(() {
              _dateViewMode = mode;
              _selectedDate = date;
            });
          },
        );
      default:
        return _buildDashboardContent(isTablet);
    }
  }

  Widget _buildDashboardContent(bool isTablet) {
    if (_isLoading) {
      return _buildSkeletonUI(isTablet);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(8),
      ),
      child: Column(
        children: [
          ShopDashboardCards(
            key: _dashboardCardsKey,
            dateViewMode: _dateViewMode,
            selectedDate: _selectedDate,
            weekStart: _weekStart,
            weekEnd: _weekEnd,
          ),
          SizedBox(height: context.h(24)),
          MonthlySalesOverview(
            key: _monthlyOverviewKey,
            dateViewMode: _dateViewMode.name,
            selectedYear: _selectedDate.year,
            selectedMonth: _selectedDate.month,
            selectedDay: _selectedDate.day,
            weekStart: _weekStart,
            weekEnd: _weekEnd,
          ),
          SizedBox(height: context.h(24)),
          ShopRecentOrders(
            key: _recentOrdersKey,
            franchiseId: _selectedFranchiseId,
            dateViewMode: _dateViewMode,
            selectedDate: _selectedDate,
            weekStart: _weekStart,
            weekEnd: _weekEnd,
            limit: 5,
          ),
          // Visitor Analytics - shown after Today's Orders with filter support
          if (_selectedFranchiseId != null && _userId != null)
            Padding(
              padding: EdgeInsets.only(top: context.h(16)),
              child: VisitorAnalyticsWidget(
                franchiseId: _selectedFranchiseId!,
                ownerUserId: _userId!,
                viewMode: _dateViewMode,
                selectedDate: _selectedDate,
                weekStart: _weekStart,
                weekEnd: _weekEnd,
              ),
            ),
          SizedBox(height: context.h(80)),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent(bool isTablet) {
    return ShopAnalyticsContent(
      initialDateViewMode: _dateViewMode,
      initialSelectedDate: _selectedDate,
      initialWeekStart: _weekStart,
      initialWeekEnd: _weekEnd,
      onFilterChanged: _onFilterChanged,
    );
  }

  Widget _buildSkeletonUI(bool isTablet) {
    final theme = context.siporaTheme;
    final crossAxisCount = isTablet ? 4 : 2;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(16),
      ),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: context.w(12),
              mainAxisSpacing: context.h(12),
              childAspectRatio: isTablet ? 1.8 : 1.6,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Container(
                padding: EdgeInsets.all(context.w(10)),
                decoration: BoxDecoration(
                  color: theme.white,
                  borderRadius: BorderRadius.circular(context.r(14)),
                  border: Border.all(color: theme.border, width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: SiporaTheme.shadowLight.withValues(alpha: 0.05),
                      blurRadius: 8.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.all(context.w(5)),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(context.r(8)),
                          ),
                          child: const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.w(6),
                            vertical: context.h(2),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(context.r(10)),
                          ),
                          child: Text(
                            '--',
                            style: TextStyle(
                              fontSize: isTablet
                                  ? context.sp(10)
                                  : context.sp(8),
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: context.w(50),
                          height: isTablet ? context.h(20) : context.h(18),
                          color: Colors.grey.shade200,
                        ),
                        SizedBox(height: context.h(3)),
                        Container(
                          width: context.w(35),
                          height: isTablet ? context.h(12) : context.h(10),
                          color: Colors.grey.shade200,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: context.h(24)),
          Container(
            padding: EdgeInsets.all(context.w(16)),
            decoration: BoxDecoration(
              color: theme.white,
              borderRadius: BorderRadius.circular(context.r(16)),
              border: Border.all(color: theme.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: context.w(140),
                  height: context.h(20),
                  color: Colors.grey.shade200,
                ),
                SizedBox(height: context.h(4)),
                Container(
                  width: context.w(200),
                  height: context.h(14),
                  color: Colors.grey.shade200,
                ),
                SizedBox(height: context.h(12)),
                Container(
                  height: isTablet ? context.h(180) : context.h(140),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(context.r(8)),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.h(24)),
          Container(
            padding: EdgeInsets.all(context.w(16)),
            decoration: BoxDecoration(
              color: theme.white,
              borderRadius: BorderRadius.circular(context.r(16)),
              border: Border.all(color: theme.border, width: 1),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: context.w(120),
                      height: context.h(20),
                      color: Colors.grey.shade200,
                    ),
                    Container(
                      width: context.w(80),
                      height: context.h(16),
                      color: Colors.grey.shade200,
                    ),
                  ],
                ),
                SizedBox(height: context.h(12)),
                ...List.generate(3, (index) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: context.h(10)),
                    child: Row(
                      children: [
                        Container(
                          width: context.w(34),
                          height: context.w(34),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(context.r(10)),
                          ),
                        ),
                        SizedBox(width: context.w(12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: context.w(80),
                                height: context.h(14),
                                color: Colors.grey.shade200,
                              ),
                              SizedBox(height: context.h(4)),
                              Container(
                                width: context.w(120),
                                height: context.h(12),
                                color: Colors.grey.shade200,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              width: context.w(60),
                              height: context.h(14),
                              color: Colors.grey.shade200,
                            ),
                            SizedBox(height: context.h(4)),
                            Container(
                              width: context.w(50),
                              height: context.h(12),
                              color: Colors.grey.shade200,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isTablet) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.w(32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade400,
              size: context.w(48),
            ),
            SizedBox(height: context.h(16)),
            Text(
              _errorMessage ?? 'Something went wrong',
              style: TextStyle(
                fontSize: isTablet ? context.sp(16) : context.sp(14),
                color: Colors.red.shade400,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.h(16)),
            ElevatedButton(
              onPressed: _fetchFranchises,
              style: ElevatedButton.styleFrom(
                backgroundColor: SiporaTheme.greenDark,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(24),
                  vertical: context.h(12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.r(8)),
                ),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  fontSize: isTablet ? context.sp(14) : context.sp(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoFranchiseState(bool isTablet) {
    final theme = context.siporaTheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.w(32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront_outlined,
              color: theme.textMuted,
              size: context.w(64),
            ),
            SizedBox(height: context.h(16)),
            Text(
              'No Franchises Found',
              style: TextStyle(
                fontSize: isTablet ? context.sp(20) : context.sp(18),
                fontWeight: FontWeight.w700,
                color: theme.textDark,
              ),
            ),
            SizedBox(height: context.h(8)),
            Text(
              'You don\'t have any franchises associated with your account.\nPlease contact your administrator.',
              style: TextStyle(
                fontSize: isTablet ? context.sp(14) : context.sp(12),
                color: theme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavTap(int index) {
    setState(() {
      _selectedNavIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        break;
      case 2:
        break;
      case 3:
        break;
      case 4:
        break;
    }
  }
}
