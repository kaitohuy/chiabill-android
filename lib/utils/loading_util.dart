import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';

class LoadingUtil {
  static bool _isShowing = false;

  static void show() {
    if (_isShowing) return; // Không cho phép mở lồng nhau
    _isShowing = true;

    Get.dialog(
      PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
           // Đảm bảo phím Back không đóng được Loading nếu _isShowing vẫn đúng
        },
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/loading.gif',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.15),
      useSafeArea: true,
    );
  }

  static void hide() {
    if (!_isShowing) return;
    _isShowing = false;
    
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }
}
