import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, MultipartFile, FormData;
import 'package:get_storage/get_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../services/offline_sync_service.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_pages.dart';
import '../../utils/toast_util.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  late final Dio _dio;
  final _storage = GetStorage();
  static bool _isHandling401 = false;

  static void _handleUnauthorized() {
    if (_isHandling401) return;
    _isHandling401 = true;
    
    GetStorage().remove('token');
    
    Future.delayed(Duration.zero, () async {
      ToastUtil.showError("Phiên đăng nhập hết hạn", "Vui lòng đăng nhập lại.");
      try {
        if (Get.isRegistered<AuthController>()) {
          await Get.find<AuthController>().logout();
        } else {
          Get.deleteAll();
          Get.offAllNamed(Routes.WELCOME);
        }
      } catch (err) {
        Get.deleteAll();
        Get.offAllNamed(Routes.WELCOME);
      } finally {
        _isHandling401 = false;
      }
    });
  }

  ApiService._internal() {
    _dio = Dio();
    _dio.options.baseUrl = dotenv.env['BASE_URL'] ?? "";
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 15);

    // Interceptor chính
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Gắn Token
        String? token = _storage.read('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        // Xử lý Offline
        if (Get.isRegistered<OfflineSyncService>()) {
          final syncService = Get.find<OfflineSyncService>();
          if (syncService.isOffline) {
            if (options.method == 'GET') {
              // Cố gắng đọc từ Cache
              String queryStr = options.queryParameters.isNotEmpty ? '_${jsonEncode(options.queryParameters)}' : '';
              String cacheKey = 'cache_GET_${options.path}$queryStr';
              var cachedData = _storage.read(cacheKey);
              if (cachedData != null) {
                return handler.resolve(Response(
                  requestOptions: options,
                  data: cachedData,
                  statusCode: 200,
                ));
              }
            } else {
              // POST, PUT, DELETE -> Ném vào Hàng đợi
              syncService.addToQueue(options.method, options.path, options.data);
              // Giả lập Response thành công ảo để không văng lỗi trên màn hình
              return handler.resolve(Response(
                requestOptions: options,
                data: {
                  'success': true,
                  'message': 'Đã lưu ngoại tuyến. Sẽ tự động đồng bộ khi có mạng.',
                  'data': null
                },
                statusCode: 200,
              ));
            }
          }
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // Lưu Cache cho các lệnh GET thành công
        if (response.requestOptions.method == 'GET' && response.data != null) {
          // Chỉ cache nếu server báo thành công
          if (response.data is Map && response.data['success'] == true) {
             String queryStr = response.requestOptions.queryParameters.isNotEmpty ? '_${jsonEncode(response.requestOptions.queryParameters)}' : '';
             String cacheKey = 'cache_GET_${response.requestOptions.path}$queryStr';
             _storage.write(cacheKey, response.data);
          }
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401) {
          _handleUnauthorized();
        }
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;
}
