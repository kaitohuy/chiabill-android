import 'package:get_storage/get_storage.dart';
import '../models/announcement_response.dart';
import '../models/api_response.dart';
import '../network/api_service.dart';

class AnnouncementRepository {
  final ApiService _apiService = ApiService();
  final _storage = GetStorage();

  static const String _seenPrefix = 'announcement_seen_';
  static const String _dailyPrefix = 'announcement_daily_';

  /// Lấy danh sách thông báo active từ server
  Future<ApiResponse<List<AnnouncementResponse>>> getActiveAnnouncements({
    String platform = 'ANDROID',
  }) async {
    try {
      final response = await _apiService.dio.get(
        '/api/announcements/active',
        queryParameters: {'platform': platform},
      );
      final apiResponse = ApiResponse<List<AnnouncementResponse>>.fromJson(
        response.data,
        (data) => (data as List)
            .map((e) => AnnouncementResponse.fromJson(e))
            .toList(),
      );
      return apiResponse;
    } catch (e) {
      return ApiResponse(success: false, message: 'Lỗi tải thông báo: $e');
    }
  }

  // ===== QUẢN LÝ TRẠNG THÁI HIỂN THỊ (lưu local) =====

  /// Kiểm tra thông báo này có nên hiển thị không (dựa theo displayMode)
  bool shouldShow(AnnouncementResponse announcement) {
    final key = '$_seenPrefix${announcement.id}';
    final dailyKey = '$_dailyPrefix${announcement.id}';

    switch (announcement.displayMode) {
      case 'ONCE':
        // Chỉ hiện nếu chưa từng xem
        return _storage.read(key) == null;

      case 'EVERY_LAUNCH':
        // Luôn hiện mỗi lần mở app
        return true;

      case 'DAILY':
        // Hiện tối đa 1 lần mỗi ngày
        final lastSeen = _storage.read(dailyKey) as String?;
        if (lastSeen == null) return true;
        final lastDate = DateTime.tryParse(lastSeen);
        if (lastDate == null) return true;
        final today = DateTime.now();
        return !(lastDate.year == today.year &&
            lastDate.month == today.month &&
            lastDate.day == today.day);

      case 'ALWAYS':
        return true;

      default:
        return true;
    }
  }

  /// Ghi nhận đã xem thông báo
  void markAsSeen(AnnouncementResponse announcement) {
    final key = '$_seenPrefix${announcement.id}';
    final dailyKey = '$_dailyPrefix${announcement.id}';
    final now = DateTime.now().toIso8601String();
    _storage.write(key, now);
    _storage.write(dailyKey, now);
  }
}
