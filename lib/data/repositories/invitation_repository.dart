import 'package:dio/dio.dart';

import '../models/api_response.dart';
import '../models/invitation_response.dart';
import '../models/invite_info_response.dart';
import '../models/trip_response.dart';
import '../network/api_service.dart';

class InvitationRepository {
  final ApiService _apiService = ApiService();

  // 1. Tạo mã mời mới
  Future<ApiResponse<InvitationResponse>> createInvite(int tripId, {String? customCode}) async {
    try {
      Map<String, dynamic>? data;
      if (customCode != null && customCode.isNotEmpty) {
        data = {'customCode': customCode};
      }
      final response = await _apiService.dio.post("/api/trips/$tripId/invites", data: data);
      return ApiResponse<InvitationResponse>.fromJson(response.data, (data) => InvitationResponse.fromJson(data));
    } catch (e) {
      // BẮT LỖI DIO Ở ĐÂY CHO MƯỢT
      if (e is DioException && e.response != null) {
        // Trích xuất message từ JSON lỗi của Spring Boot (nếu BE có cấu hình bắt Exception)
        String errorMsg = e.response?.data['message'] ?? "Mã này đã có người sử dụng. Vui lòng chọn mã khác!";
        return ApiResponse(success: false, message: errorMsg);
      }
      return ApiResponse(success: false, message: "Lỗi kết nối server: $e");
    }
  }

  // 2. Lấy thông tin chuyến đi từ mã mời
  Future<ApiResponse<InviteInfoResponse>> getInviteInfo(String inviteCode) async {
    try {
      final response = await _apiService.dio.get("/api/invites/$inviteCode");
      return ApiResponse<InviteInfoResponse>.fromJson(response.data, (data) => InviteInfoResponse.fromJson(data));
    } catch (e) {
      return ApiResponse(success: false, message: "Mã không hợp lệ hoặc đã hết hạn");
    }
  }

  // 3. Tham gia bằng mã mời
  Future<ApiResponse<TripResponse>> joinByInvite(String inviteCode) async {
    try {
      final response = await _apiService.dio.post("/api/invites/$inviteCode/join");
      return ApiResponse<TripResponse>.fromJson(response.data, (data) => TripResponse.fromJson(data));
    } catch (e) {
      return ApiResponse(success: false, message: "Lỗi tham gia: $e");
    }
  }

  Future<ApiResponse<InvitationResponse?>> getActiveInvite(int tripId) async {
    try {
      final response = await _apiService.dio.get("/api/trips/$tripId/invites/active");
      if (response.data['data'] == null) {
        return ApiResponse(success: true, data: null); // Chưa có mã nào
      }
      return ApiResponse<InvitationResponse?>.fromJson(response.data, (data) => InvitationResponse.fromJson(data));
    } catch (e) {
      return ApiResponse(success: false, message: "Lỗi lấy mã");
    }
  }
}