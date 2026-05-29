import 'package:chiabill/utils/loading_util.dart';
import 'package:chiabill/utils/toast_util.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../data/models/user_response.dart';
import '../data/models/update_profile_request.dart';
import '../data/repositories/user_repository.dart';

class ProfileController extends GetxController {
  final UserRepository _repository = UserRepository();
  final ImagePicker _picker = ImagePicker();

  var isLoading = true.obs;
  var isUploading = false.obs;
  var user = Rxn<UserResponse>();

  // Text Controllers
  final nameController = TextEditingController();
  final phoneController = TextEditingController(); // Đã thêm Phone
  final bankIdController = TextEditingController();
  final accountNoController = TextEditingController();

  // Biến quản lý UI
  var currentAvatarUrl = RxnString();
  var currentQrUrl = RxnString();
  var isVietQrExpanded = false.obs;
  var isStaticQrExpanded = false.obs;
  var paymentPriority = 1.obs;

  // Biến cấu hình (Settings)
  var allowAutoAdd = true.obs;
  var allowAutoApprovePayment = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    isLoading.value = true;
    try {
      final result = await _repository.getMyProfile();
      if (isClosed) return;
      if (result.success && result.data != null) {
        user.value = result.data;

        // 1. Gán lại Text
        nameController.text = user.value!.name ?? "";
        phoneController.text = user.value!.phone ?? ""; // Đã thêm gán Phone
        bankIdController.text = user.value!.bankId ?? "";
        accountNoController.text = user.value!.accountNo ?? "";

        // Gán lại Setting
        allowAutoAdd.value = user.value!.allowAutoAdd;
        allowAutoApprovePayment.value = user.value!.allowAutoApprovePayment;

        // 2. Gán lại URL ảnh
        currentAvatarUrl.value = (user.value!.avatarUrl == null || user.value!.avatarUrl!.isEmpty)
            ? null
            : user.value!.avatarUrl;

        currentQrUrl.value = (user.value!.bankQrUrl == null || user.value!.bankQrUrl!.isEmpty)
            ? null
            : user.value!.bankQrUrl;

        // 3. Lấy ưu tiên thanh toán
        paymentPriority.value = result.data!.paymentPriority;

        // Ép đóng toàn bộ các Tab khi mới vào màn hình
        isVietQrExpanded.value = false;
        isStaticQrExpanded.value = false;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveProfile({bool silent = false}) async {
    try {
      if (!silent) {
        isLoading.value = true;
        LoadingUtil.show();
      }

      final request = UpdateProfileRequest(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        bankId: bankIdController.text.trim().toUpperCase(),
        accountNo: accountNoController.text.trim(),
        avatarUrl: currentAvatarUrl.value ?? "",
        bankQrUrl: currentQrUrl.value ?? "",
        allowAutoAdd: allowAutoAdd.value,
        allowAutoApprovePayment: allowAutoApprovePayment.value,
        paymentPriority: paymentPriority.value,
      );

      final result = await _repository.updateProfile(request);

      if (result.success) {
        user.value = result.data;
        if (!silent) {
          LoadingUtil.hide();
          ToastUtil.showSuccess("Thành công", "Đã lưu thay đổi");
        }
      } else {
        if (!silent) ToastUtil.showError("Lỗi", result.message ?? "Lỗi lưu thông tin");
      }
    } catch (e) {
      if (!silent) ToastUtil.showError("Lỗi", e.toString());
    } finally {
      if (!silent) {
        isLoading.value = false;
        LoadingUtil.hide();
      }
    }
  }

  void toggleAutoApprovePayment(bool value) {
    allowAutoApprovePayment.value = value;
    saveProfile(silent: true);
  }

  void toggleAutoAdd(bool value) {
    allowAutoAdd.value = value;
    saveProfile(silent: true);
  }

  void setAsDefault(int priority) {
    paymentPriority.value = priority;
    saveProfile(silent: true);
  }

  void removeImage(String type) {
    if (type == 'avatar') currentAvatarUrl.value = null;
    if (type == 'bank-qr') currentQrUrl.value = null;
    saveProfile(silent: true);
  }

  Future<void> pickAndUploadImage(String type) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 1080);
    if (image == null) return;

    try {
      File file = File(image.path);
      isUploading.value = true;
      LoadingUtil.show();

      String endpoint = type == 'avatar' ? "/api/users/avatar" : "/api/users/bank-qr";
      final result = await _repository.uploadImage(endpoint, file);

      if (result.success && result.data != null) {
        if (type == 'avatar') currentAvatarUrl.value = result.data;
        if (type == 'bank-qr') currentQrUrl.value = result.data;

        saveProfile(silent: true);
        LoadingUtil.hide();
        ToastUtil.showSuccess("Thành công", "Đã cập nhật ảnh!");
      } else {
        ToastUtil.showError("Lỗi", result.message ?? "Không thể tải ảnh");
      }
    } catch (e) {
      ToastUtil.showError("Lỗi", "Đã xảy ra lỗi khi tải ảnh");
    } finally {
      isUploading.value = false;
      LoadingUtil.hide();
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose(); // Đừng quên dọn dẹp biến này để tránh rò rỉ RAM
    bankIdController.dispose();
    accountNoController.dispose();
    super.onClose();
  }
}
