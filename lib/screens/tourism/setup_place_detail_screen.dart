import 'dart:io';
import 'package:chiabill/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/tourism_controller.dart';
import '../../data/models/place_model.dart';

// Class đại diện cho ảnh trong hàng đợi tải lên bất đồng bộ
class PendingImage {
  final File file;
  final String fileName;
  String? serverUrl;
  bool isUploading;
  bool isError;

  PendingImage({
    required this.file,
    required this.fileName,
    this.serverUrl,
    this.isUploading = true,
    this.isError = false,
  });
}

class SetupPlaceDetailScreen extends StatefulWidget {
  final PlaceModel place;
  const SetupPlaceDetailScreen({super.key, required this.place});

  @override
  State<SetupPlaceDetailScreen> createState() => _SetupPlaceDetailScreenState();
}

class _SetupPlaceDetailScreenState extends State<SetupPlaceDetailScreen> {
  final TourismController _tourismController = Get.find<TourismController>();

  final _formKey = GlobalKey<FormState>();
  final _summaryController = TextEditingController();
  final _priceController = TextEditingController();
  final _hoursController = TextEditingController();

  // Danh sách hàng đợi ảnh tải lên bất đồng bộ (Async Queue)
  final List<PendingImage> _pendingImages = [];
  bool _isReporting = false;

  @override
  void dispose() {
    _summaryController.dispose();
    _priceController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  // Chọn ảnh và đưa ngay vào hàng đợi upload bất đồng bộ (không block UI)
  Future<void> _pickAndUploadImageAsync() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    final File file = File(image.path);
    final String fileName = image.name;

    final pending = PendingImage(
      file: file,
      fileName: fileName,
      isUploading: true,
    );

    // Hiển thị ngay lập tức lên UI (0ms delay)
    setState(() {
      _pendingImages.add(pending);
    });

    // Chạy tác vụ tải lên bất đồng bộ ngầm
    _uploadImageAsync(pending);
  }

  // Tác vụ upload ngầm không block người dùng
  Future<void> _uploadImageAsync(PendingImage pending) async {
    try {
      // Album mặc định là "Khác" để khớp 100% với UI album gallery ở màn hình Detail
      final String? uploadedUrl = await _tourismController.uploadPlaceImage(
        widget.place.id,
        "Khác",
        pending.file,
      );

      if (uploadedUrl != null) {
        setState(() {
          pending.serverUrl = uploadedUrl;
          pending.isUploading = false;
        });
      } else {
        setState(() {
          pending.isUploading = false;
          pending.isError = true;
        });
      }
    } catch (e) {
      setState(() {
        pending.isUploading = false;
        pending.isError = true;
      });
    }
  }

