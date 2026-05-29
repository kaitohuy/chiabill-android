import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/calculator_controller.dart';
import '../../../theme/app_colors.dart';

class CalculatorHistorySheet extends StatelessWidget {
  final CalculatorController controller = Get.find();

  CalculatorHistorySheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Lịch sử", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () {
                    if (controller.history.isNotEmpty) {
                      _confirmClearHistory(context);
                    }
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  label: const Text("Xóa", style: TextStyle(color: Colors.red)),
                )
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.history.isEmpty) {
                return const Center(
                  child: Text("Chưa có lịch sử tính toán", style: TextStyle(color: Colors.grey, fontSize: 16)),
                );
              }
              
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: controller.history.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final equation = controller.history[index];
                  // Phân tách phép tính và kết quả để hiển thị đẹp hơn
                  final parts = equation.split('=');
                  final expr = parts[0].trim();
                  final res = parts.length > 1 ? parts[1].trim() : '';

                  return InkWell(
                    onTap: () => controller.applyHistoryItem(equation),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(expr, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text("= $res", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _confirmClearHistory(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Xóa lịch sử?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Bạn có chắc chắn muốn xóa toàn bộ lịch sử tính toán?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              Get.back();
              controller.clearHistory();
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
