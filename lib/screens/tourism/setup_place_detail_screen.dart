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
          "thank_you".tr,
          "place_report_success_msg".tr,
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      Get.snackbar("error".tr, "cannot_send_report".trParams({'error': e.toString()}), backgroundColor: Colors.redAccent, colorText: Colors.white);
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
        title: Text("setup_details".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  child: Text("skip_caps".tr, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                )
        ],
      ),
      body: _isReporting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text("sending_request_to_admin".tr, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
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
                                  "place_category_prefix".trParams({'category': widget.place.category.tr}),
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

                      Text(
                        "detailed_info".tr,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _summaryController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: "overview_description_label".tr,
                          hintText: "overview_description_hint".tr,
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
                        validator: (v) => v!.trim().isEmpty ? "overview_description_empty_error".tr : null,
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration: InputDecoration(
                                labelText: "ticket_price_label".tr,
                                hintText: "ticket_price_hint".tr,
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
                                labelText: "opening_hours_label".tr,
                                hintText: "opening_hours_hint".tr,
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

                      Text(
                        "real_images".tr,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
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
                                Text(
                                  "tap_to_select_image_caps".tr,
                                  style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "image_upload_album_hint".tr,
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
                        Text(
                          "image_upload_queue".tr,
                          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
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
                                          Row(
                                            children: [
                                              const SizedBox(
                                                width: 12,
                                                height: 12,
                                                child: CircularProgressIndicator(strokeWidth: 1.5),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                "uploading_to_cloudinary".tr,
                                                style: const TextStyle(fontSize: 11, color: Colors.blue),
                                              ),
                                            ],
                                          )
                                        else if (pending.isError)
                                          Text(
                                            "upload_failed".tr,
                                            style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold),
                                          )
                                        else
                                          Row(
                                            children: [
                                              const Icon(Icons.check_circle, size: 12, color: Colors.green),
                                              const SizedBox(width: 4),
                                              Text(
                                                "upload_success_album_other".tr,
                                                style: const TextStyle(fontSize: 11, color: Colors.green),
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
                                "please_wait".tr,
                                "image_still_uploading_msg".tr,
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
                                  "success".tr,
                                  "setup_details_success_msg".tr,
                                  backgroundColor: Colors.green,
                                  colorText: Colors.white,
                                );
                              }
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.save_outlined, color: Colors.white),
                              const SizedBox(width: 10),
                              Text(
                                "save_and_complete_caps".tr,
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
