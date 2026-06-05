import '../models/api_response.dart';
import '../models/itinerary_item_response.dart';
import '../network/api_service.dart';
import 'package:dio/dio.dart';

class ItineraryRepository {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<List<ItineraryItemResponse>>> getItinerary(int tripId) async {
    try {
      final response = await _apiService.dio.get("/api/trips/$tripId/itinerary");
      return ApiResponse<List<ItineraryItemResponse>>.fromJson(
        response.data,
        (data) => (data as List).map((i) => ItineraryItemResponse.fromJson(i)).toList(),
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi tải lịch trình chuyến đi");
    }
  }

  Future<ApiResponse<List<ItineraryItemResponse>>> saveItineraryBulk(int tripId, List<ItineraryItemResponse> items) async {
    try {
      final data = items.map((i) => i.toJson()).toList();
      final response = await _apiService.dio.post(
        "/api/trips/$tripId/itinerary/bulk",
        data: data,
      );
      return ApiResponse<List<ItineraryItemResponse>>.fromJson(
        response.data,
        (data) => (data as List).map((i) => ItineraryItemResponse.fromJson(i)).toList(),
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi lưu danh sách lịch trình");
    }
  }

  Future<ApiResponse<ItineraryItemResponse>> saveItineraryItem(int tripId, ItineraryItemResponse item) async {
    try {
      final response = await _apiService.dio.post(
        "/api/trips/$tripId/itinerary/item",
        data: item.toJson(),
      );
      return ApiResponse<ItineraryItemResponse>.fromJson(
        response.data,
        (data) => ItineraryItemResponse.fromJson(data),
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi lưu hoạt động lịch trình");
    }
  }

  Future<ApiResponse<void>> deleteItineraryItem(int tripId, int itemId) async {
    try {
      await _apiService.dio.delete("/api/trips/$tripId/itinerary/$itemId");
      return ApiResponse(success: true, message: "Đã xóa hoạt động");
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi xóa hoạt động lịch trình");
    }
  }

  Future<ApiResponse<List<int>>> exportItineraryBytes(int tripId) async {
    try {
      final response = await _apiService.dio.get(
        "/api/trips/$tripId/itinerary/export/excel",
        options: Options(responseType: ResponseType.bytes),
      );
      return ApiResponse(success: true, data: response.data);
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi tải tệp báo cáo lịch trình");
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getItinerarySettings(int tripId) async {
    try {
      final response = await _apiService.dio.get("/api/trips/$tripId/itinerary/settings");
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (data) => Map<String, dynamic>.from(data),
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi tải cấu hình báo thức");
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updateItinerarySettings(
      int tripId, bool alarmEnabled, int alarmValue, String alarmUnit) async {
    try {
      final response = await _apiService.dio.put(
        "/api/trips/$tripId/itinerary/settings",
        data: {
          "alarmEnabled": alarmEnabled,
          "alarmValue": alarmValue,
          "alarmUnit": alarmUnit,
        },
      );
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (data) => Map<String, dynamic>.from(data),
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi cập nhật cấu hình báo thức");
    }
  }

  Future<ApiResponse<List<ItineraryItemResponse>>> cloneItinerary(int tripId, int sourceTripId) async {
    try {
      final response = await _apiService.dio.post("/api/trips/$tripId/itinerary/import-from/$sourceTripId");
      return ApiResponse<List<ItineraryItemResponse>>.fromJson(
        response.data,
        (data) => (data as List).map((i) => ItineraryItemResponse.fromJson(i)).toList(),
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi sao chép lịch trình");
    }
  }
}
