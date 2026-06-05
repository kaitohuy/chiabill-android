import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/app_colors.dart';
import '../../../controllers/join_trip_controller.dart';
import '../qr_scanner_screen.dart';

class JoinTripDialog {
  static void show(BuildContext context) {
    final JoinTripController joinController = Get.put(JoinTripController());
    joinController.codeController.clear();
    joinController.inviteInfo.value = null;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Obx(() {
          if (joinController.inviteInfo.value == null) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/join_trip.gif',
                  height: 100,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.group_add, size: 60, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                const Text("Tham gia nhóm", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("Nhập mã mời hoặc quét mã QR do bạn bè chia sẻ để tham gia.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 24),

                TextField(
                  controller: joinController.codeController,
                  decoration: InputDecoration(
                    labelText: "Mã mời (VD: abcd-1234)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.keyboard),
                  ),
                ),
                const SizedBox(height: 16),

                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary
                  ),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text("Quét mã QR"),
                  onPressed: () async {
                    final String? scannedCode = await Get.to(() => const QRScannerScreen());
                    if (scannedCode != null && scannedCode.isNotEmpty) {
                      joinController.codeController.text = scannedCode;
                      joinController.checkInviteCode();
                    }
                  },
                ),
              ],
            );
          } else {
            final info = joinController.inviteInfo.value!;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: Text("🎉 Tìm thấy chuyến đi!", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16))),
                const Divider(height: 24),
                Text("Tên chuyến: ${info.tripName}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Text("Người tạo: ${info.createdByName}", style: TextStyle(color: Colors.grey[700])),
                Text("Thành viên hiện tại: ${info.memberCount} người", style: TextStyle(color: Colors.grey[700])),
              ],
            );
          }
        }),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              Get.delete<JoinTripController>();
            },
            child: const Text("HỦY", style: TextStyle(color: Colors.grey)),
          ),
          Obx(() {
            if (joinController.inviteInfo.value == null) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                onPressed: joinController.isLoading.value ? null : () => joinController.checkInviteCode(),
                child: joinController.isLoading.value
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("KIỂM TRA"),
              );
            } else {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                onPressed: joinController.isLoading.value ? null : () => joinController.confirmJoin(),
                child: joinController.isLoading.value
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("XÁC NHẬN"),
              );
            }
          }),
        ],
      ),
    ).then((_) {
      Get.delete<JoinTripController>();
    });
  }
}
