import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/trip_repository.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/trip_detail_controller.dart';
import '../../data/models/trip_response.dart';

class EditTripDialog extends StatefulWidget {
  final TripResponse trip;
  final bool isFromHome; // Cờ để biết đang gọi từ màn hình nào để refresh cho đúng

  const EditTripDialog({super.key, required this.trip, this.isFromHome = false});

  @override
  State<EditTripDialog> createState() => _EditTripDialogState();
}

class _EditTripDialogState extends State<EditTripDialog> {
  late TextEditingController nameController;
  late TextEditingController descController;
  bool isLoading = false;
  final TripRepository _repo = TripRepository();

  @override
  void initState() {
    super.initState();
    // Pre-fill dữ liệu cũ vào form
    nameController = TextEditingController(text: widget.trip.name);
    descController = TextEditingController(text: widget.trip.description);
  }

  @override
  void dispose() {
    nameController.dispose();
    descController.dispose();
    super.dispose();
  }

  Future<void> _submitUpdate() async {
    String name = nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar("Lỗi", "Tên chuyến đi không được để trống");
      return;
    }

    setState(() => isLoading = true);
    final result = await _repo.updateTrip(widget.trip.id, name, descController.text.trim());
    setState(() => isLoading = false);

    if (result.success) {
      Get.back(); // Đóng Dialog
      Get.snackbar("Thành công", "Đã cập nhật chuyến đi", backgroundColor: Colors.green, colorText: Colors.white);

      // Refresh lại data tùy theo nơi gọi
      if (widget.isFromHome) {
        Get.find<HomeController>().fetchTrips();
      } else {
        Get.find<TripDetailController>(tag: widget.trip.id.toString()).fetchTripDetail();
        // Cập nhật luôn list Home bên ngoài cho đồng bộ
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().fetchTrips();
        }
      }
    } else {
      Get.snackbar("Lỗi", result.message ?? "Không thể cập nhật");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Sửa chuyến đi", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.lightGreen)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: "Tên chuyến đi", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: descController,
            decoration: InputDecoration(labelText: "Mô tả", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text("HỦY", style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.lightGreen, foregroundColor: Colors.white),
          onPressed: isLoading ? null : _submitUpdate,
          child: isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("LƯU"),
        ),
      ],
    );
  }
}