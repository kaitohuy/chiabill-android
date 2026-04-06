import '../models/api_response.dart';
import '../models/expense_category_respone.dart';
import '../network/api_service.dart';

class CategoryRepository {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<List<ExpenseCategoryResponse>>> getCategories(int tripId) async {
    try {
      final response = await _apiService.dio.get("/api/categories/trip/$tripId");
      return ApiResponse<List<ExpenseCategoryResponse>>.fromJson(
        response.data,
            (data) => (data as List).map((i) => ExpenseCategoryResponse.fromJson(i)).toList(),
      );
    } catch (e) {
      return ApiResponse(success: false, message: "Lỗi tải danh mục: $e");
    }
  }

  Future<ApiResponse<ExpenseCategoryResponse>> createCustomCategory(int tripId, String name, String icon) async {
    try {
      final response = await _apiService.dio.post(
        "/api/categories/trip/$tripId",
        data: {"name": name, "icon": icon},
      );
      return ApiResponse<ExpenseCategoryResponse>.fromJson(
        response.data,
            (data) => ExpenseCategoryResponse.fromJson(data),
      );
    } catch (e) {
      return ApiResponse(success: false, message: "Lỗi tạo danh mục: $e");
    }
  }
}