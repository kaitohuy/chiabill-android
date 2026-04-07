import 'package:chiabill/utils/loading_util.dart';
import 'package:chiabill/utils/toast_util.dart';
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
      ToastUtil.showError("Lỗi", result.message ?? "Mã không hợp lệ");
      inviteInfo.value = null;
    }
    isLoading.value = false;
  }

  // 2. Hàm xác nhận tham gia
  Future<void> confirmJoin() async {
    String code = codeController.text.trim();
    try {
      isLoading.value = true;
      LoadingUtil.show();
      final result = await _repository.joinByInvite(code);

      if (result.success) {
        Get.back(); // Đóng popup
        ToastUtil.showSuccess("Chào mừng!", "Bạn đã tham gia chuyến đi thành công");
        Get.find<HomeController>().fetchTrips();
      } else {
        ToastUtil.showError("Thất bại", result.message ?? "Không thể tham gia");
      }
    } catch (e) {
      ToastUtil.showError("Lỗi hệ thống", "Đã xảy ra lỗi khi tham gia chuyến đi");
    } finally {
      isLoading.value = false;
      LoadingUtil.hide();
    }
  }

  @override
  void onClose() {
    codeController.dispose();
    super.onClose();
  }
}