import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

class LoadingUtil {
  static bool _isShowing = false;
  static Timer? _timeoutTimer;

  static void show({int timeoutSeconds = 10}) {
    if (_isShowing) return;
    _isShowing = true;

    // Tự động đóng sau X giây nếu quên gọi hide()
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(Duration(seconds: timeoutSeconds), () {
      hide();
    });

    Get.dialog(
      PopScope(
        canPop: true, // Cho phép pop (cả back button và Get.back)
        onPopInvokedWithResult: (didPop, result) {
           // Đồng bộ state nếu user bấm nút Back vật lý trên Android
           _isShowing = false; 
        },
        child: Center(
          child: Container(
            width: 120,
            height: 120,
            color: Colors.transparent,
            child: Image.asset(
              'assets/images/loading.gif',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.15),
      useSafeArea: true,
    ).then((_) {
      _isShowing = false;
    });
  }

  static void hide() {
    _timeoutTimer?.cancel();
    if (!_isShowing) return;
    _isShowing = false;
    
    // Tránh race condition khi gọi hide() quá nhanh ngay sau show()
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isDialogOpen == true) {
        Get.back();
      } else {
        // Dự phòng nếu dialog đang trong quá trình chuyển cảnh
        Future.delayed(const Duration(milliseconds: 250), () {
          if (Get.isDialogOpen == true) {
            Get.back();
          }
        });
      }
    });
  }
}
