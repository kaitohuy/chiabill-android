import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/user_guide_controller.dart';
import '../../theme/app_colors.dart';
import '../../utils/toast_util.dart';

class UserGuideSettingsScreen extends StatelessWidget {
  const UserGuideSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserGuideController>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("user_guide_title".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
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
            Text(
              "user_guide_desc".tr,
              style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 25),

            // Card Toggle Settings
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              color: Colors.white,
              child: Column(
                children: [
                  Obx(() => SwitchListTile(
                    activeThumbColor: AppColors.primary,
                    title: Text("guide_home_title".tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                    subtitle: Text("guide_home_desc".tr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    value: controller.guideHomeEnabled.value,
                    onChanged: (val) => controller.setGuideEnabled('home', val),
                  )),
                  const Divider(height: 1),
                  Obx(() => SwitchListTile(
                    activeThumbColor: AppColors.primary,
                    title: Text("guide_trip_detail_title".tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                    subtitle: Text("guide_trip_detail_desc".tr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    value: controller.guideTripDetailEnabled.value,
                    onChanged: (val) => controller.setGuideEnabled('trip_detail', val),
                  )),
                  const Divider(height: 1),
                  Obx(() => SwitchListTile(
                    activeThumbColor: AppColors.primary,
                    title: Text("guide_tourism_title".tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                    subtitle: Text("guide_tourism_desc".tr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    value: controller.guideTourismEnabled.value,
                    onChanged: (val) => controller.setGuideEnabled('tourism', val),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 35),

            // Section buttons
            Text(
              "quick_actions_label".tr,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // Reset button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.refresh, size: 20),
                label: Text("reset_guides_btn".tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onPressed: () {
                  controller.resetAllGuides();
                  ToastUtil.showSuccess("reset_guides_success_title".tr, "reset_guides_success_msg".tr);
                },
              ),
            ),
            const SizedBox(height: 12),

            // Demo trigger button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.play_circle_outline, size: 20),
                label: Text("try_home_guide_btn".tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onPressed: () {
                  controller.setGuideEnabled('home', true);
                  Get.offAllNamed('/main'); // Quay về màn hình chính và khởi chạy tour
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
