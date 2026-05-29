import 'dart:io';
import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/page_response.dart';
import '../models/payment_response.dart';
import '../network/api_service.dart';

class PaymentRepository {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<PaymentResponse>> createPayment(int tripId, int toUserId, double amount, File? proofFile) async {
    try {
      Map<String, dynamic> mapData = {
        "toUserId": toUserId,
        "amount": amount,
      };
      if (proofFile != null) {
        String fileName = proofFile.path.split('/').last;
        mapData["proof"] = await MultipartFile.fromFile(proofFile.path, filename: fileName);
      }
      FormData formData = FormData.fromMap(mapData);

      final response = await _apiService.dio.post("/api/trips/$tripId/payments", data: formData);
      return ApiResponse<PaymentResponse>.fromJson(response.data, (data) => PaymentResponse.fromJson(data));
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi tạo giao dịch");
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
      return ApiResponse.withError(e, defaultMessage: "Lỗi tải giao dịch");
    }
  }

  // 2. Duyệt (Approve)
  Future<ApiResponse<String>> approvePayment(int paymentId) async {
    try {
      final response = await _apiService.dio.put("/api/payments/$paymentId/approve");
      return ApiResponse.fromJson(response.data, (data) => data as String);
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi duyệt giao dịch");
    }
  }

  // 3. Từ chối (Reject)
  Future<ApiResponse<String>> rejectPayment(int paymentId) async {
    try {
      final response = await _apiService.dio.put("/api/payments/$paymentId/reject");
      return ApiResponse.fromJson(response.data, (data) => data as String);
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi từ chối giao dịch");
    }
  }

  Future<ApiResponse<PageResponse<PaymentResponse>>> getTripPaymentsPaginated({
    required int tripId,
    int page = 0,
    int size = 20,
    String? status,
    int? fromUserId, // THÊM NÀY
    int? toUserId,   // THÊM NÀY
    String? startDate,
    String? endDate,
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
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

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
      return ApiResponse.withError(e, defaultMessage: "Lỗi tải lịch sử giao dịch");
    }
  }

  Future<ApiResponse<PaymentResponse>> createBatchPayOnBehalf({
    required int tripId,
    required int toUserId,
    required double totalAmount,
    required List<int> onBehalfOfUserIds,
    required List<double> onBehalfOfAmounts,
    File? proofFile,
  }) async {
    try {
      Map<String, dynamic> mapData = {
        "toUserId": toUserId,
        "totalAmount": totalAmount,
        "onBehalfOfUserIds": onBehalfOfUserIds.join(','),
        "onBehalfOfAmounts": onBehalfOfAmounts.join(','),
      };
      if (proofFile != null) {
        String fileName = proofFile.path.split('/').last;
        mapData["proof"] = await MultipartFile.fromFile(proofFile.path, filename: fileName);
      }
      FormData formData = FormData.fromMap(mapData);
      final response = await _apiService.dio.post("/api/trips/$tripId/payments/batch-behalf", data: formData);
      return ApiResponse<PaymentResponse>.fromJson(response.data, (data) => PaymentResponse.fromJson(data));
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi thanh toán hộ");
    }
  }
}