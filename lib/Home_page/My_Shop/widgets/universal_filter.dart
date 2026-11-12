import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import '../../../theme/sipora_theme.dart';
import '../../../utils/screen_utils.dart';

enum DateViewMode {
  day('Day'),
  week('Week'),
  month('Month'),
  year('Year');

  final String label;
  const DateViewMode(this.label);
}

class UniversalFilter extends StatefulWidget {
  final DateViewMode initialMode;
  final DateTime initialDate;
  final Function(DateViewMode mode, DateTime date) onFilterChanged;

  UniversalFilter({
    super.key,
    this.initialMode = DateViewMode.month,
    DateTime? initialDate,
    required this.onFilterChanged,
  }) : initialDate = initialDate ?? DateTime.now();

  @override
  State<UniversalFilter> createState() => _UniversalFilterState();
}

class _UniversalFilterState extends State<UniversalFilter> {
  late DateViewMode _selectedMode;
  late DateTime _selectedDate;
  final GlobalKey _buttonKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  // For week view
  DateTime? _weekStart;
  DateTime? _weekEnd;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode;
    _selectedDate = widget.initialDate;
    _calculateWeekRange();
  }

  void _calculateWeekRange() {
    if (_selectedMode == DateViewMode.week) {
      final weekday = _selectedDate.weekday;
      final start = _selectedDate.subtract(Duration(days: weekday - 1));
      // ✅ FIXED: Removed 'const' from Duration
      final end = start.add(Duration(days: 6));
      _weekStart = DateTime(start.year, start.month, start.day);
      _weekEnd = DateTime(end.year, end.month, end.day);
    }
  }

  String _getDisplayText() {
    switch (_selectedMode) {
      case DateViewMode.day:
        return '${_selectedDate.day} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}';
      case DateViewMode.week:
        if (_weekStart != null && _weekEnd != null) {
          final sameMonth = _weekStart!.month == _weekEnd!.month;
          if (sameMonth) {
            return '${_weekStart!.day} - ${_weekEnd!.day} ${_getMonthName(_weekStart!.month)} ${_weekStart!.year}';
          } else {
            return '${_weekStart!.day} ${_getMonthName(_weekStart!.month)} - ${_weekEnd!.day} ${_getMonthName(_weekEnd!.month)} ${_weekStart!.year}';
          }
        }
        return 'This Week';
      case DateViewMode.month:
        return '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}';
      case DateViewMode.year:
        return '${_selectedDate.year}';
    }
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

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
      if (_selectedMode == DateViewMode.week) {
        _calculateWeekRange();
      }
    });
    widget.onFilterChanged(_selectedMode, _selectedDate);
    _removeOverlay();
  }

  int _maxDaysInMonth(int year, int month) {
    if (month == 2) {
      final isLeapYear =
          (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      return isLeapYear ? 29 : 28;
    }
    const daysInMonths = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return daysInMonths[month];
  }

  void _navigateDate(int direction) {
    DateTime newDate;
    switch (_selectedMode) {
      case DateViewMode.day:
        newDate = _selectedDate.add(Duration(days: direction));
        break;
      case DateViewMode.week:
        newDate = _selectedDate.add(Duration(days: direction * 7));
        break;
      case DateViewMode.month:
        var newYear = _selectedDate.year;
        var newMonth = _selectedDate.month + direction;
        if (newMonth > 12) {
          newYear += 1;
          newMonth = 1;
        } else if (newMonth < 1) {
          newYear -= 1;
          newMonth = 12;
        }
        final maxDay = _maxDaysInMonth(newYear, newMonth);
        final safeDay =
            _selectedDate.day > maxDay ? maxDay : _selectedDate.day;
        newDate = DateTime(newYear, newMonth, safeDay);
        break;
      case DateViewMode.year:
        final newYear = _selectedDate.year + direction;
        final maxDay = _maxDaysInMonth(newYear, _selectedDate.month);
        final safeDay =
            _selectedDate.day > maxDay ? maxDay : _selectedDate.day;
        newDate = DateTime(newYear, _selectedDate.month, safeDay);
        break;
    }
    _onDateChanged(newDate);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: SiporaTheme.greenDark,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _onDateChanged(picked);
    }
  }

  void _onModeSelected(DateViewMode mode) {
    setState(() {
      _selectedMode = mode;
      if (mode == DateViewMode.week) {
        _calculateWeekRange();
      }
    });
    widget.onFilterChanged(_selectedMode, _selectedDate);
    _removeOverlay();
  }

  void _toggleOverlay() {
    if (_overlayEntry != null) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    final RenderBox renderBox =
        _buttonKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _removeOverlay,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: offset.dx,
            top: offset.dy + size.height + 4,
            width: size.width,
            child: _DropdownMenuOverlay(
              selectedMode: _selectedMode,
              onModeSelected: _onModeSelected,
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final isTablet = context.isTablet;

    return Container(
      key: _buttonKey,
      padding: EdgeInsets.symmetric(
        horizontal: context.w(12),
        vertical: context.h(8),
      ),
      decoration: BoxDecoration(
        color: theme.white,
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(color: theme.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: SiporaTheme.shadowLight.withValues(alpha: 0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // ─── Mode Selector ──────────────────────────────────────────────
          GestureDetector(
            onTap: _toggleOverlay,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(10),
                vertical: context.h(6),
              ),
              decoration: BoxDecoration(
                color: SiporaTheme.greenDark,
                borderRadius: BorderRadius.circular(context.r(8)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedMode.label,
                    style: TextStyle(
                      fontSize: isTablet ? context.sp(13) : context.sp(11),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: context.w(4)),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: Colors.white,
                    size: context.w(20),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(width: context.w(8)),

          // ─── Navigation Buttons ─────────────────────────────────────────
          GestureDetector(
            onTap: () => _navigateDate(-1),
            child: Container(
              padding: EdgeInsets.all(context.w(4)),
              decoration: BoxDecoration(
                color: theme.cream,
                borderRadius: BorderRadius.circular(context.r(6)),
                border: Border.all(color: theme.border, width: 0.5),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                size: isTablet ? context.w(20) : context.w(18),
                color: theme.textDark,
              ),
            ),
          ),

          // ─── Date Display (Clickable) ──────────────────────────────────
          Expanded(
            child: GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(8),
                  vertical: context.h(4),
                ),
                child: Text(
                  _getDisplayText(),
                  style: TextStyle(
                    fontSize: isTablet ? context.sp(14) : context.sp(12),
                    fontWeight: FontWeight.w600,
                    color: theme.textDark,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),

          // ─── Navigation Buttons ─────────────────────────────────────────
          GestureDetector(
            onTap: () => _navigateDate(1),
            child: Container(
              padding: EdgeInsets.all(context.w(4)),
              decoration: BoxDecoration(
                color: theme.cream,
                borderRadius: BorderRadius.circular(context.r(6)),
                border: Border.all(color: theme.border, width: 0.5),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                size: isTablet ? context.w(20) : context.w(18),
                color: theme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dropdown Menu Overlay ──────────────────────────────────────────────────
class _DropdownMenuOverlay extends StatelessWidget {
  final DateViewMode selectedMode;
  final Function(DateViewMode) onModeSelected;

  const _DropdownMenuOverlay({
    required this.selectedMode,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.siporaTheme;
    final modes = DateViewMode.values;

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(context.r(12)),
      child: Container(
        decoration: BoxDecoration(
          color: theme.white,
          borderRadius: BorderRadius.circular(context.r(12)),
          border: Border.all(color: theme.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: modes.map((mode) {
            final isSelected = mode == selectedMode;
            return GestureDetector(
              onTap: () => onModeSelected(mode),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(16),
                  vertical: context.h(10),
                ),
                decoration: BoxDecoration(
                  color: isSelected ? SiporaTheme.greenBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(context.r(8)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getModeIcon(mode),
                      size: context.w(18),
                      color: isSelected
                          ? SiporaTheme.greenDark
                          : theme.textMuted,
                    ),
                    SizedBox(width: context.w(12)),
                    Expanded(
                      child: Text(
                        mode.label,
                        style: TextStyle(
                          fontSize: context.sp(13),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? SiporaTheme.greenDark
                              : theme.textDark,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_rounded,
                        size: context.w(18),
                        color: SiporaTheme.greenDark,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  IconData _getModeIcon(DateViewMode mode) {
    switch (mode) {
      case DateViewMode.day:
        return Icons.calendar_today_rounded;
      case DateViewMode.week:
        return Icons.view_week_rounded;
      case DateViewMode.month:
        return Icons.calendar_month_rounded;
      case DateViewMode.year:
        return Icons.calendar_today_rounded;
    }
  }
}
