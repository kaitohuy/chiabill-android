import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';

class ApiService {
  final Dio _dio = Dio();
  final _storage = GetStorage();

  ApiService() {
    // SỬA LỖI NULL Ở ĐÂY: Thêm ?? "URL_MẶC_ĐỊNH"
    _dio.options.baseUrl = dotenv.env['BASE_URL'] ?? "https://chiabill-server.onrender.com";
    //_dio.options.baseUrl = "http://10.151.115.234:8080";
    _dio.options.connectTimeout = const Duration(seconds: 10);

    // Interceptor: Tự động gắn Token vào Header nếu có
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        String? token = _storage.read('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Dio get dio => _dio;
}