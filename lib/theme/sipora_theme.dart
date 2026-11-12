import 'package:flutter/material.dart';

/// Sipora Café Theme - Centralized theme configuration
/// Use this theme across all pages for consistent styling
class SiporaTheme {
  // Private constructor to prevent instantiation
  SiporaTheme._();

  // ==================== CORE COLORS ====================

  /// Primary brand colors (keep as static for direct access)
  static const Color greenDark = Color(0xFF2D5016);
  static const Color greenMid = Color(0xFF3D6B1E);
  static const Color greenLight = Color(0xFF5A8A2E);
  static const Color greenBg = Color(0xFFEFF5E8);
  static const Color greenSurface = Color(0xFFF7FAF2);
  static const Color greenPill = Color(0xFF7ECC4A);

  /// Background & surfaces
  static const Color creamLight = Color(0xFFFAFAF7);
  static const Color whiteLight = Color(0xFFFFFFFF);
  static const Color creamDark = Color(0xFF121212);
  static const Color whiteDark = Color(0xFF1E1E1E);

  /// Text colors
  static const Color textDarkLight = Color(0xFF1A2810);
  static const Color textMutedLight = Color(0xFF6B7B5A);
  static const Color textDarkDark = Color(0xFFE0E0E0);
  static const Color textMutedDark = Color(0xFF9E9E9E);

  /// Border colors
  static const Color borderLight = Color(0xFFD4E0C4);
  static const Color borderDark = Color(0xFF3D3D3D);

  /// Gold / VIP colors (brand colors - keep same for both themes)
  static const Color gold = Color(0xFFC8960C);
  static const Color goldText = Color(0xFF8A6400);
  static const Color goldBorder = Color(0xFFE8C64A);
  static const Color goldBg = Color(0xFFFDF6E3);

  /// Danger / Error colors
  static const Color red = Color(0xFFC0392B);
  static const Color redBg = Color(0xFFFDECEA);
  static const Color redBorder = Color(0xFFF0C4C0);

  /// Shadow colors (with opacity)
  static const Color shadowLight = Color(0x0D2D5016); // 5% opacity
  static const Color shadowMedium = Color(0x1A2D5016); // 10% opacity
  static const Color shadowStrong = Color(0x332D5016); // 20% opacity

  // ==================== DYNAMIC COLORS (for theme extension) ====================

  /// Returns cream color based on theme mode
  static Color getCream(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? creamDark : creamLight;
  }

  /// Returns white color based on theme mode
  static Color getWhite(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? whiteDark : whiteLight;
  }

  /// Returns text dark color based on theme mode
  static Color getTextDark(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? textDarkDark : textDarkLight;
  }

  /// Returns text muted color based on theme mode
  static Color getTextMuted(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? textMutedDark : textMutedLight;
  }

