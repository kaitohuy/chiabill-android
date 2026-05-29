import 'package:get/get.dart';
import '../data/models/trip_response.dart';
import '../data/repositories/trip_repository.dart';
import '../services/offline_sync_service.dart';
import 'fcm_controller.dart';
import '../utils/app_links_util.dart';

class HomeController extends GetxController {
  final TripRepository _repository = TripRepository();

  var isLoading = true.obs;
  var trips = <TripResponse>[].obs;

  // ==============================
  // BIẾN PHÂN TRANG VÀ TÌM KIẾM
  // ==============================

  var currentTripPage = 0.obs;
  var isTripLastPage = false.obs;
  var isLoadingMoreTrips = false.obs;
  var searchKeyword = "".obs;

  // BIẾN LỌC THEO THỜI GIAN
  var filterMode = 'Tất cả'.obs;
  var selectedMonth = DateTime.now().month.obs;
  var selectedYear = DateTime.now().year.obs;

  @override
  void onReady() {
    super.onReady();
    if (Get.isRegistered<AppLinksService>()) {
      Get.find<AppLinksService>().checkAndHandlePendingLink();
    }
  }

  @override
  void onInit() {
    super.onInit();
    Get.put(FcmController(), permanent: true);
    fetchTrips();
    
    debounce(searchKeyword, (_) {
      fetchTrips(isRefresh: true);
    }, time: const Duration(milliseconds: 500));
  }

  // ==============================
  // HÀM TẢI DỮ LIỆU
  // ==============================
  
  Future<void> fetchTrips({bool isRefresh = true}) async {
    if (isRefresh) {
      currentTripPage.value = 0;
      isTripLastPage.value = false;
      isLoadingMoreTrips.value = false;
      trips.clear(); 
      isLoading.value = true;
    } else {
      if (isTripLastPage.value || isLoadingMoreTrips.value) return;
      isLoadingMoreTrips.value = true;
    }

    try {
      final result = await _repository.getMyTripsPaginated(
        keyword: searchKeyword.value,
        month: filterMode.value == 'Tất cả' || filterMode.value == 'Năm' ? null : selectedMonth.value,
        year: filterMode.value == 'Tất cả' ? null : selectedYear.value,
        page: currentTripPage.value,
        size: 10,
      );

      if (result.success && result.data != null) {
        List<TripResponse> loadedData = result.data!.content;
        
        final syncService = Get.find<OfflineSyncService>();
        List<int> pendingDeletedIds = syncService.getPendingDeletedTripIds();
        
        // Lọc bỏ những chuyến đi đã xóa ngoại tuyến
        loadedData.removeWhere((t) => pendingDeletedIds.contains(t.id));

        if (isRefresh) {
          List<Map<String, dynamic>> pendingCreated = syncService.getPendingCreatedTrips();
          
          // Thêm những chuyến đi mới tạo (ảo) vào đầu danh sách
          List<TripResponse> offlineTrips = pendingCreated.map((req) {
            var data = req['data'] as Map<String, dynamic>? ?? {};
            return TripResponse(
              id: -1, // ID ảo để đánh dấu
              name: data['name'] ?? "Chuyến đi mới",
              description: data['description'],
              totalBudget: data['totalBudget'] != null ? double.tryParse(data['totalBudget'].toString()) : null,
              startDate: data['startDate'],
              createdAt: DateTime.now().toIso8601String(),
              categoryName: data['categoryName'],
              categoryIcon: data['categoryIcon'],
            );
          }).toList();

          trips.value = [...offlineTrips, ...loadedData];
        } else {
          trips.addAll(loadedData);
        }
        currentTripPage.value++;
        isTripLastPage.value = result.data!.last;
      }
    } finally {
      isLoading.value = false;
      if (!isRefresh) isLoadingMoreTrips.value = false;
    }
  }

  void onSearchTrips(String keyword) {
    searchKeyword.value = keyword;
  }

  void onFilterModeChanged(String mode) {
    filterMode.value = mode;
    fetchTrips(isRefresh: true);
  }

  void onDateChanged(int month, int year) {
    selectedMonth.value = month;
    selectedYear.value = year;
    fetchTrips(isRefresh: true);
  }
}
