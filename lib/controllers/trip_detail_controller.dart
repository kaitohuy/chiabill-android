import 'package:flutter/material.dart';
import 'package:chiabill/utils/toast_util.dart';
import 'package:chiabill/utils/export_helper.dart';
import 'package:chiabill/controllers/profile_controller.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:chiabill/utils/loading_util.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models/trip_response.dart';
import '../services/trip_service.dart';
import 'home_controller.dart';
import 'trip_expense_controller.dart';
import 'trip_settlement_controller.dart';
import 'trip_history_controller.dart';
import 'itinerary_controller.dart';
import 'group_fund_controller.dart';
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

  Worker? _syncWorker;
  Worker? _tabWorker;

  @override
  void onInit() {
    super.onInit();
    // Khởi tạo các controller con dùng chung tripId
    Get.put(TripExpenseController(tripId), tag: tripId.toString());
    Get.put(TripSettlementController(tripId), tag: tripId.toString());
    Get.put(ItineraryController(tripId), tag: tripId.toString());

    if (Get.isRegistered<OfflineSyncService>()) {
      _syncWorker = ever(Get.find<OfflineSyncService>().syncTrigger, (_) {
        if (!isClosed) fetchData(isSilent: true);
      });
    }

    _tabWorker = ever(currentTab, (_) {
      triggerActiveTabFetch();
    });

    fetchData();
  }

  void triggerActiveTabFetch() {
    final String tagStr = tripId.toString();
    final int index = currentTab.value;
    
    if (index == 0) {
      if (Get.isRegistered<TripExpenseController>(tag: tagStr)) {
        final ctrl = Get.find<TripExpenseController>(tag: tagStr);
        ctrl.fetchCategories();
        ctrl.fetchExpenses(isRefresh: true, isSilent: true);
        ctrl.fetchStats();
      }
    } else if (index == 1) {
      final fundCtrl = Get.isRegistered<GroupFundController>(tag: tagStr)
          ? Get.find<GroupFundController>(tag: tagStr)
          : Get.put(GroupFundController(tripId), tag: tagStr);
      fundCtrl.fetchFundData();
    } else if (index == 2) {
      if (Get.isRegistered<TripSettlementController>(tag: tagStr)) {
        Get.find<TripSettlementController>(tag: tagStr).fetchSettlements();
      }
    }
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
      ToastUtil.showSuccess("success".tr, "member_activated_success".tr);
    } else {
      ToastUtil.showError("error".tr, res.message ?? "cannot_activate_member".tr);
    }
    isLoading.value = false;
  }

  Future<void> disableMember(int memberId) async {
    isLoading.value = true;
    final res = await _tripService.disableMember(tripId, memberId);
    if (res.success) {
      await fetchTripDetail();
      ToastUtil.showSuccess("success".tr, "member_disabled_success".tr);
    } else {
      ToastUtil.showError("error".tr, res.message ?? "cannot_disable_member".tr);
    }
    isLoading.value = false;
  }

  Future<void> kickMember(int memberId, bool forgive) async {
    isLoading.value = true;
    final res = await _tripService.kickMember(tripId, memberId, forgive);
    if (res.success) {
      await fetchTripDetail();
      ToastUtil.showSuccess("success".tr, "member_kicked_success".tr);
    } else {
      ToastUtil.showError("error".tr, res.message ?? "cannot_kick_member".tr);
    }
    isLoading.value = false;
  }


  @override
  void onClose() {
    _syncWorker?.dispose();
    _tabWorker?.dispose();
    Get.delete<TripExpenseController>(tag: tripId.toString());
    Get.delete<TripSettlementController>(tag: tripId.toString());
    if (Get.isRegistered<TripHistoryController>(tag: tripId.toString())) {
      Get.delete<TripHistoryController>(tag: tripId.toString());
    }
    Get.delete<ItineraryController>(tag: tripId.toString());
    super.onClose();
  }

  Future<void> fetchData({bool isSilent = false}) async {
    if (!isSilent) isLoading.value = true;
    
    final detailResult = await _tripService.getTripDetail(tripId);
    if (!detailResult.success) {
      if (!isSilent) isLoading.value = false;
      Future.delayed(Duration.zero, () {
        ToastUtil.showError("cannot_access".tr, detailResult.message ?? "failed_to_load_trip_info".tr);
        Get.back();
      });
      return;
    }

    trip.value = detailResult.data;
    await fetchActiveInvite();

    // Trigger lazy loading cho tab đang hoạt động
    triggerActiveTabFetch();

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
      ToastUtil.showError("error".tr, result.message ?? "cannot_create_invite_code".tr);
    }
    isLoading.value = false;
  }

  void copyToClipboard() {
    if (activeInviteCode.value.isNotEmpty) {
      final String baseUrl = dotenv.env['BASE_URL'] ?? "https://chiabill-server.onrender.com";
      final inviteUrl = "$baseUrl/join/${activeInviteCode.value}";
      Clipboard.setData(ClipboardData(text: inviteUrl));
      ToastUtil.showSuccess("success".tr, "invite_link_copied".tr);
    }
  }

  Future<void> shareInviteLink() async {
    if (isSharingInvite.value || activeInviteCode.value.isEmpty) return;
    
    isSharingInvite.value = true;
    final String codeToShare = activeInviteCode.value;
    final String baseUrl = dotenv.env['BASE_URL'] ?? "";
    final String shareText = "invite_message_prefix".trParams({'url': '$baseUrl/join/$codeToShare'});

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
        ToastUtil.showSuccess("notification".tr, "trip_deleted_success".tr);
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().fetchTrips();
        }
      });
    } else {
      ToastUtil.showError("error".tr, result.message ?? "cannot_delete".tr);
      isLoading.value = false;
    }
  }

  Future<void> addDirectMember(String input) async {
    isAddingMember.value = true;
    final result = await _tripService.addDirectMember(tripId, input);
    isAddingMember.value = false;

    if (result.success) {
      FocusManager.instance.primaryFocus?.unfocus();

      // Chờ bàn phím ẩn
      await Future.delayed(const Duration(milliseconds: 150));
      Get.back();

      Future.delayed(const Duration(milliseconds: 300), () {
        ToastUtil.showSuccess("success".tr, "member_added_success_remind".tr);
      });
      fetchData(isSilent: true);
    } else {
      ToastUtil.showError("failed".tr, result.message ?? "cannot_add".tr);
    }
  }

  int? get currentUserId {
    if (Get.isRegistered<ProfileController>()) {
      return Get.find<ProfileController>().user.value?.id;
    }
    return GetStorage().read('userId');
  }

  bool get isOwner => trip.value?.ownerId != null && trip.value?.ownerId == currentUserId;

  bool get isCurrentUserDisabled {
    if (trip.value == null) return false;
    final uId = currentUserId;
    if (uId == null) return false;
    final member = trip.value!.members?.firstWhereOrNull((m) => m.id == uId);
    return member?.status == 'DISABLED';
  }

  Future<void> leaveTrip() async {
    if (Get.isDialogOpen == true) Get.back();
    isLoading.value = true;
    final result = await _tripService.leaveTrip(tripId);
    isLoading.value = false;
    if (result.success) {
      Get.back();
      ToastUtil.showSuccess("success".tr, "left_group_success".tr);
      if (Get.isRegistered<HomeController>()) Get.find<HomeController>().fetchTrips();
    } else {
      ToastUtil.showError("cannot_leave_group".tr, result.message ?? "SERVER_ERROR".tr);
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
      await LoadingUtil.hide();

      if (result.success && result.data != null) {
        final List<int> bytes = List<int>.from(result.data!);

        final ext = format == 'excel' ? 'xlsx' : 'pdf';
        final safeName = (trip.value?.name ?? 'ChuyenDi')
            .replaceAll(RegExp(r'[^\w\s]'), '')
            .replaceAll(' ', '_');
        final fileName = "${'report_file_prefix'.tr}_${safeName}_$tripId.$ext";

        final mimeType = format == 'excel'
            ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
            : 'application/pdf';

        ExportHelper.showExportActionSheet(
          bytes: bytes,
          fileName: fileName,
          mimeType: mimeType,
          shareText: 'report_share_text'.trParams({'name': trip.value?.name ?? ''}),
        );
      } else {
        ToastUtil.showError("export_file_error".tr, result.message ?? "cannot_download_report".tr);
      }
    } catch (e) {
      await LoadingUtil.hide();
      ToastUtil.showError("system_error".tr, "error_processing_file".trParams({'error': e.toString()}));
    }
  }
}
