import '../models/api_response.dart';
import '../models/settlement_response.dart';
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
}