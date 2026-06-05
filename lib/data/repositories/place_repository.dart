import 'dart:io';
import 'package:dio/dio.dart' as dio_form; // Tránh xung đột Dio
import 'package:chiabill/data/models/place_model.dart';
import 'package:chiabill/data/models/api_response.dart';
import '../network/api_service.dart';

class PlaceRepository {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<List<PlaceModel>>> getPlaces({String? category, int page = 0, int size = 10}) async {
    try {
      final response = await _apiService.dio.get(
        '/api/v1/places',
        queryParameters: {
          if (category != null && category != 'Tất cả') 'category': category,
          'page': page,
          'size': size,
        },
      );
      if (response.data != null && response.data['success'] == true) {
        final List<dynamic> data = response.data['data']['content'];
        final places = data.map((json) => PlaceModel.fromJson(json)).toList();
        return ApiResponse(success: true, data: places);
      }
      return ApiResponse(success: false, message: response.data['message']);
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<List<PlaceModel>>> getPlacesNearby(double lat, double lng, {double radius = 50.0, int limit = 100}) async {
    try {
      final response = await _apiService.dio.get(
        '/api/v1/places/map',
        queryParameters: {
          'latitude': lat,
          'longitude': lng,
          'radius': radius,
          'limit': limit,
        },
      );
      if (response.data != null && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        final places = data.map((json) => PlaceModel.fromJson(json)).toList();
        return ApiResponse(success: true, data: places);
      }
      return ApiResponse(success: false, message: response.data['message']);
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<List<PlaceModel>>> searchPlaces(String keyword, {int page = 0, int size = 10}) async {
    try {
      final response = await _apiService.dio.get(
        '/api/v1/places/search',
        queryParameters: {
          'keyword': keyword,
          'page': page,
          'size': size,
        },
      );
      if (response.data != null && response.data['success'] == true) {
        final List<dynamic> data = response.data['data']['content']; // Phân trang
        final places = data.map((json) => PlaceModel.fromJson(json)).toList();
        return ApiResponse(success: true, data: places);
      }
      return ApiResponse(success: false, message: response.data['message']);
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<PlaceModel>> createPlace(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.post('/api/v1/places', data: data);
      if (response.data != null && response.data['success'] == true) {
        final place = PlaceModel.fromJson(response.data['data']);
        return ApiResponse(success: true, data: place);
      }
      return ApiResponse(success: false, message: response.data['message']);
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<PlaceModel>> updatePlace(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.put('/api/v1/places/$id', data: data);
      if (response.data != null && response.data['success'] == true) {
        final place = PlaceModel.fromJson(response.data['data']);
        return ApiResponse(success: true, data: place);
      }
      return ApiResponse(success: false, message: response.data['message']);
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<String>> uploadPlaceImage(int placeId, String album, File file) async {
    try {
      String fileName = file.path.split('/').last;
      dio_form.FormData formData = dio_form.FormData.fromMap({
        "file": await dio_form.MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _apiService.dio.post(
        '/api/v1/places/$placeId/images',
        data: formData,
        queryParameters: {'album': album},
      );

      if (response.data != null && response.data['success'] == true) {
        return ApiResponse(success: true, data: response.data['data']);
      }
      return ApiResponse(success: false, message: response.data['message']);
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<void>> reportPlace(int id, String reportType, String description) async {
    try {
      final response = await _apiService.dio.post(
        '/api/v1/places/$id/report',
        data: {
          'reportType': reportType,
          'description': description,
        },
      );
      if (response.data != null && response.data['success'] == true) {
        return ApiResponse(success: true);
      }
      return ApiResponse(success: false, message: response.data['message']);
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }
}
