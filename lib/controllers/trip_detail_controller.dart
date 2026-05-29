import 'package:chiabill/utils/toast_util.dart';
import 'package:chiabill/controllers/profile_controller.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:chiabill/utils/loading_util.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../data/models/trip_response.dart';
import '../services/trip_service.dart';
import 'home_controller.dart';
import 'trip_expense_controller.dart';
import 'trip_settlement_controller.dart';
import 'trip_history_controller.dart';
import '../services/offline_sync_service.dart';

class TripDetailController extends GetxController {
  final int tripId;
  TripDetailController(this.tripId);

  final TripService _tripService = TripService();

  var isLoading = true.obs;
  var trip = Rxn<TripResponse>();

  var currentTab = 0.obs;
  var isAddingMember = false.obs;
  var activeInviteCode = "".obs;
  var isSharingInvite = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Khởi tạo các controller con dùng chung tripId
    Get.put(TripExpenseController(tripId), tag: tripId.toString());
    Get.put(TripSettlementController(tripId), tag: tripId.toString());
    Get.put(TripHistoryController(tripId), tag: tripId.toString());

    if (Get.isRegistered<OfflineSyncService>()) {
      ever(Get.find<OfflineSyncService>().syncTrigger, (_) {
        if (!isClosed) fetchData(isSilent: true);
      });
    }

