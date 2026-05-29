import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../theme/app_theme.dart';

class ThemeController extends GetxController {
  final _storage = GetStorage();
  final String _themeKey = 'selected_theme';

  var currentTheme = AppThemes.emerald.obs;

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
  }

  ThemeData getThemeData() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: currentTheme.value.primary,
        primary: currentTheme.value.primary,
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
