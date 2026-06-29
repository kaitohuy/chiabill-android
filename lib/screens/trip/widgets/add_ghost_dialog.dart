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
      title: Text("add_ghost_member".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("add_ghost_member_instruction".tr, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          TextField(
            controller: ghostController.namesController,
            decoration: InputDecoration(
              hintText: "add_ghost_member_hint".tr,
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
          child: Text("cancel_caps".tr),
        ),
        Obx(() => ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: ghostController.isLoading.value ? null : () => ghostController.submitGhosts(),
          child: Text("confirm_caps".tr),
        )),
      ],
    );
  }
}
