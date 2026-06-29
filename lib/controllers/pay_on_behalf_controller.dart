import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../data/models/settlement_response.dart';
import '../data/repositories/payment_repository.dart';
import '../utils/currency_util.dart';
import '../utils/toast_util.dart';
import 'trip_detail_controller.dart';

class PayOnBehalfController extends GetxController {
  final int tripId;
  final List<SettlementResponse> allSettlements;

  PayOnBehalfController(this.tripId, this.allSettlements);

  final PaymentRepository _repo = PaymentRepository();

  // Chủ nợ được chọn (toUserId)
  var selectedCreditorId = RxnInt();

  // Set fromUserId đã tích chọn để trả hộ
  var selectedFromUserIds = <int>{}.obs;

  // Tùy chỉnh số tiền cho mỗi fromUserId
  var customAmounts = <int, TextEditingController>{}.obs;

  // Upload proof
  var selectedImage = Rxn<File>();
  var isLoading = false.obs;

  // Danh sách các chủ nợ (unique toUser)
  List<SettlementResponse> get uniqueCreditors {
    final seen = <int>{};
    return allSettlements.where((s) {
      if (s.toUserId == null) return false;
      return seen.add(s.toUserId!);
    }).toList();
  }

  // Lấy thông tin User của chủ nợ đang chọn (để hiển thị QR)
  dynamic get creditorUser {
    if (selectedCreditorId.value == null) return null;
    if (Get.isRegistered<TripDetailController>(tag: tripId.toString())) {
      final tripCtrl = Get.find<TripDetailController>(tag: tripId.toString());
      final matches = tripCtrl.trip.value?.members?.where((m) => m.user.id == selectedCreditorId.value);
      if (matches != null && matches.isNotEmpty) {
        return matches.first.user;
      }
    }
    return null;
  }

  // Danh sách khoản nợ theo chủ nợ đang chọn
  List<SettlementResponse> get settlementsForCreditor {
    if (selectedCreditorId.value == null) return [];
    return allSettlements.where((s) => s.toUserId == selectedCreditorId.value).toList();
  }

  // Tên chủ nợ đang chọn
  String get selectedCreditorName {
    if (selectedCreditorId.value == null) return '';
    return allSettlements.firstWhere((s) => s.toUserId == selectedCreditorId.value).toUserName ?? '';
  }

  // Tổng tiền đã tích chọn
  double get totalAmount {
    return selectedFromUserIds.fold(0.0, (sum, fromId) {
      final ctrl = customAmounts[fromId];
      final val = double.tryParse(ctrl?.text.replaceAll(',', '') ?? '') ?? 0.0;
      return sum + val;
    });
  }

  void onCreditorSelected(int? creditorId) {
    selectedCreditorId.value = creditorId;
    selectedFromUserIds.clear();
    // Dispose old controllers
    customAmounts.forEach((_, ctrl) => ctrl.dispose());
    customAmounts.clear();
    // Pre-fill default amounts for all debts of this creditor
    for (final s in settlementsForCreditor) {
      if (s.fromUserId != null) {
        customAmounts[s.fromUserId!] = TextEditingController(
          text: CurrencyUtils.formatNumber(s.amount),
        );
      }
    }
  }

  void toggleDebt(int fromUserId) {
    if (selectedFromUserIds.contains(fromUserId)) {
      selectedFromUserIds.remove(fromUserId);
    } else {
      selectedFromUserIds.add(fromUserId);
    }
  }

  void selectAll() {
    for (final s in settlementsForCreditor) {
      if (s.fromUserId != null) selectedFromUserIds.add(s.fromUserId!);
    }
  }

  void deselectAll() => selectedFromUserIds.clear();

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 1080);
    if (picked != null) selectedImage.value = File(picked.path);
  }

  Future<void> submit() async {
    if (selectedCreditorId.value == null) {
      ToastUtil.showWarning("error".tr, "select_creditor_warning".tr);
      return;
    }
    if (selectedFromUserIds.isEmpty) {
      ToastUtil.showWarning("error".tr, "select_at_least_one_debtor_warning".tr);
      return;
    }
    if (totalAmount <= 0) {
      ToastUtil.showWarning("error".tr, "invalid_total_amount".tr);
      return;
    }

    isLoading.value = true;
    try {
      List<int> userIds = selectedFromUserIds.toList();
      List<double> amounts = userIds.map((id) {
        final ctrl = customAmounts[id];
        return double.tryParse(ctrl?.text.replaceAll(',', '') ?? '') ?? 0.0;
      }).toList();

      final result = await _repo.createBatchPayOnBehalf(
        tripId: tripId,
        toUserId: selectedCreditorId.value!,
        totalAmount: totalAmount,
        onBehalfOfUserIds: userIds,
        onBehalfOfAmounts: amounts,
        proofFile: selectedImage.value,
      );

      if (result.success) {
        isLoading.value = false;
        Get.back(); // Đóng BottomSheet
        Get.back(); // Đóng PayOnBehalfScreen
        Future.delayed(const Duration(milliseconds: 400), () {
          ToastUtil.showSuccess("success".tr, "pay_on_behalf_request_sent".tr);
        });
        Future.delayed(const Duration(milliseconds: 900), () {
          if (Get.isRegistered<TripDetailController>(tag: tripId.toString())) {
            Get.find<TripDetailController>(tag: tripId.toString()).fetchData(isSilent: true);
          }
        });
      } else {
        ToastUtil.showError("error".tr, result.message ?? "failed_send_pay_on_behalf".tr);
      }
    } catch (e) {
      ToastUtil.showError("system_error".tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    customAmounts.forEach((_, ctrl) => ctrl.dispose());
    super.onClose();
  }
}
