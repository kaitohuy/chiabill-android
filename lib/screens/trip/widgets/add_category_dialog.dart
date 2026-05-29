import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/toast_util.dart';
import '../../../../controllers/add_expense_controller.dart';
import '../../../../data/models/trip_response.dart';

class AddCategoryDialog extends StatelessWidget {
  final AddExpenseController controller;
  final TripResponse trip;

  const AddCategoryDialog({
    super.key,
    required this.controller,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    final nameCtrl = TextEditingController();
    // Danh sách Emoji phổ biến cho các danh mục chi tiêu
    final List<String> popularEmojis = [
      "🍕", "🍹", "🚩", "📸", "🐶", "🐱", "👶", "💆‍♀️",
      "💇‍♂️", "💍", "📚", "🎨", "🔧", "⚙️", "✨", "🔥",
      "💡", "💳", "📱", "💻", "⚽", "🎫", "🧸", "🧧"
    ];

    // Biến lưu icon đang được chọn (Mặc định chọn cái đầu tiên)
    final RxString selectedEmoji = popularEmojis.first.obs;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Tạo danh mục mới", style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: "Tên danh mục (VD: Tiền trạm)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.edit, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "THÔNG TIN CHI TIẾT", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2, color: Colors.grey)
            ),
            const SizedBox(height: 16),
            Text(
              "Chuyến đi: ${trip.name}",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)
            ),
            const SizedBox(height: 16),

            const Text("Chọn một biểu tượng:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 12),

            // KHUNG CHỌN EMOJI
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: popularEmojis.map((emoji) {
                return Obx(() {
                  bool isSelected = selectedEmoji.value == emoji;
                  return GestureDetector(
                    onTap: () => selectedEmoji.value = emoji,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryLight : Colors.grey.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.grey.shade300,
                          width: isSelected ? 2 : 1
                        )
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                });
              }).toList(),
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text("HỦY", style: TextStyle(color: Colors.grey))
        ),
        Obx(() => ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary, 
            foregroundColor: Colors.white
          ),
          onPressed: controller.isLoading.value ? null : () {
            if (nameCtrl.text.trim().isEmpty) {
              ToastUtil.showWarning("Thiếu thông tin", "Vui lòng nhập tên danh mục");
              return;
            }
            // Gọi API tạo danh mục với tên và emoji đã chọn
            controller.createNewCategory(nameCtrl.text.trim(), selectedEmoji.value);
          },
          child: controller.isLoading.value
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("TẠO MỚI"),
        )),
      ],
    );
  }
}
