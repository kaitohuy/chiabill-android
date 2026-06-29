import 'package:chiabill/utils/loading_util.dart';
import 'package:chiabill/utils/toast_util.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../data/models/user_response.dart';
import '../data/models/update_profile_request.dart';
import '../data/repositories/user_repository.dart';
import 'auth_controller.dart';

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
  var phoneError = RxnString();
  var isVietQrExpanded = false.obs;
  var isStaticQrExpanded = false.obs;
  var paymentPriority = 1.obs;

  // Biến cấu hình (Settings)
  var allowAutoAdd = true.obs;
  var allowAutoApprovePayment = true.obs;

  @override
  void onInit() {
    super.onInit();
    phoneController.addListener(() {
      validatePhone(phoneController.text);
    });
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

  void validatePhone(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      phoneError.value = null;
      return;
    }
    
    if (!text.startsWith('0')) {
      phoneError.value = "Số điện thoại phải bắt đầu bằng số 0";
      return;
    }
    
    if (text.length > 1 && !RegExp(r'^0[235789]').hasMatch(text)) {
      phoneError.value = "Đầu số phải là 02, 03, 05, 07, 08 hoặc 09";
      return;
    }

    if (text.length < 10) {
      phoneError.value = "Số điện thoại chưa đủ 10 chữ số";
      return;
    }

    if (text.length > 10) {
      phoneError.value = "Số điện thoại chỉ được có tối đa 10 chữ số";
      return;
    }
    
    final phoneRegex = RegExp(r'^(0[235789])[0-9]{8}$');
    if (!phoneRegex.hasMatch(text)) {
      phoneError.value = "Số điện thoại không đúng định dạng Việt Nam";
    } else {
      phoneError.value = null;
    }
  }

  Future<void> saveProfile({bool silent = false}) async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final bankId = bankIdController.text.trim().toUpperCase();
    final accountNo = accountNoController.text.trim();

    if (!silent) {
      if (name.isEmpty) {
        ToastUtil.showWarning("Lỗi nhập liệu", "Họ và tên không được để trống");
        return;
      }
      if (name.length < 2 || name.length > 50) {
        ToastUtil.showWarning("Lỗi nhập liệu", "Họ và tên phải từ 2 đến 50 ký tự");
        return;
      }
      if (phone.isNotEmpty) {
        validatePhone(phone);
        if (phoneError.value != null) {
          ToastUtil.showWarning("Lỗi nhập liệu", phoneError.value!);
          return;
        }
      }
      if (bankId.isNotEmpty && accountNo.isEmpty) {
        ToastUtil.showWarning("Lỗi nhập liệu", "Vui lòng điền số tài khoản ngân hàng");
        return;
      }
      if (accountNo.isNotEmpty && bankId.isEmpty) {
        ToastUtil.showWarning("Lỗi nhập liệu", "Vui lòng chọn hoặc nhập mã ngân hàng");
        return;
      }
    }

    try {
      if (!silent) {
        isLoading.value = true;
        LoadingUtil.show();
      }

      final request = UpdateProfileRequest(
        name: name,
        phone: phone,
        bankId: bankId,
        accountNo: accountNo,
        avatarUrl: currentAvatarUrl.value ?? "",
        bankQrUrl: currentQrUrl.value ?? "",
        allowAutoAdd: allowAutoAdd.value,
        allowAutoApprovePayment: allowAutoApprovePayment.value,
        paymentPriority: paymentPriority.value,
        language: Get.locale?.languageCode ?? 'vi',
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

  Future<void> deleteAccount() async {
    try {
      isLoading.value = true;
      LoadingUtil.show();
      
      final result = await _repository.deleteAccount();
      
      LoadingUtil.hide();
      if (result.success) {
        ToastUtil.showSuccess("Thành công", "Tài khoản của bạn đã được xóa.");
        
        // Sử dụng Get.find để lấy AuthController và đăng xuất
        if (Get.isRegistered<AuthController>()) {
          await Get.find<AuthController>().logout();
        } else {
          final authCtrl = Get.put(AuthController());
          await authCtrl.logout();
        }
      } else {
        ToastUtil.showError("Lỗi", result.message ?? "Không thể xóa tài khoản");
      }
    } catch (e) {
      LoadingUtil.hide();
      ToastUtil.showError("Lỗi", e.toString());
    } finally {
      isLoading.value = false;
      LoadingUtil.hide();
    }
  }

  @override
  void onClose() {
    // Không dispose các TextEditingController ở đây để tránh lỗi 'used after being disposed'
    // khi GetX tái sử dụng instance của ProfileController.
    super.onClose();
  }
}
