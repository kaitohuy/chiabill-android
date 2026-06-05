import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../routes/app_pages.dart';

class AppLinksService extends GetxService {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  String? _pendingInviteCode;

  @override
  void onInit() {
    super.onInit();
    // Trì hoãn xử lý Deep Link 1 giây để tránh nghẽn luồng lúc khởi động mượt mà,
    // nhường tài nguyên cho khung hình đầu tiên của Flutter được vẽ trọn vẹn.
    Future.delayed(const Duration(seconds: 1), () {
      _initDeepLinks();
    });
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // 1. Xử lý link khi ứng dụng bị đóng hoàn toàn (Cold Start)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint("Cold Start Deep Link: $initialUri");
        _handleIncomingLink(initialUri);
      }
    } catch (e) {
      debugPrint("Deep Link Cold Start Error: $e");
    }

    // 2. Lắng nghe link khi ứng dụng đang mở (Background / Foreground)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint("Nhận Deep Link mới: $uri");
        _handleIncomingLink(uri);
      },
      onError: (err) {
        debugPrint("Deep Link Stream Error: $err");
      },
    );
  }

  /// Hàm này được gọi bởi HomeController.onReady() để xử lý link đang chờ
  void checkAndHandlePendingLink() {
    if (_pendingInviteCode != null) {
      debugPrint("Đang xử lý mã mời đang chờ: $_pendingInviteCode");
      final code = _pendingInviteCode!;
      _pendingInviteCode = null; // Xóa ngay để tránh trùng lặp
      
      // Đợi thêm một chút cho chắc chắn Navigator ổn định
      Future.delayed(const Duration(milliseconds: 300), () {
        _navigateToJoinTrip(code);
      });
    }
  }

  void _handleIncomingLink(Uri uri) {
    debugPrint("Xử lý URI: path = ${uri.path}");
    
    if (uri.path.startsWith('/join/')) {
      final segments = uri.pathSegments;
      if (segments.length >= 2) {
        final inviteCode = segments[1];
        if (inviteCode.isNotEmpty) {
          // CHẾ ĐỘ AN TOÀN: 
          // Nếu đang ở màn Home và đã xong xuôi (có HomeController), cho phép chuyển trang luôn.
          // Nếu chưa (đang init), cất vào hàng chờ pending.
          if (Get.currentRoute == Routes.MAIN && Get.isRegistered<HomeController>()) {
            _navigateToJoinTrip(inviteCode);
          } else {
            debugPrint("Chưa sẵn sàng, cất mã mời vào hàng chờ: $inviteCode");
            _pendingInviteCode = inviteCode;
          }
        }
      }
    }
  }

  void _navigateToJoinTrip(String inviteCode) {
    if (Get.currentRoute != Routes.JOIN_TRIP) {
      Get.toNamed(Routes.JOIN_TRIP, arguments: inviteCode);
    }
  }

  @override
  void onClose() {
    _linkSubscription?.cancel();
    super.onClose();
  }
}
