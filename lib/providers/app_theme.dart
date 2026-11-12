import 'package:flutter/material.dart';
import '../theme/sipora_theme.dart';

// This file is kept for backward compatibility
class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    extensions: [SiporaThemeExtension.light],
    scaffoldBackgroundColor: SiporaTheme.creamLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: SiporaTheme.whiteLight,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    // Add these to ensure proper color scheme
    colorScheme: const ColorScheme.light(
      primary: SiporaTheme.greenDark,
      secondary: SiporaTheme.greenMid,
      surface: SiporaTheme.whiteLight,
      error: SiporaTheme.red,
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    extensions: [SiporaThemeExtension.dark],
    scaffoldBackgroundColor: SiporaTheme.creamDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: SiporaTheme.whiteDark,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    // Complete color scheme for dark mode
    colorScheme: const ColorScheme.dark(
      primary: SiporaTheme.greenDark,
      primaryContainer: SiporaTheme.greenBg,
      secondary: SiporaTheme.greenMid,
      secondaryContainer: SiporaTheme.greenMid,
      surface: SiporaTheme.whiteDark, // was: surface (keep)
      // background line removed — surface covers it now
      error: SiporaTheme.red,
      errorContainer: SiporaTheme.redBg,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface:
          SiporaTheme.textDarkDark, // keep existing one, remove onBackground
      onError: Colors.white,
    ),
    // Card theme for dark mode
    cardTheme: CardThemeData(
      color: SiporaTheme.whiteDark,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    // Text theme for dark mode
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: SiporaTheme.textDarkDark,
        letterSpacing: -0.3,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: SiporaTheme.textDarkDark,
        letterSpacing: -0.2,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: SiporaTheme.textDarkDark,
        letterSpacing: -0.2,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: SiporaTheme.textDarkDark,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: SiporaTheme.textDarkDark,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: SiporaTheme.textDarkDark,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: SiporaTheme.textDarkDark,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: SiporaTheme.textMutedDark,
      ),
    ),
    // Divider theme
    dividerTheme: const DividerThemeData(
      color: SiporaTheme.borderDark,
      thickness: 1,
    ),
    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: SiporaTheme.whiteDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SiporaTheme.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SiporaTheme.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SiporaTheme.greenMid, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SiporaTheme.red),
      ),
      labelStyle: const TextStyle(color: SiporaTheme.textMutedDark),
      hintStyle: const TextStyle(color: SiporaTheme.textMutedDark),
    ),
  );
}
