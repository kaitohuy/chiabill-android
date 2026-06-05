import 'package:get/get.dart';
import '../controllers/main_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/notification_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/overall_stats_controller.dart';
import '../controllers/tourism_controller.dart';
import '../controllers/create_trip_controller.dart';
import '../controllers/auth_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainController>(() => MainController());
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<NotificationController>(() => NotificationController());
    Get.lazyPut<ProfileController>(() => ProfileController());
    Get.lazyPut<OverallStatsController>(() => OverallStatsController(), fenix: true);
    Get.lazyPut<TourismController>(() => TourismController());
    Get.lazyPut<CreateTripController>(() => CreateTripController(), fenix: true);
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
  }
}
