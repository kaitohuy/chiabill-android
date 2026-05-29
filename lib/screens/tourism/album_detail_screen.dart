import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chiabill/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'image_viewer_screen.dart';

class AlbumDetailScreen extends StatefulWidget {
  final String albumName;
  final List<String> images;
  final int placeId;

  const AlbumDetailScreen({
    super.key,
    required this.albumName,
    required this.images,
    required this.placeId,
  });

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  late List<String> _currentImages;

  @override
  void initState() {
    super.initState();
    _currentImages = List.from(widget.images);
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isUploading = true);

      final String targetPath = "${image.path}_compressed.jpg";

      // Nén ảnh: quality 50%, max width 1080 (Mục tiêu khoảng 50-100KB)
      final XFile? compressedImage = await FlutterImageCompress.compressAndGetFile(
        image.path,
        targetPath,
        quality: 50,
        minWidth: 1080,
        minHeight: 1080,
      );

      if (compressedImage != null) {
        // Tương lai: Gọi API Upload với file compressedImage
        // Giả lập sau khi upload thành công, thêm ảnh vào danh sách hiển thị
        // String newUrl = await ApiService.uploadPlaceImage(widget.placeId, widget.albumName, compressedImage);
        
        // Mock add
        setState(() {
          _currentImages.add(compressedImage.path); // Tạm thời hiện path local
        });
        
        Get.snackbar(
          "Thành công", 
          "Đã tải ảnh lên album ${widget.albumName}",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Lỗi tải ảnh", 
        "Không thể tải ảnh: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.albumName),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _currentImages.isEmpty
          ? const Center(child: Text("Album này chưa có hình ảnh nào."))
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: _currentImages.length,
              itemBuilder: (context, index) {
                final url = _currentImages[index];
                return GestureDetector(
                  onTap: () {
                    Get.to(() => ImageViewerScreen(
                          images: _currentImages,
                          initialIndex: index,
                        ));
                  },
                  child: url.startsWith('http') 
                      ? CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(color: Colors.grey),
                        )
                      : Image.file(
                          File(url),
                          fit: BoxFit.cover,
                        ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isUploading ? null : _pickAndUploadImage,
        backgroundColor: AppColors.primary,
        child: _isUploading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.add_a_photo, color: Colors.white),
      ),
    );
  }
}
