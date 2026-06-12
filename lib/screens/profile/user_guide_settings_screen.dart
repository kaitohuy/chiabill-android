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
        title: const Text("Hướng dẫn sử dụng", style: TextStyle(fontWeight: FontWeight.bold)),
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
              "Tùy chỉnh bật/tắt các tour hướng dẫn nhanh. Khi kích hoạt, hướng dẫn sẽ tự động hiển thị khi bạn truy cập vào màn hình tương ứng.",
              style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
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
                    title: const Text("Màn hình chính (Trang chủ)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                    subtitle: const Text("Hướng dẫn tạo chuyến đi, quét QR, máy tính và thông báo.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    value: controller.guideHomeEnabled.value,
                    onChanged: (val) => controller.setGuideEnabled('home', val),
                  )),
                  const Divider(height: 1),
                  Obx(() => SwitchListTile(
                    activeThumbColor: AppColors.primary,
                    title: const Text("Chi tiết chuyến đi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                    subtitle: const Text("Hướng dẫn quản lý chi tiêu, quyết toán nợ và lên lịch trình.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    value: controller.guideTripDetailEnabled.value,
                    onChanged: (val) => controller.setGuideEnabled('trip_detail', val),
                  )),
                  const Divider(height: 1),
                  Obx(() => SwitchListTile(
                    activeThumbColor: AppColors.primary,
                    title: const Text("Bản đồ du lịch", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                    subtitle: const Text("Hướng dẫn tìm địa điểm du lịch, xem bản đồ và lọc danh mục.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    value: controller.guideTourismEnabled.value,
                    onChanged: (val) => controller.setGuideEnabled('tourism', val),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 35),

            // Section buttons
            const Text(
              "Thao tác nhanh",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
                label: const Text("ĐẶT LẠI TOÀN BỘ HƯỚNG DẪN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onPressed: () {
                  controller.resetAllGuides();
                  ToastUtil.showSuccess("Thành công", "Đã bật lại toàn bộ hướng dẫn cho lần truy cập sau!");
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
                label: const Text("XEM THỬ HƯỚNG DẪN TRANG CHỦ NGAY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
