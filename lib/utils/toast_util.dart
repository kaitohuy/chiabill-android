import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ToastUtil {
  // Thành công: Xanh lá cây nhạt (Mã màu từ ảnh tham khảo)
  static void showSuccess(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFFE7F4E9).withOpacity(0.95), // Màu xanh lá siêu nhạt
      colorText: const Color(0xFF1E4620), // Màu xanh lá đậm cho text
      icon: const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 28),
      borderRadius: 16,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      duration: const Duration(seconds: 3),
      borderWidth: 1,
      borderColor: const Color(0xFFB9DFBB),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    );
  }

  // Lỗi: Đỏ nhạt
  static void showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFFFDEBEC).withOpacity(0.95),
      colorText: const Color(0xFF611A15),
      icon: const Icon(Icons.error_outline, color: Color(0xFFC62828), size: 28),
      borderRadius: 16,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      duration: const Duration(seconds: 4),
      borderWidth: 1,
      borderColor: const Color(0xFFF8B4B4),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    );
  }

  // Cảnh báo: Vàng nhạt
  static void showWarning(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFFFFF4E5).withOpacity(0.95),
      colorText: const Color(0xFF663C00),
      icon: const Icon(Icons.warning_amber_outlined, color: Color(0xFFEF6C00), size: 28),
      borderRadius: 16,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      duration: const Duration(seconds: 4),
      borderWidth: 1,
      borderColor: const Color(0xFFFFD599),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    );
  }

  // Thông tin: Xanh dương nhạt
  static void showInfo(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFFE5F6FD).withOpacity(0.95),
      colorText: const Color(0xFF014361),
      icon: const Icon(Icons.info_outline, color: Color(0xFF0277BD), size: 28),
      borderRadius: 16,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      duration: const Duration(seconds: 3),
      borderWidth: 1,
      borderColor: const Color(0xFFB3E5FC),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    );
  }
}
