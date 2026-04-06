import 'package:chiabill/utils/toast_util.dart';
import 'package:chiabill/controllers/home_controller.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../data/models/user_response.dart';
import '../data/repositories/auth_repository.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/home/home_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'fcm_controller.dart'; // IMPORT THÊM DÒNG NÀY

class AuthController extends GetxController {
  var isLoading = false.obs;
  var currentUser = Rxn<UserResponse>();

  final AuthRepository _repository = AuthRepository();
  final _storage = GetStorage();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
  );

  Future<void> logout() async {
    try {
      isLoading.value = true;
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.disconnect();
      }
      GetStorage().erase();
      Get.deleteAll(force: true);
      Get.offAll(() => WelcomeScreen());
    } catch (e) {
      GetStorage().erase();
      Get.deleteAll(force: true);
      Get.offAll(() => WelcomeScreen());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginAnonymous() async {
    isLoading.value = true;
    final result = await _repository.loginAnonymous();

    if (result.success && result.data != null) {
      await _storage.write('token', result.data!.token);
      currentUser.value = result.data!.user;

      // ==========================================
      // GỌI FCM CONTROLLER SAU KHI CÓ TOKEN
      // ==========================================
      if (Get.isRegistered<FcmController>()) {
        Get.find<FcmController>().setupFCM();
      } else {
        Get.put(FcmController(), permanent: true);
      }

      ToastUtil.showSuccess("Thành công", "Đăng nhập thành công!");
      Get.put(HomeController()).fetchTrips();
      Get.offAll(() => HomeScreen());
    } else {
      ToastUtil.showError("Lỗi", result.message ?? "Không thể đăng nhập");
    }
    isLoading.value = false;
  }

  Future<void> loginWithGoogle() async {
    try {
      isLoading.value = true;
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        isLoading.value = false;
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken != null) {
        final result = await _repository.loginGoogle(idToken);

        if (result.success && result.data != null) {
          await _storage.write('token', result.data!.token);
          currentUser.value = result.data!.user;

          // ==========================================
          // GỌI FCM CONTROLLER SAU KHI CÓ TOKEN
          // ==========================================
          if (Get.isRegistered<FcmController>()) {
            Get.find<FcmController>().setupFCM();
          } else {
            Get.put(FcmController(), permanent: true);
          }

          ToastUtil.showSuccess("Thành công", "Đăng nhập thành công!");
          Get.put(HomeController()).fetchTrips();
          Get.offAll(() => HomeScreen());
        } else {
          ToastUtil.showError("Lỗi", result.message ?? "Xác thực server thất bại");
        }
      }
    } catch (error) {
      print("Google Auth Error: $error");
      ToastUtil.showError("Lỗi", "Không thể đăng nhập Google");
    } finally {
      isLoading.value = false;
    }
  }
}