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
    final result = await _repository.getMyProfile();
    if (result.success && result.data != null) {
      user.value = result.data;

      // 1. Gán lại Text
      nameController.text = user.value!.name ?? "";
      phoneController.text = user.value!.phone ?? ""; // Đã thêm gán Phone
      bankIdController.text = user.value!.bankId ?? "";
      accountNoController.text = user.value!.accountNo ?? "";

      // Gán lại Setting
      allowAutoAdd.value = user.value!.allowAutoAdd ?? true;
      allowAutoApprovePayment.value = user.value!.allowAutoApprovePayment ?? true;

      // 2. Gán lại URL ảnh
      currentAvatarUrl.value = (user.value!.avatarUrl == null || user.value!.avatarUrl!.isEmpty)
          ? null
          : user.value!.avatarUrl;

      currentQrUrl.value = (user.value!.bankQrUrl == null || user.value!.bankQrUrl!.isEmpty)
          ? null
          : user.value!.bankQrUrl;

      // 3. Lấy ưu tiên thanh toán
      paymentPriority.value = result.data!.paymentPriority ?? 1;

      // Ép đóng toàn bộ các Tab khi mới vào màn hình
      isVietQrExpanded.value = false;
      isStaticQrExpanded.value = false;
    }
    isLoading.value = false;
  }

  Future<void> saveProfile({bool silent = false}) async {
    if (!silent) isLoading.value = true;

    // Gói toàn bộ dữ liệu vào UpdateProfileRequest
    final request = UpdateProfileRequest(
      name: nameController.text.trim(),
      phone: phoneController.text.trim(), // Truyền Phone vào Request
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
        Get.snackbar("Thành công", "Đã lưu thay đổi", backgroundColor: Colors.green, colorText: Colors.white);
      }
    } else {
      if (!silent) {
        Get.snackbar("Lỗi", result.message ?? "Lỗi lưu thông tin", backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    }
    if (!silent) isLoading.value = false;
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

    File file = File(image.path);
    isUploading.value = true;

    String endpoint = type == 'avatar' ? "/api/users/avatar" : "/api/users/bank-qr";
    final result = await _repository.uploadImage(endpoint, file);

    if (result.success && result.data != null) {
      if (type == 'avatar') currentAvatarUrl.value = result.data;
      if (type == 'bank-qr') currentQrUrl.value = result.data;

      saveProfile(silent: true);
      Get.snackbar("Thành công", "Đã cập nhật ảnh!", backgroundColor: Colors.green, colorText: Colors.white);
    } else {
      Get.snackbar("Lỗi", result.message ?? "Không thể tải ảnh");
    }
    isUploading.value = false;
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