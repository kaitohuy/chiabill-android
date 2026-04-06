import 'package:chiabill/data/models/create_trip_request.dart';
import 'package:dio/dio.dart';

import '../models/api_response.dart';
import '../models/page_response.dart';
import '../models/trip_response.dart';
import '../network/api_service.dart';

class TripRepository {
  final ApiService _apiService = ApiService();

  // Thêm hàm lấy chuyến đi có phân trang và search
  Future<ApiResponse<PageResponse<TripResponse>>> getMyTripsPaginated({
    String? keyword,
    int page = 0,
    int size = 10, // Chuyến đi cái Card to nên load 10 cái 1 lần là vừa
  }) async {
    try {
      Map<String, dynamic> queryParams = {
        'page': page,
        'size': size,
        'sort': 'createdAt,desc', // Mới nhất xếp lên đầu
      };

      if (keyword != null && keyword.trim().isNotEmpty) {
        queryParams['keyword'] = keyword.trim();
      }

      final response = await _apiService.dio.get("/api/trips/search", queryParameters: queryParams);

      return ApiResponse<PageResponse<TripResponse>>.fromJson(
        response.data,
            (data) => PageResponse<TripResponse>.fromJson(
          data as Map<String, dynamic>,
              (item) => TripResponse.fromJson(item as Map<String, dynamic>),
        ),
      );
    } catch (e) {
      return ApiResponse(success: false, message: "Lỗi tải danh sách chuyến đi: $e");
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
      return ApiResponse(success: false, message: "Lỗi tải dữ liệu: $e");
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
      return ApiResponse(success: false, message: "Lỗi tạo chuyến đi: $e");
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
      return ApiResponse(success: false, message: "Lỗi tải chi tiết: $e");
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
      return ApiResponse(success: false, message: "Lỗi tham gia: $e");
    }
  }

  // ==================================================
  // ĐÃ CẬP NHẬT: Thêm tham số totalBudget vào hàm Sửa chuyến đi
  // ==================================================
  Future<ApiResponse<TripResponse>> updateTrip(int tripId, String name, String? description, double? totalBudget) async {
    try {
      Map<String, dynamic> requestData = {
        "name": name,
        "description": description ?? ""
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
      return ApiResponse(success: false, message: "Lỗi cập nhật chuyến đi: $e");
    }
  }

  // Xóa chuyến đi
  Future<ApiResponse<void>> deleteTrip(int tripId) async {
    try {
      await _apiService.dio.delete("/api/trips/$tripId");
      return ApiResponse(success: true);
    } catch (e) {
      return ApiResponse(success: false, message: "Lỗi xóa chuyến đi: $e");
    }
  }

  Future<ApiResponse<dynamic>> addDirectMember(int tripId, String email, String phone) async {
    try {
      final data = {};
      if (email.isNotEmpty) data['email'] = email;
      if (phone.isNotEmpty) data['phone'] = phone;

      final response = await _apiService.dio.post("/api/trips/$tripId/members/add", data: data);
      return ApiResponse.fromJson(response.data, (data) => data);

    } on DioException catch (e) {
      // 1. NẾU LÀ LỖI TỪ BACKEND (Có status code 400, 401, 500...)
      if (e.response != null && e.response?.data != null) {
        try {
          // Bóc tách JSON lỗi từ BE trả về (chứa câu tiếng Việt của bạn)
          return ApiResponse.fromJson(e.response!.data, (data) => data);
        } catch (_) {
          return ApiResponse(success: false, message: "Lỗi máy chủ: ${e.response?.statusCode}");
        }
      }
      // 2. NẾU LÀ LỖI MẠNG (Không có kết nối, timeout...)
      return ApiResponse(success: false, message: "Vui lòng kiểm tra lại kết nối mạng.");

    } catch (e) {
      // 3. CÁC LỖI KHÁC CỦA FLUTTER
      return ApiResponse(success: false, message: "Đã xảy ra lỗi: $e");
    }
  }

// 1. Rời nhóm
  Future<ApiResponse<dynamic>> leaveTrip(int tripId) async {
    try {
      final response = await _apiService.dio.post("/api/trips/$tripId/leave");
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      // KIỂM TRA XEM BE CÓ TRẢ VỀ JSON CHUẨN KHÔNG
      if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
        return ApiResponse.fromJson(e.response!.data, (data) => data);
      }
      return ApiResponse(success: false, message: "Lỗi máy chủ (Code: ${e.response?.statusCode})");
    } catch (e) {
      return ApiResponse(success: false, message: "Đã xảy ra lỗi hệ thống");
    }
  }

  // LÀM TƯƠNG TỰ CHO 3 HÀM DƯỚI NÀY
  // 2. Chuyển quyền Chủ phòng
  Future<ApiResponse<dynamic>> transferOwner(int tripId, int newOwnerId) async {
    try {
      final response = await _apiService.dio.put("/api/trips/$tripId/transfer-owner", data: {"newOwnerId": newOwnerId});
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
        return ApiResponse.fromJson(e.response!.data, (data) => data);
      }
      return ApiResponse(success: false, message: "Lỗi máy chủ");
    } catch (e) {
      return ApiResponse(success: false, message: "Lỗi hệ thống");
    }
  }

  // 3. Tạm ngưng
  Future<ApiResponse<dynamic>> disableMember(int tripId, int memberId) async {
    try {
      final response = await _apiService.dio.put("/api/trips/$tripId/members/$memberId/disable");
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
        return ApiResponse.fromJson(e.response!.data, (data) => data);
      }
      return ApiResponse(success: false, message: "Lỗi máy chủ");
    } catch (e) {
      return ApiResponse(success: false, message: "Lỗi hệ thống");
    }
  }

  // 4. Đuổi khỏi nhóm
  Future<ApiResponse<dynamic>> kickMember(int tripId, int memberId, bool forgiveDebt) async {
    try {
      final response = await _apiService.dio.delete("/api/trips/$tripId/members/$memberId?forgiveDebt=$forgiveDebt");
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
        return ApiResponse.fromJson(e.response!.data, (data) => data);
      }
      return ApiResponse(success: false, message: "Lỗi máy chủ");
    } catch (e) {
      return ApiResponse(success: false, message: "Lỗi hệ thống");
    }
  }

  // 5. Mở khóa thành viên
  Future<ApiResponse<dynamic>> activateMember(int tripId, int memberId) async {
    try {
      final response = await _apiService.dio.put("/api/trips/$tripId/members/$memberId/active");
      return ApiResponse.fromJson(response.data, (data) => data);
    } catch (e) {
      return ApiResponse(success: false, message: "Lỗi mở khóa: $e");
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
      return ApiResponse(success: false, message: e.toString());
    }
  }
}