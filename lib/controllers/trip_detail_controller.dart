import 'package:chiabill/utils/toast_util.dart';
import 'package:chiabill/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../data/models/category_stat_response.dart';
import '../data/models/expense_category_respone.dart';
import '../data/models/payment_response.dart';
import '../data/models/trip_response.dart';
import '../data/models/expense_response.dart';
import '../data/models/settlement_response.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/invitation_repository.dart';
import '../data/repositories/payment_repository.dart';
import '../data/repositories/trip_repository.dart';
import '../data/repositories/expense_repository.dart';
import '../data/repositories/settlement_repository.dart';
import 'home_controller.dart';

class TripDetailController extends GetxController {
  final int tripId;
  TripDetailController(this.tripId);

  final TripRepository _tripRepo = TripRepository();
  final ExpenseRepository _expenseRepo = ExpenseRepository();
  final SettlementRepository _settlementRepo = SettlementRepository();
  final InvitationRepository _invitationRepo = InvitationRepository();
  final PaymentRepository _paymentRepo = PaymentRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();

  var isLoading = true.obs;
  var trip = Rxn<TripResponse>();
  var expenses = <ExpenseResponse>[].obs;
  var settlements = <SettlementResponse>[].obs;
  var payments = <PaymentResponse>[].obs;

  // BIẾN THỐNG KÊ MỚI
  var categoryStats = <CategoryStatResponse>[].obs;

  var currentTab = 0.obs;
  var isAddingMember = false.obs;
  var activeInviteCode = "".obs;

  // PHÂN TRANG & FILTER (Giữ nguyên các biến của bạn...)
  var currentExpensePage = 0.obs;
  var isExpenseLastPage = false.obs;
  var isLoadingMoreExpenses = false.obs;
  var currentPaymentPage = 0.obs;
  var isPaymentLastPage = false.obs;
  var isLoadingMorePayments = false.obs;
  var searchKeyword = "".obs;
  var filterCategoryId = RxnInt();
  var filterPayerId = RxnInt();
  var categories = <ExpenseCategoryResponse>[].obs;
  var filterPaymentStatus = RxnString();
  var filterPaymentFromUserId = RxnInt();
  var filterPaymentToUserId = RxnInt();

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  // CẬP NHẬT FETCH DATA: Thêm fetchStats vào danh sách đợi
  Future<void> fetchData() async {
    isLoading.value = true;
    await Future.wait([
      fetchTripDetail(),
      fetchCategories(),
      fetchExpenses(isRefresh: true),
      fetchSettlements(),
      fetchActiveInvite(),
      fetchPayments(isRefresh: true),
      fetchStats(), // <--- THÊM DÒNG NÀY
    ]);
    isLoading.value = false;
  }

  // ==========================================
  // HÀM LẤY DỮ LIỆU THỐNG KÊ BIỂU ĐỒ
  // ==========================================
  Future<void> fetchStats() async {
    final result = await _expenseRepo.getTripStats(tripId);
    if (result.success && result.data != null) {
      categoryStats.value = result.data!;
    }
  }

  Future<void> fetchCategories() async {
    final result = await _categoryRepo.getCategories(tripId);
    if (result.success && result.data != null) {
      categories.value = result.data!;
    }
  }

  // ĐÃ CẬP NHẬT: Nhét các biến Filter vào hàm gọi Repo
  Future<void> fetchExpenses({bool isRefresh = true}) async {
    if (isRefresh) {
      currentExpensePage.value = 0;
      isExpenseLastPage.value = false;
      isLoadingMoreExpenses.value = false;
      // Nếu là refresh do filter, ta clear danh sách cũ ngay để UI hiện Loading tròn
      if (expenses.isNotEmpty) expenses.clear();
    } else {
      if (isExpenseLastPage.value || isLoadingMoreExpenses.value) return;
      isLoadingMoreExpenses.value = true;
    }

    final result = await _expenseRepo.searchExpenses(
      tripId: tripId,
      page: currentExpensePage.value,
      size: 20,
      keyword: searchKeyword.value.trim().isNotEmpty ? searchKeyword.value.trim() : null,
      categoryId: filterCategoryId.value,
      payerId: filterPayerId.value,
    );

    if (result.success && result.data != null) {
      if (isRefresh) {
        expenses.value = result.data!.content;
      } else {
        expenses.addAll(result.data!.content);
      }
      currentExpensePage.value++;
      isExpenseLastPage.value = result.data!.last;
    }

    if (!isRefresh) isLoadingMoreExpenses.value = false;
  }

