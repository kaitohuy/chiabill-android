import 'package:chiabill/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/repositories/ghost_repository.dart';
import 'trip_detail_controller.dart';

class GhostController extends GetxController {
  final int tripId;
  GhostController(this.tripId);

  final GhostRepository _repository = GhostRepository();
  final namesController = TextEditingController();
  var isLoading = false.obs;

  Future<void> submitGhosts() async {
    String input = namesController.text.trim();
    if (input.isEmpty) return;

    // Tách chuỗi theo dấu phẩy và lọc bỏ khoảng trắng/rỗng
    List<String> names = input.split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (names.isEmpty) return;

    isLoading.value = true;
    final result = await _repository.createGhostMembers(tripId, names);

    // Bỏ ép kiểu, chỉ check success
    if (result.success) {
      FocusManager.instance.primaryFocus?.unfocus();
      namesController.clear(); // 🌟 XÓA TRẮNG ĐỂ LẦN SAU MỞ RA KHÔNG BỊ DÍNH TÊN CŨ

      // Chờ bàn phím ẩn
      await Future.delayed(const Duration(milliseconds: 150));
      Get.back(); // Đóng popup

      Future.delayed(const Duration(milliseconds: 300), () {
        ToastUtil.showSuccess("Thành công", "Đã thêm ${names.length} người. Nhớ cập nhật khoản chi cũ nếu muốn họ gánh chung nhé!");
      });

      // Load lại TOÀN BỘ dữ liệu Trip Detail (Members, Expenses, Settlements)
      if (Get.isRegistered<TripDetailController>(tag: tripId.toString())) {
        Get.find<TripDetailController>(tag: tripId.toString()).fetchData(isSilent: true);
      }
    } else {
      ToastUtil.showError("Lỗi", result.message ?? "Không thể thêm");
    }
    isLoading.value = false;
  }

  @override
  void onClose() {
    Future.delayed(const Duration(milliseconds: 500), () {
      namesController.dispose();
    });
    super.onClose();
  }
}
