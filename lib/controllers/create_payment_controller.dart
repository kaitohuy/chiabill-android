import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../data/repositories/payment_repository.dart';
import '../data/models/settlement_response.dart';
import 'trip_detail_controller.dart';

class CreatePaymentController extends GetxController {
  final int tripId;
  final SettlementResponse settlement;

  CreatePaymentController(this.tripId, this.settlement);

  final PaymentRepository _repo = PaymentRepository();
  final amountController = TextEditingController();

  var selectedImage = Rxn<File>();
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Khởi tạo mặc định số tiền = đúng số tiền còn nợ
    amountController.text = settlement.amount.toInt().toString();
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
      Get.snackbar("Lỗi", "Số tiền không hợp lệ");
      return;
    }
    if (selectedImage.value == null) {
      Get.snackbar("Lỗi", "Vui lòng đính kèm ảnh minh chứng giao dịch!");
      return;
    }

    isLoading.value = true;
    final result = await _repo.createPayment(tripId, settlement.toUserId!, amount, selectedImage.value!);
    isLoading.value = false;

    if (result.success) {
      Get.back(); // Đóng BottomSheet QR Code
      Get.back(); // Đóng BottomSheet Nhập tiền
      Get.snackbar("Thành công", "Đã gửi yêu cầu thanh toán. Đang chờ xác nhận!", backgroundColor: Colors.green, colorText: Colors.white);

      // Load lại Tab Thanh toán
      if (Get.isRegistered<TripDetailController>(tag: tripId.toString())) {
        Get.find<TripDetailController>(tag: tripId.toString()).fetchData();
      }
    } else {
      Get.snackbar("Lỗi", result.message ?? "Không thể gửi minh chứng", backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }
}