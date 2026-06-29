import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../theme/app_colors.dart';
import '../../../../controllers/trip_detail_controller.dart';

class CreateInviteDialog extends StatefulWidget {
  final TripDetailController controller;
  const CreateInviteDialog({super.key, required this.controller});

  @override
  State<CreateInviteDialog> createState() => _CreateInviteDialogState();
}

class _CreateInviteDialogState extends State<CreateInviteDialog> {
  late TextEditingController customCodeController;

  @override
  void initState() {
    super.initState();
    customCodeController = TextEditingController();
  }

  @override
  void dispose() {
    customCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Obx(() {
        if (widget.controller.activeInviteCode.value.isNotEmpty) {
          String inviteCode = widget.controller.activeInviteCode.value;
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("join_invite_code".tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                QrImageView(
                  data: inviteCode,
                  version: QrVersions.auto,
                  size: 200.0,
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Colors.black87),
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: Colors.black87),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                  child: Text(inviteCode, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.share),
                    label: Text("share_link_caps".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => widget.controller.shareInviteLink(),
                  ),
                ),
              ],
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("create_invite_code".tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text("invite_code_auto_hint".tr, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 24),
                TextField(
                  controller: customCodeController,
                  decoration: InputDecoration(
                    hintText: "custom_code_hint".tr,
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: widget.controller.isLoading.value
                        ? null
                        : () => widget.controller.generateInviteCode(customCodeController.text),
                    child: Text("generate_code_caps".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        }
      }),
    );
  }
}
