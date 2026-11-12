// lib/Home_page/My_Shop/widgets/visitor_analytics_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../theme/sipora_theme.dart';
import '../../../utils/screen_utils.dart';
import '../../../services/storage_service.dart';
import '../../../config/api_config.dart';
import 'universal_filter.dart';

class VisitorAnalyticsWidget extends StatefulWidget {
  final String franchiseId;
  final String ownerUserId;
  final DateViewMode? viewMode;
  final DateTime? selectedDate;
  final DateTime? weekStart;
  final DateTime? weekEnd;

  const VisitorAnalyticsWidget({
    super.key,
    required this.franchiseId,
    required this.ownerUserId,
    this.viewMode,
    this.selectedDate,
    this.weekStart,
    this.weekEnd,
  });

  @override
  State<VisitorAnalyticsWidget> createState() => _VisitorAnalyticsWidgetState();
}

class _VisitorAnalyticsWidgetState extends State<VisitorAnalyticsWidget> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(VisitorAnalyticsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewMode != widget.viewMode ||
        oldWidget.selectedDate != widget.selectedDate ||
        oldWidget.weekStart != widget.weekStart ||
        oldWidget.weekEnd != widget.weekEnd ||
        oldWidget.franchiseId != widget.franchiseId) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await StorageService.getToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
          _error = 'Please login again';
        });
        return;
      }

      String url =
          '${ApiConfig.baseUrl}/api/dashboard/franchise/analytics/visitors'
          '?owner_user_id=${widget.ownerUserId}'
          '&franchise_id=${widget.franchiseId}';

      if (widget.viewMode != null) {
        String startDate, endDate;
        switch (widget.viewMode!) {
          case DateViewMode.day:
            final date = widget.selectedDate ?? DateTime.now();
            startDate = _formatDate(date);
            endDate = _formatDate(date);
            url += '&start_date=$startDate&end_date=$endDate';
            break;
          case DateViewMode.week:
            if (widget.weekStart != null && widget.weekEnd != null) {
              startDate = _formatDate(widget.weekStart!);
              endDate = _formatDate(widget.weekEnd!);
            } else {
              final now = DateTime.now();
              final weekday = now.weekday;
              final start = now.subtract(Duration(days: weekday - 1));
              final end = start.add(Duration(days: 6));
              startDate = _formatDate(start);
              endDate = _formatDate(end);
            }
            url += '&start_date=$startDate&end_date=$endDate';
            break;
          case DateViewMode.month:
            final date = widget.selectedDate ?? DateTime.now();
            final start = DateTime(date.year, date.month, 1);
            final end = DateTime(date.year, date.month + 1, 0);
            startDate = _formatDate(start);
            endDate = _formatDate(end);
            url += '&start_date=$startDate&end_date=$endDate';
            break;
          case DateViewMode.year:
            final date = widget.selectedDate ?? DateTime.now();
            final start = DateTime(date.year, 1, 1);
            final end = DateTime(date.year, 12, 31);
            startDate = _formatDate(start);
            endDate = _formatDate(end);
            url += '&start_date=$startDate&end_date=$endDate';
            break;
        }
      } else {
        url += '&days=30';
      }

      final uri = Uri.parse(url);
      final response = await http.get(
        uri,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        if (json['success'] == true) {
          setState(() {
            _data = json['visitors'];
            _isLoading = false;
          });
          return;
        }
      }
      setState(() {
        _isLoading = false;
        _error = 'Failed to load visitor data';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Network error: $e';
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getDateRangeLabel() {
    if (widget.viewMode == null) return 'Last 30 Days';

    switch (widget.viewMode!) {
      case DateViewMode.day:
        final date = widget.selectedDate ?? DateTime.now();
        return _formatDisplayDate(date);
      case DateViewMode.week:
        if (widget.weekStart != null && widget.weekEnd != null) {
          return '${_formatDisplayDate(widget.weekStart!)} - ${_formatDisplayDate(widget.weekEnd!)}';
        }
        return 'This Week';
      case DateViewMode.month:
        final date = widget.selectedDate ?? DateTime.now();
        return '${_getMonthName(date.month)} ${date.year}';
      case DateViewMode.year:
        final date = widget.selectedDate ?? DateTime.now();
        return '${date.year}';
    }
  }

  String _formatDisplayDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;

    if (_isLoading) {
      return _buildSkeleton(isTablet);
    }

    if (_error != null) {
      return _buildError(isTablet);
    }

    if (_data == null) {
      return const SizedBox.shrink();
    }

    final visitors = _data!['unique_visitors'] ?? 0;
    final platforms = _data!['platforms'] as List? ?? [];

    int pos = 0, mobile = 0, web = 0;
    for (var p in platforms) {
      final name = p['platform']?.toString() ?? '';
      final count = (p['unique_visitors'] ?? 0) as int;
      if (name == 'POS')
        pos = count;
      else if (name == 'Mobile')
        mobile = count;
      else if (name == 'Web')
        web = count;
    }

    final stats = [
      {
        'label': 'Unique Visitors',
        'value': visitors.toString(),
        'color': SiporaTheme.greenDark,
        'icon': Icons.people_rounded,
      },
      {
        'label': 'POS',
        'value': pos.toString(),
        'color': Colors.blue.shade600,
        'icon': Icons.storefront_rounded,
      },
      {
        'label': 'Mobile',
        'value': mobile.toString(),
        'color': Colors.deepPurple.shade600,
        'icon': Icons.phone_android_rounded,
      },
      {
        'label': 'Web',
        'value': web.toString(),
        'color': Colors.orange.shade600,
        'icon': Icons.laptop_rounded,
      },
    ];

    return Container(
      margin: EdgeInsets.only(bottom: context.h(16)),
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(context.r(16)),
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
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_rounded,
                color: SiporaTheme.greenMid,
                size: context.w(20),
              ),
              SizedBox(width: context.w(8)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visitor Analytics',
                      style: TextStyle(
                        fontSize: isTablet ? context.sp(16) : context.sp(14),
                        fontWeight: FontWeight.w700,
                        color: theme.textDark,
                      ),
                    ),
                    Text(
                      _getDateRangeLabel(),
                      style: TextStyle(
                        fontSize: isTablet ? context.sp(11) : context.sp(10),
                        color: theme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(8)),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isTablet ? 4 : 2,
              crossAxisSpacing: context.w(8),
              mainAxisSpacing: context.h(8),
              childAspectRatio: 1.8,
            ),
            itemCount: stats.length,
            itemBuilder: (context, index) {
              final stat = stats[index];
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(8),
                  vertical: context.h(6),
                ),
                decoration: BoxDecoration(
                  color: theme.cream,
                  borderRadius: BorderRadius.circular(context.r(10)),
                  border: Border.all(
                    color: theme.border.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      stat['icon'] as IconData,
                      color: stat['color'] as Color,
                      size: context.w(18),
                    ),
                    SizedBox(width: context.w(6)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            stat['value'] as String,
                            style: TextStyle(
                              fontSize: isTablet
                                  ? context.sp(16)
                                  : context.sp(14),
                              fontWeight: FontWeight.w800,
                              color: theme.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            stat['label'] as String,
                            style: TextStyle(
                              fontSize: isTablet
                                  ? context.sp(10)
                                  : context.sp(9),
                              color: theme.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(bool isTablet) {
    final theme = context.siporaTheme;
    return Container(
      margin: EdgeInsets.only(bottom: context.h(16)),
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(context.r(16)),
        border: Border.all(color: theme.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: context.w(140),
            height: context.h(18),
            color: Colors.grey.shade200,
          ),
          SizedBox(height: context.h(10)),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isTablet ? 4 : 2,
              crossAxisSpacing: context.w(8),
              mainAxisSpacing: context.h(8),
              childAspectRatio: 1.8,
            ),
            itemCount: 4,
            itemBuilder: (context, index) => Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(context.r(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(bool isTablet) {
    final theme = context.siporaTheme;
    return Container(
      margin: EdgeInsets.only(bottom: context.h(16)),
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(context.r(16)),
        border: Border.all(color: Colors.red.shade200, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade400,
            size: context.w(20),
          ),
          SizedBox(width: context.w(8)),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                fontSize: isTablet ? context.sp(13) : context.sp(11),
                color: Colors.red.shade400,
              ),
            ),
          ),
          TextButton(
            onPressed: _fetchData,
            child: Text(
              'Retry',
              style: TextStyle(color: SiporaTheme.greenDark),
            ),
          ),
        ],
      ),
    );
  }
}
