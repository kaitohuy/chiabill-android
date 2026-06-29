import 'dart:io';
import 'package:chiabill/utils/loading_util.dart';
import 'package:chiabill/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../data/models/create_trip_request.dart';
import '../data/repositories/trip_repository.dart';
import 'home_controller.dart';

class CreateTripController extends GetxController {
  final TripRepository _repository = TripRepository();
  final ImagePicker _picker = ImagePicker();

  // Quản lý chữ người dùng nhập vào
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final budgetController = TextEditingController(); // Đã có
  
  var startDate = DateTime.now().obs;
  var endDate = Rx<DateTime?>(null);
  
  var selectedCategoryName = Rx<String?>("Biển");
  var selectedCategoryIcon = Rx<String?>("beach_access");

  // Ảnh bìa chuyến đi
  var selectedCoverFile = Rxn<File>();

  var isLoading = false.obs;

  Future<void> pickCoverImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 1080,
    );
    if (image != null) {
      selectedCoverFile.value = File(image.path);
    }
  }

  void clearCoverImage() {
    selectedCoverFile.value = null;
  }

  Future<void> _uploadCoverAsync(int tripId, File file) async {
    try {
      final uploadResult = await _repository.updateTripCover(tripId, file);
      if (uploadResult.success) {
        ToastUtil.showSuccess("success".tr, "cover_uploaded_success".tr);
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().fetchTrips();
        }
      } else {
        ToastUtil.showError("error".tr, "${'cover_upload_failed'.tr}: ${uploadResult.message}");
      }
    } catch (e) {
      // Bỏ qua lỗi ngầm
    }
  }

  Future<void> createTrip() async {
    if (nameController.text.trim().isEmpty) {
      ToastUtil.showWarning("error".tr, "create_trip_name_empty".tr);
      return;
    }

    isLoading.value = true;
    LoadingUtil.show();
    try {
      final File? coverFile = selectedCoverFile.value;

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
        endDate: endDate.value?.toIso8601String(),
        categoryName: selectedCategoryName.value,
        categoryIcon: selectedCategoryIcon.value,
      );

      final result = await _repository.createTrip(request);
      LoadingUtil.hide();

      if (result.success) {
        FocusManager.instance.primaryFocus?.unfocus();
        // Xóa thông tin cũ trước
        nameController.clear();
        descController.clear();
        budgetController.clear();
        startDate.value = DateTime.now();
        endDate.value = null;
        selectedCoverFile.value = null;

        // Chờ bàn phím và loading đóng hẳn (tránh race condition)
        await Future.delayed(const Duration(milliseconds: 300));

        // Đóng form
        if (Get.isBottomSheetOpen == true) {
          Get.back();
        } else {
          Get.back(); // fallback
        }

        if (result.data != null) {
          Future.delayed(const Duration(milliseconds: 350), () {
            ToastUtil.showSuccess("success".tr, "${'trip_created_success'.tr} ${result.data!.name}");
          });
          // Bắt đầu upload ảnh bìa bất đồng bộ (async) không chặn UI
          if (coverFile != null) {
            _uploadCoverAsync(result.data!.id, coverFile);
          }
        } else {
          Future.delayed(const Duration(milliseconds: 350), () {
            ToastUtil.showSuccess("offline_saved".tr, result.message ?? "offline_sync_hint".tr);
          });
        }

        // Dùng postFrameCallback để chọn đợi UI settle xong mới refresh
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Get.isRegistered<HomeController>()) {
            Get.find<HomeController>().fetchTrips();
          }
        });
      } else {
        ToastUtil.showError("error".tr, result.message ?? "trip_create_failed".tr);
      }
    } catch (e) {
      ToastUtil.showError("system_error".tr, e.toString());
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
