import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// Main content width used for pages
  static double contentWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= 600) {
      return 700;
    }

    return width;
  }

  /// Standard page horizontal padding
  static double horizontalPadding(BuildContext context) {
    return isTablet(context) ? 32 : 16;
  }

  /// Standard page vertical padding
  static double verticalPadding(BuildContext context) {
    return isTablet(context) ? 24 : 16;
  }

  static double messageWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return isTablet(context) ? width * 0.55 : width * 0.75;
  }

  static double iconSize(BuildContext context) {
    return isTablet(context) ? 24 : 20;
  }

  static double avatarRadius(BuildContext context) {
    return isTablet(context) ? 20 : 16;
  }

  static double bodyFont(BuildContext context) {
    return isTablet(context) ? 15 : 13;
  }

  static double titleFont(BuildContext context) {
    return isTablet(context) ? 22 : 18;
  }

  static double buttonHeight(BuildContext context) {
    return isTablet(context) ? 56 : 48;
  }
}
