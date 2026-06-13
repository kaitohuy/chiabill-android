import 'dart:io';
import 'package:dio/dio.dart'; // Import thẳng dio để dùng MultipartFile và FormData
import '../models/api_response.dart';
import '../models/user_response.dart';
import '../models/update_profile_request.dart';
import '../network/api_service.dart';

class UserRepository {
  final ApiService _apiService = ApiService();

  // 1. Lấy thông tin cá nhân
  Future<ApiResponse<UserResponse>> getMyProfile() async {
    try {
      final response = await _apiService.dio.get("/api/users/me");
      return ApiResponse<UserResponse>.fromJson(response.data, (data) => UserResponse.fromJson(data));
    } catch (e) {
      return ApiResponse(success: false, message: "Lỗi tải thông tin: $e");
    }
  }

  // 2. Cập nhật thông tin text
  Future<ApiResponse<UserResponse>> updateProfile(UpdateProfileRequest request) async {
    try {
      final response = await _apiService.dio.put("/api/users/me", data: request.toJson());
      return ApiResponse<UserResponse>.fromJson(response.data, (data) => UserResponse.fromJson(data));
    } catch (e) {
      return ApiResponse(success: false, message: "Lỗi cập nhật: $e");
    }
  }

  // 3. Upload File dùng chung (cho cả Avatar và Bank QR)
  Future<ApiResponse<String>> uploadImage(String endpoint, File file) async {
    try {
      // Bọc file vào FormData theo chuẩn multipart/form-data
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _apiService.dio.post(endpoint, data: formData);

      // Data BE trả về là một chuỗi String (URL của ảnh)
      return ApiResponse<String>.fromJson(response.data, (data) => data as String);
    } catch (e) {
      return ApiResponse(success: false, message: "Lỗi tải ảnh lên: $e");
    }
  }

  // 4. Xóa tài khoản
  Future<ApiResponse<void>> deleteAccount() async {
    try {
      final response = await _apiService.dio.delete("/api/users/me");
      return ApiResponse<void>.fromJson(response.data, (data) {});
    } catch (e) {
      return ApiResponse(success: false, message: "Lỗi xóa tài khoản: $e");
    }
  }
}