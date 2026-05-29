import 'package:chiabill/data/models/api_response.dart';
import 'package:chiabill/data/models/fund_contribution_response.dart';
import 'package:chiabill/data/models/fund_response.dart';
import '../network/api_service.dart';

class GroupFundRepository {
  final ApiService _apiService = ApiService();

  // GET /api/trips/{tripId}/fund
  Future<ApiResponse<FundResponse>> getFund(int tripId) async {
    try {
      final response = await _apiService.dio.get("/api/trips/$tripId/fund");
      return ApiResponse<FundResponse>.fromJson(
        response.data,
        (data) => FundResponse.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi tải thông tin quỹ chung");
    }
  }

  // POST /api/trips/{tripId}/fund/activate
  Future<ApiResponse<FundResponse>> activateFund(
      int tripId, double? alertThreshold, int? treasurerId) async {
    try {
      final response = await _apiService.dio.post(
        "/api/trips/$tripId/fund/activate",
        data: {
          if (alertThreshold != null) 'alertThreshold': alertThreshold,
          if (treasurerId != null) 'treasurerId': treasurerId,
        },
      );
      return ApiResponse<FundResponse>.fromJson(
        response.data,
        (data) => FundResponse.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi kích hoạt quỹ chung");
    }
  }

  // PUT /api/trips/{tripId}/fund/treasurer
  Future<ApiResponse<FundResponse>> updateTreasurer(int tripId, int treasurerId) async {
    try {
      final response = await _apiService.dio.put(
        "/api/trips/$tripId/fund/treasurer",
        data: {
          'treasurerId': treasurerId,
        },
      );
      return ApiResponse<FundResponse>.fromJson(
        response.data,
        (data) => FundResponse.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi thay đổi thủ quỹ");
    }
  }

  // POST /api/trips/{tripId}/fund/contributions/required
  Future<ApiResponse<List<FundContributionResponse>>> createRequiredContribution({
    required int tripId,
    required double amount,
    required String notes,
    required List<int> contributorIds,
  }) async {
    try {
      final response = await _apiService.dio.post(
        "/api/trips/$tripId/fund/contributions/required",
        data: {
          'amount': amount,
          'notes': notes,
          'contributorIds': contributorIds,
        },
      );
      return ApiResponse<List<FundContributionResponse>>.fromJson(
        response.data,
        (data) => (data as List)
            .map((item) => FundContributionResponse.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi tạo yêu cầu thu quỹ");
    }
  }

  // POST /api/trips/{tripId}/fund/contributions/voluntary
  Future<ApiResponse<FundContributionResponse>> createVoluntaryContribution({
    required int tripId,
    required double amount,
    required String notes,
  }) async {
    try {
      final response = await _apiService.dio.post(
        "/api/trips/$tripId/fund/contributions/voluntary",
        data: {
          'amount': amount,
          'notes': notes,
        },
      );
      return ApiResponse<FundContributionResponse>.fromJson(
        response.data,
        (data) => FundContributionResponse.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi thực hiện đóng góp");
    }
  }

  // GET /api/trips/{tripId}/fund/contributions
  Future<ApiResponse<List<FundContributionResponse>>> getContributions(int tripId) async {
    try {
      final response = await _apiService.dio.get("/api/trips/$tripId/fund/contributions");
      return ApiResponse<List<FundContributionResponse>>.fromJson(
        response.data,
        (data) => (data as List)
            .map((item) => FundContributionResponse.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi tải lịch sử đóng góp quỹ");
    }
  }

  // POST /api/trips/{tripId}/fund/contributions/{contributionId}/confirm
  Future<ApiResponse<FundContributionResponse>> confirmContribution(
      int tripId, int contributionId) async {
    try {
      final response = await _apiService.dio.post(
        "/api/trips/$tripId/fund/contributions/$contributionId/confirm",
      );
      return ApiResponse<FundContributionResponse>.fromJson(
        response.data,
        (data) => FundContributionResponse.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi xác nhận đóng quỹ");
    }
  }
}
