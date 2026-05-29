import 'package:chiabill/utils/toast_util.dart';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import '../data/network/api_service.dart';
import '../routes/app_pages.dart';

class FcmController extends GetxController {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();

  @override
  void onInit() {
    super.onInit();
    setupFCM();
  }

  Future<void> setupFCM() async {
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
        if (message.notification != null) {
          ToastUtil.showInfo(
            message.notification!.title ?? "Thông báo mới",
            message.notification!.body ?? "",
          );
        }
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
      int tripId = int.parse(referenceId); // Ép kiểu String từ Firebase sang Int

      if (type == "EXPENSE_CREATED" || type == "PAYMENT_REQUESTED" || type == "PAYMENT_APPROVED") {
        // Thực hiện điều hướng
        Get.toNamed(Routes.TRIP_DETAIL, arguments: tripId);
      }
      // Thêm các nhánh khác tùy ý bạn sau này...
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
      print("Đã đăng ký token với Backend thành công!");
    } catch (e) {
      print("Lỗi gửi token lên BE: $e");
    }
  }

}
