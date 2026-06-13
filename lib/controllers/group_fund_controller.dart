import 'package:chiabill/data/models/fund_contribution_response.dart';
import 'package:chiabill/data/models/fund_response.dart';
import 'package:chiabill/services/group_fund_service.dart';
import 'package:chiabill/utils/toast_util.dart';
import 'package:get/get.dart';
import 'trip_detail_controller.dart';
import 'trip_settlement_controller.dart';

class GroupFundController extends GetxController {
  final int tripId;
  GroupFundController(this.tripId);

  final GroupFundService _fundService = GroupFundService();

  var fund = Rxn<FundResponse>();
  var contributions = <FundContributionResponse>[].obs;

  var isLoading = false.obs;
  var isContributionsLoading = false.obs;
  var isActionLoading = false.obs;
  var isFundActivated = false.obs;

  @override
  void onInit() {
    super.onInit();
    isActionLoading.value = false;
  }

  Future<void> fetchFundData() async {
    isLoading.value = true;
    contributions.clear();
    final result = await _fundService.getFund(tripId);
    if (result.success && result.data != null) {
      fund.value = result.data;
      isFundActivated.value = true;
      await fetchContributions();
    } else {
      isFundActivated.value = false;
      fund.value = null;
    }
    isLoading.value = false;
  }

  Future<void> fetchContributions() async {
    isContributionsLoading.value = true;
    final result = await _fundService.getContributions(tripId);
    if (result.success && result.data != null) {
      contributions.value = result.data!;
    }
    isContributionsLoading.value = false;
  }

  Future<bool> activateFund(double? alertThreshold, int? treasurerId) async {
    isActionLoading.value = true;
    final result = await _fundService.activateFund(tripId, alertThreshold, treasurerId);
    isActionLoading.value = false;

    if (result.success && result.data != null) {
      fund.value = result.data;
      isFundActivated.value = true;
      ToastUtil.showSuccess("Thành công", "Đã kích hoạt Quỹ chung!");
      fetchContributions();
      return true;
    } else {
      ToastUtil.showError("Lỗi", result.message ?? "Không thể kích hoạt Quỹ chung");
      return false;
    }
  }

  Future<bool> updateTreasurer(int treasurerId) async {
    isActionLoading.value = true;
    final result = await _fundService.updateTreasurer(tripId, treasurerId);
    isActionLoading.value = false;

    if (result.success && result.data != null) {
      fund.value = result.data;
      ToastUtil.showSuccess("Thành công", "Đã thay đổi thủ quỹ mới!");
      return true;
    } else {
      ToastUtil.showError("Lỗi", result.message ?? "Không thể đổi thủ quỹ");
      return false;
    }
  }

  Future<bool> createRequiredContribution({
    required double amount,
    required String notes,
    required List<int> contributorIds,
  }) async {
    isActionLoading.value = true;
    final result = await _fundService.createRequiredContribution(
      tripId: tripId,
      amount: amount,
      notes: notes,
      contributorIds: contributorIds,
    );
    isActionLoading.value = false;

    if (result.success) {
      ToastUtil.showSuccess("Thành công", "Đã tạo đợt nộp quỹ bắt buộc!");
      await fetchContributions();
      
      // Reload nợ nần
      _triggerReloads();
      return true;
    } else {
      ToastUtil.showError("Lỗi", result.message ?? "Không thể tạo đợt nộp quỹ");
      return false;
    }
  }

  Future<bool> createVoluntaryContribution({
    required double amount,
    required String notes,
  }) async {
    isActionLoading.value = true;
    final result = await _fundService.createVoluntaryContribution(
      tripId: tripId,
      amount: amount,
      notes: notes,
    );
    isActionLoading.value = false;

    if (result.success && result.data != null) {
      ToastUtil.showSuccess("Cảm ơn!", "Đóng góp tự nguyện của bạn đã được ghi nhận!");
      // Cập nhật số dư local trước
      if (fund.value != null) {
        fund.value = FundResponse(
          id: fund.value!.id,
          tripId: fund.value!.tripId,
          balance: fund.value!.balance + amount,
          currency: fund.value!.currency,
          alertThreshold: fund.value!.alertThreshold,
          treasurer: fund.value!.treasurer,
        );
      }
      await fetchContributions();
      
      // Update Main Trip Detail để reload số dư
      if (Get.isRegistered<TripDetailController>(tag: tripId.toString())) {
        Get.find<TripDetailController>(tag: tripId.toString()).fetchTripDetail();
      }
      return true;
    } else {
      ToastUtil.showError("Lỗi", result.message ?? "Không thể thực hiện đóng góp");
      return false;
    }
  }

  Future<bool> confirmContribution(int contributionId) async {
    isActionLoading.value = true;
    final result = await _fundService.confirmContribution(tripId, contributionId);
    isActionLoading.value = false;

    if (result.success && result.data != null) {
      ToastUtil.showSuccess("Thành công", "Đã xác nhận đóng quỹ!");
      
      // Cập nhật cục bộ đóng góp
      final idx = contributions.indexWhere((c) => c.id == contributionId);
      if (idx != -1) {
        contributions[idx] = result.data!;
      }
      
      // Reload thông tin quỹ để cập nhật số dư mới
      final fundResult = await _fundService.getFund(tripId);
      if (fundResult.success && fundResult.data != null) {
        fund.value = fundResult.data;
      }

      // Reload nợ nần
      _triggerReloads();
      return true;
    } else {
      ToastUtil.showError("Lỗi", result.message ?? "Không thể xác nhận đóng quỹ");
      return false;
    }
  }

  Future<bool> confirmMultipleContributions(List<int> contributionIds) async {
    isActionLoading.value = true;
    bool allSuccess = true;
    String? errorMsg;
    
    for (final id in contributionIds) {
      final result = await _fundService.confirmContribution(tripId, id);
      if (result.success && result.data != null) {
        final idx = contributions.indexWhere((c) => c.id == id);
        if (idx != -1) {
          contributions[idx] = result.data!;
        }
      } else {
        allSuccess = false;
        errorMsg = result.message;
      }
    }
    
    isActionLoading.value = false;

    if (allSuccess) {
      ToastUtil.showSuccess("Thành công", "Đã xác nhận toàn bộ đóng quỹ cho thành viên!");
      
      // Reload thông tin quỹ để cập nhật số dư mới
      final fundResult = await _fundService.getFund(tripId);
      if (fundResult.success && fundResult.data != null) {
        fund.value = fundResult.data;
      }

      // Reload nợ nần
      _triggerReloads();
      return true;
    } else {
      ToastUtil.showError("Thông báo", errorMsg ?? "Không thể xác nhận một số đợt đóng quỹ");
      
      // Vẫn reload lại để đồng bộ trạng thái mới nhất
      final fundResult = await _fundService.getFund(tripId);
      if (fundResult.success && fundResult.data != null) {
        fund.value = fundResult.data;
      }
      _triggerReloads();
      return false;
    }
  }

  void _triggerReloads() {
    // Reload nợ nần ở Settlements Tab
    if (Get.isRegistered<TripSettlementController>(tag: tripId.toString())) {
      Get.find<TripSettlementController>(tag: tripId.toString()).fetchSettlements();
    }
    // Reload Trip Detail
    if (Get.isRegistered<TripDetailController>(tag: tripId.toString())) {
      Get.find<TripDetailController>(tag: tripId.toString()).fetchTripDetail();
    }
  }
}
