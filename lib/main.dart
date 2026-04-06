import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/home/home_screen.dart'; // Import HomeScreen

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Nhận thông báo khi tắt app: ${message.messageId}");
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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Đọc token từ bộ nhớ máy
    final token = GetStorage().read('token');

    return GetMaterialApp(
      title: 'Chia Bill',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreen),
        useMaterial3: true,
      ),
      // LOGIC MỚI: Nếu có token rồi thì vào Home, chưa có thì vào Welcome
      home: (token != null && token.toString().isNotEmpty)
          ? HomeScreen()
          : WelcomeScreen(),
    );
  }
}
