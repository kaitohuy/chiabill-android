import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import thư viện này để dùng Clipboard
import 'package:get/get.dart';
import '../data/repositories/invitation_repository.dart';

class InviteController extends GetxController {
  final int tripId;
  InviteController(this.tripId);

  final InvitationRepository _repository = InvitationRepository();
  final customCodeController = TextEditingController();

  var isLoading = false.obs;
  var generatedCode = "".obs; // Biến lưu mã sau khi tạo thành công

  @override
  void onInit() {
    super.onInit();
    checkExistingInvite();
  }

  Future<void> checkExistingInvite() async {
    isLoading.value = true;
    final result = await _repository.getActiveInvite(tripId);
    if (result.success && result.data != null) {
      generatedCode.value = result.data!.inviteCode; // Nếu có rồi thì hiện luôn!
    }
    isLoading.value = false;
  }

  Future<void> generateCode() async {
    isLoading.value = true;
    String custom = customCodeController.text.trim();

    final result = await _repository.createInvite(
        tripId,
        customCode: custom.isNotEmpty ? custom : null
    );

    if (result.success && result.data != null) {
      generatedCode.value = result.data!.inviteCode;
    } else {
      Get.snackbar("Lỗi", result.message ?? "Không thể tạo mã, có thể mã này đã bị trùng!");
    }
    isLoading.value = false;
  }

  // Hàm Copy vào Clipboard
  void copyToClipboard() {
    if (generatedCode.value.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: generatedCode.value));
      Get.snackbar(
        "Thành công",
        "Đã copy mã: ${generatedCode.value}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  @override
  void onClose() {
    customCodeController.dispose();
    super.onClose();
  }
}