  // Xử lý khi bấm nút "BỎ QUA" (Tạo place_report yêu cầu admin bổ sung thông tin)
  Future<void> _handleSkip() async {
    setState(() {
      _isReporting = true;
    });

    try {
      final success = await _tourismController.reportPlace(
        widget.place.id,
        "ADDITIONAL_INFO_REQUIRED",
        "Người dùng đã ghim địa điểm '${widget.place.name}' nhưng bỏ qua bước thiết lập chi tiết. Cần Admin bổ sung thông tin mô tả, giá vé, giờ mở cửa và hình ảnh.",
      );

      if (success) {
        Get.back();
        Get.snackbar(
          "Cảm ơn bạn",
          "Yêu cầu bổ sung thông tin chi tiết địa điểm đã được gửi tới Ban quản trị!",
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      Get.snackbar("Lỗi", "Không thể gửi yêu cầu: $e", backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      setState(() {
        _isReporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thiết lập chi tiết", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          _isReporting
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                )
              : TextButton(
                  onPressed: _handleSkip,
                  child: const Text("BỎ QUA", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                )
        ],
      ),
      body: _isReporting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Đang gửi yêu cầu bổ sung tới Admin...", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Phần Header hiển thị thông tin chung
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha:0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withValues(alpha:0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.place.name,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.category, color: AppColors.primary, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  "Danh mục: ${widget.place.category}",
                                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                                ),
                                const Spacer(),
                                Icon(Icons.location_city, color: Colors.grey[600], size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  widget.place.city,
                                  style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        "Thông Tin Chi Tiết",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _summaryController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: "Mô tả tổng quan (*)",
                          hintText: "Nhập một vài mô tả nổi bật về địa điểm du lịch này...",
                          alignLabelWithHint: true,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 50),
                            child: Icon(Icons.description_outlined),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                        validator: (v) => v!.trim().isEmpty ? "Vui lòng nhập mô tả tổng quan" : null,
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration: InputDecoration(
                                labelText: "Giá vé",
                                hintText: "VD: Miễn phí / 100.000đ",
                                prefixIcon: const Icon(Icons.confirmation_number_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _hoursController,
                              decoration: InputDecoration(
                                labelText: "Giờ mở cửa",
                                hintText: "VD: 24/7 hoặc 08:00 - 22:00",
                                prefixIcon: const Icon(Icons.access_time),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        "Hình Ảnh Thực Tế",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 12),

                      // Nút Tải ảnh lên
                      GestureDetector(
                        onTap: _pickAndUploadImageAsync,
                        child: Container(
                          width: double.infinity,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              style: BorderStyle.solid,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.primary),
                                const SizedBox(height: 6),
                                const Text(
                                  "BẤM ĐỂ CHỌN ẢNH TỪ THƯ VIỆN",
                                  style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Hình ảnh sẽ được tải ngầm lên album \"Khác\"",
                                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Danh sách hàng đợi ảnh đang upload ngầm (Async UI)
                      if (_pendingImages.isNotEmpty) ...[
                        const Text(
                          "Hàng đợi tải ảnh lên hệ thống:",
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _pendingImages.length,
                          itemBuilder: (context, index) {
                            final pending = _pendingImages[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Row(
                                children: [
                                  // Hiển thị ảnh local tức thì
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      pending.file,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Tên file và trạng thái upload ngầm
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          pending.fileName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        if (pending.isUploading)
                                          const Row(
                                            children: [
                                              SizedBox(
                                                width: 12,
                                                height: 12,
                                                child: CircularProgressIndicator(strokeWidth: 1.5),
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                "Đang tải lên Cloudinary...",
                                                style: TextStyle(fontSize: 11, color: Colors.blue),
                                              ),
                                            ],
                                          )
                                        else if (pending.isError)
                                          const Text(
                                            "Tải lên thất bại!",
                                            style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold),
                                          )
                                        else
                                          const Row(
                                            children: [
                                              Icon(Icons.check_circle, size: 12, color: Colors.green),
                                              SizedBox(width: 4),
                                              Text(
                                                "Tải lên thành công (Album: Khác)",
                                                style: TextStyle(fontSize: 11, color: Colors.green),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Nút xóa/hủy ảnh khỏi danh sách
                                  IconButton(
                                    icon: const Icon(Icons.cancel, color: Colors.grey, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _pendingImages.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Nút Lưu thông tin hoàn tất
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () async {
                            // Kiểm tra xem có ảnh nào chưa upload xong không
                            final hasUploading = _pendingImages.any((img) => img.isUploading);
                            if (hasUploading) {
                              Get.snackbar(
                                "Vui lòng chờ",
                                "Có hình ảnh đang được tải lên. Vui lòng đợi trong giây lát!",
                                backgroundColor: Colors.orange,
                                colorText: Colors.white,
                              );
                              return;
                            }

                            if (_formKey.currentState!.validate()) {
                              final success = await _tourismController.updatePlaceDetails(
                                id: widget.place.id,
                                name: widget.place.name,
                                category: widget.place.category,
                                latitude: widget.place.latitude,
                                longitude: widget.place.longitude,
                                city: widget.place.city,
                                summary: _summaryController.text.trim(),
                                ticketPrices: _priceController.text.trim(),
                                openingHours: _hoursController.text.trim(),
                              );

                              if (success) {
                                Get.back();
                                Get.snackbar(
                                  "Thành công",
                                  "Cảm ơn bạn đã hoàn tất thông tin địa điểm du lịch!",
                                  backgroundColor: Colors.green,
                                  colorText: Colors.white,
                                );
                              }
                            }
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save_outlined, color: Colors.white),
                              SizedBox(width: 10),
                              Text(
                                "LƯU & HOÀN TẤT",
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
