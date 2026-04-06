import 'package:get/get.dart';
import '../data/models/notification_response.dart';
import '../data/repositories/notification_repository.dart';
import '../screens/trip/trip_detail_screen.dart';

class NotificationController extends GetxController {
  final NotificationRepository _repository = NotificationRepository();

  var notifications = <NotificationResponse>[].obs;
  var unreadCount = 0.obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUnreadCount();
  }

  // Cập nhật riêng cái chấm đỏ (gọi khi ở HomeScreen)
  Future<void> fetchUnreadCount() async {
    final result = await _repository.getUnreadCount();
    if (result.success && result.data != null) {
      unreadCount.value = result.data!;
    }
  }

  // Tải toàn bộ danh sách khi mở màn hình NotificationScreen
  Future<void> fetchNotifications() async {
    isLoading.value = true;
    final result = await _repository.getNotifications();
    if (result.success && result.data != null) {
      notifications.value = result.data!;
      // Update lại biến unread đếm tại chỗ cho chắc chắn
      unreadCount.value = notifications.where((n) => !n.isRead).length;
    }
    isLoading.value = false;
  }

  // Xử lý khi user bấm vào 1 thông báo
  Future<void> handleNotificationClick(NotificationResponse notif) async {
    // 1. Đánh dấu đã đọc ngay trên UI cho mượt
    if (!notif.isRead) {
      final index = notifications.indexWhere((n) => n.id == notif.id);
      if (index != -1) {
        notifications[index].isRead = true;
        notifications.refresh(); // Ép UI vẽ lại
        unreadCount.value = (unreadCount.value > 0) ? unreadCount.value - 1 : 0;
      }
      // 2. Gọi API ngầm ở background
      _repository.markAsRead(notif.id);
    }

    // 3. Điều hướng dựa vào Type
    if (notif.referenceId != null) {
      if (notif.type == "EXPENSE_CREATED" ||
          notif.type == "PAYMENT_REQUESTED" ||
          notif.type == "PAYMENT_APPROVED" ||
          notif.type == "MEMBER_KICKED") {
        Get.to(() => TripDetailScreen(tripId: notif.referenceId!));
      } else if (notif.type == "TRIP_INVITE") {
        // Tùy logic bạn muốn dẫn đi đâu (có thể là màn nhập mã)
      }
    }
  }
}