import 'package:get/get.dart';
import '../data/models/trip_response.dart';
import '../data/repositories/trip_repository.dart';
import 'fcm_controller.dart';

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


  @override
  void onInit() {
    super.onInit();
    Get.put(FcmController(), permanent: true); // permanent: true để nó sống xuyên suốt app
    fetchTrips(); // Gọi API ngay khi mở màn hình
  }

  // ==============================
  // HÀM TẢI DỮ LIỆU
  // ==============================
  Future<void> fetchTrips({bool isRefresh = true}) async {
    if (isRefresh) {
      currentTripPage.value = 0;
      isTripLastPage.value = false;
      isLoadingMoreTrips.value = false;
      if (searchKeyword.value.isNotEmpty) {
        trips.clear(); // Nếu đang search thì clear cho nó nháy loading cho đẹp
      }
      if (trips.isEmpty) isLoading.value = true;
    } else {
      if (isTripLastPage.value || isLoadingMoreTrips.value) return;
      isLoadingMoreTrips.value = true;
    }

    final result = await _repository.getMyTripsPaginated(
      keyword: searchKeyword.value,
      page: currentTripPage.value,
      size: 10,
    );

    if (result.success && result.data != null) {
      if (isRefresh) {
        trips.value = result.data!.content;
      } else {
        trips.addAll(result.data!.content);
      }
      currentTripPage.value++;
      isTripLastPage.value = result.data!.last;
    }

    isLoading.value = false;
    if (!isRefresh) isLoadingMoreTrips.value = false;
  }

  // Hàm gọi khi gõ vào ô Search
  void onSearchTrips(String keyword) {
    searchKeyword.value = keyword;
    fetchTrips(isRefresh: true);
  }
}