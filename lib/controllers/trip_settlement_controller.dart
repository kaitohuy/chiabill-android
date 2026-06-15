import 'package:chiabill/utils/toast_util.dart';
import 'package:get/get.dart';
import '../data/models/settlement_response.dart';
import '../data/repositories/settlement_repository.dart';
import '../data/repositories/payment_repository.dart';
import '../data/repositories/notification_repository.dart';
import 'profile_controller.dart';
import 'trip_detail_controller.dart'; // Để trigger reload nếu cần

class TripSettlementController extends GetxController {
  final int tripId;
  TripSettlementController(this.tripId);

  final SettlementRepository _settlementRepo = SettlementRepository();
  final PaymentRepository _paymentRepo = PaymentRepository();
  final NotificationRepository _notificationRepo = NotificationRepository();

  var settlements = <SettlementResponse>[].obs;
  var isLoading = true.obs;
  bool _isFirstLoad = true;

  // BIẾN CHO TÌM KIẾM, LỌC, SẮP XẾP
  var searchQuery = "".obs;
  var filterOnlyMe = false.obs; // false = Tất cả, true = Chỉ mình tôi
  var sortOrder = "highest".obs; // highest = Cao nhất, lowest = Thấp nhất

  List<SettlementResponse> get filteredSettlements {
    List<SettlementResponse> result = List.from(settlements);

    // 1. Tìm kiếm (theo tên người gửi hoặc người nhận)
    if (searchQuery.value.trim().isNotEmpty) {
      final q = searchQuery.value.trim().toLowerCase();
      result = result.where((s) {
        return (s.fromUserName?.toLowerCase().contains(q) ?? false) ||
               (s.toUserName?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // 2. Lọc "Chỉ mình tôi"
    if (filterOnlyMe.value) {
      if (Get.isRegistered<ProfileController>()) {
        final myId = Get.find<ProfileController>().user.value?.id;
        if (myId != null) {
          result = result.where((s) => s.fromUserId == myId || s.toUserId == myId).toList();
        }
      }
    }

    // 3. Sắp xếp theo số tiền hoặc tên
    if (sortOrder.value == "highest") {
      result.sort((a, b) => b.amount.compareTo(a.amount));
    } else if (sortOrder.value == "lowest") {
      result.sort((a, b) => a.amount.compareTo(b.amount));
    } else if (sortOrder.value == "az") {
      result.sort((a, b) => (a.fromUserName ?? "").toLowerCase().compareTo((b.fromUserName ?? "").toLowerCase()));
    } else if (sortOrder.value == "za") {
      result.sort((a, b) => (b.fromUserName ?? "").toLowerCase().compareTo((a.fromUserName ?? "").toLowerCase()));
    }

    return result;
  }



  Future<void> fetchSettlements() async {
    if (_isFirstLoad) isLoading.value = true;
    final result = await _settlementRepo.getSettlements(tripId);
    if (result.success && result.data != null) {
      settlements.value = result.data!;
    }
    if (_isFirstLoad) {
      isLoading.value = false;
      _isFirstLoad = false;
    }
  }

  Future<void> approvePayment(int paymentId) async {
    isLoading.value = true;
    final result = await _paymentRepo.approvePayment(paymentId);
    if (result.success) {
      ToastUtil.showSuccess("Thành công", "Đã xác nhận nhận tiền!");
      await fetchSettlements(); // Cập nhật lại nợ
      
      // Update Main Trip Detail nếu cần
      if (Get.isRegistered<TripDetailController>(tag: tripId.toString())) {
        Get.find<TripDetailController>(tag: tripId.toString()).fetchTripDetail();
      }
    } else {
      ToastUtil.showError("Lỗi", result.message ?? "Không thể duyệt");
    }
    isLoading.value = false;
  }

  Future<void> rejectPayment(int paymentId) async {
    isLoading.value = true;
    final result = await _paymentRepo.rejectPayment(paymentId);
    if (result.success) {
      ToastUtil.showSuccess("Thành công", "Đã từ chối khoản thanh toán");
      await fetchSettlements();
    } else {
      ToastUtil.showError("Lỗi", result.message ?? "Không thể từ chối");
    }
    isLoading.value = false;
  }

  Future<void> remindDebt(int debtorId, double amount) async {
    final result = await _notificationRepo.remindDebt(debtorId, tripId, amount);
    if (result.success) {
      ToastUtil.showSuccess("Thành công", "Đã gửi thông báo nhắc nợ!");
    } else {
      ToastUtil.showError("Lỗi", result.message ?? "Không thể gửi thông báo");
    }
  }
}
