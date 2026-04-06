import 'package:dio/dio.dart';

import '../models/api_response.dart';
import '../models/user_response.dart';
import '../models/create_ghost_request.dart';
import '../network/api_service.dart';

class GhostRepository {
  final ApiService _apiService = ApiService();

  // Gọi POST /api/trips/{tripId}/ghost-members
  Future<ApiResponse<List<UserResponse>>> createGhostMembers(int tripId, List<String> names) async {
    try {
      final response = await _apiService.dio.post(
        "/api/trips/$tripId/ghost-members",
        data: CreateGhostRequest(names: names).toJson(),
      );
      return ApiResponse<List<UserResponse>>.fromJson(
        response.data,
            (data) {
          if (data == null) return [];
          if (data is List) return data.map((item) => UserResponse.fromJson(item)).toList();
          return [];
        },
      );
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        try {
          return ApiResponse.fromJson(e.response!.data, (data) => []);
        } catch (_) { }
      }
      return ApiResponse(success: false, message: "Lỗi kết nối mạng");
    } catch (e) {
      return ApiResponse(success: false, message: "Lỗi hệ thống: $e");
    }
  }
}