import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/trash_controller.dart';
import '../../theme/app_colors.dart';
import '../../utils/trip_category_util.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TrashController>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Thùng rác", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (controller.trashTrips.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text("Thùng rác trống", style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchTrashTrips(),
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.trashTrips.length,
            itemBuilder: (context, index) {
              final trip = controller.trashTrips[index];
              Color categoryColor = TripCategoryUtil.getColor(trip.categoryIcon);
              
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), 
                  side: BorderSide(color: Colors.grey.shade200)
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
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
                                Text(trip.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text("Đã xóa", style: TextStyle(color: Colors.red.shade400, fontSize: 13, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _confirmRestore(context, controller, trip.id),
                            icon: const Icon(Icons.restore, color: Colors.green, size: 20),
                            label: const Text("Phục hồi", style: TextStyle(color: Colors.green)),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => _confirmDelete(context, controller, trip.id),
                            icon: const Icon(Icons.delete_forever, color: Colors.red, size: 20),
                            label: const Text("Xóa vĩnh viễn", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  void _confirmRestore(BuildContext context, TrashController controller, int tripId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Phục hồi chuyến đi"),
        content: const Text("Chuyến đi sẽ được khôi phục lại vào danh sách của bạn. Bạn có chắc chắn muốn phục hồi không?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              Get.back();
              controller.restoreTrip(tripId);
            },
            child: const Text("Phục hồi", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, TrashController controller, int tripId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xóa vĩnh viễn"),
        content: const Text("Hành động này không thể hoàn tác. Mọi dữ liệu về chi tiêu, thành viên và hình ảnh của chuyến đi này sẽ bị xóa vĩnh viễn khỏi hệ thống. Bạn có chắc chắn không?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              Get.back();
              controller.forceDeleteTrip(tripId);
            },
            child: const Text("Xóa vĩnh viễn", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
