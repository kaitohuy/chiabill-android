import 'package:chiabill/data/models/trip_member_response.dart';
import 'package:chiabill/data/models/trip_response.dart';
import 'package:chiabill/data/repositories/trip_repository.dart';
import 'package:chiabill/utils/toast_util.dart';
import 'package:get/get.dart';
import 'trip_detail_controller.dart';

class ImportMemberController extends GetxController {
  final int currentTripId;
  final TripRepository _repo = TripRepository();

  var isLoadingTrips = true.obs;
  var isLoadingMembers = false.obs;
  var isImporting = false.obs;

  var myTrips = <TripResponse>[].obs;
  var selectedTripId = RxnInt();

  var availableMembers = <TripMemberResponse>[].obs;
  var selectedUserIds = <int>[].obs;

  ImportMemberController(this.currentTripId);

  @override
  void onInit() {
    super.onInit();
    fetchMyTrips();
  }

  Future<void> fetchMyTrips() async {
    isLoadingTrips.value = true;
    final result = await _repo.getMyTrips();
    if (result.success && result.data != null) {
      // Loại bỏ trip hiện tại ra khỏi danh sách
      myTrips.value = result.data!.where((t) => t.id != currentTripId).toList();
    } else {
      ToastUtil.showError("Lỗi", result.message ?? "Không thể lấy danh sách nhóm");
    }
    isLoadingTrips.value = false;
  }

  Future<void> onTripSelected(int? tripId) async {
    selectedTripId.value = tripId;
    if (tripId == null) {
      availableMembers.clear();
      selectedUserIds.clear();
      return;
    }

    isLoadingMembers.value = true;
    final result = await _repo.getTripDetail(tripId);
    if (result.success && result.data != null) {
      final tripDetail = result.data!;
      
      // Lấy danh sách thành viên của trip hiện tại để loại bỏ những người đã có mặt
      List<int> currentMemberIds = [];
      if (Get.isRegistered<TripDetailController>(tag: currentTripId.toString())) {
        final currentTrip = Get.find<TripDetailController>(tag: currentTripId.toString()).trip.value;
        if (currentTrip != null && currentTrip.members != null) {
          currentMemberIds = currentTrip.members!.map((m) => m.id).toList();
        }
      }

      availableMembers.value = tripDetail.members!
          .where((m) => !currentMemberIds.contains(m.id))
          .toList();
      selectedUserIds.clear(); // Reset selection
    } else {
      ToastUtil.showError("Lỗi", result.message ?? "Không thể lấy thành viên nhóm này");
      availableMembers.clear();
    }
    isLoadingMembers.value = false;
  }

  void toggleMemberSelection(int userId) {
    if (selectedUserIds.contains(userId)) {
      selectedUserIds.remove(userId);
    } else {
      selectedUserIds.add(userId);
    }
  }

  void toggleAllMembers(bool selectAll) {
    if (selectAll) {
      selectedUserIds.value = availableMembers.map((m) => m.id).toList();
    } else {
      selectedUserIds.clear();
    }
  }

  Future<void> importMembers() async {
    if (selectedUserIds.isEmpty) {
      ToastUtil.showWarning("Chưa chọn", "Vui lòng chọn ít nhất 1 thành viên để nhập");
      return;
    }

    isImporting.value = true;
    final result = await _repo.importMembers(currentTripId, selectedUserIds);
    isImporting.value = false;

    if (result.success) {
      Get.back(); // Đóng màn hình
      
      // Delay to avoid BLASTBufferQueue errors during heavy UI transitions
      Future.delayed(const Duration(milliseconds: 300), () {
        ToastUtil.showSuccess("Thành công", "Đã nhập ${selectedUserIds.length} thành viên vào nhóm");
      });
      
      Future.delayed(const Duration(milliseconds: 800), () {
        if (Get.isRegistered<TripDetailController>(tag: currentTripId.toString())) {
          Get.find<TripDetailController>(tag: currentTripId.toString()).fetchData(isSilent: true);
        }
      });
    } else {
      ToastUtil.showError("Lỗi", result.message ?? "Nhập thành viên thất bại");
    }
  }
}
