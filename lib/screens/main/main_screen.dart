import 'package:chiabill/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/main_controller.dart';
import '../../controllers/theme_controller.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../stats/overall_stats_screen.dart';
import '../tourism/tourism_map_screen.dart';
import '../trip/create_trip_bottom_sheet.dart';
import '../../controllers/user_guide_controller.dart';
import '../../widgets/user_guide_overlay.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final MainController controller = Get.find<MainController>();
  late PageController _pageController;
  late Worker _tabWorker;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: controller.currentIndex.value);
    
    // Đồng bộ từ Controller sang PageView (khi người dùng click tab bar)
    _tabWorker = ever(controller.currentIndex, (int index) {
      if (mounted && _pageController.hasClients && _pageController.page?.round() != index) {
        final int currentPage = _pageController.page?.round() ?? controller.currentIndex.value;
        if ((index - currentPage).abs() == 1) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          _pageController.jumpToPage(index);
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _checkAndShowGuides();
        }
      });
    });
  }

  void _checkAndShowGuides() {
    final userGuideController = Get.find<UserGuideController>();
    if (userGuideController.isFirstRun.value) {
      _showWelcomeDialog(userGuideController);
    } else if (userGuideController.guideHomeEnabled.value) {
      _startHomeGuide(userGuideController);
    }
  }

  void _showWelcomeDialog(UserGuideController userGuideController) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.rocket_launch, color: AppColors.primary, size: 48),
              ),
              const SizedBox(height: 20),
              const Text(
                "Chào mừng tới DuliVie! 🚀",
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "Để giúp bạn làm quen nhanh với ứng dụng chia tiền nhóm và lên lịch trình du lịch, chúng tôi đã chuẩn bị sẵn một tour hướng dẫn nhanh.",
                style: TextStyle(fontSize: 13.5, color: Colors.black87, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        foregroundColor: Colors.black87,
                      ),
                      onPressed: () {
                        userGuideController.disableFirstRun();
                        userGuideController.setGuideEnabled('home', false);
                        userGuideController.setGuideEnabled('trip_detail', false);
                        userGuideController.setGuideEnabled('tourism', false);
                        Get.back();
                      },
                      child: const Text("Để sau", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      onPressed: () {
                        userGuideController.disableFirstRun();
                        Get.back();
                        _startHomeGuide(userGuideController);
                      },
                      child: const Text("Khám phá ngay", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _startHomeGuide(UserGuideController userGuideController) {
    if (controller.currentIndex.value != 0) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        
        final targets = [
          GuideTarget(
            key: userGuideController.fabTripKey,
            title: "Thêm chuyến đi mới",
            description: "Nhấp vào đây để tạo hành trình du lịch mới, thêm thành viên và quản lý các hóa đơn chi tiêu chung.",
            isCircle: true,
          ),
          GuideTarget(
            key: userGuideController.joinTripKey,
            title: "Tham gia bằng mã/link",
            description: "Nhập nhóm cực nhanh bằng cách quét mã QR hoặc nhập mã mời tham gia chuyến đi từ bạn bè.",
            isCircle: true,
          ),
          GuideTarget(
            key: userGuideController.calculatorKey,
            title: "Máy tính nhanh",
            description: "Mở máy tính mini để tính toán nhẩm các khoản tiền nhanh chóng mà không cần thoát ứng dụng.",
            isCircle: true,
          ),
          GuideTarget(
            key: userGuideController.bellKey,
            title: "Hộp thư thông báo",
            description: "Nơi cập nhật lịch sử hoạt động, các yêu cầu thanh toán hoặc tin nhắc nhở từ các thành viên trong nhóm.",
            isCircle: true,
          ),
        ];

        UserGuideOverlay.show(
          context,
          targets: targets,
          onCompleted: () {
            userGuideController.setGuideEnabled('home', false);
          },
          onDismissed: () {
            userGuideController.setGuideEnabled('home', false);
          },
        );
      });
    });
  }

  @override
  void dispose() {
    _tabWorker.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra xem bàn phím có đang mở không
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Obx(() {
        return PageView(
          controller: _pageController,
          physics: controller.currentIndex.value == 2
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
          onPageChanged: (index) {
            controller.changeTabIndex(index);
          },
          children: [
            const HomeScreen(),
            const OverallStatsScreen(),
            const TourismMapScreen(),
            const ProfileScreen(),
          ],
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: AnimatedScale(
        scale: isKeyboardOpen ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Obx(() {
          // Lắng nghe sự thay đổi của Theme
          Get.find<ThemeController>().currentTheme.value;
          return FloatingActionButton(
            key: Get.find<UserGuideController>().fabTripKey,
            onPressed: isKeyboardOpen ? null : () {
              if (Get.isBottomSheetOpen == true) return;
              Get.bottomSheet(CreateTripBottomSheet(), isScrollControlled: true);
            },
            backgroundColor: AppColors.primary,
            shape: const CircleBorder(),
            elevation: isKeyboardOpen ? 0 : 4,
            child: const Icon(Icons.add, color: Colors.white, size: 32),
          );
        }),
      ),
      bottomNavigationBar: isKeyboardOpen
          ? null
          : BottomAppBar(
              color: Colors.white,
              elevation: 10,
              notchMargin: 8,
              shape: const CircularNotchedRectangle(),
              child: SizedBox(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(0, Icons.home_outlined, Icons.home, "Chuyến đi"),
                    _buildNavItem(1, Icons.pie_chart_outline, Icons.pie_chart, "Thống kê"),
                    const SizedBox(width: 48), // Khoảng trống cho FAB
                    _buildNavItem(2, Icons.map_outlined, Icons.map, "Du lịch"),
                    _buildNavItem(3, Icons.person_outline, Icons.person, "Cá nhân"),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    return Obx(() {
      bool isSelected = controller.currentIndex.value == index;
      Color color = isSelected ? AppColors.primary : Colors.grey;

      return MaterialButton(
        minWidth: 36,
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onPressed: () => controller.changeTabIndex(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    });
  }
}