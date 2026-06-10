import 'dart:io';
import 'package:dio/dio.dart';
import 'package:chiabill/data/models/update_expense_request.dart';
import 'package:chiabill/data/models/scan_receipt_response.dart';

import '../models/api_response.dart';
import '../models/category_stat_response.dart';
import '../models/expense_response.dart';
import '../models/page_response.dart';
import '../network/api_service.dart';
import '../models/create_expense_request.dart';

import '../models/trip_stat_response.dart';

class ExpenseRepository {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<PageResponse<ExpenseResponse>>> searchExpenses({
    required int tripId,
    int page = 0,
    int size = 10,
    String? keyword,
    int? categoryId,
    int? payerId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      // Build query parameters
      Map<String, dynamic> queryParams = {
        'page': page,
        'size': size,
        'sort': 'expenseDate,desc',
      };
      if (keyword != null && keyword.isNotEmpty) queryParams['keyword'] = keyword;
      if (categoryId != null) queryParams['categoryId'] = categoryId;
      if (payerId != null) queryParams['payerId'] = payerId;
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final response = await _apiService.dio.get(
        "/api/expenses/trip/$tripId/search",
        queryParameters: queryParams,
      );

      return ApiResponse<PageResponse<ExpenseResponse>>.fromJson(
        response.data,
        // Ép kiểu Data trả về thành PageResponse
            (data) => PageResponse<ExpenseResponse>.fromJson(
          data as Map<String, dynamic>,
              (item) => ExpenseResponse.fromJson(item as Map<String, dynamic>),
        ),
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi tải chi phí");
    }
  }

  // Gọi API GET /api/expenses/trip/{tripId}
  Future<ApiResponse<List<ExpenseResponse>>> getExpensesByTrip(int tripId) async {
    try {
      final response = await _apiService.dio.get("/api/expenses/trip/$tripId");
      return ApiResponse<List<ExpenseResponse>>.fromJson(
        response.data,
            (data) => (data as List).map((item) => ExpenseResponse.fromJson(item)).toList(),
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi tải chi phí");
    }
  }

  Future<ApiResponse<ExpenseResponse>> createExpense(CreateExpenseRequest request) async {
    try {
      final response = await _apiService.dio.post("/api/expenses", data: request.toJson());
      return ApiResponse<ExpenseResponse>.fromJson(
        response.data,
            (data) => ExpenseResponse.fromJson(data),
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi tạo chi phí");
    }
  }

  Future<ApiResponse<ExpenseResponse>> updateExpense(int expenseId, UpdateExpenseRequest request) async {
    try {
      final response = await _apiService.dio.put("/api/expenses/$expenseId", data: request.toJson());
      return ApiResponse<ExpenseResponse>.fromJson(
        response.data,
            (data) => ExpenseResponse.fromJson(data),
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi cập nhật chi phí");
    }
  }

  // Xóa khoản chi
  Future<ApiResponse<void>> deleteExpense(int expenseId) async {
    try {
      await _apiService.dio.delete("/api/expenses/$expenseId");
      return ApiResponse(success: true);
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi xóa khoản chi");
    }
  }

  Future<ApiResponse<List<CategoryStatResponse>>> getTripStats(int tripId) async {
    try {
      final response = await _apiService.dio.get("/api/expenses/trip/$tripId/stats");
      return ApiResponse<List<CategoryStatResponse>>.fromJson(
        response.data,
            (data) => (data as List).map((i) => CategoryStatResponse.fromJson(i)).toList(),
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi tải thống kê");
    }
  }

  Future<ApiResponse<List<TripStatResponse>>> getOverallStats({int? month, int? year}) async {
    try {
      final response = await _apiService.dio.get(
        "/api/expenses/overall-stats",
        queryParameters: {
          if (month != null) 'month': month,
          if (year != null) 'year': year,
        },
      );
      return ApiResponse<List<TripStatResponse>>.fromJson(
        response.data,
            (data) => (data as List).map((i) => TripStatResponse.fromJson(i)).toList(),
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi tải thống kê tổng");
    }
  }

  Future<ApiResponse<double>> getLatestExchangeRate(String currency) async {
    try {
      final response = await _apiService.dio.get(
        "/api/expenses/exchange-rate",
        queryParameters: {'currency': currency},
      );
      // Backend returns BigDecimal which maps to number in json
      return ApiResponse<double>(
        success: true,
        data: (response.data['data'] as num).toDouble(),
        message: response.data['message']
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi lấy tỷ giá");
    }
  }

  Future<ApiResponse<ScanReceiptResponse>> scanReceipt(int tripId, File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
        "tripId": tripId,
      });
      final response = await _apiService.dio.post(
        "/api/expenses/scan-receipt",
        data: formData,
      );
      return ApiResponse<ScanReceiptResponse>.fromJson(
        response.data,
        (data) => ScanReceiptResponse.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi quét hóa đơn bằng AI");
    }
  }

  Future<ApiResponse<String>> uploadImage(File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });
      final response = await _apiService.dio.post(
        "/api/images/upload",
        data: formData,
      );
      return ApiResponse<String>(
        success: response.data['success'] ?? false,
        data: response.data['data'] as String?,
        message: response.data['message'] as String?,
      );
    } catch (e) {
      return ApiResponse.withError(e, defaultMessage: "Lỗi tải ảnh lên hệ thống");
    }
  }
}