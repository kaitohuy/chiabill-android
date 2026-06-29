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
                Text("join_group".tr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("join_group_hint".tr, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 24),

                TextField(
                  controller: joinController.codeController,
                  decoration: InputDecoration(
                    labelText: "invite_code_hint".tr,
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
                  label: Text("scan_qr".tr),
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
                Center(child: Text("trip_found".tr, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16))),
                const Divider(height: 24),
                Text("trip_name_label".trParams({'name': info.tripName}), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Text("creator_label".trParams({'name': info.createdByName}), style: TextStyle(color: Colors.grey[700])),
                Text("members_count_label".trParams({'count': info.memberCount.toString()}), style: TextStyle(color: Colors.grey[700])),
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
            child: Text("cancel_caps_alt".tr, style: const TextStyle(color: Colors.grey)),
          ),
          Obx(() {
            if (joinController.inviteInfo.value == null) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                onPressed: joinController.isLoading.value ? null : () => joinController.checkInviteCode(),
                child: joinController.isLoading.value
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text("check_caps".tr),
              );
            } else {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                onPressed: joinController.isLoading.value ? null : () => joinController.confirmJoin(),
                child: joinController.isLoading.value
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text("confirm_join".tr),
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
