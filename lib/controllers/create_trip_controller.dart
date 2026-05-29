import 'package:chiabill/utils/loading_util.dart';
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
  
  var startDate = DateTime.now().obs;
  
  var selectedCategoryName = Rx<String?>("Biển");
  var selectedCategoryIcon = Rx<String?>("beach_access");

  var isLoading = false.obs;

  Future<void> createTrip() async {
    if (nameController.text.trim().isEmpty) {
      ToastUtil.showWarning("Lỗi", "Vui lòng nhập tên chuyến đi");
      return;
    }

    isLoading.value = true;
    LoadingUtil.show();
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
        startDate: startDate.value.toIso8601String(),
        categoryName: selectedCategoryName.value,
        categoryIcon: selectedCategoryIcon.value,
      );

      final result = await _repository.createTrip(request);
      LoadingUtil.hide();

      if (result.success) {
        // Xóa thông tin cũ trước
        nameController.clear();
        descController.clear();
        budgetController.clear();
        startDate.value = DateTime.now();

        // Đóng form
        Get.back();

        if (result.data != null) {
          ToastUtil.showSuccess("Thành công", "Đã tạo chuyến đi ${result.data!.name}");
        } else {
          ToastUtil.showSuccess("Đã lưu ngoại tuyến", result.message ?? "Sẽ đồng bộ khi có mạng");
        }

        // Dùng postFrameCallback để chọn đợi UI settle xong mới refresh
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Get.isRegistered<HomeController>()) {
            Get.find<HomeController>().fetchTrips();
          }
        });
      } else {
        ToastUtil.showError("Lỗi", result.message ?? "Không thể tạo chuyến đi");
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
    Future.delayed(const Duration(milliseconds: 500), () {
      nameController.dispose();
      descController.dispose();
      budgetController.dispose(); // NHỚ DISPOSE ĐỂ TRÁNH TRÀN RAM
    });
    super.onClose();
  }
}