  // HÀM MỚI: Dùng để gọi khi user bấm "Áp dụng" trên UI Lọc
  void applyExpenseFilter({String? keyword, int? catId, int? payerId}) {
    if (keyword != null) searchKeyword.value = keyword;
    filterCategoryId.value = catId;
    filterPayerId.value = payerId;
    fetchExpenses(isRefresh: true); // Load lại trang 1 với filter mới
  }

  // ==========================================
  // LOGIC TẢI LỊCH SỬ GIAO DỊCH (CÓ PHÂN TRANG)
  // ==========================================
  Future<void> fetchPayments({bool isRefresh = true}) async {
    if (isRefresh) {
      currentPaymentPage.value = 0;
      isPaymentLastPage.value = false;
      isLoadingMorePayments.value = false;
      if (payments.isNotEmpty) payments.clear(); // Clear để UI hiện loading tròn
    } else {
      if (isPaymentLastPage.value || isLoadingMorePayments.value) return;
      isLoadingMorePayments.value = true;
    }

    final result = await _paymentRepo.getTripPaymentsPaginated(
      tripId: tripId,
      page: currentPaymentPage.value,
      size: 20,
      status: filterPaymentStatus.value,
      fromUserId: filterPaymentFromUserId.value,
      toUserId: filterPaymentToUserId.value,
    );

    if (result.success && result.data != null) {
      if (isRefresh) {
        payments.value = result.data!.content;
      } else {
        payments.addAll(result.data!.content);
      }
      currentPaymentPage.value++;
      isPaymentLastPage.value = result.data!.last;
    }

    if (!isRefresh) isLoadingMorePayments.value = false;
  }

  // HÀM MỚI ĐỂ ÁP DỤNG LỌC THANH TOÁN
  void applyPaymentFilter({String? status, int? fromId, int? toId}) {
    filterPaymentStatus.value = status;
    filterPaymentFromUserId.value = fromId;
    filterPaymentToUserId.value = toId;
    fetchPayments(isRefresh: true);
  }
  // Lấy mã đang hoạt động
  Future<void> fetchActiveInvite() async {
    final result = await _invitationRepo.getActiveInvite(tripId);
    if (result.success && result.data != null) {
      activeInviteCode.value = result.data!.inviteCode;
    }
  }

  // Tạo mã mới
  Future<void> generateInviteCode(String customCode) async {
    isLoading.value = true;
    final result = await _invitationRepo.createInvite(
        tripId,
        customCode: customCode.isNotEmpty ? customCode : null
    );

    if (result.success && result.data != null) {
      activeInviteCode.value = result.data!.inviteCode;
    } else {
      // FE chỉ cần hiển thị đúng cái message BE trả về
      ToastUtil.showError("Lỗi", result.message ?? "Không thể tạo mã mời");
    }
    isLoading.value = false;
  }

