import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/notification_controller.dart';

class NotificationScreen extends StatelessWidget {
  NotificationScreen({super.key});

  final NotificationController controller = Get.find<NotificationController>();

  @override
  Widget build(BuildContext context) {
    // Gọi tải dữ liệu mỗi khi mở màn hình này
    controller.fetchNotifications();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Thông báo", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: Colors.lightGreen));
        }

        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text("Chưa có thông báo nào", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: controller.notifications.length,
          itemBuilder: (context, index) {
            final notif = controller.notifications[index];

            // Xử lý chuỗi ngày giờ (chỉ lấy ngày và giờ)
            String timeStr = notif.createdAt;
            if (timeStr.length > 16) {
              timeStr = timeStr.substring(0, 16).replaceAll("T", " ");
            }

            return Container(
              color: notif.isRead ? Colors.white : Colors.lightGreen.shade50,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: _getIconColor(notif.type).withOpacity(0.2),
                  child: Icon(_getIcon(notif.type), color: _getIconColor(notif.type)),
                ),
                title: Text(
                  notif.title,
                  style: TextStyle(
                    fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(notif.message, style: TextStyle(color: Colors.grey[700])),
                    const SizedBox(height: 6),
                    Text(timeStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                onTap: () => controller.handleNotificationClick(notif),
              ),
            );
          },
        );
      }),
    );
  }

  // Hàm helper để render Icon theo type
  IconData _getIcon(String type) {
    if (type == "EXPENSE_CREATED") return Icons.receipt_long;
    if (type == "PAYMENT_REQUESTED") return Icons.money_off;
    if (type == "PAYMENT_APPROVED") return Icons.check_circle;
    if (type == "MEMBER_KICKED") return Icons.person_remove;
    if (type == "TRIP_INVITE") return Icons.mail;
    return Icons.notifications;
  }

  Color _getIconColor(String type) {
    if (type == "EXPENSE_CREATED") return Colors.orange;
    if (type == "PAYMENT_REQUESTED") return Colors.redAccent;
    if (type == "PAYMENT_APPROVED") return Colors.green;
    return Colors.blue;
  }
}