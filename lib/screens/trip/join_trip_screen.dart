import 'package:chiabill/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/join_trip_controller.dart';
import '../../routes/app_pages.dart';

class JoinTripScreen extends StatefulWidget {
  const JoinTripScreen({super.key});

  @override
  State<JoinTripScreen> createState() => _JoinTripScreenState();
}

class _JoinTripScreenState extends State<JoinTripScreen> {
  final JoinTripController controller = Get.find<JoinTripController>();
  late String inviteCode;

  @override
  void initState() {
    super.initState();
    // Lấy inviteCode từ arguments (do AppLinksService truyền vào)
    inviteCode = Get.arguments?.toString() ?? "";
    
    if (inviteCode.isNotEmpty) {
      controller.codeController.text = inviteCode;
      // Tự động kiểm tra mã mời ngay khi vào màn hình
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.checkInviteCode();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("join_trip_title".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.inviteInfo.value == null) {
          return Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (controller.inviteInfo.value == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(
                    "invite_code_invalid".tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Get.offAllNamed(Routes.MAIN),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    child: Text("back_to_home".tr),
                  )
                ],
              ),
            ),
          );
        }

        final info = controller.inviteInfo.value!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryBackgroundLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.celebration, size: 50, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Text(
                "invited_to_join".tr,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 32),
              
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.map, "Chuyến đi".tr, info.tripName),
                      const Divider(height: 32),
                      _buildInfoRow(Icons.person, "invited_by".tr, info.createdByName),
                      const Divider(height: 32),
                      _buildInfoRow(Icons.group, "members_count".tr, "${info.memberCount} ${'people'.tr}"),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value ? null : () => controller.confirmJoin(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text("confirm_join".tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: () => Get.offAllNamed(Routes.MAIN),
                child: Text("guide_later".tr, style: const TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}