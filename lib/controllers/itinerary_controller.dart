import 'package:chiabill/utils/toast_util.dart';
import 'package:chiabill/utils/loading_util.dart';
import 'package:get/get.dart';
import '../data/models/itinerary_item_response.dart';
import '../data/models/trip_response.dart';
import '../data/repositories/itinerary_repository.dart';
import '../data/repositories/trip_repository.dart';
import 'package:chiabill/services/alarm_service.dart';
import 'package:flutter/foundation.dart';
import 'trip_detail_controller.dart';
import '../utils/time_util.dart';

class ItineraryController extends GetxController {
  final int tripId;
  ItineraryController(this.tripId);

  final ItineraryRepository _repo = ItineraryRepository();
  final TripRepository _tripRepo = TripRepository();

  var isLoading = false.obs;
  var itineraryList = <ItineraryItemResponse>[].obs;
  var selectedDayIndex = 0.obs;
  var isBannerDismissed = false.obs;
  var isAscending = true.obs;
  var localTrip = Rxn<TripResponse>();
  var hasLoadedOnce = false.obs;

  Worker? _alarmWorker;

  @override
  void onInit() {
    super.onInit();
    fetchItinerary();
    if (_tripDetailController == null) {
      fetchTripDetail();
    }

    if (_tripDetailController != null) {
      _alarmWorker = ever(_tripDetailController!.trip, (_) {
        _rescheduleTripAlarms();
      });
    } else {
      _alarmWorker = ever(localTrip, (_) {
        _rescheduleTripAlarms();
      });
    }
  }

  @override
  void onClose() {
    _alarmWorker?.dispose();
    super.onClose();
  }

  Future<void> fetchTripDetail() async {
    try {
      final res = await _tripRepo.getTripDetail(tripId);
      if (res.success && res.data != null) {
        localTrip.value = res.data;
        _rescheduleTripAlarms();
      }
    } catch (_) {}
  }

  Future<List<TripResponse>> fetchAllMyTrips() async {
    try {
      final res = await _tripRepo.getMyTrips();
      if (res.success && res.data != null) {
        return res.data!;
      }
    } catch (_) {}
    return [];
  }

  /// Tải lịch trình từ API
  Future<void> fetchItinerary({bool showLoading = true}) async {
    if (showLoading) isLoading.value = true;
    try {
      final res = await _repo.getItinerary(tripId);
      if (res.success && res.data != null) {
        itineraryList.assignAll(res.data!);
        _rescheduleTripAlarms();
      } else {
        ToastUtil.showError("Lỗi", res.message ?? "Không thể tải lịch trình");
      }
    } catch (e) {
      ToastUtil.showError("Lỗi hệ thống", e.toString());
    } finally {
      if (showLoading) isLoading.value = false;
      hasLoadedOnce.value = true;
    }
  }

  Future<List<int>?> exportItineraryToExcel() async {
    try {
      final res = await _repo.exportItineraryBytes(tripId);
      if (res.success && res.data != null) {
        return res.data;
      } else {
        ToastUtil.showError("Lỗi", res.message ?? "Không thể xuất lịch trình");
      }
    } catch (e) {
      ToastUtil.showError("Lỗi hệ thống", e.toString());
    }
    return null;
  }

  /// Lấy thông tin Trip từ TripDetailController để tính toán ngày tuyệt đối
  TripDetailController? get _tripDetailController {
    if (Get.isRegistered<TripDetailController>(tag: tripId.toString())) {
      return Get.find<TripDetailController>(tag: tripId.toString());
    }
    return null;
  }

  String? get startDate => _tripDetailController?.trip.value?.startDate ?? localTrip.value?.startDate;
  String? get endDate => _tripDetailController?.trip.value?.endDate ?? localTrip.value?.endDate;
  String get tripName => _tripDetailController?.trip.value?.name ?? localTrip.value?.name ?? "Lịch trình";

  /// Sinh danh sách các ngày tuyệt đối dựa trên startDate, endDate và max day trong lịch trình
  List<DateTime> get tripDays {
    if (startDate == null) return [DateTime.now()];
    final start = DateTime.tryParse(startDate!) ?? DateTime.now();
    int daysCount = 3; // Mặc định ít nhất 3 ngày
    if (endDate != null) {
      final end = DateTime.tryParse(endDate!) ?? start;
      daysCount = end.difference(start).inDays + 1;
    }
    // Nếu có hoạt động vượt quá số ngày của Trip, mở rộng tab tương ứng
    if (itineraryList.isNotEmpty) {
      final maxDayNum = itineraryList.map((e) => e.dayNumber).reduce((a, b) => a > b ? a : b);
      if (maxDayNum > daysCount) {
        daysCount = maxDayNum;
      }
    }
    return List.generate(daysCount, (i) => start.add(Duration(days: i)));
  }

