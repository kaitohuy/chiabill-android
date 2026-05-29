import 'package:flutter/material.dart';

class AppThemePreset {
  final String id;
  final String name;
  final Color primary;

  const AppThemePreset({
    required this.id,
    required this.name,
    required this.primary,
  });
}

class AppThemes {
  static const emerald = AppThemePreset(
    id: 'emerald',
    name: 'Emerald Green',
    primary: Color(0xFF10B981),
  );

  static const ocean = AppThemePreset(
    id: 'ocean',
    name: 'Ocean Blue',
    primary: Color(0xFF0EA5E9),
  );

  static const sunset = AppThemePreset(
    id: 'sunset',
    name: 'Sunset Orange',
    primary: Color(0xFFF97316),
  );

  static const royal = AppThemePreset(
    id: 'royal',
    name: 'Royal Purple',
    primary: Color(0xFF8B5CF6),
  );

  static const cherry = AppThemePreset(
    id: 'cherry',
    name: 'Cherry Red',
    primary: Color(0xFFF43F5E),
  );

  static const List<AppThemePreset> presets = [
    emerald,
    ocean,
    sunset,
    royal,
    cherry,
  ];

  static AppThemePreset getById(String id) {
    return presets.firstWhere((p) => p.id == id, orElse: () => emerald);
  }
}
