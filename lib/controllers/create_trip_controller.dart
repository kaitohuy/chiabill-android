import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/models/create_trip_request.dart';
import '../data/repositories/trip_repository.dart';
import 'home_controller.dart';

class CreateTripController extends GetxController {
  final TripRepository _repository = TripRepository();

  // Quản lý chữ người dùng nhập vào
  final nameController = TextEditingController();
  final descController = TextEditingController();

  var isLoading = false.obs;

  Future<void> createTrip() async {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar("Lỗi", "Vui lòng nhập tên chuyến đi");
      return;
    }

    isLoading.value = true;
    final request = CreateTripRequest(
      name: nameController.text.trim(),
      description: descController.text.trim(),
    );

    final result = await _repository.createTrip(request);

    if (result.success && result.data != null) {
      nameController.clear();
      descController.clear();
      Get.back(); // Đóng BottomSheet
      Get.snackbar("Thành công", "Đã tạo chuyến đi ${result.data!.name}");

      // Gọi HomeController load lại danh sách chuyến đi mới nhất
      Get.find<HomeController>().fetchTrips();
    } else {
      Get.snackbar("Lỗi", result.message ?? "Không thể tạo chuyến đi");
    }

    isLoading.value = false;
  }

  @override
  void onClose() {
    nameController.dispose();
    descController.dispose();
    super.onClose();
  }
}