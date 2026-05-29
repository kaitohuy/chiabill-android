import '../models/api_response.dart';
import '../models/notification_response.dart';
import '../network/api_service.dart';

class NotificationRepository {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<List<NotificationResponse>>> getNotifications() async {
    try {
      final response = await _apiService.dio.get('/api/notifications');
      final data = (response.data['data'] as List)
          .map((json) => NotificationResponse.fromJson(json))
          .toList();

      return ApiResponse<List<NotificationResponse>>(
          success: true,
          data: data,
          message: response.data['message']
      );
    } catch (e) {
      return ApiResponse<List<NotificationResponse>>(
          success: false,
          message: e.toString()
      );
    }
  }

  Future<ApiResponse<int>> getUnreadCount() async {
    try {
      final response = await _apiService.dio.get('/api/notifications/unread-count');
      return ApiResponse<int>(
          success: true,
          data: response.data['data'],
          message: response.data['message']
      );
    } catch (e) {
      return ApiResponse<int>(
          success: false,
          message: e.toString()
      );
    }
  }

  Future<ApiResponse<void>> markAsRead(int id) async {
    try {
      await _apiService.dio.put('/api/notifications/$id/read');
      return ApiResponse<void>(
          success: true,
          message: "Thành công"
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi");
    }
  }

  Future<ApiResponse<void>> markAllAsRead() async {
    try {
      await _apiService.dio.put("/api/notifications/mark-all-read");
      return ApiResponse(success: true);
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi đánh dấu đã đọc");
    }
  }

  Future<ApiResponse<void>> remindDebt(int debtorId, int tripId, double amount) async {
    try {
      await _apiService.dio.post('/api/notifications/remind-debt', data: {
        'debtorId': debtorId,
        'tripId': tripId,
        'amount': amount,
      });
      return ApiResponse<void>(
          success: true,
          message: "Đã gửi thông báo nhắc nợ"
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi gửi thông báo");
    }
  }
}