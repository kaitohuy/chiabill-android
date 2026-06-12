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
      title: const Text("Thêm thành viên", style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Nhập Email hoặc SĐT người dùng đã đăng ký app.", style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 20),
          TextField(
            controller: inputController,
            decoration: InputDecoration(
              hintText: "VD: 0987654321",
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
          child: const Text("HỦY", style: TextStyle(color: Colors.grey)),
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
              : const Text("THÊM"),
        )),
      ],
    );
  }
}
