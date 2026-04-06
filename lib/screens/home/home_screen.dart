import 'package:chiabill/screens/profile/profile_screen.dart';
import 'package:chiabill/screens/trip/create_trip_bottom_sheet.dart';
import 'package:chiabill/screens/trip/trip_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/join_trip_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../data/repositories/trip_repository.dart';
import '../notification/notification_screen.dart';
import '../trip/edit_trip_dialog.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final HomeController controller = Get.put(HomeController());
  final NotificationController notifController = Get.put(NotificationController(), permanent: true);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Nền hơi xám nhạt để nổi bật Card
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.lightGreen[800],
        elevation: 0,
        // Chuyển title sang góc trái và chia làm 2 dòng
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Chào Huy 👋", style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.normal)),
            const Text("Chuyến đi của bạn", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          // 1. NÚT THAM GIA NHÓM
          IconButton(
            icon: const Icon(Icons.group_add, size: 26),
            onPressed: () => _showJoinTripDialog(context),
          ),

          // 2. NÚT THÔNG BÁO (Chuông có chấm đỏ)
          IconButton(
            icon: Obx(() {
              return Badge(
                isLabelVisible: notifController.unreadCount.value > 0, // Ẩn chấm đỏ nếu = 0
                label: Text(notifController.unreadCount.value.toString()),
                backgroundColor: Colors.redAccent,
                child: const Icon(Icons.notifications_none, size: 26),
              );
            }),
            onPressed: () {
              Get.to(() => NotificationScreen());
            },
          ),

          // 3. NÚT PROFILE
          IconButton(
            icon: const Icon(Icons.account_circle, size: 28),
            onPressed: () => Get.to(() => ProfileScreen()),
          ),
          const SizedBox(width: 8), // Đệm một chút cho khỏi sát lề màn hình
        ],
      ),
      // BỌC TRONG COLUMN ĐỂ CHỨA THANH SEARCH VÀ LIST
      body: Column(
        children: [
          // ==========================================
          // 1. THANH TÌM KIẾM CHUYẾN ĐI
          // ==========================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: TextField(
              onChanged: (value) => controller.onSearchTrips(value),
              decoration: InputDecoration(
                hintText: "Tìm theo tên chuyến đi...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),

          // ==========================================
          // 2. DANH SÁCH CHUYẾN ĐI (PHÂN TRANG)
          // ==========================================
          Expanded(
            child: Obx(() {
              // Trạng thái 1: Đang load lần đầu
              if (controller.isLoading.value && controller.trips.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: Colors.lightGreen));
              }

              // Trạng thái 2: Trống
              if (controller.trips.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flight_takeoff, size: 80, color: Colors.lightGreen.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text("Không tìm thấy chuyến đi nào.\nHãy tạo ngay để bắt đầu chia bill nhé!",
                          textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              // Trạng thái 3: Có dữ liệu (Cuộn vô tận)
              return RefreshIndicator(
                color: Colors.lightGreen,
                onRefresh: () async => controller.fetchTrips(isRefresh: true),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (!controller.isLoadingMoreTrips.value && scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                      controller.fetchTrips(isRefresh: false);
                    }
                    return false;
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.trips.length + (controller.isTripLastPage.value ? 0 : 1),
                    itemBuilder: (context, index) {
                      // Vòng tròn Loading ở đáy
                      if (index == controller.trips.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(child: CircularProgressIndicator(color: Colors.lightGreen)),
                        );
                      }

                      final trip = controller.trips[index];

                      // Xử lý format ngày tạo (cắt lấy phần YYYY-MM-DD)
                      String dateStr = trip.createdAt ?? "";
                      if (dateStr.length >= 10) {
                        dateStr = dateStr.substring(0, 10);
                        // Tùy chọn format lại thành DD/MM/YYYY cho thân thiện hơn
                        final parts = dateStr.split('-');
                        if (parts.length == 3) {
                          dateStr = "${parts[2]}/${parts[1]}/${parts[0]}";
                        }
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        // Dùng InkWell để hiệu ứng ripple (sóng nhấp) đẹp hơn khi bấm
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Get.to(() => TripDetailScreen(tripId: trip.id!)),
                          onLongPress: () {
                            Get.bottomSheet(
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(trip.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const Divider(),
                                    ListTile(
                                      leading: const Icon(Icons.edit, color: Colors.blue),
                                      title: const Text("Sửa thông tin"),
                                      onTap: () {
                                        Get.back();
                                        Get.dialog(EditTripDialog(trip: trip, isFromHome: true));
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.delete, color: Colors.red),
                                      title: const Text("Xóa chuyến đi", style: TextStyle(color: Colors.red)),
                                      onTap: () {
                                        Get.back();
                                        Get.defaultDialog(
                                          title: "Xóa chuyến đi?",
                                          middleText: "Chuyến đi này sẽ bị xóa vĩnh viễn.",
                                          textConfirm: "XÓA",
                                          textCancel: "HỦY",
                                          confirmTextColor: Colors.white,
                                          buttonColor: Colors.red,
                                          onConfirm: () async {
                                            Get.back();
                                            final result = await TripRepository().deleteTrip(trip.id!);
                                            if (result.success) {
                                              Get.snackbar("Thành công", "Đã xóa chuyến đi");
                                              controller.fetchTrips();
                                            }
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icon du lịch (Thay vì card_travel, dùng explore)
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.lightGreen.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(Icons.flight_land, color: Colors.lightGreen.shade700, size: 30)
                                ),
                                const SizedBox(width: 16),

                                // Nội dung chuyến đi
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                                trip.name,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Ngày tạo ở góc phải
                                          Text(
                                              dateStr,
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        trip.description ?? "Không có mô tả",
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: Colors.grey.shade600, height: 1.3),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.bottomSheet(
            CreateTripBottomSheet(),
            isScrollControlled: true,
          );
        },
        backgroundColor: Colors.lightGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Tạo chuyến đi", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showJoinTripDialog(BuildContext context) {
    final JoinTripController joinController = Get.put(JoinTripController());
    joinController.codeController.clear();
    joinController.inviteInfo.value = null;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.group_add, color: Colors.lightGreen),
            SizedBox(width: 8),
            Text("Tham gia nhóm", style: TextStyle(color: Colors.lightGreen, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Obx(() {
          if (joinController.inviteInfo.value == null) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Nhập mã mời do bạn bè chia sẻ để tham gia vào chuyến đi."),
                const SizedBox(height: 16),
                TextField(
                  controller: joinController.codeController,
                  decoration: InputDecoration(
                    labelText: "Mã mời (VD: abcd-1234)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.qr_code_scanner),
                  ),
                ),
              ],
            );
          } else {
            final info = joinController.inviteInfo.value!;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text("🎉 Tìm thấy chuyến đi!", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const Divider(height: 24),
                Text("Tên chuyến: ${info.tripName}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Text("Người tạo: ${info.createdByName}", style: TextStyle(color: Colors.grey[700])),
                Text("Thành viên hiện tại: ${info.memberCount} người", style: TextStyle(color: Colors.grey[700])),
                if (info.description != null && info.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text("Mô tả: ${info.description}", style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic)),
                ]
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.lightGreen, foregroundColor: Colors.white),
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
                    : const Text("XÁC NHẬN VÀO NHÓM"),
              );
            }
          }),
        ],
      ),
    ).then((_) {
      Get.delete<JoinTripController>();
    });
  }
}