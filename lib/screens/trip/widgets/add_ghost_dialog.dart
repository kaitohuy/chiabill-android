import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../theme/app_colors.dart';
import '../../../../controllers/ghost_controller.dart';

class AddGhostDialog extends StatefulWidget {
  final int tripId;
  const AddGhostDialog({super.key, required this.tripId});

  @override
  State<AddGhostDialog> createState() => _AddGhostDialogState();
}

class _AddGhostDialogState extends State<AddGhostDialog> {
  late GhostController ghostController;

  @override
  void initState() {
    super.initState();
    ghostController = Get.put(GhostController(widget.tripId));
  }

  @override
  void dispose() {
    Get.delete<GhostController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Thêm người ảo", style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Nhập tên những người không dùng app (cách nhau bằng dấu phẩy).", style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 20),
          TextField(
            controller: ghostController.namesController,
            decoration: InputDecoration(
              hintText: "VD: Bố, Mẹ, Anh Hai...",
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text("HỦY"),
        ),
        Obx(() => ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: ghostController.isLoading.value ? null : () => ghostController.submitGhosts(),
          child: const Text("XÁC NHẬN"),
        )),
      ],
    );
  }
}
