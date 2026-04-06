import 'package:chiabill/data/models/update_expense_request.dart';
import 'package:dio/dio.dart';

import '../models/api_response.dart';
import '../models/category_stat_response.dart';
import '../models/expense_response.dart';
import '../models/page_response.dart';
import '../network/api_service.dart';
import '../models/create_expense_request.dart';

class ExpenseRepository {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<PageResponse<ExpenseResponse>>> searchExpenses({
    required int tripId,
    int page = 0,
    int size = 20,
    String? keyword,
    int? categoryId,
    int? payerId,
  }) async {
    try {
      // Build query parameters
      Map<String, dynamic> queryParams = {
        'page': page,
        'size': size,
        'sort': 'expenseDate,desc', // Mặc định xếp mới nhất lên đầu
      };
      if (keyword != null && keyword.isNotEmpty) queryParams['keyword'] = keyword;
      if (categoryId != null) queryParams['categoryId'] = categoryId;
      if (payerId != null) queryParams['payerId'] = payerId;

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
      return ApiResponse(success: false, message: "Lỗi tải chi phí: $e");
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
      return ApiResponse(success: false, message: "Lỗi tải chi phí: $e");
    }
  }

  Future<ApiResponse<ExpenseResponse>> createExpense(CreateExpenseRequest request) async {
    try {
      final response = await _apiService.dio.post("/api/expenses", data: request.toJson());
      return ApiResponse<ExpenseResponse>.fromJson(
        response.data,
            (data) => ExpenseResponse.fromJson(data),
      );
    } on DioException catch (e) {
      // BẮT LỖI TỪ BACKEND VÀ TRÍCH XUẤT MESSAGE CỰC AN TOÀN
      if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
        final errorData = e.response!.data as Map<String, dynamic>;
        return ApiResponse<ExpenseResponse>(
          success: false,
          message: errorData['message'] ?? "Lỗi từ server (Code: ${e.response?.statusCode})",
        );
      }
      return ApiResponse<ExpenseResponse>(success: false, message: "Lỗi máy chủ (Code: ${e.response?.statusCode})");
    } catch (e) {
      return ApiResponse<ExpenseResponse>(success: false, message: "Lỗi hệ thống: $e");
    }
  }

  Future<ApiResponse<ExpenseResponse>> updateExpense(int expenseId, UpdateExpenseRequest request) async {
    try {
      final response = await _apiService.dio.put("/api/expenses/$expenseId", data: request.toJson());
      return ApiResponse<ExpenseResponse>.fromJson(
        response.data,
            (data) => ExpenseResponse.fromJson(data),
      );
    } on DioException catch (e) {
      // BẮT LỖI TỪ BACKEND
      if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
        final errorData = e.response!.data as Map<String, dynamic>;
        return ApiResponse<ExpenseResponse>(
          success: false,
          message: errorData['message'] ?? "Lỗi từ server (Code: ${e.response?.statusCode})",
        );
      }
      return ApiResponse<ExpenseResponse>(success: false, message: "Lỗi máy chủ (Code: ${e.response?.statusCode})");
    } catch (e) {
      return ApiResponse<ExpenseResponse>(success: false, message: "Lỗi hệ thống: $e");
    }
  }

  // Xóa khoản chi
  Future<ApiResponse<void>> deleteExpense(int expenseId) async {
    try {
      await _apiService.dio.delete("/api/expenses/$expenseId");
      return ApiResponse(success: true);
    } catch (e) {
      return ApiResponse(success: false, message: "Lỗi xóa khoản chi: $e");
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
      return ApiResponse(success: false, message: "Lỗi tải thống kê: $e");
    }
  }
}