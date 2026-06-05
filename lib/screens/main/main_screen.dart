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
      floatingActionButton: isKeyboardOpen
          ? null
          : Obx(() {
              // Lắng nghe sự thay đổi của Theme
              Get.find<ThemeController>().currentTheme.value;
              return FloatingActionButton(
                onPressed: () => Get.bottomSheet(CreateTripBottomSheet(), isScrollControlled: true),
                backgroundColor: AppColors.primary,
                shape: const CircleBorder(),
                elevation: 4,
                child: const Icon(Icons.add, color: Colors.white, size: 32),
              );
            }),
      bottomNavigationBar: isKeyboardOpen
          ? null
          : BottomAppBar(
              color: Colors.white,
              elevation: 10,
              notchMargin: 8,
              shape: const CircularNotchedRectangle(),
              child: SizedBox(
                height: 60,
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
        minWidth: 40,
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
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    });
  }
}
