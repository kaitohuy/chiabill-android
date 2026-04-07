import 'package:chiabill/utils/toast_util.dart';
import 'package:chiabill/screens/profile/profile_screen.dart';
import 'package:chiabill/screens/trip/create_trip_bottom_sheet.dart';
import 'package:chiabill/screens/trip/trip_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/join_trip_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../data/repositories/trip_repository.dart';
import '../notification/notification_screen.dart';
import '../trip/edit_trip_dialog.dart';

// THÊM IMPORT TIỆN ÍCH TIỀN TỆ
import '../../utils/currency_util.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final HomeController controller = Get.put(HomeController());
  final NotificationController notifController = Get.put(NotificationController(), permanent: true);
  final ProfileController profileController = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Cho phép nền của body tràn xuống dưới thanh điều hướng hệ thống
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.lightGreen[800],
        elevation: 0,
        title: Obx(() {
          String fullName = profileController.user.value?.name ?? "bạn";
          if (fullName.trim().isEmpty) fullName = "bạn";

          List<String> nameParts = fullName.trim().split(" ");
          String shortName = nameParts.isNotEmpty ? nameParts.last : "bạn";

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Chào $shortName 👋", style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.normal)),
              const Text("Chuyến đi của bạn", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          );
        }),
        actions: [
          IconButton(
            onPressed: () => _showJoinTripDialog(context),
            icon: Image.asset(
              'assets/images/join_trip.gif',
              width: 28,
              height: 28,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.group_add, size: 26, color: Colors.lightGreen),
            ),
          ),
          IconButton(
            icon: Obx(() => Badge(
              isLabelVisible: notifController.unreadCount.value > 0,
              label: Text(notifController.unreadCount.value.toString()),
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.notifications_none, size: 26),
            )),
            onPressed: () => Get.to(() => NotificationScreen()),
          ),
          IconButton(
              icon: const Icon(Icons.account_circle, size: 28),
              onPressed: () => Get.to(() => ProfileScreen())
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ==========================================
          // 1. DASHBOARD TÀI CHÍNH TỔNG QUAN
          // ==========================================
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Row(
              children: [
                Expanded(child: Obx(() => _buildFinancialCard("Bạn đang nợ", controller.totalOwe.value, Colors.redAccent, Icons.arrow_outward))),
                const SizedBox(width: 12),
                Expanded(child: Obx(() => _buildFinancialCard("Người ta nợ", controller.totalReceive.value, Colors.green, Icons.call_received))),
              ],
            ),
          ),

          // ==========================================
          // 2. THANH TÌM KIẾM
          // ==========================================
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => controller.onSearchTrips(value),
              decoration: InputDecoration(
                hintText: "Tìm theo tên chuyến đi...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true, fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
            ),
          ),

          // ==========================================
          // 3. DANH SÁCH CHUYẾN ĐI
          // ==========================================
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => Get.bottomSheet(CreateTripBottomSheet(), isScrollControlled: true),
              child: Obx(() {
                if (controller.isLoading.value && controller.trips.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: Colors.lightGreen));
                }

                if (controller.trips.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/empty_trip.gif',
                          width: 150,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.flight_takeoff, size: 80, color: Colors.lightGreen.withValues(alpha: 0.5)),
                        ),
                        const SizedBox(height: 16),
                        const Text("Chưa có chuyến đi nào.\nChạm vào bất cứ đâu để tạo mới!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: Colors.lightGreen,
                  onRefresh: () async {
                    await controller.fetchTrips(isRefresh: true);
                    await controller.fetchSummary();
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: controller.trips.length + (controller.isTripLastPage.value ? 0 : 1),
                    itemBuilder: (context, index) {
                      if (index == controller.trips.length) {
                        return const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Center(child: CircularProgressIndicator(color: Colors.lightGreen)));
                      }

                      final trip = controller.trips[index];

                      List<String> avatars = [];
                      if (trip.members != null) {
                        avatars = trip.members!
                            .where((m) => m.user?.avatarUrl != null && m.user!.avatarUrl!.isNotEmpty)
                            .map((m) => m.user!.avatarUrl!)
                            .toList();
                      }
                      int totalMembers = trip.memberCount ?? trip.members?.length ?? 1;

                      String dateStr = trip.createdAt ?? "";
                      if (dateStr.length >= 10) {
                        final parts = dateStr.substring(0, 10).split('-');
                        if (parts.length == 3) {
                          dateStr = "${parts[2]}/${parts[1]}/${parts[0]}";
                        }
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Get.to(() => TripDetailScreen(tripId: trip.id!)),
                          onLongPress: () {
                            Get.bottomSheet(
                              Container(
                                padding: EdgeInsets.only(top: 16, left: 0, right: 0, bottom: 16 + MediaQuery.of(context).padding.bottom),
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
                                              ToastUtil.showSuccess("Thành công", "Đã xóa chuyến đi");
                                              controller.fetchTrips(isRefresh: true);
                                              controller.fetchSummary();
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
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                    width: 52, height: 52,
                                    decoration: BoxDecoration(color: Colors.lightGreen.shade50, borderRadius: BorderRadius.circular(16)),
                                    child: Icon(Icons.flight_land, color: Colors.lightGreen.shade700, size: 28)
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(trip.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Text(trip.description ?? "Không có mô tả", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _buildAvatarStack(avatars, totalMembers),
                                    const SizedBox(height: 6),
                                    Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.bottomSheet(CreateTripBottomSheet(), isScrollControlled: true),
        backgroundColor: Colors.lightGreen,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text("Tạo chuyến đi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }

  Widget _buildFinancialCard(String title, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),

          // SỬ DỤNG CURRENCY UTILS TẠI ĐÂY
          Text(
              "${CurrencyUtils.formatNumber(amount)} đ",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarStack(List<String> avatars, int totalMembers) {
    int maxDisplay = 3;
    int displayCount = avatars.length > maxDisplay ? maxDisplay : avatars.length;
    int remaining = totalMembers - displayCount;

    if (displayCount == 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people, size: 14, color: Colors.grey.shade400),
          const SizedBox(width: 4),
          Text("$totalMembers người", style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(displayCount + (remaining > 0 ? 1 : 0), (index) {
        if (remaining > 0 && index == displayCount) {
          return Align(
            widthFactor: 0.7,
            child: CircleAvatar(
              radius: 13,
              backgroundColor: Colors.grey.shade200,
              child: Text("+$remaining", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
            ),
          );
        }
        return Align(
          widthFactor: 0.7,
          child: CircleAvatar(
            radius: 14,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 12,
              backgroundImage: NetworkImage(avatars[index]),
              onBackgroundImageError: (_, __) => const Icon(Icons.person, size: 12),
            ),
          ),
        );
      }),
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
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.group_add, size: 60, color: Colors.lightGreen),
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
                    prefixIcon: const Icon(Icons.keyboard),
                  ),
                ),
                const SizedBox(height: 16),

                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Colors.lightGreen),
                      foregroundColor: Colors.lightGreen
                  ),
                  icon: const Icon(Icons.qr_code_scanner),
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
                Text("Tên chuyến: ${info.tripName}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
}