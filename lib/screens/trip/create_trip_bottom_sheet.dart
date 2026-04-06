import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Thêm dòng này
import 'package:get/get.dart';
import '../../controllers/create_trip_controller.dart';
import '../../utils/currency_util.dart'; // Thêm dòng này

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
            const Text("Tạo chuyến đi mới", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.lightGreen)),
            const SizedBox(height: 24),

            TextField(
              controller: controller.nameController,
              decoration: InputDecoration(
                labelText: "Tên chuyến đi (VD: Vũng Tàu 2N1Đ)",
                prefixIcon: const Icon(Icons.map, color: Colors.lightGreen),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // ===================================
            // THÊM Ô NHẬP NGÂN SÁCH Ở ĐÂY
            // ===================================
            TextField(
              controller: controller.budgetController, // Nhớ khai báo budgetController trong CreateTripController
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
              ],
              decoration: InputDecoration(
                labelText: "Ngân sách dự kiến (Không bắt buộc)",
                prefixIcon: const Icon(Icons.account_balance_wallet, color: Colors.lightGreen),
                suffixText: "đ",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

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