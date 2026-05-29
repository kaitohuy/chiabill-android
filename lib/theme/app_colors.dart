import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppColors {
  // Trả về màu Primary hiện tại của Theme
  static Color get primary => Get.theme.colorScheme.primary;

  // Lấy các sắc độ động
  static Color get primaryDark => _darken(primary, 0.2);
  static Color get primaryDarker => _darken(primary, 0.4);
  static Color get primaryLight => _lighten(primary, 0.2);
  static Color get primaryLighter => _lighten(primary, 0.4);
  
  // Background nhẹ nhàng
  static Color get primaryBackground => primary.withValues(alpha: 0.1);
  static Color get primaryBackgroundLight => primary.withValues(alpha: 0.05);

  // Helper functions
  static Color _darken(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  static Color _lighten(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }
}
