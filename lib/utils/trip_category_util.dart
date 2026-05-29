import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TripCategoryUtil {
  static final List<Map<String, dynamic>> categories = [
    {"name": "Biển", "icon": Icons.beach_access, "iconName": "beach_access", "color": Colors.blue},
    {"name": "Núi", "icon": Icons.terrain, "iconName": "terrain", "color": Colors.green},
    {"name": "Bể bơi", "icon": Icons.pool, "iconName": "pool", "color": Colors.cyan},
    {"name": "TTTM", "icon": Icons.local_mall, "iconName": "local_mall", "color": Colors.purple},
    {"name": "Di tích", "icon": Icons.account_balance, "iconName": "account_balance", "color": Colors.brown},
    {"name": "Cafe", "icon": Icons.local_cafe, "iconName": "local_cafe", "color": Colors.orange},
    {"name": "Nhà hàng", "icon": Icons.restaurant, "iconName": "restaurant", "color": Colors.red},
    {"name": "Cắm trại", "icon": Icons.park, "iconName": "park", "color": Colors.green[700]!},
    {"name": "Khác", "icon": Icons.category, "iconName": "category", "color": Colors.grey},
  ];

  static IconData getIconData(String? iconName) {
    if (iconName == null) return Icons.flight_land;
    final category = categories.firstWhere(
      (cat) => cat["iconName"] == iconName, 
      orElse: () => categories.last
    );
    return category["icon"] as IconData;
  }

  static Color getColor(String? iconName) {
    if (iconName == null) return AppColors.primary;
    final category = categories.firstWhere(
      (cat) => cat["iconName"] == iconName, 
      orElse: () => categories.last
    );
    return category["color"] as Color;
  }

  static String getName(String? iconName) {
    if (iconName == null) return "Chuyến đi";
    final category = categories.firstWhere(
      (cat) => cat["iconName"] == iconName, 
      orElse: () => categories.last
    );
    return category["name"] as String;
  }
}
