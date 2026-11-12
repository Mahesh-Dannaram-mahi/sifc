// lib/utils/screen_utils.dart

import 'package:flutter/material.dart';

/// Screen utility extensions for responsive design
extension ScreenUtils on BuildContext {
  /// Returns true if the screen width is 600dp or more (tablet)
  bool get isTablet {
    final width = MediaQuery.of(this).size.width;
    return width >= 600;
  }

  /// Returns true if the screen width is less than 360dp (small phone)
  bool get isSmallScreen {
    final width = MediaQuery.of(this).size.width;
    return width < 360;
  }
}
