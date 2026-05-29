import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UIUtil {
  /// Một hàm bọc GestureDetector.onTap để tối ưu trải nghiệm người dùng:
  /// 1. Nếu bàn phím đang hiện -> Ẩn bàn phím đi (Unfocus) và KHÔNG thực hiện hành động khác.
  /// 2. Nếu đã có Dialog hoặc BottomSheet đang mở -> Bỏ qua.
  /// 3. Nếu mọi thứ bình thường -> Thực hiện hành động chính [action].
  static void smartTap(BuildContext context, VoidCallback action) {
    // 1. Kiểm tra bàn phím (nếu cao hơn 0 thì là bàn phím đang hiện)
    if (MediaQuery.of(context).viewInsets.bottom > 0) {
      FocusScope.of(context).unfocus();
      return; 
    }

    // 2. Kiểm tra nếu đang có Dialog hoặc BottomSheet mở để tránh chồng chéo
    if (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
      return;
    }

    // 3. Thực hiện hành động (VD: Mở form tạo mới)
    action();
  }
}
