import 'package:chiabill/theme/app_colors.dart';
import 'package:chiabill/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/quote_banner.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/overall_stats_controller.dart';
import 'widgets/debt_banner.dart';
import 'widgets/join_trip_dialog.dart';
import 'widgets/trip_card.dart';
import 'widgets/trip_gallery_card.dart';
import '../../controllers/user_guide_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final HomeController controller = Get.find<HomeController>();
  final NotificationController notifController = Get.find<NotificationController>();
  final ProfileController profileController = Get.find<ProfileController>();
  final OverallStatsController statsController = Get.find<OverallStatsController>();

  bool isSearching = false;
  final TextEditingController searchController = TextEditingController();

  late ScrollController _monthScrollController;
  late ScrollController _yearScrollController;

  @override
  void initState() {
    super.initState();
    statsController.fetchSummary();

    _monthScrollController = ScrollController();
    _yearScrollController = ScrollController();
    
    // Cuộn sau khi build xong nếu đang ở mode đó
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrent(jump: true);
    });
  }

  void _scrollToCurrent({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      double screenWidth = Get.width;
      double itemWidth = 100.0;
      
      if (controller.filterMode.value == 'Tháng' && _monthScrollController.hasClients) {
        int monthIndex = controller.selectedMonth.value - 1;
        if (monthIndex < 0) monthIndex = 0;
        double offset = (monthIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
        if (offset < 0) offset = 0;
        if (offset > _monthScrollController.position.maxScrollExtent) {
          offset = _monthScrollController.position.maxScrollExtent;
        }
        if (jump) {
          _monthScrollController.jumpTo(offset);
        } else {
          _monthScrollController.animateTo(offset, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        }
      } else if (controller.filterMode.value == 'Năm' && _yearScrollController.hasClients) {
        int yearIndex = controller.selectedYear.value - 1950;
        if (yearIndex < 0) yearIndex = 0;
        double offset = (yearIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
        if (offset < 0) offset = 0;
        if (offset > _yearScrollController.position.maxScrollExtent) {
          offset = _yearScrollController.position.maxScrollExtent;
        }
        if (jump) {
          _yearScrollController.jumpTo(offset);
        } else {
          _yearScrollController.animateTo(offset, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        }
      }
    });
  }

  @override
  void dispose() {
    _monthScrollController.dispose();
    _yearScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Obx(() {
          String fullName = profileController.user.value?.name ?? "bạn";
          if (fullName.trim().isEmpty) fullName = "bạn";
          List<String> nameParts = fullName.trim().split(" ");
          String shortName = nameParts.isNotEmpty ? nameParts.last : "bạn";
          return Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: ClipOval(
                  child: profileController.user.value?.avatarUrl != null
                      ? Image.network(
                          profileController.user.value!.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholderAvatar(shortName),
                        )
                      : _buildPlaceholderAvatar(shortName),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Chào $shortName",
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const QuoteMarquee(),
                  ],
                ),
              ),
            ],
          );
        }),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            key: Get.find<UserGuideController>().joinTripKey,
            onPressed: () => JoinTripDialog.show(context),
            icon: Image.asset(
              'assets/images/join_trip.gif',
              width: 30,
              height: 30,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.group_add, size: 26, color: AppColors.primary),
            ),
          ),
          IconButton(
            key: Get.find<UserGuideController>().calculatorKey,
            onPressed: () => Get.toNamed(Routes.CALCULATOR),
            icon: Image.asset(
              'assets/images/calculator.png',
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.calculate_outlined, size: 28, color: AppColors.primary),
            ),
          ),
          IconButton(
            key: Get.find<UserGuideController>().bellKey,
            icon: Obx(() => Badge(
              isLabelVisible: notifController.unreadCount.value > 0,
              label: Text(notifController.unreadCount.value.toString()),
              backgroundColor: Colors.redAccent,
              child: Image.asset(
                'assets/images/bell.png',
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.notifications_none, size: 26, color: AppColors.primaryDark),
              ),
            )),
            onPressed: () => Get.toNamed(Routes.NOTIFICATION),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const DebtBanner(),
          _buildSearchAndFilter(),
          Obx(() {
            if (controller.filterMode.value == 'Tháng') {
               return _buildMonthHeader();
            } else if (controller.filterMode.value == 'Năm') {
               return _buildYearHeader();
            }
            return const SizedBox.shrink(); // 'Tất cả' doesn't show any pill list
          }),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  controller.fetchTrips(isRefresh: true),
                  statsController.fetchSummary(),
                ]);
              },
              color: AppColors.primary,
              child: Obx(() {
                if (controller.isLoading.value && controller.trips.isEmpty) {
                  return Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (controller.trips.isEmpty) {
                  return _buildEmptyState();
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (!controller.isLoadingMoreTrips.value && scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                      controller.fetchTrips(isRefresh: false);
                    }
                    return false;
                  },
                  child: controller.isGridView.value
                      ? GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: controller.trips.length + (controller.isTripLastPage.value ? 0 : 1),
                          itemBuilder: (context, index) {
                            if (index == controller.trips.length) {
                              return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)));
                            }
                            return TripGalleryCard(trip: controller.trips[index]);
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: controller.trips.length + (controller.isTripLastPage.value ? 0 : 1),
                          itemBuilder: (context, index) {
                            if (index == controller.trips.length) {
                              return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)));
                            }
                            return TripCard(trip: controller.trips[index]);
                          },
                        ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: searchController,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: "Tìm chuyến đi...",
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 12, right: 8),
                    child: Icon(Icons.search, color: Colors.grey, size: 20),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 24,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (val) {
                   if (val.isNotEmpty && controller.filterMode.value != 'Tất cả') {
                      controller.filterMode.value = 'Tất cả';
                      controller.fetchTrips(isRefresh: true);
                   } else {
                      controller.onSearchTrips(val);
                   }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Obx(() => DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: controller.filterMode.value,
                borderRadius: BorderRadius.circular(16),
                dropdownColor: Colors.white,
                icon: Icon(Icons.keyboard_arrow_down, color: AppColors.primary, size: 20),
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                items: ['Tất cả', 'Tháng', 'Năm'].map((String mode) {
                  return DropdownMenuItem<String>(
                    value: mode,
                    child: Text(mode),
                  );
                }).toList(),
                onChanged: (String? newMode) {
                  if (newMode != null) {
                    controller.onFilterModeChanged(newMode);
                    _scrollToCurrent(jump: true);
                  }
                },
              ),
            )),
          ),
          const SizedBox(width: 12),
          Obx(() => GestureDetector(
            onTap: () => controller.toggleViewMode(),
            child: Container(
              width: 64,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: controller.isGridView.value ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        controller.isGridView.value ? Icons.grid_view_rounded : Icons.view_list_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ))
        ],
      ),
    );
  }

  Widget _buildYearHeader() {
    int currentYear = DateTime.now().year;
    int maxYear = currentYear + 10;
    int itemCount = maxYear - 1950 + 1;

    return Container(
      height: 45,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView.builder(
        controller: _yearScrollController,
        scrollDirection: Axis.horizontal,
        itemExtent: 100.0,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          int year = 1950 + index;
          return Obx(() {
            bool isSelected = controller.selectedYear.value == year;
            return GestureDetector(
              onTap: () {
                controller.onDateChanged(controller.selectedMonth.value, year);
                _scrollToCurrent();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    "Năm $year",
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13
                    ),
                  ),
                ),
              ));
          });
        },
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Container(
      height: 45,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView.builder(
        controller: _monthScrollController,
        scrollDirection: Axis.horizontal,
        itemExtent: 100.0,
        itemCount: 13, // 12 tháng + 1 icon lịch
        itemBuilder: (context, index) {
          if (index == 12) {
            // Nút Lịch đổi sang dạng pill capsule
            return GestureDetector(
              onTap: () => _showYearPicker(context),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBackgroundLight,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: AppColors.primaryLighter),
                ),
                child: Center(
                  child: FittedBox(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_month_outlined, color: AppColors.primaryDark, size: 18),
                        const SizedBox(width: 4),
                        Text("Đổi năm", style: TextStyle(color: AppColors.primaryDark, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          int month = index + 1; // 1-12
          return Obx(() {
            bool isSelected = controller.selectedMonth.value == month;
            return GestureDetector(
              onTap: () {
                controller.onDateChanged(month, controller.selectedYear.value);
                _scrollToCurrent();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    "Tháng $month",
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.primaryDark,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13
                    ),
                  ),
                ),
              ));
          });
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: Get.height * 0.15),
        const EmptyState(text: "Chưa có chuyến đi nào trong khoảng thời gian này.\nHãy nhấn (+) để tạo chuyến đi đầu tiên!"),
      ],
    );
  }

  void _showYearPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Chọn năm"),
          content: SizedBox(
            width: 300,
            height: 300,
            child: Obx(() => YearPicker(
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
              selectedDate: DateTime(controller.selectedYear.value),
              onChanged: (DateTime dateTime) {
                controller.onDateChanged(controller.selectedMonth.value, dateTime.year);
                Navigator.pop(context);
              },
            )),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderAvatar(String shortName) {
    String initial = shortName.isNotEmpty ? shortName[0].toUpperCase() : "U";
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}