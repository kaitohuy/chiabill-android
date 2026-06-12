import 'package:get/get.dart';
import '../data/models/trip_stat_response.dart';
import '../data/repositories/expense_repository.dart';
import '../data/repositories/trip_repository.dart';

class OverallStatsController extends GetxController {
  final ExpenseRepository _expenseRepo = ExpenseRepository();
  final TripRepository _tripRepo = TripRepository();

  var isLoading = true.obs;
  var tripStats = <TripStatResponse>[].obs;
  
  // Mặc định chọn 0 (Tất cả)
  var selectedMonth = 0.obs;
  var selectedYear = DateTime.now().year.obs;
  var isAllTimeMode = false.obs;
  var isGroupByCategory = false.obs;

  List<TripStatResponse> get displayStats {
    if (!isGroupByCategory.value) return tripStats;

    Map<String, double> grouped = {};
    for (var stat in tripStats) {
      String icon = stat.categoryIcon ?? 'category';
      grouped[icon] = (grouped[icon] ?? 0) + stat.totalAmount;
    }

    List<TripStatResponse> result = [];
    grouped.forEach((icon, amount) {
      result.add(TripStatResponse(
        tripId: -1,
        tripName: '', // Tên sẽ được lấy từ icon trong UI
        totalAmount: amount,
        categoryIcon: icon,
      ));
    });

    result.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return result;
  }

  var monthlyTotalExpense = 0.0.obs;
  var yearlyTotalExpense = 0.0.obs;
  var allTimeTotalExpense = 0.0.obs;
  
  var totalOwe = 0.0.obs; // Nợ (Global)
  var totalReceive = 0.0.obs; // Thu (Global)

  DateTime? _lastFetchTime;

  Future<void> fetchAll({bool force = false}) async {
    final now = DateTime.now();
    if (!force && _lastFetchTime != null && now.difference(_lastFetchTime!) < const Duration(seconds: 15)) {
      return;
    }
    _lastFetchTime = now;

    await Future.wait([
      fetchSummary(),
      fetchAllTimeStats(),
      fetchOverallStats(),
    ]);
  }

  @override
  void onInit() {
    super.onInit();
    // Trì hoãn load thống kê để ưu tiên tải Chuyến đi ở màn hình chính
    Future.delayed(const Duration(milliseconds: 300), () {
      fetchAll();
    });
  }

  Future<void> fetchSummary() async {
    final result = await _tripRepo.getSettlementSummary();
    if (result.success && result.data != null) {
      totalOwe.value = (result.data!['totalOwed'] ?? 0).toDouble();
      totalReceive.value = (result.data!['totalReceivable'] ?? 0).toDouble();
    }
  }

  Future<void> fetchAllTimeStats() async {
    final result = await _expenseRepo.getOverallStats();
    if (result.success && result.data != null) {
      allTimeTotalExpense.value = result.data!.fold(0, (sum, item) => sum + item.totalAmount);
    }
  }

  Future<void> fetchOverallStats() async {
    isLoading.value = true;
    
    // Fetch dữ liệu của tháng (hoặc năm nếu month == 0) để vẽ biểu đồ và danh sách
    final result = await _expenseRepo.getOverallStats(
      month: isAllTimeMode.value ? null : (selectedMonth.value == 0 ? null : selectedMonth.value),
      year: isAllTimeMode.value ? null : selectedYear.value
    );
    if (result.success && result.data != null) {
      tripStats.value = result.data!;
      monthlyTotalExpense.value = tripStats.fold(0, (sum, item) => sum + item.totalAmount);
    } else {
      tripStats.clear();
      monthlyTotalExpense.value = 0;
    }

    // Fetch dữ liệu riêng cho cả năm đang chọn (cho thẻ dashboard)
    if (!isAllTimeMode.value) {
      final yearResult = await _expenseRepo.getOverallStats(year: selectedYear.value);
      if (yearResult.success && yearResult.data != null) {
        yearlyTotalExpense.value = yearResult.data!.fold(0, (sum, item) => sum + item.totalAmount);
      } else {
        yearlyTotalExpense.value = 0;
      }
    }

    isLoading.value = false;
  }

  void onDateChanged(int month, int year) {
    isAllTimeMode.value = false;
    selectedMonth.value = month;
    selectedYear.value = year;
    fetchOverallStats();
  }

  void toggleAllTimeMode() {
    isAllTimeMode.value = true;
    fetchOverallStats();
  }
}
