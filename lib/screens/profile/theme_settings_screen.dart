import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/theme_controller.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_colors.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Tùy chỉnh giao diện", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Chọn một chủ đề màu sắc yêu thích. Giao diện sẽ tự động được làm mới ngay lập tức.",
              style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 30),
            Obx(() {
              final currentThemeId = themeController.currentTheme.value.id;
              return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: AppThemes.presets.length,
              itemBuilder: (context, index) {
                final preset = AppThemes.presets[index];
                final isSelected = currentThemeId == preset.id;
                
                return GestureDetector(
                  onTap: () => themeController.changeTheme(preset.id),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? preset.primary : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(color: preset.primary.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))
                      ] : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: preset.primary,
                            shape: BoxShape.circle,
                          ),
                          child: isSelected 
                              ? const Icon(Icons.check, color: Colors.white, size: 28)
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          preset.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? preset.primary : Colors.black87,
                            fontSize: 14,
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            );
            }),
          ],
        ),
      ),
    );
  }
}
