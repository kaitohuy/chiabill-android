import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../data/models/api_response.dart';
import '../data/models/auth_response.dart';
import '../data/repositories/auth_repository.dart';

class AuthService {
  final AuthRepository _repository = AuthRepository();
  final _storage = GetStorage();

  late final GoogleSignIn _googleSignIn;

  AuthService() {
    _googleSignIn = GoogleSignIn(
      serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
    );
  }

  /// Xử lý logic đăng xuất: ngắt kết nối Google và xóa storage
  Future<void> logout() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.disconnect();
      }
    } catch (e) {
      // Bỏ qua lỗi ngắt kết nối Google nếu có

    } finally {
      await _storage.erase();
    }
  }

  /// Đăng nhập ẩn danh và lưu token
  Future<ApiResponse<AuthResponse>> loginAnonymous() async {
    final result = await _repository.loginAnonymous();
    if (result.success && result.data != null) {
      await _storage.write('token', result.data!.token);
    }
    return result;
  }

  /// Mở luồng đăng nhập Google, lấy idToken, gọi API và lưu token
  Future<ApiResponse<AuthResponse>> loginWithGoogle({bool forceSwitch = false}) async {
    if (forceSwitch && await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
    }
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return ApiResponse.withError(Exception("Người dùng đã hủy đăng nhập Google"), defaultMessage: "Đã hủy đăng nhập");
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final String? idToken = googleAuth.idToken;

    if (idToken == null) {
      return ApiResponse.withError(Exception("Không thể lấy ID Token từ Google"), defaultMessage: "Lỗi xác thực Google");
    }

    final result = await _repository.loginGoogle(idToken);
    if (result.success && result.data != null) {
      await _storage.write('token', result.data!.token);
    }
    return result;
  }
}
