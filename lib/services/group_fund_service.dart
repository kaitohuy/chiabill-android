import 'package:chiabill/data/models/api_response.dart';
import 'package:chiabill/data/models/fund_contribution_response.dart';
import 'package:chiabill/data/models/fund_response.dart';
import 'package:chiabill/data/repositories/group_fund_repository.dart';

class GroupFundService {
  final GroupFundRepository _repository = GroupFundRepository();

  Future<ApiResponse<FundResponse>> getFund(int tripId) {
    return _repository.getFund(tripId);
  }

  Future<ApiResponse<FundResponse>> activateFund(
      int tripId, double? alertThreshold, int? treasurerId) {
    return _repository.activateFund(tripId, alertThreshold, treasurerId);
  }

  Future<ApiResponse<FundResponse>> updateTreasurer(int tripId, int treasurerId) {
    return _repository.updateTreasurer(tripId, treasurerId);
  }

  Future<ApiResponse<List<FundContributionResponse>>> createRequiredContribution({
    required int tripId,
    required double amount,
    required String notes,
    required List<int> contributorIds,
  }) {
    return _repository.createRequiredContribution(
      tripId: tripId,
      amount: amount,
      notes: notes,
      contributorIds: contributorIds,
    );
  }

  Future<ApiResponse<FundContributionResponse>> createVoluntaryContribution({
    required int tripId,
    required double amount,
    required String notes,
  }) {
    return _repository.createVoluntaryContribution(
      tripId: tripId,
      amount: amount,
      notes: notes,
    );
  }

  Future<ApiResponse<List<FundContributionResponse>>> getContributions(int tripId) {
    return _repository.getContributions(tripId);
  }

  Future<ApiResponse<FundContributionResponse>> confirmContribution(
      int tripId, int contributionId) {
    return _repository.confirmContribution(tripId, contributionId);
  }
}
