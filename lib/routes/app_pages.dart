// ignore_for_file: constant_identifier_names
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../controllers/notification_controller.dart';
import '../controllers/profile_controller.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/main/main_screen.dart';
import '../bindings/main_binding.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/notification/notification_screen.dart';
import '../screens/trip/trip_detail_screen.dart';
import '../screens/trip/join_trip_screen.dart';
import '../screens/trip/trash_screen.dart';
import '../screens/calculator/calculator_screen.dart';

abstract class Routes {
  static const WELCOME = '/welcome';
  static const MAIN = '/main';
  static const HOME = '/home';
  static const PROFILE = '/profile';
  static const NOTIFICATION = '/notification';
  static const TRIP_DETAIL = '/trip-detail';
  static const JOIN_TRIP = '/join-trip';
  static const TRASH = '/trash';
  static const CALCULATOR = '/calculator';
}

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
    Get.lazyPut<NotificationController>(() => NotificationController(), fenix: true);
    Get.lazyPut<ProfileController>(() => ProfileController(), fenix: true);
  }
}

class AppPages {
  static final routes = [
    GetPage(
      name: Routes.WELCOME,
      page: () => WelcomeScreen(),
    ),
    GetPage(
      name: Routes.MAIN,
      page: () => const MainScreen(),
      binding: MainBinding(),
    ),
    GetPage(
      name: Routes.HOME,
      page: () => HomeScreen(),
      binding: HomeBinding(), 
    ),
    GetPage(
      name: Routes.PROFILE,
      page: () => ProfileScreen(),
    ),
    GetPage(
      name: Routes.NOTIFICATION,
      page: () => NotificationScreen(),
    ),
    GetPage(
      name: Routes.TRIP_DETAIL,
      // Nhận id qua arguments hoặc parameters
      page: () {
        final id = Get.arguments;
        return TripDetailScreen(tripId: id is int ? id : int.parse(id.toString()));
      },
    ),
    GetPage(
      name: Routes.JOIN_TRIP,
      page: () => const JoinTripScreen(),
    ),
    GetPage(
      name: Routes.TRASH,
      page: () => const TrashScreen(),
    ),
    GetPage(
      name: Routes.CALCULATOR,
      page: () => CalculatorScreen(),
    ),
  ];
}
