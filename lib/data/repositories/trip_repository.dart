import 'package:chiabill/data/models/create_trip_request.dart';
import 'package:dio/dio.dart';

import '../models/api_response.dart';
import '../models/page_response.dart';
import '../models/trip_response.dart';
import '../models/trip_history_response.dart';
import '../network/api_service.dart';

class TripRepository {
  final ApiService _apiService = ApiService();

  // Thêm hàm lấy chuyến đi có phân trang và search
  Future<ApiResponse<PageResponse<TripResponse>>> getMyTripsPaginated({
    String? keyword,
    int? month,
    int? year,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'size': size,
        'sort': 'createdAt,desc',
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        if (month != null) 'month': month,
        if (year != null) 'year': year,
      };

      final response = await _apiService.dio.get("/api/trips/search", queryParameters: queryParams);

      return ApiResponse<PageResponse<TripResponse>>.fromJson(
        response.data,
            (data) => PageResponse<TripResponse>.fromJson(
          data as Map<String, dynamic>,
              (item) => TripResponse.fromJson(item as Map<String, dynamic>),
        ),
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi tải danh sách chuyến đi");
    }
  }

  Future<ApiResponse<List<TripResponse>>> getMyTrips() async {
    try {
      final response = await _apiService.dio.get("/api/trips");
      return ApiResponse<List<TripResponse>>.fromJson(
        response.data,
            (data) => (data as List).map((item) => TripResponse.fromJson(item)).toList(),
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi tải dữ liệu");
    }
  }

  Future<ApiResponse<TripResponse>> createTrip(CreateTripRequest request) async {
    try {
      final response = await _apiService.dio.post(
        "/api/trips",
        data: request.toJson(),
      );
      return ApiResponse<TripResponse>.fromJson(
        response.data,
            (data) => TripResponse.fromJson(data),
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi tạo chuyến đi");
    }
  }

  Future<ApiResponse<TripResponse>> getTripDetail(int tripId) async {
    try {
      final response = await _apiService.dio.get("/api/trips/$tripId");
      return ApiResponse<TripResponse>.fromJson(
        response.data,
            (data) => TripResponse.fromJson(data),
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi tải chi tiết");
    }
  }

  // Hàm tham gia chuyến đi bằng Trip ID
  Future<ApiResponse<TripResponse>> joinTrip(int tripId) async {
    try {
      final response = await _apiService.dio.post("/api/trips/$tripId/join");
      return ApiResponse<TripResponse>.fromJson(
        response.data,
            (data) => TripResponse.fromJson(data),
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi tham gia");
    }
  }

  // ==================================================
  // ĐÃ CẬP NHẬT: Thêm tham số totalBudget vào hàm Sửa chuyến đi
  // ==================================================
  Future<ApiResponse<TripResponse>> updateTrip(int tripId, String name, String? description, double? totalBudget, String? startDate) async {
    try {
      Map<String, dynamic> requestData = {
        "name": name,
        "description": description ?? "",
        "startDate": startDate
      };

      // Nếu có sửa ngân sách thì nhét thêm vào requestData
      if (totalBudget != null) {
        requestData["totalBudget"] = totalBudget;
      }

      final response = await _apiService.dio.put(
        "/api/trips/$tripId",
        data: requestData,
      );
      return ApiResponse<TripResponse>.fromJson(response.data, (data) => TripResponse.fromJson(data));
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi cập nhật chuyến đi");
    }
  }

  // Xóa chuyến đi
  Future<ApiResponse<void>> deleteTrip(int tripId) async {
    try {
      await _apiService.dio.delete("/api/trips/$tripId");
      return ApiResponse(success: true, message: "Đã chuyển vào thùng rác");
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi xóa chuyến đi");
    }
  }

  Future<ApiResponse<List<TripResponse>>> getTrashTrips() async {
    try {
      final response = await _apiService.dio.get("/api/trips/trash");
      return ApiResponse<List<TripResponse>>.fromJson(
        response.data,
        (data) => (data as List).map((i) => TripResponse.fromJson(i)).toList(),
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi tải thùng rác");
    }
  }

  Future<ApiResponse<void>> restoreTrip(int tripId) async {
    try {
      await _apiService.dio.put("/api/trips/$tripId/restore");
      return ApiResponse(success: true, message: "Phục hồi thành công");
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi phục hồi chuyến đi");
    }
  }

  Future<ApiResponse<void>> forceDeleteTrip(int tripId) async {
    try {
      await _apiService.dio.delete("/api/trips/$tripId/force");
      return ApiResponse(success: true, message: "Đã xóa vĩnh viễn");
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi xóa vĩnh viễn");
    }
  }

  Future<ApiResponse<dynamic>> addDirectMember(int tripId, String email, String phone) async {
    try {
      final data = {};
      if (email.isNotEmpty) data['email'] = email;
      if (phone.isNotEmpty) data['phone'] = phone;

      final response = await _apiService.dio.post("/api/trips/$tripId/members/add", data: data);
      return ApiResponse.fromJson(response.data, (data) => data);

    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi thêm thành viên");
    }
  }

  Future<ApiResponse<dynamic>> importMembers(int tripId, List<int> userIds) async {
    try {
      final response = await _apiService.dio.post(
        "/api/trips/$tripId/members/import", 
        data: {"userIds": userIds}
      );
      return ApiResponse.fromJson(response.data, (data) => data);
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi nhập thành viên");
    }
  }

// 1. Rời nhóm
  Future<ApiResponse<dynamic>> leaveTrip(int tripId) async {
    try {
      final response = await _apiService.dio.post("/api/trips/$tripId/leave");
      return ApiResponse.fromJson(response.data, (data) => data);
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi rời nhóm");
    }
  }

  // LÀM TƯƠNG TỰ CHO 3 HÀM DƯỚI NÀY
  // 2. Chuyển quyền Chủ phòng
  Future<ApiResponse<dynamic>> transferOwner(int tripId, int newOwnerId) async {
    try {
      final response = await _apiService.dio.put("/api/trips/$tripId/transfer-owner", data: {"newOwnerId": newOwnerId});
      return ApiResponse.fromJson(response.data, (data) => data);
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi chuyển quyền");
    }
  }

  // 3. Tạm ngưng
  Future<ApiResponse<dynamic>> disableMember(int tripId, int memberId) async {
    try {
      final response = await _apiService.dio.put("/api/trips/$tripId/members/$memberId/disable");
      return ApiResponse.fromJson(response.data, (data) => data);
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi tạm ngưng");
    }
  }

  // 4. Đuổi khỏi nhóm
  Future<ApiResponse<dynamic>> kickMember(int tripId, int memberId, bool forgiveDebt) async {
    try {
      final response = await _apiService.dio.delete("/api/trips/$tripId/members/$memberId?forgiveDebt=$forgiveDebt");
      return ApiResponse.fromJson(response.data, (data) => data);
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi đuổi thành viên");
    }
  }

  // 5. Mở khóa thành viên
  Future<ApiResponse<dynamic>> activateMember(int tripId, int memberId) async {
    try {
      final response = await _apiService.dio.put("/api/trips/$tripId/members/$memberId/active");
      return ApiResponse.fromJson(response.data, (data) => data);
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi mở khóa");
    }
  }

  // Hàm lấy tổng quan tài chính
  Future<ApiResponse<Map<String, dynamic>>> getSettlementSummary() async {
    try {
      final response = await _apiService.dio.get('/api/settlements/summary');
      return ApiResponse(
        success: true,
        data: response.data['data'],
        message: response.data['message'],
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi tải tổng quan tài chính");
    }
  }

  // 6. Xuất báo cáo Excel/PDF — hỗ trợ query options
  Future<ApiResponse<List<int>>> exportTripBytes(
    int tripId,
    String format, {
    bool includeDetails = false,
    bool includeSettlement = false,
  }) async {
    try {
      final response = await _apiService.dio.get(
        "/api/trips/$tripId/export/$format",
        queryParameters: {
          if (includeDetails) 'includeDetails': true,
          if (includeSettlement) 'includeSettlement': true,
        },
        options: Options(responseType: ResponseType.bytes),
      );
      return ApiResponse(success: true, data: response.data);
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi tải tệp báo cáo");
    }
  }

  // 7. Lấy lịch sử hoạt động (Sửa/Xóa chi phí)
  Future<ApiResponse<PageResponse<TripHistoryResponse>>> getTripHistory({
    required int tripId,
    int page = 0,
    int size = 20,
    List<String>? actions,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'size': size,
      };

      if (actions != null && actions.isNotEmpty) {
        queryParams['actions'] = actions;
      }
      if (startDate != null) {
        queryParams['startDate'] = startDate;
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate;
      }

      final response = await _apiService.dio.get(
        "/api/trips/$tripId/history",
        queryParameters: queryParams,
      );
      
      return ApiResponse<PageResponse<TripHistoryResponse>>.fromJson(
        response.data,
        (data) => PageResponse.fromJson(data as Map<String, dynamic>, (json) => TripHistoryResponse.fromJson(json as Map<String, dynamic>)),
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi tải lịch sử hoạt động");
    }
  }
}