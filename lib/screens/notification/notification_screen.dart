import 'package:chiabill/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/empty_state.dart';
import '../../controllers/notification_controller.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationController controller = Get.find<NotificationController>();

  @override
  void initState() {
    super.initState();
    // Gọi tải dữ liệu một lần duy nhất khi mở màn hình này
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Thông báo", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          Obx(() => controller.notifications.isNotEmpty 
            ? IconButton(
                icon: Icon(Icons.done_all, color: AppColors.primary),
                tooltip: "Đánh dấu tất cả đã đọc",
                onPressed: () => controller.markAllAsRead(),
              )
            : const SizedBox.shrink()
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (controller.notifications.isEmpty) {
          return const EmptyState(text: "Hộp thư của bạn đang trống.\nKhông có thông báo mới nào!");
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
              color: notif.isRead ? Colors.white : AppColors.primary.withValues(alpha: 0.04),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: _getIconColor(notif.type).withValues(alpha:0.2),
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
                    Text(timeStr, style: TextStyle(fontSize: 12, color: Colors.grey)),
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
    if (type == "PAYMENT_APPROVED") return AppColors.primary;
    return Colors.blue;
  }
}