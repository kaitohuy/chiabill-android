import 'package:chiabill/theme/app_colors.dart';
import 'package:chiabill/screens/trip/tabs/expense_tab.dart';
import 'package:chiabill/screens/trip/tabs/member_tabs.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/add_expense_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/trip_detail_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../controllers/trip_expense_controller.dart';
import '../../controllers/itinerary_controller.dart';
import 'add_expense_bottom_sheet.dart';
import 'history_screen.dart';
import 'itinerary_screen.dart';
import 'tabs/group_fund_tab.dart';
import 'tabs/settlements_tab.dart';
import '../../controllers/user_guide_controller.dart';
import '../../widgets/user_guide_overlay.dart';
import 'widgets/export_report_sheet.dart';
import 'widgets/add_member_options_sheet.dart';
import 'widgets/create_invite_dialog.dart';

class TripDetailScreen extends StatefulWidget {
  final int tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  late TripDetailController controller;
  late PageController _pageController;
  late Worker _tabWorker;

  bool _guideChecked = false;

  @override
  void initState() {
    super.initState();
    Get.put(ProfileController(), permanent: true);
    Get.delete<TripDetailController>(tag: widget.tripId.toString(), force: true);
    controller = Get.put(TripDetailController(widget.tripId), tag: widget.tripId.toString());

    _pageController = PageController(initialPage: controller.currentTab.value);

    // Đồng bộ từ Controller sang PageView (khi người dùng click tab bar)
    _tabWorker = ever(controller.currentTab, (int index) {
      if (mounted && _pageController.hasClients && _pageController.page?.round() != index) {
        final int currentPage = _pageController.page?.round() ?? controller.currentTab.value;
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

    // Check guide when data completes loading
    ever(controller.isLoading, (bool isLoading) {
      if (!isLoading && controller.trip.value != null) {
        _checkAndShowTripDetailGuide();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.isLoading.value && controller.trip.value != null) {
        _checkAndShowTripDetailGuide();
      }
    });
  }

  void _checkAndShowTripDetailGuide() {
    if (_guideChecked || !mounted) return;
    final userGuideController = Get.find<UserGuideController>();
    if (userGuideController.guideTripDetailEnabled.value) {
      _guideChecked = true;
      _startTripDetailGuide(userGuideController);
    }
  }

  void _startTripDetailGuide(UserGuideController userGuideController) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;

        final targets = [
          GuideTarget(
            key: userGuideController.shareTripKey,
            title: "Chia sẻ chuyến đi",
            description: "Nhấn vào đây để xem mã mời và chia sẻ link tham gia chuyến đi này tới bạn bè.",
            isCircle: true,
          ),
          GuideTarget(
            key: userGuideController.itineraryBtnKey,
            title: "Lên lịch trình chi tiết",
            description: "Lên kế hoạch vui chơi, danh sách địa điểm theo từng ngày cực kỳ tiện lợi.",
            isCircle: true,
          ),
          GuideTarget(
            key: userGuideController.bottomTabExpenseKey,
            title: "Danh sách chi tiêu",
            description: "Xem tổng hợp tất cả hóa đơn của cả nhóm. Bạn có thể nhấn để xem chi tiết hoặc vuốt để sửa/xóa.",
            isCircle: true,
          ),
          GuideTarget(
            key: userGuideController.bottomTabFundKey,
            title: "Quỹ chung chuyến đi",
            description: "Quản lý tiền cọc, tiền quỹ thu thêm và các khoản đóng góp chung của các thành viên.",
            isCircle: true,
          ),
          GuideTarget(
            key: userGuideController.bottomTabSettlementKey,
            title: "Quyết toán nợ nần",
            description: "Hiển thị chi tiết số tiền mỗi người cần trả hoặc nhận lại, hỗ trợ tính toán bù trừ tự động tối ưu nhất.",
            isCircle: true,
          ),
          GuideTarget(
            key: userGuideController.bottomTabMembersKey,
            title: "Thành viên nhóm",
            description: "Danh sách những người tham gia chuyến đi. Bạn có thể thêm thành viên ảo (ghost) hoặc mời bạn bè.",
            isCircle: true,
          ),
          GuideTarget(
            key: userGuideController.addExpenseKey,
            title: "Thêm chi tiêu mới",
            description: "Nhấp vào nút dấu cộng này để tạo hóa đơn chi tiêu, chọn người trả và chia đều cho cả nhóm.",
            isCircle: true,
          ),
        ];

        UserGuideOverlay.show(
          context,
          targets: targets,
          onStepChanged: (stepIndex) {
            if (stepIndex == 2) {
              controller.currentTab.value = 0;
            } else if (stepIndex == 3) {
              controller.currentTab.value = 1;
            } else if (stepIndex == 4) {
              controller.currentTab.value = 2;
            } else if (stepIndex == 5) {
              controller.currentTab.value = 3;
            } else if (stepIndex == 6) {
              controller.currentTab.value = 0;
            }
          },
          onCompleted: () {
            userGuideController.setGuideEnabled('trip_detail', false);
          },
          onDismissed: () {
            userGuideController.setGuideEnabled('trip_detail', false);
          },
        );
      });
    });
  }

  @override
  void dispose() {
    _tabWorker.dispose();
    _pageController.dispose();
    Get.delete<TripDetailController>(tag: widget.tripId.toString(), force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Obx(() => Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            controller.trip.value?.name ?? "Chi tiết",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
          ),
        )),
        actions: [
          IconButton(
            key: Get.find<UserGuideController>().shareTripKey,
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () => Get.dialog(CreateInviteDialog(controller: controller)),
          ),
          IconButton(
            key: Get.find<UserGuideController>().itineraryBtnKey,
            icon: const Icon(Icons.explore_outlined, color: Colors.white),
            onPressed: () => Get.to(() => ItineraryScreen(tripId: controller.tripId)),
          ),
          IconButton(
            key: Get.find<UserGuideController>().historyBtnKey,
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () => Get.to(() => HistoryScreen(mainController: controller)),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Colors.white),
            onPressed: () => Get.bottomSheet(
              ExportReportSheet(controller: controller),
              isScrollControlled: true,
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.trip.value == null) {
          return Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final itineraryCtrl = Get.find<ItineraryController>(
          tag: controller.tripId.toString(),
        );

        return Column(
          children: [
            Obx(() {
              if (controller.isCurrentUserDisabled) {
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade600, Colors.red.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Bạn đang bị tạm ngưng hoạt động!",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Bạn chỉ có quyền xem chi tiết chuyến đi này, không thể thêm mới chi tiêu hay chia tiền.",
                              style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(230)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            Obx(() {
              if (itineraryCtrl.hasLoadedOnce.value && itineraryCtrl.itineraryList.isEmpty && !itineraryCtrl.isBannerDismissed.value) {
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.orange.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => Get.to(() => ItineraryScreen(tripId: controller.tripId)),
                          child: Row(
                            children: [
                              const Icon(Icons.explore, color: Colors.white, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      "Lên lịch trình du lịch ngay!",
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Quản lý lịch trình, import/export Excel lịch trình.",
                                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          itineraryCtrl.isBannerDismissed.value = true;
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  controller.currentTab.value = index;
                },
                children: [
                  ExpensesTab(mainController: controller),
                  GroupFundTab(mainController: controller),
                  SettlementsTab(mainController: controller),
                  MembersTab(
                    controller: controller,
                    onAddMemberTap: () => Get.bottomSheet(
                      AddMemberOptionsSheet(controller: controller),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: AnimatedScale(
        scale: isKeyboardOpen ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Obx(() {
          Get.find<ThemeController>().currentTheme.value;
          return FloatingActionButton(
            key: Get.find<UserGuideController>().addExpenseKey,
            onPressed: isKeyboardOpen ? null : _handleFabPress,
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
                height: 40, // Đồng bộ với MainScreen
                child: Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBottomTab(0, Icons.list_alt_outlined, Icons.list_alt, "Chi tiêu"),
                    _buildBottomTab(1, Icons.analytics_outlined, Icons.analytics, "Thống kê"),
                    const SizedBox(width: 48), // Khoảng trống cho FAB
                    _buildBottomTab(2, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, "Nợ nần"),
                    _buildBottomTab(3, Icons.people_outline, Icons.people, "Thành viên"),
                  ],
                )),
              ),
            ),
    );
  }

  Widget _buildBottomTab(int index, IconData icon, IconData activeIcon, String label) {
    bool isSelected = controller.currentTab.value == index;
    Color color = isSelected ? AppColors.primary : Colors.grey[600]!;
    
    final userGuideController = Get.find<UserGuideController>();
    Key? tabKey;
    if (index == 0) tabKey = userGuideController.bottomTabExpenseKey;
    if (index == 1) tabKey = userGuideController.bottomTabFundKey;
    if (index == 2) tabKey = userGuideController.bottomTabSettlementKey;
    if (index == 3) tabKey = userGuideController.bottomTabMembersKey;

    return MaterialButton(
      key: tabKey,
      minWidth: 36,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onPressed: () => controller.currentTab.value = index,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isSelected ? activeIcon : icon, color: color, size: 24),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  void _handleFabPress() {
    if (controller.trip.value == null) return;
    if (Get.isBottomSheetOpen == true || Get.isDialogOpen == true) return;
    
    if (controller.isCurrentUserDisabled) {
      Get.snackbar(
        "Thông báo",
        "Bạn đã bị tạm ngưng hoạt động trong chuyến đi này, không thể thực hiện thao tác này.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Nếu ở tab thành viên thì hiện menu thêm TV, còn lại là thêm chi phí
    if (controller.currentTab.value == 3) {
      Get.bottomSheet(AddMemberOptionsSheet(controller: controller));
    } else {
      const tag = 'add';
      // Khởi tạo controller ở đây
      final addController = Get.put(
          AddExpenseController(controller.trip.value!, initialDate: Get.find<TripExpenseController>(tag: controller.tripId.toString()).selectedExpenseDate.value),
          tag: tag
      );

      Get.bottomSheet(
        AddExpenseBottomSheet(
          trip: controller.trip.value!,
          initialDate: Get.find<TripExpenseController>(tag: controller.tripId.toString()).selectedExpenseDate.value,
          controller: addController,
        ), 
        isScrollControlled: true
      );
    }
  }

}