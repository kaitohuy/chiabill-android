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
import 'utils/storage_util.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Nhận thông báo khi tắt app: ${message.messageId}");
  // OS sẽ tự động hiện popup thông báo vì BE của bạn có truyền block "notification"
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cấu hình thanh điều hướng và thanh trạng thái
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent, // Nền thanh 3 nút trong suốt
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark, // Màu của 3 nút (đen/xám)
      systemNavigationBarContrastEnforced: false, // Tắt ép buộc độ tương phản (để trong suốt hoàn toàn)
      statusBarColor: Colors.transparent, // Thanh trạng thái pin/sóng cũng trong suốt luôn
      statusBarIconBrightness: Brightness.dark,
      systemStatusBarContrastEnforced: false,
    ),
  );

  // Đảm bảo app vẽ tràn màn hình (Edge-to-Edge)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();

  // 3. ĐĂNG KÝ HÀM CHẠY NGẦM
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  await GetStorage.init();
  
  // Khởi chạy dọn dẹp bộ nhớ đệm tự động nếu đến kỳ hoặc vượt dung lượng
  StorageUtil.checkAndAutoClean();

  // Khởi tạo các Service/Controller toàn cục
  Get.put(AppLinksService(), permanent: true);
  final themeController = Get.put(ThemeController(), permanent: true);
  Get.put(OfflineSyncService(), permanent: true);
  
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
      title: 'Chia Bill',
      debugShowCheckedModeBanner: false,
      theme: themeController.getThemeData(),
      initialRoute: hasToken ? Routes.MAIN : Routes.WELCOME,
      getPages: AppPages.routes,
    );
  }
}
