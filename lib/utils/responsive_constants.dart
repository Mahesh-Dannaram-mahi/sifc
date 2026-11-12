import 'package:flutter/material.dart';
import '../theme/sipora_theme.dart';

// Move enum outside the class
enum ScreenTypeDetailed {
  extraSmall, // < 360
  small, // 360-400
  medium, // 400-600
  large, // 600-1024
  extraLarge, // > 1024
}

class ResponsiveConstants {
  // Screen breakpoints
  static const double extraSmallBreakpoint = 360;
  static const double smallBreakpoint = 400;
  static const double mediumBreakpoint = 600;
  static const double largeBreakpoint = 1024;

  // Helper method to get detailed screen type (now using consistent breakpoints)
  static ScreenTypeDetailed getScreenTypeDetailed(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < extraSmallBreakpoint) return ScreenTypeDetailed.extraSmall;
    if (width < smallBreakpoint) return ScreenTypeDetailed.small;
    if (width < mediumBreakpoint) return ScreenTypeDetailed.medium;
    if (width < largeBreakpoint) return ScreenTypeDetailed.large;
    return ScreenTypeDetailed.extraLarge;
  }

  // Simple screen type (using SiporaTheme for consistency)
  static ScreenType getScreenType(BuildContext context) {
    return SiporaTheme.getScreenType(context);
  }

  // Get screen type as string
  static String getScreenTypeString(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return 'small';
      case ScreenType.tablet:
        return 'large';
      default:
        return 'medium';
    }
  }

  // Check if screen is tablet
  static bool isTablet(BuildContext context) {
    return SiporaTheme.getScreenType(context) == ScreenType.tablet;
  }

  // Check if screen is small phone
  static bool isSmallPhone(BuildContext context) {
    return SiporaTheme.getScreenType(context) == ScreenType.small;
  }

  // Check if screen is normal phone
  static bool isNormalPhone(BuildContext context) {
    return SiporaTheme.getScreenType(context) == ScreenType.normal;
  }

  // Get responsive value based on screen type
  static T responsive<T>(
    BuildContext context, {
    required T defaultValue,
    T? small,
    T? tablet,
    T? extraSmall,
    T? large,
  }) {
    final screenType = getScreenTypeDetailed(context);
    switch (screenType) {
      case ScreenTypeDetailed.extraSmall:
        return extraSmall ?? small ?? defaultValue;
      case ScreenTypeDetailed.small:
        return small ?? defaultValue;
      case ScreenTypeDetailed.medium:
        return defaultValue;
      case ScreenTypeDetailed.large:
        return large ?? defaultValue;
      case ScreenTypeDetailed.extraLarge:
        return large ?? defaultValue;
    }
  }

  // Get responsive value based on simple screen type (small/normal/tablet)
  static T responsiveSimple<T>(
    BuildContext context, {
    required T defaultValue,
    T? small,
    T? tablet,
  }) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return small ?? defaultValue;
      case ScreenType.tablet:
        return tablet ?? defaultValue;
      default:
        return defaultValue;
    }
  }

  // ============ NAVIGATION BAR ============
  static double getBarHeight(BuildContext context) {
    final screenType = getScreenTypeDetailed(context);
    switch (screenType) {
      case ScreenTypeDetailed.extraSmall:
        return 55.0;
      case ScreenTypeDetailed.small:
        return 58.0;
      case ScreenTypeDetailed.medium:
        return 60.0;
      case ScreenTypeDetailed.large:
        return 64.0;
      case ScreenTypeDetailed.extraLarge:
        return 70.0;
    }
  }

  static double getCircleSize(BuildContext context) {
    final screenType = getScreenTypeDetailed(context);
    switch (screenType) {
      case ScreenTypeDetailed.extraSmall:
        return 65.0;
      case ScreenTypeDetailed.small:
        return 70.0;
      case ScreenTypeDetailed.medium:
        return 75.0;
      case ScreenTypeDetailed.large:
        return 80.0;
      case ScreenTypeDetailed.extraLarge:
        return 90.0;
    }
  }

  static double getPillWidth(BuildContext context) {
    final screenType = getScreenTypeDetailed(context);
    switch (screenType) {
      case ScreenTypeDetailed.extraSmall:
        return 55.0;
      case ScreenTypeDetailed.small:
        return 60.0;
      case ScreenTypeDetailed.medium:
        return 65.0;
      case ScreenTypeDetailed.large:
        return 70.0;
      case ScreenTypeDetailed.extraLarge:
        return 75.0;
    }
  }

  static double getPillHeight() {
    return 36.0;
  }

  static double getSpacerWidth(BuildContext context) {
    final screenType = getScreenTypeDetailed(context);
    switch (screenType) {
      case ScreenTypeDetailed.extraSmall:
        return 55.0;
      case ScreenTypeDetailed.small:
        return 60.0;
      case ScreenTypeDetailed.medium:
        return 70.0;
      case ScreenTypeDetailed.large:
        return 80.0;
      case ScreenTypeDetailed.extraLarge:
        return 90.0;
    }
  }

  static double getHorizontalPadding(BuildContext context) {
    final screenType = getScreenTypeDetailed(context);
    switch (screenType) {
      case ScreenTypeDetailed.extraSmall:
        return 6.0;
      case ScreenTypeDetailed.small:
        return 8.0;
      case ScreenTypeDetailed.medium:
        return 10.0;
      case ScreenTypeDetailed.large:
        return 12.0;
      case ScreenTypeDetailed.extraLarge:
        return 16.0;
    }
  }

  // ============ GENERAL UI ELEMENTS (using SiporaThemeExtension for dynamic theming) ============
  static double getIconSize(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return 18.0;
      case ScreenType.tablet:
        return 28.0;
      default:
        return 22.0;
    }
  }

  static double getFontSize(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return 11.0;
      case ScreenType.tablet:
        return 16.0;
      default:
        return 13.0;
    }
  }

  static double getTitleFontSize(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return 16.0;
      case ScreenType.tablet:
        return 28.0;
      default:
        return 20.0;
    }
  }

  static double getHeadingFontSize(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return 20.0;
      case ScreenType.tablet:
        return 32.0;
      default:
        return 24.0;
    }
  }

  static double getSubheadingFontSize(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return 12.0;
      case ScreenType.tablet:
        return 20.0;
      default:
        return 14.0;
    }
  }

  static double getButtonHeight(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return 40.0;
      case ScreenType.tablet:
        return 56.0;
      default:
        return 48.0;
    }
  }

  static double getButtonFontSize(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return 12.0;
      case ScreenType.tablet:
        return 18.0;
      default:
        return 14.0;
    }
  }

  static double getCardBorderRadius(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return 8.0;
      case ScreenType.tablet:
        return 20.0;
      default:
        return 12.0;
    }
  }

  static double getCardPadding(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return 8.0;
      case ScreenType.tablet:
        return 20.0;
      default:
        return 12.0;
    }
  }

  static double getScreenPadding(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return 8.0;
      case ScreenType.tablet:
        return 24.0;
      default:
        return 16.0;
    }
  }

  static double getGridSpacing(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return 4.0;
      case ScreenType.tablet:
        return 16.0;
      default:
        return 8.0;
    }
  }

  static int getGridCrossAxisCount(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return 1;
      case ScreenType.tablet:
        return 4;
      default:
        return 2;
    }
  }

  // ============ ORDER NOW BUTTON SPECIFIC ============
  static double getOrderNowIconSize(BuildContext context) {
    final screenType = getScreenTypeDetailed(context);
    switch (screenType) {
      case ScreenTypeDetailed.extraSmall:
        return 22.0;
      case ScreenTypeDetailed.small:
        return 24.0;
      case ScreenTypeDetailed.medium:
        return 26.0;
      case ScreenTypeDetailed.large:
        return 28.0;
      case ScreenTypeDetailed.extraLarge:
        return 32.0;
    }
  }

  static double getOrderNowFontSize(BuildContext context) {
    final screenType = getScreenTypeDetailed(context);
    switch (screenType) {
      case ScreenTypeDetailed.extraSmall:
        return 7.0;
      case ScreenTypeDetailed.small:
        return 8.0;
      case ScreenTypeDetailed.medium:
        return 8.5;
      case ScreenTypeDetailed.large:
        return 9.0;
      case ScreenTypeDetailed.extraLarge:
        return 11.0;
    }
  }

  static double getBorderWidth(BuildContext context) {
    final screenType = getScreenTypeDetailed(context);
    switch (screenType) {
      case ScreenTypeDetailed.extraSmall:
        return 1.2;
      case ScreenTypeDetailed.small:
        return 1.5;
      case ScreenTypeDetailed.medium:
        return 1.8;
      case ScreenTypeDetailed.large:
        return 2.0;
      case ScreenTypeDetailed.extraLarge:
        return 2.5;
    }
  }

  // ============ CART BADGE ============
  static double getCartBadgeSize(BuildContext context) {
    final screenType = getScreenTypeDetailed(context);
    switch (screenType) {
      case ScreenTypeDetailed.extraSmall:
        return 12.0;
      case ScreenTypeDetailed.small:
        return 14.0;
      case ScreenTypeDetailed.medium:
        return 16.0;
      default:
        return 16.0;
    }
  }

  static double getCartBadgeFontSize(BuildContext context) {
    final screenType = getScreenTypeDetailed(context);
    switch (screenType) {
      case ScreenTypeDetailed.extraSmall:
        return 7.0;
      case ScreenTypeDetailed.small:
        return 8.0;
      case ScreenTypeDetailed.medium:
        return 9.0;
      default:
        return 9.0;
    }
  }

  // ============ IMAGE SIZES ============
  static double getProductImageSize(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return 80.0;
      case ScreenType.tablet:
        return 200.0;
      default:
        return 120.0;
    }
  }

  static double getAvatarSize(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return 30.0;
      case ScreenType.tablet:
        return 60.0;
      default:
        return 40.0;
    }
  }

  // ============ LIST VIEW SETTINGS ============
  static double getListItemHeight(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return 60.0;
      case ScreenType.tablet:
        return 100.0;
      default:
        return 72.0;
    }
  }

  static double getListTileSpacing(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return 8.0;
      case ScreenType.tablet:
        return 20.0;
      default:
        return 12.0;
    }
  }

  // ============ DIALOG SIZES ============
  static double getDialogWidth(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return MediaQuery.of(context).size.width * 0.9;
      case ScreenType.tablet:
        return 500.0;
      default:
        return MediaQuery.of(context).size.width * 0.85;
    }
  }

  static double getDialogHeight(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return MediaQuery.of(context).size.height * 0.5;
      case ScreenType.tablet:
        return 400.0;
      default:
        return MediaQuery.of(context).size.height * 0.45;
    }
  }

  // ============ CUP QUEST SPECIFIC METHODS (AGGRESSIVELY REDUCED) ============
  static double getCupQuestTitleSize(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return 12.0; // Was 14
      case ScreenType.tablet:
        return 16.0; // Was 20
      default:
        return 14.0; // Was 16
    }
  }

  static double getCupQuestNumberSize(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return 13.0; // Was 16
      case ScreenType.tablet:
        return 20.0; // Was 26
      default:
        return 16.0; // Was 20
    }
  }

  static double getCupQuestLabelSize(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return 8.0; // Was 9
      case ScreenType.tablet:
        return 11.0; // Was 13
      default:
        return 9.0; // Was 11
    }
  }

  static double getCupQuestSubtitleSize(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return 9.0; // Was 10
      case ScreenType.tablet:
        return 11.0; // Was 13
      default:
        return 10.0; // Was 11
    }
  }

  static double getCupQuestMilestoneSize(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return 8.0; // Was 9
      case ScreenType.tablet:
        return 10.0; // Was 12
      default:
        return 9.0; // Was 10
    }
  }

  static double getCupQuestRewardTextSize(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return 16.0; // Was 20
      case ScreenType.tablet:
        return 24.0; // Was 30
      default:
        return 20.0; // Was 24
    }
  }

  // Cup Quest circle/bean sizes (AGGRESSIVELY REDUCED)
  static double getCupQuestBeanSize(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return 16.0; // Was 20
      case ScreenType.tablet:
        return 22.0; // Was 28
      default:
        return 19.0; // Was 24
    }
  }

  static double getCupQuestBeanIconSize(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return 9.0; // Was 12
      case ScreenType.tablet:
        return 12.0; // Was 16
      default:
        return 10.0; // Was 14
    }
  }

  static double getCupQuestBeanSpacing(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return 4.0; // Was 6
      case ScreenType.tablet:
        return 6.0; // Was 8
      default:
        return 5.0; // Was 7
    }
  }

  static double getCupQuestCardIconSize(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return 38.0; // Was 48
      case ScreenType.tablet:
        return 52.0; // Was 64
      default:
        return 44.0; // Was 56
    }
  }

  static double getCupQuestBackgroundImageSize(BuildContext context) {
    final screenType = SiporaTheme.getScreenType(context);
    switch (screenType) {
      case ScreenType.small:
        return 70.0; // Was 100
      case ScreenType.tablet:
        return 110.0; // Was 140
      default:
        return 80.0; // Was 100
    }
  }

  // ============ NEW: METHODS THAT USE SIPORA THEME EXTENSION ============
  static Color getDynamicTextColor(BuildContext context) {
    return context.siporaTheme.textDark;
  }

  static Color getDynamicBorderColor(BuildContext context) {
    return context.siporaTheme.border;
  }

  static Color getDynamicCardColor(BuildContext context) {
    return context.siporaTheme.white;
  }

  static Color getDynamicBackgroundColor(BuildContext context) {
    return context.siporaTheme.cream;
  }
}

