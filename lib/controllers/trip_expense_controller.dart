import 'package:chiabill/utils/toast_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../data/models/expense_response.dart';
import '../data/models/expense_category_respone.dart';
import '../data/models/category_stat_response.dart';
import '../services/expense_service.dart';
import '../services/offline_sync_service.dart';
import 'trip_detail_controller.dart'; // Để trigger reload nếu cần
import 'trip_settlement_controller.dart';

class TripExpenseController extends GetxController {
  final int tripId;
  TripExpenseController(this.tripId);

  final ExpenseService _expenseService = ExpenseService();
  final ScrollController dateScrollController = ScrollController();

  var expenses = <ExpenseResponse>[].obs;
  var categories = <ExpenseCategoryResponse>[].obs;
  var categoryStats = <CategoryStatResponse>[].obs;

  // Pagination & Filters
  var currentExpensePage = 0.obs;
  var isExpenseLastPage = false.obs;
  var isLoadingMoreExpenses = false.obs;
  var searchKeyword = "".obs;
  var filterCategoryId = RxnInt();
  var filterPayerId = RxnInt();
  var selectedExpenseDate = Rxn<DateTime>();
  var selectedExpenseMonth = DateTime.now().month.obs;
  var selectedExpenseYear = DateTime.now().year.obs;

  var isLoading = true.obs;
  var isStatsLoading = false.obs;
  bool _isFirstLoad = true;



  @override
  void onClose() {
    dateScrollController.dispose();
    super.onClose();
  }

  Future<void> fetchCategories() async {
    final result = await _expenseService.getCategories(tripId);
    if (result.success && result.data != null) {
      categories.value = result.data!;
    }
  }

  Future<void> fetchStats() async {
    isStatsLoading.value = true;
    final result = await _expenseService.getTripStats(tripId);
    if (result.success && result.data != null) {
      categoryStats.value = result.data!;
    }
    isStatsLoading.value = false;
  }

  Future<void> fetchExpenses({bool isRefresh = true, bool isSilent = false}) async {
    if (isRefresh) {
      currentExpensePage.value = 0;
      isExpenseLastPage.value = false;
      isLoadingMoreExpenses.value = false;
      if (expenses.isNotEmpty && !isSilent) expenses.clear();
      if (!isSilent && _isFirstLoad) isLoading.value = true;
    } else {
      if (isExpenseLastPage.value || isLoadingMoreExpenses.value) return;
      isLoadingMoreExpenses.value = true;
    }

    String? startDate;
    String? endDate;
    if (selectedExpenseDate.value != null) {
      final date = selectedExpenseDate.value!;
      startDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T00:00:00";
      endDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T23:59:59";
    }

    final result = await _expenseService.searchExpenses(
      tripId: tripId,
      page: currentExpensePage.value,
      size: 10,
      keyword: searchKeyword.value.trim().isNotEmpty ? searchKeyword.value.trim() : null,
      categoryId: filterCategoryId.value,
      payerId: filterPayerId.value,
      startDate: startDate,
      endDate: endDate,
    );

    List<ExpenseResponse> loadedData = [];
    if (result.success && result.data != null) {
      loadedData = result.data!.content;
      currentExpensePage.value++;
      isExpenseLastPage.value = result.data!.last;
    } else if (isRefresh) {
      // Nếu API lỗi (e.g. mất mạng và ko có cache), coi như list tạm rỗng để gắn offline
      isExpenseLastPage.value = true; 
    }

    // THÊM: Gắn các khoản chi chờ đồng bộ (Offline) vào trang đầu tiên
    if (isRefresh && Get.isRegistered<OfflineSyncService>()) {
      final syncService = Get.find<OfflineSyncService>();
      final pending = syncService.getPendingExpensesForTrip(tripId);
      
      List<ExpenseResponse> offlineExpenses = pending.map((item) {
        var data = item['data'] as Map<String, dynamic>;
        return ExpenseResponse(
          id: -1, // ID ảo
          totalAmount: (data['totalAmount'] as num).toDouble(),
          description: data['description'] ?? 'Khoản chi ngoại tuyến',
          expenseDate: data['expenseDate'],
          clientUuid: item['id'], // Dùng ID này làm cờ đánh dấu Offline
          isFromFund: data['isFromFund'] ?? false,
        );
      }).toList();
      
      // Nối mảng offline lên đầu
      loadedData = [...offlineExpenses, ...loadedData];
    }

    if (isRefresh) {
      expenses.value = loadedData;
    } else if (loadedData.isNotEmpty) {
      expenses.addAll(loadedData);
    }

    if (!isRefresh) isLoadingMoreExpenses.value = false;
    if (isRefresh && !isSilent) isLoading.value = false;
    _isFirstLoad = false;
  }

  void patchExpense(ExpenseResponse expense) {
    final idx = expenses.indexWhere((e) => e.id == expense.id);
    if (idx != -1) {
      expenses[idx] = expense; 
    }
    fetchStats(); // Update stats locally or re-fetch
  }

  Future<void> deleteExpense(int expenseId) async {
    isLoading.value = true;
    final result = await _expenseService.deleteExpense(expenseId);
    if (result.success) {
      ToastUtil.showSuccess("Thành công", "Đã xóa khoản chi");
      fetchExpenses(isRefresh: true, isSilent: true);
      fetchStats();
      
      // Update Main Trip Detail
      if (Get.isRegistered<TripDetailController>(tag: tripId.toString())) {
        Get.find<TripDetailController>(tag: tripId.toString()).fetchTripDetail();
      }
      
      // Reload Settlements (Nợ nần)
      if (Get.isRegistered<TripSettlementController>(tag: tripId.toString())) {
        Get.find<TripSettlementController>(tag: tripId.toString()).fetchSettlements();
      }
    } else {
      ToastUtil.showError("Lỗi", result.message ?? "Không thể xóa");
    }
    isLoading.value = false;
  }

  void onExpenseDateChanged(DateTime? date) {
    selectedExpenseDate.value = date;
    if (date != null) {
      selectedExpenseMonth.value = date.month;
      selectedExpenseYear.value = date.year;
      
      // Animate scroll to the selected date chip (width ~105px per chip)
      final index = date.day; // index 0 is "Tất cả", index 1 is day 1. So day n is index n.
      if (dateScrollController.hasClients) {
        // Calculate the center offset
        double screenWidth = Get.width;
        double targetScroll = (index * 105.0) - (screenWidth / 2) + 50.0; // center it
        if (targetScroll < 0) targetScroll = 0;
        
        // Ensure we don't scroll past the max extent
        if (targetScroll > dateScrollController.position.maxScrollExtent) {
          targetScroll = dateScrollController.position.maxScrollExtent;
        }

        dateScrollController.animateTo(
          targetScroll,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    }
    fetchExpenses(isRefresh: true);
  }

  void onExpenseMonthYearChanged(int month, int year) {
    selectedExpenseMonth.value = month;
    selectedExpenseYear.value = year;
    selectedExpenseDate.value = null;
    fetchExpenses(isRefresh: true);
  }

  void applyExpenseFilter({String? keyword, int? catId, int? payerId}) {
    if (keyword != null) searchKeyword.value = keyword;
    filterCategoryId.value = catId;
    filterPayerId.value = payerId;
    fetchExpenses(isRefresh: true);
  }
}
