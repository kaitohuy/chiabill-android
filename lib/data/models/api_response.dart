import 'package:get/get.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? _message;
  final String? errorCode;

  ApiResponse({
    required this.success,
    this.data,
    String? message,
    this.errorCode,
  }) : _message = message;

  String? get message {
    if (errorCode != null && errorCode!.isNotEmpty) {
      final translated = errorCode!.tr;
      if (translated != errorCode) {
        return translated;
      }
    }
    return _message;
  }

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic json) fromJsonT) {
    return ApiResponse<T>(
      success: json['success'] as bool,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      message: json['message'] as String?,
      errorCode: json['errorCode'] as String?,
    );
  }

  static ApiResponse<T> withError<T>(Object e, {String defaultMessage = "Lỗi hệ thống"}) {
    if (e.runtimeType.toString() == 'DioException') {
      dynamic dioException = e;
      
      // Xử lý riêng các lỗi kết nối/timeout
      if (dioException.type.toString() == 'DioExceptionType.connectionTimeout' || 
          dioException.type.toString() == 'DioExceptionType.receiveTimeout' ||
          dioException.type.toString() == 'DioExceptionType.connectionError') {
        return ApiResponse<T>(
          success: false, 
          message: "Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại kết nối mạng hoặc IP Server.",
          errorCode: 'CONNECTION_ERROR',
        );
      }

      if (dioException.response?.data != null && dioException.response?.data is Map<String, dynamic>) {
        final errorData = dioException.response!.data as Map<String, dynamic>;
        final msg = errorData['message'];
        final errCode = errorData['errorCode'] as String?;
        if (msg != null && msg.toString().isNotEmpty) {
          return ApiResponse<T>(
            success: false, 
            message: msg.toString(),
            errorCode: errCode,
          );
        }
      }
      return ApiResponse<T>(
        success: false, 
        message: "Lỗi máy chủ (Code: ${dioException.response?.statusCode ?? 'N/A'})",
        errorCode: 'SERVER_ERROR',
      );
    }
    return ApiResponse<T>(
      success: false, 
      message: "$defaultMessage: $e",
      errorCode: 'UNKNOWN_ERROR',
    );
  }
}
