import 'dart:io';
import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/page_response.dart';
import '../models/payment_response.dart';
import '../network/api_service.dart';

class PaymentRepository {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<PaymentResponse>> createPayment(int tripId, int toUserId, double amount, File proofFile) async {
    try {
      String fileName = proofFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        "toUserId": toUserId,
        "amount": amount,
        "proof": await MultipartFile.fromFile(proofFile.path, filename: fileName),
      });

      final response = await _apiService.dio.post("/api/trips/$tripId/payments", data: formData);
      return ApiResponse<PaymentResponse>.fromJson(response.data, (data) => PaymentResponse.fromJson(data));
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        try {
          return ApiResponse.fromJson(e.response!.data, (data) => PaymentResponse.fromJson(data));
        } catch (_) {
          return ApiResponse(success: false, message: "Lỗi máy chủ: ${e.response?.statusCode}");
        }
      }
      return ApiResponse(success: false, message: "Lỗi kết nối mạng");
    } catch (e) {
      return ApiResponse(success: false, message: "Đã xảy ra lỗi: $e");
    }
  }

  // 1. Lấy danh sách giao dịch
  Future<ApiResponse<List<PaymentResponse>>> getTripPayments(int tripId) async {
    try {
      final response = await _apiService.dio.get("/api/trips/$tripId/payments");
      return ApiResponse<List<PaymentResponse>>.fromJson(
        response.data,
            (data) => (data as List).map((e) => PaymentResponse.fromJson(e)).toList(),
      );
    } catch (e) {
      return ApiResponse(success: false, message: "Lỗi tải giao dịch: $e");
    }
  }

  // 2. Duyệt (Approve)
  Future<ApiResponse<String>> approvePayment(int paymentId) async {
    try {
      final response = await _apiService.dio.put("/api/payments/$paymentId/approve");
      return ApiResponse.fromJson(response.data, (data) => data as String);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        return ApiResponse.fromJson(e.response!.data, (data) => data as String);
      }
      return ApiResponse(success: false, message: "Lỗi kết nối");
    } catch (e) {
      return ApiResponse(success: false, message: "Lỗi: $e");
    }
  }

  // 3. Từ chối (Reject)
  Future<ApiResponse<String>> rejectPayment(int paymentId) async {
    try {
      final response = await _apiService.dio.put("/api/payments/$paymentId/reject");
      return ApiResponse.fromJson(response.data, (data) => data as String);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        return ApiResponse.fromJson(e.response!.data, (data) => data as String);
      }
      return ApiResponse(success: false, message: "Lỗi kết nối");
    } catch (e) {
      return ApiResponse(success: false, message: "Lỗi: $e");
    }
  }

  Future<ApiResponse<PageResponse<PaymentResponse>>> getTripPaymentsPaginated({
    required int tripId,
    int page = 0,
    int size = 20,
    String? status,
    int? fromUserId, // THÊM NÀY
    int? toUserId,   // THÊM NÀY
  }) async {
    try {
      Map<String, dynamic> queryParams = {
        'page': page,
        'size': size,
        'sort': 'createdAt,desc',
      };
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (fromUserId != null) queryParams['fromUserId'] = fromUserId;
      if (toUserId != null) queryParams['toUserId'] = toUserId;

      final response = await _apiService.dio.get(
        "/api/trip/$tripId/search", // Nhớ check lại route này nếu BE bạn đổi thành /api/payments/trip/...
        queryParameters: queryParams,
      );

      return ApiResponse<PageResponse<PaymentResponse>>.fromJson(
        response.data,
            (data) => PageResponse<PaymentResponse>.fromJson(
          data as Map<String, dynamic>,
              (item) => PaymentResponse.fromJson(item as Map<String, dynamic>),
        ),
      );
    } catch (e) {
      return ApiResponse(success: false, message: "Lỗi tải lịch sử giao dịch: $e");
    }
  }
}