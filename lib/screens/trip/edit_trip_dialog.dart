import 'dart:io';
import 'package:chiabill/theme/app_colors.dart';
import 'package:chiabill/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
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
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  final TripRepository _repo = TripRepository();
  final ImagePicker _picker = ImagePicker();
  File? selectedCoverFile;

  Future<void> _pickCoverImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 1080,
    );
    if (image != null) {
      setState(() {
        selectedCoverFile = File(image.path);
      });
    }
  }

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
    
    if (widget.trip.startDate != null) {
      selectedStartDate = DateTime.tryParse(widget.trip.startDate!);
    }
    if (widget.trip.endDate != null) {
      selectedEndDate = DateTime.tryParse(widget.trip.endDate!);
    }
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
          parsedBudget, // <-- Biến mới được thêm
          selectedStartDate?.toIso8601String(),
          selectedEndDate?.toIso8601String()
      );

      if (result.success) {
        if (selectedCoverFile != null) {
          final uploadRes = await _repo.updateTripCover(widget.trip.id, selectedCoverFile!);
          if (!uploadRes.success) {
            ToastUtil.showError("Lỗi", "Không thể tải lên ảnh bìa mới: ${uploadRes.message}");
          }
        }
        // Đóng ngay khi thành công
        Get.back(); 
        ToastUtil.showSuccess("Thành công", "Đã cập nhật chuyến đi");

        // Refresh lại data tùy theo nơi gọi
        if (widget.isFromHome) {
          Get.find<HomeController>().fetchTrips();
        } else {
          if (Get.isRegistered<TripDetailController>(tag: widget.trip.id.toString())) {
            Get.find<TripDetailController>(tag: widget.trip.id.toString()).fetchData(isSilent: true);
          }
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
      title: Text(
          "Sửa chuyến đi", 
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 22)
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
                maxLength: 100,
                decoration: InputDecoration(
                    labelText: "Tên chuyến đi", 
                    prefixIcon: Icon(Icons.flight_takeoff, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    counterText: "",
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: descController,
                maxLength: 200,
                maxLines: 3,
                decoration: InputDecoration(
                    labelText: "Mô tả chuyến đi",
                    prefixIcon: Icon(Icons.description, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    counterText: "",
                ),
              ),
              const SizedBox(height: 20),
              
              // Date Picker
              InkWell(
                onTap: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                    initialDateRange: DateTimeRange(
                      start: selectedStartDate ?? DateTime.now(),
                      end: selectedEndDate ?? (selectedStartDate ?? DateTime.now()).add(const Duration(days: 1)),
                    ),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: AppColors.primary,
                            onPrimary: Colors.white,
                            onSurface: Colors.black87,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      selectedStartDate = picked.start;
                      selectedEndDate = picked.end;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Thời gian chuyến đi", style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(
                              selectedStartDate != null
                                ? (selectedEndDate != null
                                    ? "${selectedStartDate!.day.toString().padLeft(2, '0')}/${selectedStartDate!.month.toString().padLeft(2, '0')}/${selectedStartDate!.year} - ${selectedEndDate!.day.toString().padLeft(2, '0')}/${selectedEndDate!.month.toString().padLeft(2, '0')}/${selectedEndDate!.year}"
                                    : "${selectedStartDate!.day.toString().padLeft(2, '0')}/${selectedStartDate!.month.toString().padLeft(2, '0')}/${selectedStartDate!.year}")
                                : "Chưa chọn",
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Budget Input Field
              TextField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Tổng ngân sách (Không bắt buộc)",
                  prefixIcon: Icon(Icons.monetization_on, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Ảnh bìa chuyến đi (Không bắt buộc)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                  image: selectedCoverFile != null
                      ? DecorationImage(
                          image: FileImage(selectedCoverFile!),
                          fit: BoxFit.cover,
                        )
                      : (widget.trip.coverUrl != null && widget.trip.coverUrl!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(widget.trip.coverUrl!),
                              fit: BoxFit.cover,
                            )
                          : null),
                ),
                child: Stack(
                  children: [
                    if (selectedCoverFile == null && (widget.trip.coverUrl == null || widget.trip.coverUrl!.isEmpty))
                      InkWell(
                        onTap: _pickCoverImage,
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.primary),
                              const SizedBox(height: 8),
                              Text(
                                "Chọn ảnh từ thư viện",
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _pickCoverImage,
                            borderRadius: BorderRadius.circular(16),
                            child: const SizedBox(),
                          ),
                        ),
                      ),
                    if (selectedCoverFile != null || (widget.trip.coverUrl != null && widget.trip.coverUrl!.isNotEmpty))
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedCoverFile = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
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
                    backgroundColor: AppColors.primary, 
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