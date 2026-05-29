import '../models/api_response.dart';
import '../models/auth_response.dart';
import '../network/api_service.dart';

class AuthRepository {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<AuthResponse>> loginAnonymous() async {
    try {
      final response = await _apiService.dio.post("/api/auth/anonymous");

      // Parse dữ liệu từ JSON sang Object
      return ApiResponse<AuthResponse>.fromJson(
          response.data,
              (data) => AuthResponse.fromJson(data)
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi kết nối server");
    }
  }

  // Thêm hàm này vào class AuthRepository
  Future<ApiResponse<AuthResponse>> loginGoogle(String idToken) async {
    try {
      final response = await _apiService.dio.post(
        "/api/auth/google",
        data: {'idToken': idToken}, // Khớp với GoogleLoginRequest bên Spring Boot
      );
      return ApiResponse<AuthResponse>.fromJson(
        response.data,
            (data) => AuthResponse.fromJson(data),
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi xác thực Google");
    }
  }
}