// Extension for easier access throughout the app
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  double get bottomPadding => MediaQuery.of(this).padding.bottom;
  double get topPadding => MediaQuery.of(this).padding.top;

  // Screen type checkers using SiporaTheme
  bool get isSmallScreen => SiporaTheme.getScreenType(this) == ScreenType.small;
  bool get isNormalScreen =>
      SiporaTheme.getScreenType(this) == ScreenType.normal;
  bool get isTabletScreen =>
      SiporaTheme.getScreenType(this) == ScreenType.tablet;

  // Additional screen checkers using detailed breakpoints
  bool get isExtraSmallScreen =>
      ResponsiveConstants.getScreenTypeDetailed(this) ==
      ScreenTypeDetailed.extraSmall;
  bool get isMediumScreen =>
      ResponsiveConstants.getScreenTypeDetailed(this) ==
      ScreenTypeDetailed.medium;
  bool get isLargeScreen =>
      ResponsiveConstants.getScreenTypeDetailed(this) ==
      ScreenTypeDetailed.large;
  bool get isExtraLargeScreen =>
      ResponsiveConstants.getScreenTypeDetailed(this) ==
      ScreenTypeDetailed.extraLarge;

  // Quick access to responsive values
  double get responsiveIconSize => ResponsiveConstants.getIconSize(this);
  double get responsiveFontSize => ResponsiveConstants.getFontSize(this);
  double get responsiveTitleSize => ResponsiveConstants.getTitleFontSize(this);
  double get responsiveHeadingSize =>
      ResponsiveConstants.getHeadingFontSize(this);
  double get responsivePadding => ResponsiveConstants.getScreenPadding(this);
  double get responsiveCardRadius =>
      ResponsiveConstants.getCardBorderRadius(this);
  double get responsiveButtonHeight =>
      ResponsiveConstants.getButtonHeight(this);
  double get responsiveButtonFontSize =>
      ResponsiveConstants.getButtonFontSize(this);
  double get responsiveGridSpacing => ResponsiveConstants.getGridSpacing(this);
  double get responsiveCardPadding => ResponsiveConstants.getCardPadding(this);

  // Cup Quest specific responsive values (AGGRESSIVELY REDUCED)
  double get cupQuestTitleSize =>
      ResponsiveConstants.getCupQuestTitleSize(this);
  double get cupQuestNumberSize =>
      ResponsiveConstants.getCupQuestNumberSize(this);
  double get cupQuestLabelSize =>
      ResponsiveConstants.getCupQuestLabelSize(this);
  double get cupQuestSubtitleSize =>
      ResponsiveConstants.getCupQuestSubtitleSize(this);
  double get cupQuestMilestoneSize =>
      ResponsiveConstants.getCupQuestMilestoneSize(this);
  double get cupQuestRewardTextSize =>
      ResponsiveConstants.getCupQuestRewardTextSize(this);

  // Cup Quest size getters
  double get cupQuestBeanSize => ResponsiveConstants.getCupQuestBeanSize(this);
  double get cupQuestBeanIconSize =>
      ResponsiveConstants.getCupQuestBeanIconSize(this);
  double get cupQuestBeanSpacing =>
      ResponsiveConstants.getCupQuestBeanSpacing(this);
  double get cupQuestCardIconSize =>
      ResponsiveConstants.getCupQuestCardIconSize(this);
  double get cupQuestBackgroundImageSize =>
      ResponsiveConstants.getCupQuestBackgroundImageSize(this);

  // Helper method for responsive values with detailed breakpoints
  T responsiveDetailed<T>({
    required T defaultValue,
    T? extraSmall,
    T? small,
    T? large,
    T? extraLarge,
  }) {
    return ResponsiveConstants.responsive(
      this,
      defaultValue: defaultValue,
      extraSmall: extraSmall,
      small: small,
      large: large,
    );
  }

  // Helper method for responsive values with simple breakpoints (small/normal/tablet)
  T responsiveSimple<T>({required T defaultValue, T? small, T? tablet}) {
    return ResponsiveConstants.responsiveSimple(
      this,
      defaultValue: defaultValue,
      small: small,
      tablet: tablet,
    );
  }

  // Quick access to theme extension colors with responsive support
  Color get siporaTextDark => ResponsiveConstants.getDynamicTextColor(this);
  Color get siporaBorder => ResponsiveConstants.getDynamicBorderColor(this);
  Color get siporaCardColor => ResponsiveConstants.getDynamicCardColor(this);
  Color get siporaBackground =>
      ResponsiveConstants.getDynamicBackgroundColor(this);
}
