import 'package:get/get.dart';
import '../controllers/main_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/notification_controller.dart';
import '../controllers/profile_controller.dart';

import '../controllers/overall_stats_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainController>(() => MainController());
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<NotificationController>(() => NotificationController());
    Get.lazyPut<ProfileController>(() => ProfileController());
    Get.lazyPut<OverallStatsController>(() => OverallStatsController(), fenix: true);
  }
}
