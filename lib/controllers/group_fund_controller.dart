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
    try {
      final result = await _fundService.activateFund(tripId, alertThreshold, treasurerId);
      if (result.success && result.data != null) {
        fund.value = result.data;
        isFundActivated.value = true;
        ToastUtil.showSuccess("success".tr, "group_fund_activated".tr);
        fetchContributions();
        return true;
      } else {
        ToastUtil.showError("error".tr, result.message ?? "failed_activate_group_fund".tr);
        return false;
      }
    } catch (e) {
      ToastUtil.showError("error".tr, "connection_error".tr);
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<bool> updateTreasurer(int treasurerId) async {
    isActionLoading.value = true;
    try {
      final result = await _fundService.updateTreasurer(tripId, treasurerId);
      if (result.success && result.data != null) {
        fund.value = result.data;
        ToastUtil.showSuccess("success".tr, "treasurer_changed".tr);
        return true;
      } else {
        ToastUtil.showError("error".tr, result.message ?? "failed_change_treasurer".tr);
        return false;
      }
    } catch (e) {
      ToastUtil.showError("error".tr, "connection_error".tr);
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<bool> createRequiredContribution({
    required double amount,
    required String notes,
    required List<int> contributorIds,
  }) async {
    isActionLoading.value = true;
    try {
      final result = await _fundService.createRequiredContribution(
        tripId: tripId,
        amount: amount,
        notes: notes,
        contributorIds: contributorIds,
      );
      if (result.success) {
        ToastUtil.showSuccess("success".tr, "mandatory_contribution_created".tr);
        await fetchContributions();
        
        // Reload nợ nần
        _triggerReloads();
        return true;
      } else {
        ToastUtil.showError("error".tr, result.message ?? "failed_create_contribution".tr);
        return false;
      }
    } catch (e) {
      ToastUtil.showError("error".tr, "connection_error".tr);
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<bool> createVoluntaryContribution({
    required double amount,
    required String notes,
  }) async {
    isActionLoading.value = true;
    try {
      final result = await _fundService.createVoluntaryContribution(
        tripId: tripId,
        amount: amount,
        notes: notes,
      );
      if (result.success && result.data != null) {
        ToastUtil.showSuccess("thank_you".tr, "voluntary_contribution_recorded".tr);
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
        ToastUtil.showError("error".tr, result.message ?? "failed_submit_contribution".tr);
        return false;
      }
    } catch (e) {
      ToastUtil.showError("error".tr, "connection_error".tr);
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<bool> confirmContribution(int contributionId) async {
    isActionLoading.value = true;
    try {
      final result = await _fundService.confirmContribution(tripId, contributionId);
      if (result.success && result.data != null) {
        ToastUtil.showSuccess("success".tr, "contribution_confirmed".tr);
        
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
        ToastUtil.showError("error".tr, result.message ?? "failed_confirm_contribution".tr);
        return false;
      }
    } catch (e) {
      ToastUtil.showError("error".tr, "connection_error".tr);
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<bool> confirmMultipleContributions(List<int> contributionIds) async {
    isActionLoading.value = true;
    try {
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

      if (allSuccess) {
        ToastUtil.showSuccess("success".tr, "all_contributions_confirmed".tr);
        
        // Reload thông tin quỹ để cập nhật số dư mới
        final fundResult = await _fundService.getFund(tripId);
        if (fundResult.success && fundResult.data != null) {
          fund.value = fundResult.data;
        }

        // Reload nợ nần
        _triggerReloads();
        return true;
      } else {
        ToastUtil.showError("notification".tr, errorMsg ?? "failed_confirm_some_contributions".tr);
        
        // Vẫn reload lại để đồng bộ trạng thái mới nhất
        final fundResult = await _fundService.getFund(tripId);
        if (fundResult.success && fundResult.data != null) {
          fund.value = fundResult.data;
        }
        _triggerReloads();
        return false;
      }
    } catch (e) {
      ToastUtil.showError("error".tr, "connection_error".tr);
      return false;
    } finally {
      isActionLoading.value = false;
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
