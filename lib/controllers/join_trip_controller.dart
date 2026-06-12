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
      LoadingUtil.hide();

      if (result.success && result.data != null) {
        FocusManager.instance.primaryFocus?.unfocus();

        // Xóa thông tin cũ
        codeController.clear();
        inviteInfo.value = null;

        // Chờ bàn phím và loading đóng hẳn
        await Future.delayed(const Duration(milliseconds: 300));

        // Nếu đang mở dưới dạng Dialog (ở Home) thì đóng popup
        if (Get.isDialogOpen ?? false) {
          Get.back();
          Get.toNamed('/trip-detail', arguments: result.data!.id);
        } else {
          // Nếu đang mở dưới dạng full screen (từ Deep Link) thì thay màn hình
          Get.offNamed('/trip-detail', arguments: result.data!.id);
        }

        Future.delayed(const Duration(milliseconds: 350), () {
          ToastUtil.showSuccess("Chào mừng!", "Bạn đã tham gia chuyến đi thành công");
        });

        // Làm mới danh sách hiển thị ở trang chủ ngầm phòng trường hợp quay lại
        if (Get.isRegistered<HomeController>()) {
           Get.find<HomeController>().fetchTrips(isRefresh: true);
        }
      } else {
        ToastUtil.showError("Thất bại", result.message ?? "Không thể tham gia");
      }
    } catch (e) {
      ToastUtil.showError("Lỗi hệ thống", e.toString());
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
