import 'package:chiabill/controllers/home_controller.dart';
import 'package:chiabill/controllers/notification_controller.dart';
import 'package:chiabill/controllers/overall_stats_controller.dart';
import 'package:chiabill/controllers/main_controller.dart';
import 'package:chiabill/controllers/profile_controller.dart';
import 'package:chiabill/utils/loading_util.dart';
import 'package:chiabill/utils/toast_util.dart';
import 'package:get/get.dart';
import '../data/models/user_response.dart';
import '../routes/app_pages.dart';
import '../services/auth_service.dart';
import 'fcm_controller.dart';

class AuthController extends GetxController {
  var isLoading = false.obs;
  var currentUser = Rxn<UserResponse>();

  final AuthService _authService = AuthService();

  Future<void> logout() async {
    try {
      isLoading.value = true;
      LoadingUtil.show();
      await _authService.logout();
      Get.deleteAll();
      LoadingUtil.hide();
      Get.offAllNamed(Routes.WELCOME);
    } catch (e) {
      Get.deleteAll();
      Get.offAllNamed(Routes.WELCOME);
    } finally {
      isLoading.value = false;
      LoadingUtil.hide();
    }
  }

  Future<void> loginAnonymous() async {
    try {
      isLoading.value = true;
      LoadingUtil.show();
      
      final result = await _authService.loginAnonymous();

      if (result.success && result.data != null) {
        currentUser.value = result.data!.user;

        if (Get.isRegistered<FcmController>()) {
          Get.find<FcmController>().setupFCM();
        } else {
          Get.put(FcmController(), permanent: true);
        }

        LoadingUtil.hide();
        ToastUtil.showSuccess("Thành công", "Đăng nhập thành công!");
        Get.offAllNamed(Routes.MAIN);
      } else {
        LoadingUtil.hide();
        ToastUtil.showError("Lỗi", result.message ?? "Không thể đăng nhập");
      }
    } catch (e) {
      LoadingUtil.hide();
      ToastUtil.showError("Lỗi hệ thống", e.toString());
    } finally {
      isLoading.value = false;
      LoadingUtil.hide();
    }
  }

  Future<void> loginWithGoogle({bool forceSwitch = false}) async {
    try {
      isLoading.value = true;
      LoadingUtil.show();
      
      final result = await _authService.loginWithGoogle(forceSwitch: forceSwitch);
      
      // Nếu user hủy thì success=false và data=null nhưng không phải lỗi crash
      if (!result.success && result.message == "Đã hủy đăng nhập") {
        LoadingUtil.hide();
        return; // Không hiển thị lỗi nếu người dùng chủ động hủy
      }

      if (result.success && result.data != null) {
        currentUser.value = result.data!.user;

        if (Get.isRegistered<FcmController>()) {
          Get.find<FcmController>().setupFCM();
        } else {
          Get.put(FcmController(), permanent: true);
        }

        LoadingUtil.hide();
        ToastUtil.showSuccess("Thành công", "Đăng nhập thành công!");
        
        if (Get.currentRoute != Routes.MAIN) {
          Get.offAllNamed(Routes.MAIN);
        } else {
          // Tải lại dữ liệu ở tất cả các tab
          if (Get.isRegistered<ProfileController>()) Get.find<ProfileController>().fetchProfile();
          if (Get.isRegistered<HomeController>()) Get.find<HomeController>().fetchTrips(isRefresh: true);
          if (Get.isRegistered<NotificationController>()) {
            Get.find<NotificationController>().fetchUnreadCount();
            Get.find<NotificationController>().fetchNotifications();
          }
          if (Get.isRegistered<OverallStatsController>()) {
            final statsCtrl = Get.find<OverallStatsController>();
            statsCtrl.fetchSummary();
            statsCtrl.fetchAllTimeStats();
            statsCtrl.fetchOverallStats();
          }
          
          // Tự động chuyển về Tab 0 (Home)
          if (Get.isRegistered<MainController>()) {
            Get.find<MainController>().changeTabIndex(0);
          }
        }
      } else {
        LoadingUtil.hide();
        ToastUtil.showError("Lỗi", result.message ?? "Xác thực thất bại");
      }
    } catch (error) {
      LoadingUtil.hide();
      ToastUtil.showError("Lỗi", error.toString());
    } finally {
      isLoading.value = false;
      LoadingUtil.hide();
    }
  }
}