  void copyToClipboard() {
    if (activeInviteCode.value.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: activeInviteCode.value));
      ToastUtil.showSuccess("Thành công", "Đã copy mã: ${activeInviteCode.value}");
    }
  }

  Future<void> fetchTripDetail() async {
    final result = await _tripRepo.getTripDetail(tripId);
    if (result.success) trip.value = result.data;
  }

  Future<void> fetchSettlements() async {
    final result = await _settlementRepo.getSettlements(tripId);
    if (result.success && result.data != null) settlements.value = result.data!;
  }

  Future<void> deleteExpense(int expenseId) async {
    isLoading.value = true;
    final result = await _expenseRepo.deleteExpense(expenseId);
    if (result.success) {
      ToastUtil.showSuccess("Thành công", "Đã xóa khoản chi");
      fetchData();
    } else {
      ToastUtil.showError("Lỗi", result.message ?? "Không thể xóa");
      isLoading.value = false;
    }
  }

  // Thêm hàm này vào class TripDetailController
  Future<void> deleteTrip() async {
    isLoading.value = true;
    final result = await _tripRepo.deleteTrip(tripId);
    if (result.success) {
      Get.back(); // Đóng dialog xác nhận
      Get.back(); // Văng ra khỏi màn TripDetail, về lại Home

      // Đợi hiệu ứng chuyển màn hình xong (300ms) rồi mới báo thành công
      Future.delayed(const Duration(milliseconds: 300), () {
        ToastUtil.showSuccess("Thông báo", "Đã xóa chuyến đi");
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().fetchTrips();
        }
      });
    } else {
      ToastUtil.showError("Lỗi", result.message ?? "Không thể xóa");
      isLoading.value = false;
    }
  }

  Future<void> addDirectMember(String input) async {
    if (input.trim().isEmpty) return;

    // Tự động phân loại Email hay SĐT
    String email = "";
    String phone = "";
    if (input.contains("@")) {
      email = input.trim();
    } else {
      phone = input.trim();
    }

    isAddingMember.value = true;
    final result = await _tripRepo.addDirectMember(tripId, email, phone);
    isAddingMember.value = false;

    if (result.success) {
      Get.back(); // Đóng dialog
      ToastUtil.showSuccess("Thành công", result.message ?? "Đã thêm thành viên");
      fetchData(); // Load lại data chuyến đi
    } else {
      ToastUtil.showError("Thất bại", result.message ?? "Không thể thêm");
    }
  }

  Future<void> approvePayment(int paymentId) async {
    isLoading.value = true;
    final result = await _paymentRepo.approvePayment(paymentId);
    if (result.success) {
      ToastUtil.showSuccess("Thành công", "Đã xác nhận nhận tiền!");
      fetchData(); // Load lại data để nợ được trừ đi
    } else {
      ToastUtil.showError("Lỗi", result.message ?? "Không thể duyệt");
      isLoading.value = false;
    }
  }

  Future<void> rejectPayment(int paymentId) async {
    isLoading.value = true;
    final result = await _paymentRepo.rejectPayment(paymentId);
    if (result.success) {
      ToastUtil.showSuccess("Thành công", "Đã từ chối khoản thanh toán");
      fetchData(); // Load lại data
    } else {
      ToastUtil.showError("Lỗi", result.message ?? "Không thể từ chối");
      isLoading.value = false;
    }
  }

  int? get currentUserId {
    if (Get.isRegistered<ProfileController>()) {
      return Get.find<ProfileController>().user.value?.id;
    }
    return GetStorage().read('userId');
  }

  // Check xem có phải chủ phòng không
  bool get isOwner => trip.value?.ownerId != null && trip.value?.ownerId == currentUserId;

  Future<void> leaveTrip() async {
    // 1. ĐÓNG DIALOG XÁC NHẬN NGAY LẬP TỨC TRƯỚC KHI GỌI MẠNG
    if (Get.isDialogOpen == true) {
      Get.back();
    }

    isLoading.value = true;
    final result = await _tripRepo.leaveTrip(tripId);
    isLoading.value = false;

    if (result.success) {
      // 2. RỜI NHÓM THÀNH CÔNG THÌ MỚI VĂNG RA MÀN HÌNH CHÍNH
      Get.back();
      ToastUtil.showSuccess("Thành công", "Bạn đã rời khỏi nhóm");
      if (Get.isRegistered<HomeController>()) Get.find<HomeController>().fetchTrips();
    } else {
      // 3. BÁO LỖI (CHẮC CHẮN DIALOG CŨ ĐÃ ĐÓNG RỒI NÊN KHÔNG SỢ ĐÈ NHAU)
      ToastUtil.showError("Không thể rời nhóm", result.message ?? "Lỗi máy chủ.");
    }
  }

  Future<void> kickMember(int memberId, bool forgiveDebt) async {
    // 1. ĐÓNG DIALOG CHỌN XÓA NỢ HAY GIỮ NỢ NGAY LẬP TỨC
    if (Get.isDialogOpen == true) {
      Get.back();
    }

    isLoading.value = true;
    final result = await _tripRepo.kickMember(tripId, memberId, forgiveDebt);
    isLoading.value = false;

    if (result.success) {
      ToastUtil.showSuccess("Thành công", "Đã xóa thành viên");
      fetchData();
    } else {
      ToastUtil.showError("Lỗi", result.message ?? "Không thể xóa");
    }
  }

  Future<void> transferOwner(int newOwnerId) async {
    isLoading.value = true;
    final result = await _tripRepo.transferOwner(tripId, newOwnerId);
    if (result.success) {
      ToastUtil.showSuccess("Thành công", "Đã chuyển quyền Chủ phòng");
      fetchData(); // Load lại data
    } else {
      ToastUtil.showError("Lỗi", result.message ?? "Không thể chuyển quyền");
      isLoading.value = false;
    }
  }

  Future<void> disableMember(int memberId) async {
    isLoading.value = true;
    final result = await _tripRepo.disableMember(tripId, memberId);
    if (result.success) {
      fetchData();
    } else {
      ToastUtil.showError("Lỗi", result.message ?? "Không thể vô hiệu hóa");
      isLoading.value = false;
    }
  }

  Future<void> activateMember(int memberId) async {
    isLoading.value = true;
    final result = await _tripRepo.activateMember(tripId, memberId);
    if (result.success) {
      ToastUtil.showSuccess("Thành công", "Đã mở khóa thành viên");
      fetchData();
    } else {
      ToastUtil.showError("Lỗi", result.message ?? "Không thể mở khóa");
      isLoading.value = false;
    }
  }
}