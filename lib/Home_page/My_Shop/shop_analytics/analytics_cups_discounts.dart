import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/sipora_theme.dart';
import '../../../utils/screen_utils.dart';

class AnalyticsCupsDiscounts extends StatelessWidget {
  final Map<String, dynamic>? data;
  final bool isLoading;
  final String? error;

  const AnalyticsCupsDiscounts({
    super.key,
    this.data,
    this.isLoading = false,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;

    if (isLoading) {
      return _buildSkeleton(context);
    }

    if (error != null || data == null) {
      return _buildError(context, error ?? 'Failed to load data');
    }

    final cupStats = data!['cup_stats'] as Map<String, dynamic>? ?? {};
    final discountTotals =
        data!['discount_totals'] as Map<String, dynamic>? ?? {};

    // ✅ Prefer new 'trend' field; fallback to 'monthly_discount_trend'
    final trend = (data!['trend'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final monthlyTrend =
        (data!['monthly_discount_trend'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    final trendData = trend.isNotEmpty ? trend : monthlyTrend;

    return Container(
      margin: EdgeInsets.only(top: context.h(24)),
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(context.r(16)),
        border: Border.all(color: theme.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: SiporaTheme.shadowLight.withValues(alpha: 0.05),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '☕ Cups & Discounts',
            style: TextStyle(
              fontSize: isTablet ? context.sp(18) : context.sp(16),
              fontWeight: FontWeight.w700,
              color: theme.textDark,
            ),
          ),
          SizedBox(height: context.h(12)),

          // ── 4 stat cards ──
          _buildStatsGrid(context, cupStats),

          SizedBox(height: context.h(20)),

          // ── Discount breakdown ──
          _buildDiscountBreakdown(context, discountTotals),

          SizedBox(height: context.h(20)),

          // ── Trend chart ──
          _buildTrendChart(context, trendData),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, dynamic> cupStats) {
    final isTablet = context.isTablet;
    final theme = context.siporaTheme;

    final items = [
      {
        'label': 'Cups Sold',
        'value': (cupStats['total_cups_sold'] ?? 0).toString(),
        'color': SiporaTheme.greenDark,
      },
      {
        'label': 'Revenue',
        'value': _formatCurrency(cupStats['total_revenue'] ?? 0),
        'color': SiporaTheme.gold,
      },
      {
        'label': 'Free Cups Used',
        'value': (cupStats['total_free_cups_used'] ?? 0).toString(),
        'color': Colors.purple.shade600,
      },
      {
        'label': 'Free Value',
        'value': _formatCurrency(cupStats['total_free_value'] ?? 0),
        'color': Colors.orange.shade600,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 4 : 2,
        crossAxisSpacing: context.w(10),
        mainAxisSpacing: context.h(10),
        childAspectRatio: isTablet ? 1.8 : 1.6,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: EdgeInsets.all(context.w(10)),
          decoration: BoxDecoration(
            color: theme.cream,
            borderRadius: BorderRadius.circular(context.r(12)),
            border: Border.all(color: theme.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item['value'] as String,
                style: TextStyle(
                  fontSize: isTablet ? context.sp(18) : context.sp(15),
                  fontWeight: FontWeight.w800,
                  color: item['color'] as Color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: context.h(2)),
              Text(
                item['label'] as String,
                style: TextStyle(
                  fontSize: isTablet ? context.sp(11) : context.sp(10),
                  color: theme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDiscountBreakdown(
    BuildContext context,
    Map<String, dynamic> discountTotals,
  ) {
    final isTablet = context.isTablet;
    final theme = context.siporaTheme;

    final freeCup =
        discountTotals['free_cup_discount'] as Map<String, dynamic>? ?? {};
    final promo =
        discountTotals['promo_discount'] as Map<String, dynamic>? ?? {};
    final grandTotal = discountTotals['grand_total'] ?? 0.0;
    final totalLineItems = discountTotals['total_line_items'] ?? 0;

    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: theme.cream,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: theme.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discount Breakdown',
            style: TextStyle(
              fontSize: isTablet ? context.sp(14) : context.sp(12),
              fontWeight: FontWeight.w600,
              color: theme.textDark,
            ),
          ),
          SizedBox(height: context.h(8)),
          _buildDiscountRow(
            context,
            label: 'Free Cup Discount',
            total: (freeCup['total'] ?? 0.0).toDouble(),
            count: freeCup['count'] ?? 0,
            color: Colors.purple.shade600,
          ),
          _buildDiscountRow(
            context,
            label: 'Promo Discount',
            total: (promo['total'] ?? 0.0).toDouble(),
            count: promo['count'] ?? 0,
            color: Colors.blue.shade600,
          ),
          Divider(color: theme.border, height: context.h(16)),
          _buildDiscountRow(
            context,
            label: 'Grand Total',
            total: grandTotal.toDouble(),
            count: totalLineItems,
            color: SiporaTheme.greenDark,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountRow(
    BuildContext context, {
    required String label,
    required double total,
    required int count,
    required Color color,
    bool bold = false,
  }) {
    final isTablet = context.isTablet;
    final theme = context.siporaTheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(3)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? context.sp(12) : context.sp(11),
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: theme.textDark,
              ),
            ),
          ),
          Text(
            '($count items)',
            style: TextStyle(
              fontSize: isTablet ? context.sp(10) : context.sp(9),
              color: theme.textMuted,
            ),
          ),
          SizedBox(width: context.w(10)),
          Text(
            _formatCurrency(total),
            style: TextStyle(
              fontSize: isTablet ? context.sp(14) : context.sp(13),
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(
    BuildContext context,
    List<Map<String, dynamic>> trendData,
  ) {
    final isTablet = context.isTablet;
    final theme = context.siporaTheme;

    if (trendData.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: context.h(20)),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(
              Icons.show_chart,
              color: theme.textMuted.withAlpha(100),
              size: context.w(40),
            ),
            SizedBox(height: context.h(8)),
            Text(
              'No discount trend data',
              style: TextStyle(
                fontSize: isTablet ? context.sp(13) : context.sp(11),
                color: theme.textMuted,
              ),
            ),
            Text(
              'Try switching to a different view',
              style: TextStyle(
                fontSize: isTablet ? context.sp(11) : context.sp(9),
                color: theme.textMuted.withAlpha(150),
              ),
            ),
          ],
        ),
      );
    }

    // Prepare data for fl_chart
    final List<FlSpot> freeCupSpots = [];
    final List<FlSpot> promoSpots = [];
    final List<String> labels = [];

    for (int i = 0; i < trendData.length; i++) {
      final item = trendData[i];
      final free = (item['free_cup'] ?? 0).toDouble();
      final promo = (item['promo'] ?? 0).toDouble();
      freeCupSpots.add(FlSpot(i.toDouble(), free));
      promoSpots.add(FlSpot(i.toDouble(), promo));
      labels.add(item['label'] ?? '');
    }

    // Find max value for Y axis
    final maxY = [
      ...freeCupSpots.map((s) => s.y),
      ...promoSpots.map((s) => s.y),
    ].fold(0.0, (max, v) => v > max ? v : max);

    final yMax = maxY * 1.2 + 10; // add some padding

    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: theme.cream,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: theme.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discount Trend',
            style: TextStyle(
              fontSize: isTablet ? context.sp(14) : context.sp(12),
              fontWeight: FontWeight.w600,
              color: theme.textDark,
            ),
          ),
          SizedBox(height: context.h(8)),
          Row(
            children: [
              _buildLegendDot(context, Colors.purple.shade600, 'Free Cup'),
              SizedBox(width: context.w(16)),
              _buildLegendDot(context, Colors.blue.shade600, 'Promo'),
            ],
          ),
          SizedBox(height: context.h(10)),
          SizedBox(
            height: isTablet ? context.h(180) : context.h(150),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yMax / 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.border,
                    strokeWidth: 0.5,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isTablet ? 36 : 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length)
                          return const SizedBox.shrink();
                        return Padding(
                          padding: EdgeInsets.only(top: context.h(6)),
                          child: Text(
                            labels[index],
                            style: TextStyle(
                              fontSize: isTablet
                                  ? context.sp(8)
                                  : context.sp(7),
                              color: theme.textMuted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isTablet ? 50 : 40,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: EdgeInsets.only(right: context.w(4)),
                        child: Text(
                          _formatCurrencyShort(value),
                          style: TextStyle(
                            fontSize: isTablet ? context.sp(8) : context.sp(7),
                            color: theme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                      return LineTooltipItem(
                        _formatCurrency(spot.y),
                        TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? context.sp(13) : context.sp(11),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: freeCupSpots,
                    isCurved: true,
                    color: Colors.purple.shade600,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.purple.shade600.withAlpha(25),
                    ),
                    dotData: FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: promoSpots,
                    isCurved: true,
                    color: Colors.blue.shade600,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.shade600.withAlpha(25),
                    ),
                    dotData: FlDotData(show: false),
                  ),
                ],
                minY: 0,
                maxY: yMax,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(BuildContext context, Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: context.sp(10),
            color: context.siporaTheme.textMuted,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  String _formatCurrencyShort(double amount) {
    if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  Widget _buildSkeleton(BuildContext context) {
    final theme = context.siporaTheme;
    return Container(
      margin: EdgeInsets.only(top: context.h(24)),
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
          SizedBox(height: context.h(12)),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: context.isTablet ? 4 : 2,
              crossAxisSpacing: context.w(10),
              mainAxisSpacing: context.h(10),
              childAspectRatio: context.isTablet ? 1.8 : 1.6,
            ),
            itemCount: 4,
            itemBuilder: (context, index) => Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(context.r(12)),
              ),
            ),
          ),
          SizedBox(height: context.h(20)),
          Container(
            width: context.w(120),
            height: context.h(16),
            color: Colors.grey.shade200,
          ),
          SizedBox(height: context.h(8)),
          ...List.generate(
            2,
            (i) => Container(
              height: context.h(24),
              color: Colors.grey.shade200,
              margin: EdgeInsets.only(bottom: context.h(4)),
            ),
          ),
          SizedBox(height: context.h(20)),
          Container(
            width: context.w(100),
            height: context.h(16),
            color: Colors.grey.shade200,
          ),
          SizedBox(height: context.h(10)),
          Container(height: context.h(150), color: Colors.grey.shade100),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    final theme = context.siporaTheme;
    return Container(
      margin: EdgeInsets.only(top: context.h(24)),
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(context.r(16)),
        border: Border.all(color: Colors.red.shade200, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade400,
            size: context.w(32),
          ),
          SizedBox(height: context.h(8)),
          Text(
            message,
            style: TextStyle(
              fontSize: context.sp(13),
              color: Colors.red.shade400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
