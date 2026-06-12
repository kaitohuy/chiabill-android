import 'package:get/get.dart';
import 'overall_stats_controller.dart';

class MainController extends GetxController {
  var currentIndex = 0.obs;

  void changeTabIndex(int index) {
    currentIndex.value = index;
    if (index == 1) {
      if (Get.isRegistered<OverallStatsController>()) {
        Get.find<OverallStatsController>().fetchAll();
      }
    }
  }
}
