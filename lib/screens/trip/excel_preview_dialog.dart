import 'package:chiabill/theme/app_colors.dart';
import 'package:chiabill/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/itinerary_item_response.dart';
import '../../controllers/itinerary_controller.dart';
import '../../utils/currency_util.dart';

class ExcelPreviewDialog extends StatefulWidget {
  final int tripId;
  final List<ItineraryItemResponse> parsedItems;

  const ExcelPreviewDialog({super.key, required this.tripId, required this.parsedItems});

  @override
  State<ExcelPreviewDialog> createState() => _ExcelPreviewDialogState();
}

class _ExcelPreviewDialogState extends State<ExcelPreviewDialog> {
  late List<ItineraryItemResponse> items;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    // Tạo bản sao để có thể sửa đổi cục bộ nếu muốn
    items = List.from(widget.parsedItems);
  }

  void _onConfirmImport() async {
    if (items.isEmpty) return;

    setState(() => isUploading = true);
    final controller = Get.find<ItineraryController>(tag: widget.tripId.toString());
    final success = await controller.saveItineraryBulk(items, showToast: false);
    setState(() => isUploading = false);

    if (success) {
      Get.back(); // Đóng Dialog Preview trước
      ToastUtil.showSuccess("Thành công", "Đã nhập ${items.length} hoạt động lịch trình"); // Hiển thị Toast sau khi đóng overlay
    }
  }

  void _deleteItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  void _editItem(int index) {
    final item = items[index];
    final activityController = TextEditingController(text: item.activity);
    final dayController = TextEditingController(text: item.dayNumber.toString());
    final timeController = TextEditingController(text: item.timeRange ?? "");
    final locationController = TextEditingController(text: item.location ?? "");
    final noteController = TextEditingController(text: item.note ?? "");
    final costController = TextEditingController(
      text: item.estimatedCost != null ? item.estimatedCost!.toInt().toString() : "",
    );

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.edit, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text(
              "Sửa hoạt động",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: activityController,
                decoration: const InputDecoration(
                  labelText: "Hoạt động * (Bắt buộc)",
                  hintText: "Nhập tên hoạt động",
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: dayController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Ngày số",
                        hintText: "VD: 1",
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: timeController,
                      decoration: const InputDecoration(
                        labelText: "Khung giờ",
                        hintText: "VD: 08:00 - 09:00",
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: "Địa điểm",
                  hintText: "Nhập địa điểm",
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: costController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Chi phí dự toán",
                  hintText: "Nhập số tiền",
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Ghi chú",
                  hintText: "Nhập ghi chú thêm",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("HỦY", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final act = activityController.text.trim();
              if (act.isEmpty) {
                Get.snackbar(
                  "Lỗi",
                  "Tên hoạt động không được để trống",
                  backgroundColor: Colors.redAccent,
                  colorText: Colors.white,
                );
                return;
              }
              final day = int.tryParse(dayController.text.trim()) ?? 1;
              final cost = double.tryParse(costController.text.trim().replaceAll(RegExp(r'[^0-9.]'), ""));

              setState(() {
                items[index] = ItineraryItemResponse(
                  id: item.id,
                  dayNumber: day,
                  timeRange: timeController.text.trim().isEmpty ? null : timeController.text.trim(),
                  activity: act,
                  location: locationController.text.trim().isEmpty ? null : locationController.text.trim(),
                  note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                  estimatedCost: cost,
                );
              });
              Get.back();
            },
            child: const Text("LƯU", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.grey.shade100,
      child: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black87),
                    onPressed: () => Get.back(),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Xem trước lịch trình",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        Text(
                          "Chạm vào hoạt động để chỉnh sửa hoặc nhấn xóa nếu cần",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Statistics Header
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem("Tổng hoạt động", "${items.length}", Icons.explore),
                  Container(width: 1, height: 40, color: Colors.grey.shade200),
                  _buildStatItem(
                    "Ước tính chi phí",
                    "${CurrencyUtils.formatNumber(
                      items.map((e) => e.estimatedCost ?? 0.0).fold(0.0, (a, b) => a + b),
                    )} đ",
                    Icons.payments,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // List of parsed items
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text("Không còn hoạt động nào để nhập", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            onTap: () => _editItem(index),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBackground,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "Ngày ${item.dayNumber}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                if (item.timeRange != null) ...[
                                  const SizedBox(width: 8),
                                  Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.timeRange!,
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text(
                                  item.activity,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                if (item.location != null && item.location!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.pin_drop, size: 12, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          item.location!,
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (item.estimatedCost != null && item.estimatedCost! > 0) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    "Dự toán: ${CurrencyUtils.formatNumber(item.estimatedCost!)} đ",
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                  ),
                                ],
                                if (item.note != null && item.note!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    "💡 ${item.note}",
                                    style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  icon: Icon(Icons.edit_outlined, size: 22, color: Colors.grey.shade600),
                                  onPressed: () => _editItem(index),
                                ),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () => _deleteItem(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Import Actions
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Get.back(),
                      child: const Text("HỦY", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: isUploading || items.isEmpty ? null : _onConfirmImport,
                      child: isUploading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("XÁC NHẬN NHẬP", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
