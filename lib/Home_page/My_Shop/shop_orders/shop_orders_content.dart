// lib/Home_page/My_Shop/shop_orders/shop_orders_content.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'widgets/product_sales_analytics.dart';
import '../widgets/universal_filter.dart';

class ShopOrdersContent extends StatefulWidget {
  final List<Map<String, dynamic>> franchises;
  final String? selectedFranchiseId;
  final DateViewMode initialDateViewMode;
  final DateTime? initialSelectedDate;
  final DateTime? initialWeekStart;
  final DateTime? initialWeekEnd;
  final Function(DateViewMode mode, DateTime date)? onFilterChanged;

  const ShopOrdersContent({
    super.key,
    required this.franchises,
    this.selectedFranchiseId,
    this.initialDateViewMode = DateViewMode.day,
    this.initialSelectedDate,
    this.initialWeekStart,
    this.initialWeekEnd,
    this.onFilterChanged,
  });

  @override
  State<ShopOrdersContent> createState() => _ShopOrdersContentState();
}

class _ShopOrdersContentState extends State<ShopOrdersContent> {
  // Filter state
  DateViewMode _dateViewMode = DateViewMode.day;
  DateTime _selectedDate = DateTime.now();
  DateTime? _weekStart;
  DateTime? _weekEnd;

  @override
  void initState() {
    super.initState();
    _dateViewMode = widget.initialDateViewMode;
    _selectedDate = widget.initialSelectedDate ?? DateTime.now();
    _weekStart = widget.initialWeekStart;
    _weekEnd = widget.initialWeekEnd;
    _calculateWeekRange();
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

  @override
  void didUpdateWidget(ShopOrdersContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDateViewMode != widget.initialDateViewMode ||
        oldWidget.initialSelectedDate != widget.initialSelectedDate ||
        oldWidget.initialWeekStart != widget.initialWeekStart ||
        oldWidget.initialWeekEnd != widget.initialWeekEnd) {
      setState(() {
        _dateViewMode = widget.initialDateViewMode;
        _selectedDate = widget.initialSelectedDate ?? DateTime.now();
        _weekStart = widget.initialWeekStart;
        _weekEnd = widget.initialWeekEnd;
        _calculateWeekRange();
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

    if (widget.onFilterChanged != null) {
      widget.onFilterChanged!(mode, date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ✅ FIXED: Universal Filter for Orders tab
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: UniversalFilter(
            initialMode: _dateViewMode,
            initialDate: _selectedDate,
            onFilterChanged: _onFilterChanged,
          ),
        ),
        // Product Sales Analytics
        Expanded(
          child: ProductSalesAnalytics(
            franchises: widget.franchises,
            initialFranchiseId: widget.selectedFranchiseId,
            initialDateViewMode: _dateViewMode,
            initialSelectedDate: _selectedDate,
            initialWeekStart: _weekStart,
            initialWeekEnd: _weekEnd,
            onFilterChanged: _onFilterChanged,
          ),
        ),
      ],
    );
  }
}
