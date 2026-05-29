import 'package:get/get.dart';
import '../../data/models/trip_response.dart';
import '../../data/repositories/trip_repository.dart';
import 'home_controller.dart';
import '../../utils/toast_util.dart';

class TrashController extends GetxController {
  final TripRepository _repository = TripRepository();
  var isLoading = true.obs;
  var trashTrips = <TripResponse>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchTrashTrips();
  }

  Future<void> fetchTrashTrips() async {
    isLoading.value = true;
    final result = await _repository.getTrashTrips();
    if (result.success && result.data != null) {
      trashTrips.value = result.data!;
    } else {
      trashTrips.clear();
    }
    isLoading.value = false;
  }

  Future<void> restoreTrip(int tripId) async {
    final result = await _repository.restoreTrip(tripId);
    if (result.success) {
      ToastUtil.showSuccess("Thành công", result.message ?? "Phục hồi thành công");
      // Cập nhật lại danh sách thùng rác
      trashTrips.removeWhere((t) => t.id == tripId);
      // Cập nhật lại home screen
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().fetchTrips(isRefresh: true);
      }
    } else {
      ToastUtil.showError("Lỗi", result.message ?? "Lỗi phục hồi");
    }
  }

  Future<void> forceDeleteTrip(int tripId) async {
    final result = await _repository.forceDeleteTrip(tripId);
    if (result.success) {
      ToastUtil.showSuccess("Thành công", result.message ?? "Đã xóa vĩnh viễn");
      // Cập nhật lại danh sách thùng rác
      trashTrips.removeWhere((t) => t.id == tripId);
    } else {
      ToastUtil.showError("Lỗi", result.message ?? "Lỗi xóa vĩnh viễn");
    }
  }
}