    fetchData();
  }

  Future<void> transferOwner(int newOwnerId) async {
    isLoading.value = true;
    final res = await _tripService.transferOwner(tripId, newOwnerId);
    if (res.success) {
      await fetchTripDetail();
    }
    isLoading.value = false;
  }

  Future<void> activateMember(int memberId) async {
    isLoading.value = true;
    final res = await _tripService.activateMember(tripId, memberId);
    if (res.success) {
      await fetchTripDetail();
    }
    isLoading.value = false;
  }

  Future<void> disableMember(int memberId) async {
    isLoading.value = true;
    final res = await _tripService.disableMember(tripId, memberId);
    if (res.success) {
      await fetchTripDetail();
    }
    isLoading.value = false;
  }

  Future<void> kickMember(int memberId, bool forgive) async {
    isLoading.value = true;
    final res = await _tripService.kickMember(tripId, memberId, forgive);
    if (res.success) {
      await fetchTripDetail();
    }
    isLoading.value = false;
  }



  @override
  void onClose() {
    Get.delete<TripExpenseController>(tag: tripId.toString());
    Get.delete<TripSettlementController>(tag: tripId.toString());
    Get.delete<TripHistoryController>(tag: tripId.toString());
    super.onClose();
  }

  Future<void> fetchData({bool isSilent = false}) async {
    if (!isSilent) isLoading.value = true;
    
    await Future.wait([
      fetchTripDetail(),
      fetchActiveInvite(),
    ]);

    // Các Controller con tự load data theo onInit() của chúng, nhưng nếu gọi fetchData() thủ công thì có thể trigger reload
    if (Get.isRegistered<TripExpenseController>(tag: tripId.toString())) {
      Get.find<TripExpenseController>(tag: tripId.toString()).fetchExpenses(isSilent: true);
      Get.find<TripExpenseController>(tag: tripId.toString()).fetchStats();
    }
    if (Get.isRegistered<TripSettlementController>(tag: tripId.toString())) {
      Get.find<TripSettlementController>(tag: tripId.toString()).fetchSettlements();
    }
    if (Get.isRegistered<TripHistoryController>(tag: tripId.toString())) {
      Get.find<TripHistoryController>(tag: tripId.toString()).fetchTripHistory(isSilent: true);
      Get.find<TripHistoryController>(tag: tripId.toString()).fetchPayments(isSilent: true);
    }

    if (!isSilent) isLoading.value = false;
  }

  Future<void> fetchTripDetail() async {
    final result = await _tripService.getTripDetail(tripId);
    if (result.success) trip.value = result.data;
  }

  Future<void> fetchActiveInvite() async {
    final result = await _tripService.getActiveInvite(tripId);
    if (result.success && result.data != null) {
      activeInviteCode.value = result.data!.inviteCode;
    }
  }

  Future<void> generateInviteCode(String customCode) async {
    isLoading.value = true;
    final result = await _tripService.generateInviteCode(tripId, customCode);

    if (result.success && result.data != null) {
      activeInviteCode.value = result.data!.inviteCode;
    } else {
      ToastUtil.showError("Lỗi", result.message ?? "Không thể tạo mã mời");
    }
    isLoading.value = false;
  }

  void copyToClipboard() {
    if (activeInviteCode.value.isNotEmpty) {
      final String baseUrl = dotenv.env['BASE_URL'] ?? "https://chiabill-server.onrender.com";
      final inviteUrl = "$baseUrl/join/${activeInviteCode.value}";
      Clipboard.setData(ClipboardData(text: inviteUrl));
      ToastUtil.showSuccess("Thành công", "Đã copy link mời tham gia");
    }
  }

  Future<void> shareInviteLink() async {
    if (isSharingInvite.value || activeInviteCode.value.isEmpty) return;
    
    isSharingInvite.value = true;
    final String codeToShare = activeInviteCode.value;
    final String baseUrl = dotenv.env['BASE_URL'] ?? "https://chiabill-server.onrender.com";
    final String shareText = 'Mời bạn tham gia nhóm trên ChiaBill:\n$baseUrl/join/$codeToShare';

    try {
      await SharePlus.instance.share(ShareParams(text: shareText));
    } finally {
      Future.delayed(const Duration(seconds: 1), () {
        isSharingInvite.value = false;
      });
    }
  }

  Future<void> deleteTrip() async {
    isLoading.value = true;
    final result = await _tripService.deleteTrip(tripId);
    if (result.success) {
      Get.back();
      Get.back();
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
    isAddingMember.value = true;
    final result = await _tripService.addDirectMember(tripId, input);
    isAddingMember.value = false;

    if (result.success) {
      Get.back();
      ToastUtil.showSuccess("Thành công", "Đã thêm thành viên. Nhớ cập nhật khoản chi cũ nếu muốn họ gánh chung nhé!");
      fetchData(isSilent: true);
    } else {
      ToastUtil.showError("Thất bại", result.message ?? "Không thể thêm");
    }
  }

  int? get currentUserId {
    if (Get.isRegistered<ProfileController>()) {
      return Get.find<ProfileController>().user.value?.id;
    }
    return GetStorage().read('userId');
  }

  bool get isOwner => trip.value?.ownerId != null && trip.value?.ownerId == currentUserId;

  Future<void> leaveTrip() async {
    if (Get.isDialogOpen == true) Get.back();
    isLoading.value = true;
    final result = await _tripService.leaveTrip(tripId);
    isLoading.value = false;
    if (result.success) {
      Get.back();
      ToastUtil.showSuccess("Thành công", "Bạn đã rời khỏi nhóm");
      if (Get.isRegistered<HomeController>()) Get.find<HomeController>().fetchTrips();
    } else {
      ToastUtil.showError("Không thể rời nhóm", result.message ?? "Lỗi máy chủ.");
    }
  }




  Future<void> exportTrip(
    String format, {
    bool includeDetails = false,
    bool includeSettlement = false,
  }) async {
    try {
      LoadingUtil.show();
      final result = await _tripService.exportTripBytes(
        tripId,
        format,
        includeDetails: includeDetails,
        includeSettlement: includeSettlement,
      );
      LoadingUtil.hide();

      if (result.success && result.data != null) {
        final List<int> bytes = List<int>.from(result.data!);

        // Sử dụng thư mục tạm an toàn để tránh crash Scoped Storage trên Android 11+
        final tempDir = await getTemporaryDirectory();
        final ext = format == 'excel' ? 'xlsx' : 'pdf';
        final safeName = (trip.value?.name ?? 'ChuyenDi')
            .replaceAll(RegExp(r'[^\w\s]'), '')
            .replaceAll(' ', '_');
        final fileName = "BaoCao_${safeName}_$tripId.$ext";
        final filePath = "${tempDir.path}/$fileName";

        final file = File(filePath);
        await file.writeAsBytes(bytes, flush: true);

        final savedSize = await file.length();
        print('[Export] Saved $filePath — $savedSize bytes');

        if (savedSize < 100) {
          ToastUtil.showError("Lỗi xuất file", "File tải về bị lỗi ($savedSize bytes)");
          return;
        }

        // Hiển thị thông báo mở hộp thoại chia sẻ
        ToastUtil.showSuccess("Đã xuất báo cáo", "📁 Đang chuẩn bị chia sẻ tệp...");

        // Mở share sheet để user có thể chia sẻ hoặc mở ngay
        final mimeType = format == 'excel'
            ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
            : 'application/pdf';

        await SharePlus.instance.share(
          ShareParams(
            text: 'Bao cao chi tieu chuyen di: ${trip.value?.name}',
            files: [XFile(filePath, mimeType: mimeType)],
          ),
        );
      } else {
        ToastUtil.showError("Lỗi xuất file", result.message ?? "Không thể tải báo cáo");
      }
    } catch (e) {
      LoadingUtil.hide();
      ToastUtil.showError("Lỗi hệ thống", "Đã xảy ra lỗi khi xử lý tệp: $e");
    }
  }
}
