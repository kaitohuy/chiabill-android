import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/create_trip_controller.dart';

class CreateTripBottomSheet extends StatelessWidget {
  CreateTripBottomSheet({super.key});

  final CreateTripController controller = Get.put(CreateTripController());

  @override
  Widget build(BuildContext context) {
    return Container(
      // Chỉ cần padding cố định, không cộng thêm bàn phím nữa
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Tạo chuyến đi mới", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.lightGreen)),
            const SizedBox(height: 24),

            // Ô nhập tên chuyến đi
            TextField(
              controller: controller.nameController,
              decoration: InputDecoration(
                labelText: "Tên chuyến đi (VD: Vũng Tàu 2 ngày 1 đêm)",
                prefixIcon: const Icon(Icons.map, color: Colors.lightGreen),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.lightGreen, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ô nhập mô tả
            TextField(
              controller: controller.descController,
              decoration: InputDecoration(
                labelText: "Mô tả (Không bắt buộc)",
                prefixIcon: const Icon(Icons.description, color: Colors.lightGreen),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Nút Tạo mới
            Obx(() => SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen,
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