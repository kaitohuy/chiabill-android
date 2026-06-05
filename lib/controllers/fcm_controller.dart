import 'package:chiabill/utils/toast_util.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import '../data/network/api_service.dart';
import '../routes/app_pages.dart';
import '../services/alarm_service.dart';
import '../screens/trip/itinerary_screen.dart';

class FcmController extends GetxController {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();

  @override
  void onInit() {
    super.onInit();
    // Trì hoãn việc cấu hình FCM và kích hoạt Flutter Engine chạy ngầm thêm 3 giây.
    // Việc này giúp tránh xung đột Vulkan/GPU driver lúc khởi động app trên dòng máy Xiaomi,
    // đồng thời tối ưu hóa luồng để loại bỏ hoàn toàn log BLASTBufferQueue.
    Future.delayed(const Duration(seconds: 3), () {
      setupFCM();
    });
  }

  Future<void> setupFCM() async {
    // Check local notification launch details
    AlarmService.checkAppLaunchNotification();

    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true, badge: true, sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) sendTokenToBackend(token);

      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        sendTokenToBackend(newToken);
      });

      // 1. FOREGROUND: App đang mở
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final title = message.data['title'] ?? message.notification?.title ?? "Thông báo mới";
        final body = message.data['body'] ?? message.notification?.body ?? "";
        final type = message.data['type'];
        final referenceId = message.data['referenceId'];
        final imageUrl = message.data['imageUrl'] ?? message.notification?.android?.imageUrl;

        ToastUtil.showInfo(title, body);

        AlarmService.showInstantNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: title,
          body: body,
          payload: (type != null && referenceId != null) ? '$type|$referenceId' : null,
          imageUrl: imageUrl,
        );
      });

      // 2. BACKGROUND: App đang ẩn dưới nền
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationClick(message.data);
      });

      // ==========================================
      // 3. TERMINATED: APP ĐÃ BỊ TẮT HẲN
      // ==========================================
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        // Cần delay một chút để GetX kịp dựng màn hình HomeScreen xong,
        // rồi mới Push sang màn TripDetail, nếu không sẽ bị lỗi trắng màn hình.
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleNotificationClick(initialMessage.data);
        });
      }
    }
  }

  // ==========================================
  // HÀM ĐIỀU HƯỚNG CHUNG (Cần bỏ comment dòng Get.to)
  // ==========================================
  void _handleNotificationClick(Map<String, dynamic> data) {
    final String? type = data['type'];
    final String? referenceId = data['referenceId'];

    if (type != null && referenceId != null) {
      int tripId = int.parse(referenceId);

      if (type == "ITINERARY") {
        Get.to(() => ItineraryScreen(tripId: tripId));
      } else if (type == "EXPENSE_CREATED" || type == "PAYMENT_REQUESTED" || type == "PAYMENT_APPROVED") {
        Get.toNamed(Routes.TRIP_DETAIL, arguments: tripId);
      }
    }
  }

  // Gửi token lên BE
  Future<void> sendTokenToBackend(String token) async {
    try {
      String platform = Platform.isAndroid ? "ANDROID" : "IOS";
      // Gọi API đến BE mà bạn vừa viết
      await _apiService.dio.post("/api/notifications/register-token", data: {
        "token": token,
        "platform": platform
      });
      debugPrint("Đã đăng ký token với Backend thành công!");
    } catch (e) {
      debugPrint("Lỗi gửi token lên BE: $e");
    }
  }

}
