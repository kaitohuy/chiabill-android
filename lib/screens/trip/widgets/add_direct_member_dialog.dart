import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../theme/app_colors.dart';
import '../../../../controllers/trip_detail_controller.dart';

class AddDirectMemberDialog extends StatefulWidget {
  final TripDetailController controller;
  const AddDirectMemberDialog({super.key, required this.controller});

  @override
  State<AddDirectMemberDialog> createState() => _AddDirectMemberDialogState();
}

class _AddDirectMemberDialogState extends State<AddDirectMemberDialog> {
  late TextEditingController inputController;

  @override
  void initState() {
    super.initState();
    inputController = TextEditingController();
  }

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text("add_member".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("add_direct_member_instruction".tr, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 20),
          TextField(
            controller: inputController,
            decoration: InputDecoration(
              hintText: "add_direct_member_hint".tr,
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
          child: Text("cancel_caps".tr, style: const TextStyle(color: Colors.grey)),
        ),
        Obx(() => ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: widget.controller.isAddingMember.value
              ? null
              : () => widget.controller.addDirectMember(inputController.text),
          child: widget.controller.isAddingMember.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text("add_caps".tr),
        )),
      ],
    );
  }
}
