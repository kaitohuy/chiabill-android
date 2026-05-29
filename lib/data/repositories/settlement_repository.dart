import '../models/api_response.dart';
import '../models/settlement_response.dart';
import '../models/personal_statement_response.dart';
import '../network/api_service.dart';

class SettlementRepository {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<List<SettlementResponse>>> getSettlements(int tripId) async {
    try {
      final response = await _apiService.dio.get("/api/settlements/trip/$tripId");
      return ApiResponse<List<SettlementResponse>>.fromJson(
        response.data,
            (data) => (data as List).map((item) => SettlementResponse.fromJson(item)).toList(),
      );
    } catch (e) {
      return ApiResponse(success: false, message: "Lỗi tải chốt sổ: $e");
    }
  }

  Future<ApiResponse<PersonalStatementResponse>> getPersonalStatement(int tripId, int targetUserId) async {
    try {
      final response = await _apiService.dio.get("/api/settlements/trip/$tripId/balance/$targetUserId");
      return ApiResponse<PersonalStatementResponse>.fromJson(
        response.data,
            (data) => PersonalStatementResponse.fromJson(data),
      );
    } catch (e) {
      return ApiResponse(success: false, message: "Lỗi tải sao kê: $e");
    }
  }
}