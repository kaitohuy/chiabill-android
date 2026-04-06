import 'package:chiabill/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../data/repositories/trip_repository.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/trip_detail_controller.dart';
import '../../data/models/trip_response.dart';
import '../../utils/currency_util.dart';

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
  late TextEditingController budgetController; // 1. ĐÃ KHAI BÁO THÊM Ở ĐÂY

  bool isLoading = false;
  final TripRepository _repo = TripRepository();

  @override
  void initState() {
    super.initState();
    // Pre-fill dữ liệu cũ vào form
    nameController = TextEditingController(text: widget.trip.name);
    descController = TextEditingController(text: widget.trip.description);

    // 2. KHỞI TẠO NGÂN SÁCH (NẾU CÓ THÌ FORMAT DẤU PHẨY)
    String initialBudget = widget.trip.totalBudget != null && widget.trip.totalBudget! > 0
        ? CurrencyUtils.formatNumber(widget.trip.totalBudget!)
        : "";
    budgetController = TextEditingController(text: initialBudget);
  }

  @override
  void dispose() {
    nameController.dispose();
    descController.dispose();
    budgetController.dispose(); // 3. DISPOSE ĐỂ TRÁNH TRÀN RAM
    super.dispose();
  }

  Future<void> _submitUpdate() async {
    String name = nameController.text.trim();
    if (name.isEmpty) {
      ToastUtil.showWarning("Lỗi", "Tên chuyến đi không được để trống");
      return;
    }

    // 4. XỬ LÝ LẤY SỐ TIỀN (BỎ DẤU PHẨY)
    double? parsedBudget;
    if (budgetController.text.trim().isNotEmpty) {
      String rawBudget = budgetController.text.replaceAll(',', '');
      parsedBudget = double.tryParse(rawBudget);
    }

    setState(() => isLoading = true);
    try {
      // 5. GỌI API UPDATE (LƯU Ý: TRUYỀN THÊM NGÂN SÁCH VÀO ĐÂY)
      final result = await _repo.updateTrip(
          widget.trip.id,
          name,
          descController.text.trim(),
          parsedBudget // <-- Biến mới được thêm
      );

      if (result.success) {
        // Đóng ngay khi thành công
        Get.back(); 
        ToastUtil.showSuccess("Thành công", "Đã cập nhật chuyến đi");

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
        ToastUtil.showError("Lỗi", result.message ?? "Không thể cập nhật");
      }
    } catch (e) {
      ToastUtil.showError("Lỗi hệ thống", "Đã xảy ra lỗi không xác định");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24), // MỞ RỘNG CHIỀU RỘNG TẠI ĐÂY
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
          "Sửa chuyến đi", 
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.lightGreen, fontSize: 22)
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width, // Ép lấy tối đa chiều rộng cho phép
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                    labelText: "Tên chuyến đi", 
                    prefixIcon: const Icon(Icons.flight_takeoff, color: Colors.lightGreen),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                ],
                decoration: InputDecoration(
                    labelText: "Ngân sách dự kiến",
                    suffixText: "đ",
                    prefixIcon: const Icon(Icons.account_balance_wallet, color: Colors.lightGreen),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                    labelText: "Mô tả / Ghi chú", 
                    prefixIcon: const Icon(Icons.notes, color: Colors.lightGreen),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: () => Get.back(), 
                  child: const Text("HỦY", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreen, 
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0
                ),
                onPressed: isLoading ? null : _submitUpdate,
                child: isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("LƯU THAY ĐỔI", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}