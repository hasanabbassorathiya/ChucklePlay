import 'package:flutter/material.dart';

class ResponsiveHelper {
  static double getCardWidth(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 1200) {
      return 160;
    } else if (screenWidth >= 600) {
      return 130;
    } else {
      return 110;
    }
  }

  static double getCardHeight(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 1200) {
      return 220;
    } else if (screenWidth >= 600) {
      return 190;
    } else {
      return 160;
    }
  }

  static int getCrossAxisCount(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 1200) {
      return 6;
    } else if (screenWidth >= 900) {
      return 5;
    } else if (screenWidth >= 600) {
      return 4;
    } else if (screenWidth >= 400) {
      return 3;
    } else {
      return 2;
    }
  }

  static bool isDesktopOrTV(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth >= 900;
  }

  static bool isTablet(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth >= 600 && screenWidth < 900;
  }

  static bool isPhone(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 600;
  }

  static double getHeroHeight(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 900) {
      return 500;
    } else if (screenWidth >= 600) {
      return 400;
    } else {
      return 300;
    }
  }

  static double getHeroTitleSize(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 900) {
      return 48;
    } else if (screenWidth >= 600) {
      return 36;
    } else {
      return 28;
    }
  }

  static double getStbCardWidth(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 900) {
      return 240;
    } else if (screenWidth >= 600) {
      return 200;
    } else {
      return 160;
    }
  }
}
