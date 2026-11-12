import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/sipora_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);

    if (savedTheme != null) {
      switch (savedTheme) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.system;
      }
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.toString().split('.').last);
  }

  void toggleTheme() {
    switch (_themeMode) {
      case ThemeMode.light:
        setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        setThemeMode(ThemeMode.system);
        break;
      case ThemeMode.system:
        setThemeMode(ThemeMode.light);
        break;
    }
  }

  // Get the current theme extension based on theme mode
  SiporaThemeExtension get currentThemeExtension {
    switch (_themeMode) {
      case ThemeMode.dark:
        return SiporaThemeExtension.dark;
      case ThemeMode.light:
        return SiporaThemeExtension.light;
      case ThemeMode.system:
        return SiporaThemeExtension.light;
    }
  }

  // Get the appropriate theme data for MaterialApp
  ThemeData get lightTheme => _buildTheme(ThemeMode.light);
  ThemeData get darkTheme => _buildTheme(ThemeMode.dark);

  // Build theme dynamically based on mode
  ThemeData _buildTheme(ThemeMode mode) {
    final isDark = mode == ThemeMode.dark;
    final themeExtension = isDark
        ? SiporaThemeExtension.dark
        : SiporaThemeExtension.light;
    final brightness = isDark ? Brightness.dark : Brightness.light;

    return ThemeData(
      brightness: brightness,
      extensions: [themeExtension],
      scaffoldBackgroundColor: themeExtension.cream,

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),

      // Card Theme - FIXED: Use CardThemeData
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SiporaTheme.greenMid, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SiporaTheme.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SiporaTheme.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SiporaTheme.greenDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SiporaTheme.greenDark,
          side: const BorderSide(color: SiporaTheme.greenDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        headlineLarge: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        headlineMedium: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        headlineSmall: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        titleSmall: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
        bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        bodySmall: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
        labelLarge: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        labelMedium: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        labelSmall: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      ),

      // Color Scheme - FIXED: Removed deprecated background and onBackground
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: SiporaTheme.greenDark,
        onPrimary: Colors.white,
        secondary: SiporaTheme.greenMid,
        onSecondary: Colors.white,
        error: SiporaTheme.red,
        onError: Colors.white,
        surface: themeExtension.white,
        onSurface: themeExtension.textDark,
        surfaceTint: Colors.transparent,
        primaryContainer: SiporaTheme.greenBg,
        onPrimaryContainer: themeExtension.textDark,
        secondaryContainer: SiporaTheme.goldBg,
        onSecondaryContainer: SiporaTheme.goldText,
        tertiary: SiporaTheme.gold,
        onTertiary: Colors.white,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(thickness: 1, space: 1),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // Dialog Theme - FIXED: Use DialogThemeData
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(fontSize: 14),
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: SiporaTheme.greenDark,
        circularTrackColor: SiporaTheme.greenBg.withValues(alpha: 0.3),
      ),

      // Tab Bar Theme - FIXED: Use TabBarThemeData
      tabBarTheme: const TabBarThemeData(dividerColor: Colors.transparent),

      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        indicatorColor: SiporaTheme.greenDark.withValues(alpha: 0.1),
      ),

      // List Tile Theme
      listTileTheme: const ListTileThemeData(tileColor: Colors.transparent),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 0,
      ),

      // Tooltip Theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 12),
      ),
    );
  }

  // Helper method to get the current theme extension in a widget
  SiporaThemeExtension getThemeExtension(BuildContext context) {
    return Theme.of(context).extension<SiporaThemeExtension>()!;
  }
}
