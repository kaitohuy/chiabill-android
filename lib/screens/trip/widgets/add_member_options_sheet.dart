import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../theme/app_colors.dart';
import '../../../../controllers/trip_detail_controller.dart';
import '../import_member_screen.dart';
import 'add_direct_member_dialog.dart';
import 'add_ghost_dialog.dart';
import 'create_invite_dialog.dart';

class AddMemberOptionsSheet extends StatelessWidget {
  final TripDetailController controller;
  const AddMemberOptionsSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 20, left: 0, right: 0, bottom: 20 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Thêm thành viên", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildActionItem(
            Icons.person_outline, 
            "Người ảo (không dùng app)", 
            "Tạo tài khoản giả để bạn chia tiền thay họ.", 
            () {
              Get.back();
              Get.dialog(
                AddGhostDialog(tripId: controller.tripId),
              );
            },
          ),
          _buildActionItem(
            Icons.group_add_outlined, 
            "Nhập từ nhóm khác", 
            "Thêm nhanh thành viên từ nhóm bạn đã tham gia.", 
            () {
              Get.back();
              Get.to(() => ImportMemberScreen(currentTripId: controller.tripId));
            },
          ),
          _buildActionItem(
            Icons.search, 
            "Tìm qua SĐT / Email", 
            "Thêm người dùng đã đăng ký app vào nhóm.", 
            () {
              Get.back();
              Get.dialog(
                AddDirectMemberDialog(controller: controller),
              );
            },
          ),
          _buildActionItem(
            Icons.share_outlined, 
            "Chia sẻ mã mời", 
            "Gửi link hoặc mã QR cho bạn bè tự tham gia.", 
            () {
              Get.back();
              Get.dialog(
                CreateInviteDialog(controller: controller),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppColors.primaryDark),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      onTap: onTap,
    );
  }
}
