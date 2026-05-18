import 'package:flutter/material.dart';

class AppPalette {
  static const Color white = Color(0xFFFFFFFF);
  static const Color silver = Color(0xFFE5E5E5);
  static const Color gold = Color(0xFFFCA311);
  static const Color navy = Color(0xFF14213D);
  static const Color black = Color(0xFF000000);
  static const Color success = Color(0xFF0F766E);
  static const Color danger = Color(0xFFB91C1C);
  static const Color canvas = Color(0xFFFCFAF5);
  static const Color canvasStrong = Color(0xFFF2EFE6);
  static const Color surfaceMuted = Color(0xFFF7F4EC);
  static const Color border = Color(0xFFD7D3C8);
  static const Color textMuted = Color(0xFF546079);
  static const Color subtleGold = Color(0x24FCA311);
  static const Color subtleNavy = Color(0x1A14213D);
  static const Color subtleBlack = Color(0x0F000000);
  static const Color overlayOnDark = Color(0xC7FFFFFF);
  static const Color dividerOnDark = Color(0x29FFFFFF);

  static Color indicatorForValue(double value) {
    if (value < 0) {
      return danger;
    }
    if (value > 0) {
      return success;
    }
    return navy;
  }
}
