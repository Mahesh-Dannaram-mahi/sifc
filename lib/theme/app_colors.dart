import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors - Orange & Pista Green Theme
  static const Color brandOrange = Color(0xFFFF8C00); // Bright Orange
  static const Color brandLightOrange = Color(0xFFFFB84D); // Light Orange
  static const Color brandPistaGreen = Color(0xFF8FBC8F); // Pista Green
  static const Color brandDarkGreen = Color(0xFF6B8E23); // Dark Pista Green
  
  // Primary Colors
  static const Color primary = brandOrange;
  static const Color primaryVariant = Color(0xFFE67300); // Darker Orange
  static const Color secondary = brandPistaGreen;
  static const Color secondaryVariant = brandDarkGreen;
  
  // Surface Colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFFFFAF0); // Very light orange tint
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);
  
  // Status Colors
  static const Color success = brandPistaGreen;
  static const Color warning = brandOrange;
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Border Colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF0F0F0);
  
  // Shadow Colors
  static const Color shadow = Color(0x1F000000);
  static const Color shadowLight = Color(0x0F000000);
  
  // Icon Colors
  static const Color iconPrimary = Color(0xFF757575);
  static const Color iconSecondary = Color(0xFFBDBDBD);
  static const Color iconActive = primary;
  
  // Input Colors
  static const Color inputBackground = Color(0xFFFFFAF0); // Light orange tint
  static const Color inputBorder = Color(0xFFE0E0E0);
  static const Color inputFocusedBorder = primary;
  
  // Button Colors
  static const Color buttonPrimary = primary;
  static const Color buttonSecondary = secondary;
  static const Color buttonDisabled = Color(0xFFBDBDBD);
  
  // Navigation Colors
  static const Color navBarBackground = Color(0xFFFFFFFF);
  static const Color navBarActive = primary;
  static const Color navBarInactive = Color(0xFF9E9E9E);
}

class AppColorsDark {
  // Brand Colors - Orange & Pista Green Theme (same as light theme)
  static const Color brandOrange = Color(0xFFFF8C00); // Bright Orange
  static const Color brandLightOrange = Color(0xFFFFB84D); // Light Orange
  static const Color brandPistaGreen = Color(0xFF8FBC8F); // Pista Green
  static const Color brandDarkGreen = Color(0xFF6B8E23); // Dark Pista Green
  
  // Primary Colors
  static const Color primary = brandOrange;
  static const Color primaryVariant = Color(0xFFE67300); // Darker Orange
  static const Color secondary = brandPistaGreen;
  static const Color secondaryVariant = brandDarkGreen;
  
  // Surface Colors
  static const Color surface = Color(0xFF1E1E1E);
  static const Color background = Color(0xFF0A0A0A); // Very dark with orange tint
  static const Color cardBackground = Color(0xFF2A2A2A);
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);
  
  // Status Colors
  static const Color success = brandPistaGreen;
  static const Color warning = brandOrange;
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Border Colors
  static const Color border = Color(0xFF404040);
  static const Color borderLight = Color(0xFF333333);
  
  // Shadow Colors
  static const Color shadow = Color(0x4D000000);
  static const Color shadowLight = Color(0x26000000);
  
  // Icon Colors
  static const Color iconPrimary = Color(0xFFB0B0B0);
  static const Color iconSecondary = Color(0xFF757575);
  static const Color iconActive = primary;
  
  // Input Colors
  static const Color inputBackground = Color(0xFF2A2A2A);
  static const Color inputBorder = Color(0xFF555555);
  static const Color inputFocusedBorder = primary;
  
  // Button Colors
  static const Color buttonPrimary = primary;
  static const Color buttonSecondary = secondary;
  static const Color buttonDisabled = Color(0xFF555555);
  
  // Navigation Colors
  static const Color navBarBackground = Color(0xFF1E1E1E);
  static const Color navBarActive = primary;
  static const Color navBarInactive = Color(0xFF757575);
}