import 'package:chiabill/theme/app_colors.dart';
import 'package:chiabill/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/empty_state.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../utils/toast_util.dart';
import '../../utils/trip_category_util.dart';
import '../../data/repositories/trip_repository.dart';
import '../trip/edit_trip_dialog.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../controllers/join_trip_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController controller = Get.find<HomeController>();
  final NotificationController notifController = Get.find<NotificationController>();
  final ProfileController profileController = Get.find<ProfileController>();

  bool isSearching = false;
  final TextEditingController searchController = TextEditingController();

  late ScrollController _monthScrollController;
  late ScrollController _yearScrollController;

  @override
  void initState() {
    super.initState();
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
              Image.asset(
                'assets/images/logo_home.png',
                height: 48,
                width: 48,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Column(
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
                  Text(
                    "Cùng đi, cùng chia sẻ!",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showJoinTripDialog(context),
            icon: Image.asset(
              'assets/images/join_trip.gif',
              width: 30,
              height: 30,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.group_add, size: 26, color: AppColors.primary),
            ),
          ),
          IconButton(
            onPressed: () => Get.toNamed(Routes.CALCULATOR),
            icon: Image.asset(
              'assets/images/calculator.png',
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.calculate_outlined, size: 28, color: AppColors.primary),
            ),
          ),
          IconButton(
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
              onRefresh: () => controller.fetchTrips(isRefresh: true),
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
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: controller.trips.length + (controller.isTripLastPage.value ? 0 : 1),
                    itemBuilder: (context, index) {
                      if (index == controller.trips.length) {
                        return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)));
                      }
                      return _buildTripCard(context, controller.trips[index]);
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
                decoration: InputDecoration(
                  hintText: "Tìm chuyến đi...",
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
          )
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

  Widget _buildTripCard(BuildContext context, dynamic trip) {
    String dateStr = trip.createdAt ?? "";
    if (dateStr.length >= 10) {
      final parts = dateStr.substring(0, 10).split('-');
      if (parts.length == 3) {
        dateStr = "${parts[2]}/${parts[1]}/${parts[0]}";
      }
    }

    Color categoryColor = TripCategoryUtil.getColor(trip.categoryIcon);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (trip.id == -1) {
            ToastUtil.showWarning("Đang chờ đồng bộ", "Chuyến đi này chưa được đồng bộ lên máy chủ");
            return;
          }
          Get.toNamed(Routes.TRIP_DETAIL, arguments: trip.id);
        },
        onLongPress: () => trip.id == -1 ? null : _showTripOptions(context, trip),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(color: categoryColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                  child: Icon(TripCategoryUtil.getIconData(trip.categoryIcon), color: categoryColor, size: 28)
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (trip.id == -1) ...[
                          const Icon(Icons.schedule, color: Colors.orange, size: 16),
                          const SizedBox(width: 4),
                        ],
                        Expanded(child: Text(trip.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(trip.description ?? "Không có mô tả", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                   _buildMemberAvatars(trip),
                   const SizedBox(height: 8),
                   Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberAvatars(dynamic trip) {
    if (trip.members == null || (trip.members as List).isEmpty) {
      return Text("${trip.memberCount ?? 0} TV", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold));
    }

    final members = trip.members as List;
    final int displayCount = members.length > 3 ? 3 : members.length;
    final int extraCount = (trip.memberCount ?? members.length) - displayCount;

    return SizedBox(
      height: 28,
      width: (displayCount * 14.0) + (extraCount > 0 ? 24.0 : 0) + 14.0, // Fixed width to align right properly
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerRight,
        children: [
          for (int i = 0; i < displayCount; i++)
            Positioned(
              right: i * 14.0 + (extraCount > 0 ? 20.0 : 0),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  radius: 12,
                  backgroundImage: members[displayCount - 1 - i].avatarUrl != null 
                      ? NetworkImage(members[displayCount - 1 - i].avatarUrl!) 
                      : null,
                  backgroundColor: Colors.grey.shade300,
                  child: members[displayCount - 1 - i].avatarUrl == null 
                      ? Text(members[displayCount - 1 - i].name?.substring(0, 1).toUpperCase() ?? "?", style: const TextStyle(fontSize: 10, color: Colors.black))
                      : null,
                ),
              ),
            ),
          if (extraCount > 0)
            Positioned(
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  color: AppColors.primaryBackgroundLight,
                ),
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primaryBackgroundLight,
                  child: Text("+$extraCount", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showTripOptions(BuildContext context, dynamic trip) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(top: 16, left: 0, right: 0, bottom: 16 + MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(trip.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ListTile(
              leading: Icon(Icons.edit, color: Colors.blue),
              title: const Text("Sửa thông tin"),
              onTap: () {
                Get.back();
                Get.dialog(EditTripDialog(trip: trip, isFromHome: true));
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: const Text("Xóa chuyến đi", style: TextStyle(color: Colors.red)),
              onTap: () {
                Get.back();
                _confirmDeleteTrip(trip);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteTrip(dynamic trip) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Xóa chuyến đi?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20), textAlign: TextAlign.center),
        content: const Text("Chuyến đi này sẽ bị xóa. Bạn vẫn có thể phục hồi lại trong Thùng rác.", textAlign: TextAlign.center, style: TextStyle(fontSize: 15)),
        actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red, 
              side: BorderSide(color: Colors.red),
              minimumSize: const Size(100, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))
            ),
            onPressed: () => Get.back(),
            child: const Text("HỦY", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, 
              foregroundColor: Colors.white,
              minimumSize: const Size(100, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))
            ),
            onPressed: () async {
              Get.back();
              final result = await TripRepository().deleteTrip(trip.id!);
              if (result.success) {
                ToastUtil.showSuccess("Thành công", "Đã xóa chuyến đi");
                controller.fetchTrips(isRefresh: true);
              } else {
                ToastUtil.showError("Lỗi", result.message ?? "Không thể xóa chuyến đi");
              }
            },
            child: const Text("XÓA", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }


  void _showJoinTripDialog(BuildContext context) {
    final JoinTripController joinController = Get.put(JoinTripController());
    joinController.codeController.clear();
    joinController.inviteInfo.value = null;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Obx(() {
          if (joinController.inviteInfo.value == null) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/join_trip.gif',
                  height: 100,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.group_add, size: 60, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                const Text("Tham gia nhóm", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("Nhập mã mời hoặc quét mã QR do bạn bè chia sẻ để tham gia.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 24),

                TextField(
                  controller: joinController.codeController,
                  decoration: InputDecoration(
                    labelText: "Mã mời (VD: abcd-1234)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(Icons.keyboard),
                  ),
                ),
                const SizedBox(height: 16),

                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary
                  ),
                  icon: Icon(Icons.qr_code_scanner),
                  label: const Text("Quét mã QR"),
                  onPressed: () {
                    Get.to(() => Scaffold(
                      appBar: AppBar(title: const Text("Quét mã QR", style: TextStyle(fontWeight: FontWeight.bold))),
                      body: MobileScanner(
                        onDetect: (capture) {
                          final List<Barcode> barcodes = capture.barcodes;
                          for (final barcode in barcodes) {
                            if (barcode.rawValue != null) {
                              Get.back();
                              joinController.codeController.text = barcode.rawValue!;
                              joinController.checkInviteCode();
                              break;
                            }
                          }
                        },
                      ),
                    ));
                  },
                ),
              ],
            );
          } else {
            final info = joinController.inviteInfo.value!;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: Text("🎉 Tìm thấy chuyến đi!", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16))),
                const Divider(height: 24),
                Text("Tên chuyến: ${info.tripName}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Text("Người tạo: ${info.createdByName}", style: TextStyle(color: Colors.grey[700])),
                Text("Thành viên hiện tại: ${info.memberCount} người", style: TextStyle(color: Colors.grey[700])),
              ],
            );
          }
        }),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              Get.delete<JoinTripController>();
            },
            child: const Text("HỦY", style: TextStyle(color: Colors.grey)),
          ),
          Obx(() {
            if (joinController.inviteInfo.value == null) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                onPressed: joinController.isLoading.value ? null : () => joinController.checkInviteCode(),
                child: joinController.isLoading.value
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("KIỂM TRA"),
              );
            } else {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                onPressed: joinController.isLoading.value ? null : () => joinController.confirmJoin(),
                child: joinController.isLoading.value
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("XÁC NHẬN"),
              );
            }
          }),
        ],
      ),
    ).then((_) {
      Get.delete<JoinTripController>();
    });
  }

  // Hàm _getIconData đã được chuyển vào TripCategoryUtil
}