import 'package:chiabill/utils/toast_util.dart';
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
  final budgetController = TextEditingController(); // Đã có

  var isLoading = false.obs;

  Future<void> createTrip() async {
    if (nameController.text.trim().isEmpty) {
      ToastUtil.showWarning("Lỗi", "Vui lòng nhập tên chuyến đi");
      return;
    }

    isLoading.value = true;
    try {
      // ==========================================
      // XỬ LÝ SỐ TIỀN: BỎ DẤU PHẨY TRƯỚC KHI ÉP KIỂU
      // ==========================================
      double? parsedBudget;
      if (budgetController.text.trim().isNotEmpty) {
        String rawBudget = budgetController.text.replaceAll(',', '');
        parsedBudget = double.tryParse(rawBudget);
      }

      final request = CreateTripRequest(
        name: nameController.text.trim(),
        description: descController.text.trim(),
        totalBudget: parsedBudget, // Gắn vào request
      );

      final result = await _repository.createTrip(request);

      if (result.success && result.data != null) {
        // ĐÓNG FORM NGAY LẬP TỨC để người dùng thấy app phản hồi nhanh
        Get.back(); 

        nameController.clear();
        descController.clear();
        budgetController.clear(); // Xóa data cũ cho lần mở sau

        ToastUtil.showSuccess("Thành công", "Đã tạo chuyến đi ${result.data!.name}");

        // Gọi HomeController load lại danh sách chuyến đi mới nhất
        Get.find<HomeController>().fetchTrips();
      } else {
        ToastUtil.showError("Lỗi", result.message ?? "Không thể tạo chuyến đi");
      }
    } catch (e) {
      ToastUtil.showError("Lỗi hệ thống", "Đã xảy ra lỗi ngoài ý muốn");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    descController.dispose();
    budgetController.dispose(); // NHỚ DISPOSE ĐỂ TRÁNH TRÀN RAM
    super.onClose();
  }
}