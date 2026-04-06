import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/repositories/invitation_repository.dart';
import '../data/models/invite_info_response.dart';
import 'home_controller.dart';

class JoinTripController extends GetxController {
  final InvitationRepository _repository = InvitationRepository();
  final codeController = TextEditingController();

  var isLoading = false.obs;
  var inviteInfo = Rxn<InviteInfoResponse>(); // Biến lưu thông tin preview chuyến đi

  // 1. Hàm kiểm tra mã
  // Trong hàm checkInviteCode()
  Future<void> checkInviteCode() async {
    String code = codeController.text.trim();
    if (code.isEmpty) return;

    isLoading.value = true;
    final result = await _repository.getInviteInfo(code);

    if (result.success && result.data != null) {
      inviteInfo.value = result.data;
    } else {
      // Dùng ScaffoldMessenger thay cho Get.snackbar
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(content: Text(result.message ?? "Mã không hợp lệ"), backgroundColor: Colors.redAccent),
      );
      inviteInfo.value = null;
    }
    isLoading.value = false;
  }

  // Trong hàm confirmJoin()
  Future<void> confirmJoin() async {
    String code = codeController.text.trim();
    isLoading.value = true;
    final result = await _repository.joinByInvite(code);

    if (result.success) {
      Get.back(); // Đóng popup
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        const SnackBar(content: Text("Chào mừng bạn đến với chuyến đi!"), backgroundColor: Colors.green),
      );
      Get.find<HomeController>().fetchTrips();
    } else {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(content: Text(result.message ?? "Không thể tham gia"), backgroundColor: Colors.redAccent),
      );
    }
    isLoading.value = false;
  }

  @override
  void onClose() {
    codeController.dispose();
    super.onClose();
  }
}