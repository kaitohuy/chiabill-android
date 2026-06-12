import 'dart:io';
import 'package:chiabill/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../data/repositories/payment_repository.dart';
import '../data/models/settlement_response.dart';
import '../utils/currency_util.dart';
import 'trip_detail_controller.dart';

class CreatePaymentController extends GetxController {
  final int tripId;
  final SettlementResponse settlement;

  CreatePaymentController(this.tripId, this.settlement);

  final PaymentRepository _repo = PaymentRepository();
  final amountController = TextEditingController();

  var selectedImage = Rxn<File>();
  var isLoading = false.obs;
  var overpayWarning = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Khởi tạo mặc định số tiền = đúng số tiền còn nợ
    amountController.text = CurrencyUtils.formatNumber(settlement.amount);
    
    // Cảnh báo nhập thừa tiền
    amountController.addListener(() {
      double? val = double.tryParse(amountController.text.replaceAll(',', ''));
      if (val != null && val > settlement.amount) {
        double excess = val - settlement.amount;
        overpayWarning.value = '⚠️ Bạn đang chuyển thừa ${CurrencyUtils.formatNumber(excess)}đ! Kiểm tra lại hoặc bo cho chủ nợ hihi 😄';
      } else {
        overpayWarning.value = '';
      }
    });
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 1080);
    if (pickedFile != null) {
      selectedImage.value = File(pickedFile.path);
    }
  }

  Future<void> submitPayment() async {
    double? amount = double.tryParse(amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ToastUtil.showWarning("Lỗi", "Số tiền không hợp lệ");
      return;
    }

    isLoading.value = true;
    try {
      final result = await _repo.createPayment(tripId, settlement.toUserId!, amount, selectedImage.value);

      if (result.success) {
        FocusManager.instance.primaryFocus?.unfocus();
        
        // Chờ bàn phím ẩn
        await Future.delayed(const Duration(milliseconds: 150));

        // Đóng ngay lập tức (Xóa QR + Xóa form)
        Get.back(); 
        Get.back(); 

        Future.delayed(const Duration(milliseconds: 300), () {
          ToastUtil.showSuccess("Thành công", "Đã gửi yêu cầu thanh toán. Đang chờ xác nhận!");
        });

        // Xóa thông tin cũ
        amountController.clear();
        selectedImage.value = null;

        // Load lại Tab Thanh toán
        if (Get.isRegistered<TripDetailController>(tag: tripId.toString())) {
          Get.find<TripDetailController>(tag: tripId.toString()).fetchData(isSilent: true);
        }
      } else {
        ToastUtil.showError("Lỗi", result.message ?? "Không thể gửi minh chứng");
      }
    } catch (e) {
      ToastUtil.showError("Lỗi hệ thống", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    Future.delayed(const Duration(milliseconds: 500), () {
      amountController.dispose();
    });
    super.onClose();
  }
}
