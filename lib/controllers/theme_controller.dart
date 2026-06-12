import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../theme/app_theme.dart';

class ThemeController extends GetxController {
  final _storage = GetStorage();
  final String _themeKey = 'selected_theme';
  final String _scaleKey = 'text_scale';

  var currentTheme = AppThemes.emerald.obs;
  var textScale = 1.0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  void _loadTheme() {
    String? savedThemeId = _storage.read(_themeKey);
    if (savedThemeId != null) {
      currentTheme.value = AppThemes.getById(savedThemeId);
    }
    textScale.value = _storage.read(_scaleKey) ?? 1.0;
  }

  void changeTextScale(double scale) {
    textScale.value = scale.clamp(0.8, 1.2);
    _storage.write(_scaleKey, textScale.value);
  }

  ThemeData getThemeData() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: currentTheme.value.primary,
        primary: currentTheme.value.primary,
      ),
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.white, // Khóa màu trắng nền hệ thống
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark, // Nút hệ thống màu tối
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontWeight: FontWeight.normal,
        ),
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.normal,
        ),
      ),
      useMaterial3: true,
    );
  }

  void changeTheme(String themeId) {
    AppThemePreset newTheme = AppThemes.getById(themeId);
    currentTheme.value = newTheme;
    _storage.write(_themeKey, themeId);
    
    // Apply theme change
    Get.changeTheme(getThemeData());
  }
}
