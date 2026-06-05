import 'package:chiabill/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  AuthController get authController => Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ==========================================
                // 1. LOGO APP (Hiệu ứng xuất hiện)
                // ==========================================
                Image.asset(
                  'assets/images/home.gif',
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, size: 60, color: Colors.lightGreen),
                  ),
                )
                // Lớp Animate: Hiệu ứng xuất hiện lúc mới mở app (Chạy 1 lần)
                    .animate()
                    .fadeIn(duration: const Duration(milliseconds: 800), curve: Curves.easeOut)
                    .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 800), curve: Curves.easeOut),

                const SizedBox(height: 32),

                // ==========================================
                // 2. TÊN APP (Xuất hiện trễ hơn Logo một chút)
                // ==========================================
                Text(
                  "Chill Travel",
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 1.2,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOut),

                const SizedBox(height: 12),

                // ==========================================
                // 3. SLOGAN (Xuất hiện nối tiếp Tên App)
                // ==========================================
                const Text(
                  "Chia bill đều,\n sẽ có chill travel!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 600.ms)
                    .slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOut),

                const SizedBox(height: 60),

                // ==========================================
                // 4. KHU VỰC NÚT BẤM (Xuất hiện cuối cùng)
                // ==========================================
                Obx(() {
                  final isLoading = authController.isLoading.value;
                  return Column(
                    children: [
                      // NÚT BẮT ĐẦU ẨN DANH
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: isLoading ? null : () => authController.loginAnonymous(),
                          child: isLoading
                              ? const Text("ĐANG XỬ LÝ...", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white70))
                              : const Text(
                              "DÙNG ẨN DANH NGAY",
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // DÒNG KẺ "HOẶC" CHIA CẮT
                      Row(
                        children: [
                          const Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text("hoặc", style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                          ),
                          const Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // NÚT ĐĂNG NHẬP GOOGLE
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: isLoading ? null : () => authController.loginWithGoogle(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/google_logo.png',
                                width: 40,
                                height: 40,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, color: Colors.blue, size: 32),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                  "Đăng nhập với Google",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                })
                    .animate() // Hiệu ứng cho toàn bộ khối nút bấm
                    .fadeIn(delay: 800.ms, duration: 600.ms)
                    .slideY(begin: 0.1, end: 0, duration: 600.ms, curve: Curves.easeOut),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