  /// Nhóm các hoạt động theo ngày (dayNumber)
  Map<int, List<ItineraryItemResponse>> get groupedItinerary {
    Map<int, List<ItineraryItemResponse>> grouped = {};
    for (var item in itineraryList) {
      grouped.putIfAbsent(item.dayNumber, () => []).add(item);
    }
    // Sắp xếp các hoạt động trong cùng ngày theo khung giờ (nếu có)
    grouped.forEach((day, list) {
      list.sort((a, b) => compareTimeRanges(a.timeRange, b.timeRange));
    });
    return grouped;
  }

  /// Thêm hoặc chỉnh sửa hoạt động lẻ
  Future<bool> saveItineraryItem(ItineraryItemResponse item, {bool showLoading = true, bool showToast = true}) async {
    if (showLoading) LoadingUtil.show();
    try {
      final res = await _repo.saveItineraryItem(tripId, item);
      if (showLoading) LoadingUtil.hide();
      if (res.success && res.data != null) {
        await fetchItinerary(showLoading: showLoading); // Reload silently if showLoading is false
        if (showToast) ToastUtil.showSuccess("Thành công", "Đã lưu hoạt động");
        return true;
      } else {
        if (showToast) ToastUtil.showError("Lỗi", res.message ?? "Không thể lưu hoạt động");
        return false;
      }
    } catch (e) {
      if (showLoading) LoadingUtil.hide();
      if (showToast) ToastUtil.showError("Lỗi hệ thống", e.toString());
      return false;
    }
  }

  /// Xóa hoạt động lẻ
  Future<bool> deleteItineraryItem(int itemId) async {
    LoadingUtil.show();
    try {
      final res = await _repo.deleteItineraryItem(tripId, itemId);
      LoadingUtil.hide();
      if (res.success) {
        itineraryList.removeWhere((e) => e.id == itemId);
        _rescheduleTripAlarms();
        ToastUtil.showSuccess("Thành công", "Đã xóa hoạt động");
        return true;
      } else {
        ToastUtil.showError("Lỗi", res.message ?? "Không thể xóa hoạt động");
        return false;
      }
    } catch (e) {
      LoadingUtil.hide();
      ToastUtil.showError("Lỗi hệ thống", e.toString());
      return false;
    }
  }

  /// Lưu hàng loạt hoạt động (ví dụ sau khi Import Excel)
  Future<bool> saveItineraryBulk(List<ItineraryItemResponse> items, {bool showToast = true}) async {
    LoadingUtil.show();
    try {
      final res = await _repo.saveItineraryBulk(tripId, items);
      LoadingUtil.hide();
      if (res.success && res.data != null) {
        itineraryList.assignAll(res.data!);
        _rescheduleTripAlarms();
        if (showToast) {
          ToastUtil.showSuccess("Thành công", "Đã nhập ${res.data!.length} hoạt động lịch trình");
        }
        return true;
      } else {
        ToastUtil.showError("Lỗi", res.message ?? "Không thể lưu danh sách lịch trình");
        return false;
      }
    } catch (e) {
      LoadingUtil.hide();
      ToastUtil.showError("Lỗi hệ thống", e.toString());
      return false;
    }
  }

  Future<bool> cloneItineraryFromTrip(int sourceTripId, {bool showToast = true}) async {
    LoadingUtil.show();
    try {
      final res = await _repo.cloneItinerary(tripId, sourceTripId);
      LoadingUtil.hide();
      if (res.success && res.data != null) {
        itineraryList.assignAll(res.data!);
        _rescheduleTripAlarms();
        if (showToast) {
          ToastUtil.showSuccess("Thành công", "Đã sao chép lịch trình từ chuyến đi khác");
        }
        return true;
      } else {
        ToastUtil.showError("Lỗi", res.message ?? "Không thể sao chép lịch trình");
        return false;
      }
    } catch (e) {
      LoadingUtil.hide();
      ToastUtil.showError("Lỗi hệ thống", e.toString());
      return false;
    }
  }

  /// Tự động cập nhật lịch báo thức cục bộ của chuyến đi
  void _rescheduleTripAlarms() {
    try {
      AlarmService.scheduleAlarmsForTrip(
        tripId: tripId,
        tripName: tripName,
        startDateStr: startDate,
        items: itineraryList,
        coverUrl: _tripDetailController?.trip.value?.coverUrl ?? localTrip.value?.coverUrl,
      );
    } catch (e) {
      debugPrint('[ItineraryController] Failed to reschedule alarms: $e');
    }
  }
}
