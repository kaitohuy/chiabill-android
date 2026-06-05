import '../models/api_response.dart';
import '../network/api_service.dart';

class FeedbackRepository {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<void>> sendFeedback(String content) async {
    try {
      final response = await _apiService.dio.post(
        "/api/feedbacks",
        data: {"content": content},
      );
      return ApiResponse<void>.fromJson(response.data, (data) {});
    } catch (e) {
      return ApiResponse(success: false, message: "Lỗi gửi phản hồi: $e");
    }
  }
}
