import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppFonts {
  // Font Families
  static const String primary = 'Roboto';
  static const String secondary = 'Poppins';
  static const String mono = 'Courier';
}

class AppTextStyles {
  // Headings
  static const TextStyle h1 = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  static const TextStyle h2 = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  static const TextStyle h3 = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  static const TextStyle h4 = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  static const TextStyle h5 = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  static const TextStyle h6 = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  // Secondary Text
  static const TextStyle secondaryLarge = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.5,
  );
  
  static const TextStyle secondaryMedium = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.5,
  );
  
  static const TextStyle secondarySmall = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );
  
  // Button Text
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    height: 1.2,
  );
  
  static const TextStyle buttonMedium = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    height: 1.2,
  );
  
  static const TextStyle buttonSmall = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    height: 1.2,
  );
  
  // Caption and Label
  static const TextStyle caption = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.3,
  );
  
  static const TextStyle label = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  // Input Text
  static const TextStyle inputLarge = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  static const TextStyle inputMedium = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  // Navigation
  static const TextStyle navBarActive = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.navBarActive,
    height: 1.2,
  );
  
  static const TextStyle navBarInactive = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.navBarInactive,
    height: 1.2,
  );
  
  // Price Text
  static const TextStyle priceLarge = TextStyle(
    fontFamily: AppFonts.secondary,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
    height: 1.2,
  );
  
  static const TextStyle priceMedium = TextStyle(
    fontFamily: AppFonts.secondary,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
    height: 1.2,
  );
  
  static const TextStyle priceSmall = TextStyle(
    fontFamily: AppFonts.secondary,
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
    height: 1.2,
  );
  
  // Status Text
  static const TextStyle success = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.success,
    height: 1.4,
  );
  
  static const TextStyle warning = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.warning,
    height: 1.4,
  );
  
  static const TextStyle error = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.error,
    height: 1.4,
  );
}

class AppTextStylesDark {
  // Headings
  static const TextStyle h1 = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColorsDark.textPrimary,
    height: 1.2,
  );
  
  static const TextStyle h2 = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColorsDark.textPrimary,
    height: 1.3,
  );
  
  static const TextStyle h3 = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColorsDark.textPrimary,
    height: 1.3,
  );
  
  static const TextStyle h4 = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColorsDark.textPrimary,
    height: 1.4,
  );
  
  static const TextStyle h5 = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColorsDark.textPrimary,
    height: 1.4,
  );
  
  static const TextStyle h6 = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColorsDark.textPrimary,
    height: 1.4,
  );
  
  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColorsDark.textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColorsDark.textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColorsDark.textPrimary,
    height: 1.4,
  );
  
  // Secondary Text
  static const TextStyle secondaryLarge = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColorsDark.textSecondary,
    height: 1.5,
  );
  
  static const TextStyle secondaryMedium = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColorsDark.textSecondary,
    height: 1.5,
  );
  
  static const TextStyle secondarySmall = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColorsDark.textSecondary,
    height: 1.4,
  );
  
  // Button Text
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColorsDark.textOnPrimary,
    height: 1.2,
  );
  
  static const TextStyle buttonMedium = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColorsDark.textOnPrimary,
    height: 1.2,
  );
  
  static const TextStyle buttonSmall = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColorsDark.textOnPrimary,
    height: 1.2,
  );
  
  // Caption and Label
  static const TextStyle caption = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: AppColorsDark.textSecondary,
    height: 1.3,
  );
  
  static const TextStyle label = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColorsDark.textPrimary,
    height: 1.3,
  );
  
  // Input Text
  static const TextStyle inputLarge = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColorsDark.textPrimary,
    height: 1.4,
  );
  
  static const TextStyle inputMedium = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColorsDark.textPrimary,
    height: 1.4,
  );
  
  // Navigation
  static const TextStyle navBarActive = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColorsDark.navBarActive,
    height: 1.2,
  );
  
  static const TextStyle navBarInactive = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColorsDark.navBarInactive,
    height: 1.2,
  );
  
  // Price Text
  static const TextStyle priceLarge = TextStyle(
    fontFamily: AppFonts.secondary,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColorsDark.primary,
    height: 1.2,
  );
  
  static const TextStyle priceMedium = TextStyle(
    fontFamily: AppFonts.secondary,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColorsDark.primary,
    height: 1.2,
  );
  
  static const TextStyle priceSmall = TextStyle(
    fontFamily: AppFonts.secondary,
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColorsDark.primary,
    height: 1.2,
  );
  
  // Status Text
  static const TextStyle success = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColorsDark.success,
    height: 1.4,
  );
  
  static const TextStyle warning = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColorsDark.warning,
    height: 1.4,
  );
  
  static const TextStyle error = TextStyle(
    fontFamily: AppFonts.primary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColorsDark.error,
    height: 1.4,
  );
}