class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic json) fromJsonT) {
    return ApiResponse<T>(
      success: json['success'] as bool,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      message: json['message'] as String?,
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
          message: "Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại kết nối mạng hoặc IP Server. (Nếu sử dụng Render Free Tier, máy chủ có thể mất 30 giây - 1 phút để tự động thức dậy)."
        );
      }

      if (dioException.response?.data != null && dioException.response?.data is Map<String, dynamic>) {
        final errorData = dioException.response!.data as Map<String, dynamic>;
        final msg = errorData['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          return ApiResponse<T>(success: false, message: msg.toString());
        }
      }
      return ApiResponse<T>(success: false, message: "Lỗi máy chủ (Code: ${dioException.response?.statusCode ?? 'N/A'})");
    }
    return ApiResponse<T>(success: false, message: "$defaultMessage: $e");
  }
}
