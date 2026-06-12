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
import '../../utils/trip_category_util.dart';

class EditTripDialog extends StatefulWidget {
  final TripResponse trip;
  final bool isFromHome;

  const EditTripDialog({super.key, required this.trip, this.isFromHome = false});

  @override
  State<EditTripDialog> createState() => _EditTripDialogState();
}

class _EditTripDialogState extends State<EditTripDialog> {
  late TextEditingController nameController;
  late TextEditingController descController;

  bool isLoading = false;
  bool isPickingImage = false;
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  String? selectedCategoryName;
  String? selectedCategoryIcon;

  final TripRepository _repo = TripRepository();
  final ImagePicker _picker = ImagePicker();
  File? selectedCoverFile;
  // Giữ lại URL hiện tại - null nghĩa là đã xóa ảnh cũ
  bool _coverCleared = false;

  Future<void> _pickCoverImage() async {
    FocusScope.of(context).unfocus();
    setState(() => isPickingImage = true);
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 60,
        maxWidth: 1080,
      );
      if (image != null) {
        setState(() {
          selectedCoverFile = File(image.path);
          _coverCleared = false;
        });
      }
    } finally {
      if (mounted) setState(() => isPickingImage = false);
    }
  }

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.trip.name);
    descController = TextEditingController(text: widget.trip.description);

    if (widget.trip.startDate != null) {
      selectedStartDate = DateTime.tryParse(widget.trip.startDate!);
    }
    if (widget.trip.endDate != null) {
      selectedEndDate = DateTime.tryParse(widget.trip.endDate!);
    }

    selectedCategoryName = widget.trip.categoryName;
    selectedCategoryIcon = widget.trip.categoryIcon;
  }

  @override
  void dispose() {
    nameController.dispose();
    descController.dispose();
    super.dispose();
  }

  Future<void> _submitUpdate() async {
    FocusScope.of(context).unfocus();
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ToastUtil.showWarning('Lỗi', 'Tên chuyến đi không được để trống');
      return;
    }

    setState(() => isLoading = true);
    try {
      final result = await _repo.updateTrip(
        widget.trip.id,
        name,
        descController.text.trim(),
        widget.trip.totalBudget,
        selectedStartDate?.toIso8601String(),
        selectedEndDate?.toIso8601String(),
        selectedCategoryName,
        selectedCategoryIcon,
      );

      if (!result.success) {
        ToastUtil.showError('Lỗi', result.message ?? 'Không thể cập nhật');
        return;
      }

      // Đóng sheet và báo thành công ngay lập tức
      Get.back();
      ToastUtil.showSuccess('Thành công', 'Đã cập nhật chuyến đi');

      // Refresh data
      _refreshData();

      // Upload ảnh bìa ASYNC chạy ngầm (fire and forget)
      if (selectedCoverFile != null) {
        _repo.updateTripCover(widget.trip.id, selectedCoverFile!).then((uploadRes) {
          if (!uploadRes.success) {
            ToastUtil.showError('Lỗi ảnh bìa', uploadRes.message ?? 'Không thể tải lên ảnh bìa');
          } else {
            // Refresh lại để lấy ảnh bìa mới
            _refreshData();
          }
        });
      }
    } catch (e) {
      ToastUtil.showError('Lỗi hệ thống', 'Đã xảy ra lỗi không xác định');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _refreshData() {
    if (widget.isFromHome) {
      if (Get.isRegistered<HomeController>()) Get.find<HomeController>().fetchTrips();
    } else {
      if (Get.isRegistered<TripDetailController>(tag: widget.trip.id.toString())) {
        Get.find<TripDetailController>(tag: widget.trip.id.toString()).fetchData(isSilent: true);
      }
      if (Get.isRegistered<HomeController>()) Get.find<HomeController>().fetchTrips();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Sửa chuyến đi',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close, color: Colors.grey),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tên chuyến đi
              TextField(
                controller: nameController,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: 'Tên chuyến đi (VD: Vũng Tàu 2N1Đ)',
                  prefixIcon: Icon(Icons.map, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),

              // Mô tả
              TextField(
                controller: descController,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: 'Mô tả (Không bắt buộc)',
                  prefixIcon: Icon(Icons.description, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 20),

              // Thời gian
              const Text('Thời gian chuyến đi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildDatePicker(),
              const SizedBox(height: 20),

              // Chủ đề chuyến đi
              const Text('Chủ đề chuyến đi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: TripCategoryUtil.categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final cat = TripCategoryUtil.categories[index];
                    final isSelected = selectedCategoryName == cat['name'];
                    return GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        setState(() {
                          selectedCategoryName = cat['name'] as String;
                          selectedCategoryIcon = cat['iconName'] as String;
                        });
                      },
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? cat['color'] as Color
                                  : (cat['color'] as Color).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              cat['icon'] as IconData,
                              color: isSelected ? Colors.white : cat['color'] as Color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat['name'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? AppColors.primary : Colors.grey[600],
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Ảnh bìa
              const Text('Ảnh bìa chuyến đi (Không bắt buộc)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildCoverPicker(),
              const SizedBox(height: 24),

              // Nút lưu
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isLoading ? null : _submitUpdate,
                  child: isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('LƯU THAY ĐỔI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    String dateRangeStr;
    if (selectedStartDate == null) {
      dateRangeStr = 'Chưa chọn';
    } else if (selectedEndDate == null) {
      dateRangeStr =
          '${selectedStartDate!.day.toString().padLeft(2, '0')}/${selectedStartDate!.month.toString().padLeft(2, '0')}/${selectedStartDate!.year}';
    } else {
      final duration = selectedEndDate!.difference(selectedStartDate!).inDays + 1;
      dateRangeStr =
          '${selectedStartDate!.day.toString().padLeft(2, '0')}/${selectedStartDate!.month.toString().padLeft(2, '0')}/${selectedStartDate!.year}'
          ' - '
          '${selectedEndDate!.day.toString().padLeft(2, '0')}/${selectedEndDate!.month.toString().padLeft(2, '0')}/${selectedEndDate!.year}'
          ' ($duration ngày)';
    }

    return InkWell(
      onTap: () async {
        FocusScope.of(context).unfocus();
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
          initialDateRange: DateTimeRange(
            start: selectedStartDate ?? DateTime.now(),
            end: selectedEndDate ?? (selectedStartDate ?? DateTime.now()).add(const Duration(days: 1)),
          ),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                onSurface: Colors.black87,
              ),
            ),
            child: child!,
          ),
        );
        FocusManager.instance.primaryFocus?.unfocus();
        if (picked != null) {
          setState(() {
            selectedStartDate = picked.start;
            selectedEndDate = picked.end;
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                dateRangeStr,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverPicker() {
    final hasExistingCover = !_coverCleared &&
        widget.trip.coverUrl != null &&
        widget.trip.coverUrl!.isNotEmpty;
    final showCover = selectedCoverFile != null || hasExistingCover;

    ImageProvider? coverImage;
    if (selectedCoverFile != null) {
      coverImage = FileImage(selectedCoverFile!);
    } else if (hasExistingCover) {
      coverImage = NetworkImage(widget.trip.coverUrl!);
    }

    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        image: coverImage != null
            ? DecorationImage(image: coverImage, fit: BoxFit.cover)
            : null,
      ),
      child: Stack(
        children: [
          // Nút chọn ảnh (toàn bộ area hoặc khi không có ảnh)
          if (!showCover)
            InkWell(
              onTap: _pickCoverImage,
              borderRadius: BorderRadius.circular(12),
              child: Center(
                child: isPickingImage
                    ? CircularProgressIndicator(color: AppColors.primary)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.primary),
                          const SizedBox(height: 8),
                          Text('Chọn ảnh từ thư viện', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
              ),
            )
          else ...[
            // Overlay tap để đổi ảnh
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _pickCoverImage,
                  borderRadius: BorderRadius.circular(12),
                  child: const SizedBox(),
                ),
              ),
            ),
            // Loading indicator khi đang chọn ảnh
            if (isPickingImage)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
            // Nút xóa ảnh
            if (!isPickingImage)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCoverFile = null;
                      _coverCleared = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
            // Badge đổi ảnh ở góc dưới trái
            if (!isPickingImage)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.edit, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text('Đổi ảnh', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}