  /// Returns border color based on theme mode
  static Color getBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? borderDark : borderLight;
  }

  // ==================== TYPOGRAPHY ====================

  /// Text styles (with dynamic color support)
  static TextStyle headlineLarge(BuildContext context) => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: getTextDark(context),
    letterSpacing: -0.3,
  );

  static TextStyle headlineMedium(BuildContext context) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: getTextDark(context),
    letterSpacing: -0.2,
  );

  static TextStyle headlineSmall(BuildContext context) => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: getTextDark(context),
    letterSpacing: -0.2,
  );

  static TextStyle titleLarge(BuildContext context) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: getTextDark(context),
  );

  static TextStyle titleMedium(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: getTextDark(context),
  );

  static TextStyle titleSmall(BuildContext context) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: getTextDark(context),
  );

  static TextStyle bodyLarge(BuildContext context) => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: getTextDark(context),
  );

  static TextStyle bodyMedium(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: getTextDark(context),
  );

  static TextStyle bodySmall(BuildContext context) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: getTextDark(context),
  );

  static TextStyle caption(BuildContext context) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: getTextMuted(context),
  );

  static TextStyle captionBold(BuildContext context) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: getTextMuted(context),
  );

  static TextStyle sectionLabel(BuildContext context) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: greenMid,
  );

  // ==================== STATIC TEXT STYLES (for backward compatibility) ====================

  static const TextStyle headlineLargeStatic = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textDarkLight,
    letterSpacing: -0.3,
  );

  static const TextStyle headlineMediumStatic = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textDarkLight,
    letterSpacing: -0.2,
  );

  static const TextStyle headlineSmallStatic = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textDarkLight,
    letterSpacing: -0.2,
  );

  static const TextStyle titleLargeStatic = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textDarkLight,
  );

  static const TextStyle titleMediumStatic = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textDarkLight,
  );

  static const TextStyle titleSmallStatic = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: textDarkLight,
  );

  static const TextStyle bodyLargeStatic = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: textDarkLight,
  );

  static const TextStyle bodyMediumStatic = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textDarkLight,
  );

  static const TextStyle bodySmallStatic = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textDarkLight,
  );

  static const TextStyle captionStatic = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textMutedLight,
  );

  static const TextStyle captionBoldStatic = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: textMutedLight,
  );

  static const TextStyle sectionLabelStatic = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: greenMid,
  );

  // ==================== DECORATIONS ====================

  /// Standard card decoration (dynamic)
  static BoxDecoration cardDecoration(
    BuildContext context, {
    double radius = 16,
    bool withBorder = true,
    List<BoxShadow>? customShadow,
  }) {
    return BoxDecoration(
      color: getWhite(context),
      borderRadius: BorderRadius.circular(radius),
      border: withBorder
          ? Border.all(color: getBorder(context), width: 1)
          : null,
      boxShadow:
          customShadow ??
          [
            BoxShadow(
              color: shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
    );
  }

  /// Standard card decoration (static - for backward compatibility)
  static BoxDecoration cardDecorationStatic({
    double radius = 16,
    bool withBorder = true,
    List<BoxShadow>? customShadow,
  }) {
    return BoxDecoration(
      color: whiteLight,
      borderRadius: BorderRadius.circular(radius),
      border: withBorder ? Border.all(color: borderLight, width: 1) : null,
      boxShadow:
          customShadow ??
          [
            BoxShadow(
              color: shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
    );
  }

  /// Gradient decoration for banners
  static BoxDecoration gradientDecoration({
    double radius = 20,
    List<Color>? colors,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors ?? [greenDark, greenMid],
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: greenDark.withValues(alpha: 0.25),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// Icon container decoration
  static BoxDecoration iconDecoration({double radius = 11, Color? color}) {
    return BoxDecoration(
      color: color ?? greenBg,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  /// Circle avatar decoration
  static BoxDecoration avatarDecoration({
    Color borderColor = greenLight,
    double borderWidth = 2,
  }) {
    return BoxDecoration(
      color: greenBg,
      shape: BoxShape.circle,
      border: Border.all(color: borderColor, width: borderWidth),
    );
  }

  /// Badge decoration (points, VIP, etc.)
  static BoxDecoration badgeDecoration({
    Color? bgColor,
    Color? borderColor,
    double radius = 16,
  }) {
    return BoxDecoration(
      color: bgColor ?? greenBg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? borderLight, width: 0.5),
    );
  }

  // ==================== BUTTON STYLES ====================

  /// Primary button style
  static ButtonStyle primaryButtonStyle({
    double height = 48,
    double radius = 12,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: greenDark,
      foregroundColor: Colors.white,
      minimumSize: Size(double.infinity, height),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      elevation: 0,
    );
  }

  /// Secondary button style (outlined)
  static ButtonStyle secondaryButtonStyle({
    double height = 48,
    double radius = 12,
  }) {
    return OutlinedButton.styleFrom(
      foregroundColor: greenDark,
      side: const BorderSide(color: greenDark),
      minimumSize: Size(double.infinity, height),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  /// Text button style
  static ButtonStyle textButtonStyle(BuildContext context) {
    return TextButton.styleFrom(foregroundColor: getTextMuted(context));
  }

  /// Danger button style (for logout, delete, etc.)
  static ButtonStyle dangerButtonStyle({double radius = 12}) {
    return ElevatedButton.styleFrom(
      backgroundColor: redBg,
      foregroundColor: red,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      side: const BorderSide(color: redBorder),
      elevation: 0,
    );
  }

  // ==================== INPUT DECORATION ====================

  /// Text field decoration (dynamic)
  static InputDecoration textFieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
    bool isTablet = false,
    BuildContext? context,
  }) {
    final isDark =
        context != null && Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? borderDark : borderLight;
    final textColor = isDark ? textMutedDark : textMutedLight;
    final fillColor = isDark ? whiteDark : creamLight;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: textColor),
      labelStyle: TextStyle(color: textColor),
      prefixIcon: Icon(icon, size: 20, color: textColor),
      fillColor: fillColor,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: greenMid, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: red),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isTablet ? 16 : 14,
      ),
    );
  }

  // ==================== HELPER METHODS ====================

  /// Show a snackbar with theme styling
  static void showSnackBar(
    BuildContext context,
    String message, {
    required bool isError,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? red : greenMid,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: duration,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show a loading dialog
  static void showLoadingDialog(
    BuildContext context, {
    String message = 'Loading...',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: getWhite(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: greenDark,
                  ),
                ),
                const SizedBox(height: 16),
                Text(message, style: bodyMedium(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Format date for display
  static String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Not available';
    try {
      final dateTime = DateTime.parse(dateString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return dateString;
    }
  }

  /// Get screen type based on width
  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) return ScreenType.tablet;
    if (width < 360) return ScreenType.small;
    return ScreenType.normal;
  }
}

/// Screen type enum
enum ScreenType {
  small, // < 360
  normal, // 360 - 600
  tablet, // > 600
}

/// Extension for ScreenType to get responsive values
extension ScreenTypeExtension on ScreenType {
  double spacing(double normal, {double? small, double? tablet}) {
    switch (this) {
      case ScreenType.small:
        return small ?? normal * 0.8;
      case ScreenType.tablet:
        return tablet ?? normal * 1.2;
      default:
        return normal;
    }
  }

  double fontSize(double normal, {double? small, double? tablet}) {
    switch (this) {
      case ScreenType.small:
        return small ?? normal * 0.9;
      case ScreenType.tablet:
        return tablet ?? normal * 1.1;
      default:
        return normal;
    }
  }
}

// ==================== THEME EXTENSION FOR DARK MODE ====================

/// Theme Extension for Sipora - adds custom properties to ThemeData
class SiporaThemeExtension extends ThemeExtension<SiporaThemeExtension> {
  final Color cream;
  final Color white;
  final Color textDark;
  final Color textMuted;
  final Color border;
  final Color greenDark;
  final Color greenMid;
  final Color greenLight;
  final Color greenBg;
  final Color greenPill;
  final Color gold;
  final Color goldText;
  final Color goldBg;
  final Color red;
  final Color redBg;

  const SiporaThemeExtension({
    required this.cream,
    required this.white,
    required this.textDark,
    required this.textMuted,
    required this.border,
    required this.greenDark,
    required this.greenMid,
    required this.greenLight,
    required this.greenBg,
    required this.greenPill,
    required this.gold,
    required this.goldText,
    required this.goldBg,
    required this.red,
    required this.redBg,
  });

  /// Light theme extension
  static const light = SiporaThemeExtension(
    cream: SiporaTheme.creamLight,
    white: SiporaTheme.whiteLight,
    textDark: SiporaTheme.textDarkLight,
    textMuted: SiporaTheme.textMutedLight,
    border: SiporaTheme.borderLight,
    greenDark: SiporaTheme.greenDark,
    greenMid: SiporaTheme.greenMid,
    greenLight: SiporaTheme.greenLight,
    greenBg: SiporaTheme.greenBg,
    greenPill: SiporaTheme.greenPill,
    gold: SiporaTheme.gold,
    goldText: SiporaTheme.goldText,
    goldBg: SiporaTheme.goldBg,
    red: SiporaTheme.red,
    redBg: SiporaTheme.redBg,
  );

  /// Dark theme extension
  static const dark = SiporaThemeExtension(
    cream: SiporaTheme.creamDark,
    white: SiporaTheme.whiteDark,
    textDark: SiporaTheme.textDarkDark,
    textMuted: SiporaTheme.textMutedDark,
    border: SiporaTheme.borderDark,
    greenDark: SiporaTheme.greenDark,
    greenMid: SiporaTheme.greenMid,
    greenLight: SiporaTheme.greenLight,
    greenBg: SiporaTheme.greenBg,
    greenPill: SiporaTheme.greenPill,
    gold: SiporaTheme.gold,
    goldText: SiporaTheme.goldText,
    goldBg: SiporaTheme.goldBg,
    red: SiporaTheme.red,
    redBg: SiporaTheme.redBg,
  );

  @override
  SiporaThemeExtension copyWith({
    Color? cream,
    Color? white,
    Color? textDark,
    Color? textMuted,
    Color? border,
    Color? greenDark,
    Color? greenMid,
    Color? greenLight,
    Color? greenBg,
    Color? greenPill,
    Color? gold,
    Color? goldText,
    Color? goldBg,
    Color? red,
    Color? redBg,
  }) {
    return SiporaThemeExtension(
      cream: cream ?? this.cream,
      white: white ?? this.white,
      textDark: textDark ?? this.textDark,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      greenDark: greenDark ?? this.greenDark,
      greenMid: greenMid ?? this.greenMid,
      greenLight: greenLight ?? this.greenLight,
      greenBg: greenBg ?? this.greenBg,
      greenPill: greenPill ?? this.greenPill,
      gold: gold ?? this.gold,
      goldText: goldText ?? this.goldText,
      goldBg: goldBg ?? this.goldBg,
      red: red ?? this.red,
      redBg: redBg ?? this.redBg,
    );
  }

  @override
  SiporaThemeExtension lerp(
    covariant ThemeExtension<SiporaThemeExtension>? other,
    double t,
  ) {
    if (other is! SiporaThemeExtension) return this;
    return SiporaThemeExtension(
      cream: Color.lerp(cream, other.cream, t)!,
      white: Color.lerp(white, other.white, t)!,
      textDark: Color.lerp(textDark, other.textDark, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      greenDark: Color.lerp(greenDark, other.greenDark, t)!,
      greenMid: Color.lerp(greenMid, other.greenMid, t)!,
      greenLight: Color.lerp(greenLight, other.greenLight, t)!,
      greenBg: Color.lerp(greenBg, other.greenBg, t)!,
      greenPill: Color.lerp(greenPill, other.greenPill, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldText: Color.lerp(goldText, other.goldText, t)!,
      goldBg: Color.lerp(goldBg, other.goldBg, t)!,
      red: Color.lerp(red, other.red, t)!,
      redBg: Color.lerp(redBg, other.redBg, t)!,
    );
  }
}

/// Helper extension for easier access to SiporaThemeExtension
extension SiporaThemeContext on BuildContext {
  SiporaThemeExtension get siporaTheme {
    try {
      return Theme.of(this).extension<SiporaThemeExtension>()!;
    } catch (e) {
      // Fallback to light theme if extension not found
      return SiporaThemeExtension.light;
    }
  }
}
