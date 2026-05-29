import 'package:chiabill/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/create_trip_controller.dart';

import '../../utils/trip_category_util.dart';

class CreateTripBottomSheet extends StatelessWidget {
  CreateTripBottomSheet({super.key});

  final CreateTripController controller = Get.put(CreateTripController());

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24, 
        right: 24, 
        top: 24, 
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Tạo chuyến đi mới", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 24),

            TextField(
              controller: controller.nameController,
              maxLength: 100,
              decoration: InputDecoration(
                labelText: "Tên chuyến đi (VD: Vũng Tàu 2N1Đ)",
                prefixIcon: Icon(Icons.map, color: AppColors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                counterText: "", // Ẩn bộ đếm chữ xấu xí nếu không cần
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: controller.descController,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: "Mô tả (Không bắt buộc)",
                prefixIcon: Icon(Icons.description, color: AppColors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                counterText: "", // Ẩn bộ đếm
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            const Text("Chủ đề chuyến đi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: TripCategoryUtil.categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final cat = TripCategoryUtil.categories[index];
                  return Obx(() {
                    final isSelected = controller.selectedCategoryName.value == cat["name"];
                    return GestureDetector(
                      onTap: () {
                        controller.selectedCategoryName.value = cat["name"];
                        controller.selectedCategoryIcon.value = cat["iconName"];
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isSelected ? cat["color"] : (cat["color"] as Color).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              cat["icon"] as IconData,
                              color: isSelected ? Colors.white : cat["color"],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat["name"] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? AppColors.primary : Colors.grey[600],
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  });
                },
              ),
            ),
            const SizedBox(height: 24),

            Obx(() => SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: controller.isLoading.value ? null : () => controller.createTrip(),
                child: controller.isLoading.value
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("TẠO CHUYẾN ĐI", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )),
          ],
        ),
      ),
    );
  }
}