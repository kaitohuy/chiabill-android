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
      Get.back(); // Đóng popup
      Get.snackbar("Thành công", "Đã thêm ${names.length} người vào nhóm", backgroundColor: Colors.green, colorText: Colors.white);

      // Load lại TOÀN BỘ dữ liệu Trip Detail (Members, Expenses, Settlements)
      if (Get.isRegistered<TripDetailController>(tag: tripId.toString())) {
        Get.find<TripDetailController>(tag: tripId.toString()).fetchData();
      }
    } else {
      Get.snackbar("Lỗi", result.message ?? "Không thể thêm", backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
    isLoading.value = false;
  }
}