import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, MultipartFile, FormData;
import 'package:get_storage/get_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../services/offline_sync_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  late final Dio _dio;
  final _storage = GetStorage();

  ApiService._internal() {
    _dio = Dio();
    // _dio.options.baseUrl = dotenv.env['BASE_URL'] ?? "";
    _dio.options.baseUrl = "http://192.168.4.29:8080";
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
              String cacheKey = 'cache_GET_${options.path}';
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
             String cacheKey = 'cache_GET_${response.requestOptions.path}';
             _storage.write(cacheKey, response.data);
          }
        }
        return handler.next(response);
      },
    ));
  }

  Dio get dio => _dio;
}
