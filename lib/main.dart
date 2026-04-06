import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
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
