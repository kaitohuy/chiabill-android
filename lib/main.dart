import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'controllers/theme_controller.dart';
import 'routes/app_pages.dart';
import 'utils/app_links_util.dart';
import 'services/offline_sync_service.dart';
import 'services/alarm_service.dart';
import 'utils/storage_util.dart';
import 'controllers/user_guide_controller.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Nhận thông báo khi tắt app: ${message.messageId}");
  if (message.data.containsKey('title') || message.data.containsKey('body')) {
    final title = message.data['title'] ?? 'Thông báo mới';
    final body = message.data['body'] ?? '';
    final type = message.data['type'];
    final referenceId = message.data['referenceId'];
    final imageUrl = message.data['imageUrl'];

    await AlarmService.init();
    await AlarmService.showInstantNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: (type != null && referenceId != null) ? '$type|$referenceId' : null,
      imageUrl: imageUrl,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Đảm bảo app vẽ tràn màn hình (Edge-to-Edge) trước
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Cấu hình thanh điều hướng và thanh trạng thái sau
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.white, // Đặt màu trắng để hệ thống kích hoạt nút màu tối (xám/đen)
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark, // Màu của 3 nút tối màu (đen/xám)
      systemNavigationBarContrastEnforced: false, // Tắt ép buộc độ tương phản
      statusBarColor: Colors.transparent, // Thanh trạng thái trong suốt
      statusBarIconBrightness: Brightness.dark,
      systemStatusBarContrastEnforced: false,
    ),
  );

  // Khởi chạy song song (đồng thời) các tác vụ bất đồng bộ nặng lúc khởi động để tối đa hóa hiệu năng luồng
  await Future.wait([
    dotenv.load(fileName: ".env"),
    Firebase.initializeApp(),
    GetStorage.init(),
    AlarmService.init(),
  ]);

  // Yêu cầu quyền thông báo của Android 13+
  AlarmService.requestPermissions();

  // 3. ĐĂNG KÝ HÀM CHẠY NGẦM (Trì hoãn 4 giây để tránh tạo thêm luồng FlutterEngine chạy ngầm làm nghẽn Vulkan lúc khởi động app)
  Future.delayed(const Duration(seconds: 4), () {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  });
  
  // Chờ app khởi dựng và render mượt mà xong, sau đó mới chạy tác vụ dọn dẹp bộ nhớ ở background sau 5 giây để tránh áp lực I/O lúc khởi động
  Future.delayed(const Duration(seconds: 5), () {
    StorageUtil.checkAndAutoClean();
  });

  // Khởi tạo các Service/Controller toàn cục
  Get.put(AppLinksService(), permanent: true);
  final themeController = Get.put(ThemeController(), permanent: true);
  Get.put(OfflineSyncService(), permanent: true);
  Get.put(UserGuideController(), permanent: true);
  
  runApp(MyApp(themeController: themeController));
}

class MyApp extends StatelessWidget {
  final ThemeController themeController;

  const MyApp({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    // Đọc token từ bộ nhớ máy
    final token = GetStorage().read('token');
    final hasToken = token != null && token.toString().isNotEmpty;

    return GetMaterialApp(
      title: 'DuliVie',
      debugShowCheckedModeBanner: false,
      theme: themeController.getThemeData(),
      initialRoute: hasToken ? Routes.MAIN : Routes.WELCOME,
      getPages: AppPages.routes,
      builder: (context, child) {
        return Obx(() {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(themeController.textScale.value),
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: child,
            ),
          );
        });
      },
    );
  }
}
