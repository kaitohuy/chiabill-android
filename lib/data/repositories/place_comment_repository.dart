import 'package:chiabill/data/models/api_response.dart';
import '../models/place_comment_model.dart';
import '../network/api_service.dart';
import 'package:dio/dio.dart';

class PlaceCommentRepository {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<List<PlaceCommentModel>>> getComments(int placeId, {int page = 0, int size = 20}) async {
    try {
      final response = await _apiService.dio.get(
        '/api/v1/places/$placeId/comments',
        queryParameters: {
          'page': page,
          'size': size,
        },
      );
      if (response.data != null && response.data['success'] == true) {
        final List<dynamic> data = response.data['data']['content'];
        final comments = data.map((json) => PlaceCommentModel.fromJson(json)).toList();
        return ApiResponse(success: true, data: comments);
      }
      return ApiResponse(success: false, message: response.data['message']);
    } catch (e) {
      return ApiResponse(success: false, message: _handleError(e));
    }
  }

  Future<ApiResponse<PlaceCommentModel>> addComment(int placeId, String content) async {
    try {
      final response = await _apiService.dio.post(
        '/api/v1/places/$placeId/comments',
        data: {'content': content},
      );
      if (response.data != null && response.data['success'] == true) {
        return ApiResponse(success: true, data: PlaceCommentModel.fromJson(response.data['data']));
      }
      return ApiResponse(success: false, message: response.data['message']);
    } catch (e) {
      return ApiResponse(success: false, message: _handleError(e));
    }
  }

  Future<ApiResponse<PlaceCommentModel>> replyComment(int commentId, String content) async {
    try {
      final response = await _apiService.dio.post(
        '/api/v1/places/comments/$commentId/reply',
        data: {'content': content},
      );
      if (response.data != null && response.data['success'] == true) {
        return ApiResponse(success: true, data: PlaceCommentModel.fromJson(response.data['data']));
      }
      return ApiResponse(success: false, message: response.data['message']);
    } catch (e) {
      return ApiResponse(success: false, message: _handleError(e));
    }
  }

  Future<ApiResponse<void>> toggleLike(int commentId) async {
    try {
      final response = await _apiService.dio.post(
        '/api/v1/places/comments/$commentId/like',
      );
      if (response.data != null && response.data['success'] == true) {
        return ApiResponse(success: true);
      }
      return ApiResponse(success: false, message: response.data['message']);
    } catch (e) {
      return ApiResponse(success: false, message: _handleError(e));
    }
  }

  Future<ApiResponse<PlaceCommentModel>> updateComment(int commentId, String content) async {
    try {
      final response = await _apiService.dio.put(
        '/api/v1/places/comments/$commentId',
        data: {'content': content},
      );
      if (response.data != null && response.data['success'] == true) {
        return ApiResponse(success: true, data: PlaceCommentModel.fromJson(response.data['data']));
      }
      return ApiResponse(success: false, message: response.data['message']);
    } catch (e) {
      return ApiResponse(success: false, message: _handleError(e));
    }
  }

  Future<ApiResponse<void>> deleteComment(int commentId) async {
    try {
      final response = await _apiService.dio.delete(
        '/api/v1/places/comments/$commentId',
      );
      if (response.data != null && response.data['success'] == true) {
        return ApiResponse(success: true);
      }
      return ApiResponse(success: false, message: response.data['message']);
    } catch (e) {
      return ApiResponse(success: false, message: _handleError(e));
    }
  }

  String _handleError(dynamic e) {
    if (e is DioException) {
      if (e.response?.data != null && e.response!.data is Map<String, dynamic>) {
        return e.response!.data['message'] ?? "Lỗi máy chủ";
      }
      return "Lỗi mạng hoặc máy chủ không phản hồi";
    }
    return "Đã xảy ra lỗi không xác định";
  }
}
