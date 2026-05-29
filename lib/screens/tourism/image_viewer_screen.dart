import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';

class ImageViewerScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const ImageViewerScreen({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late int currentIndex;
  late PageController pageController;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    pageController = PageController(initialPage: widget.initialIndex);
  }

  void onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  Future<void> _shareImage() async {
    final url = widget.images[currentIndex];
    
    // Nếu là file local
    if (!url.startsWith('http')) {
      SharePlus.instance.share(ShareParams(text: 'Xem bức ảnh tuyệt đẹp này!', files: [XFile(url)]));
      return;
    }

    // Nếu là URL web
    try {
      Get.snackbar('Đang chuẩn bị...', 'Vui lòng chờ trong giây lát');
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/share_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await Dio().download(url, savePath);
      await SharePlus.instance.share(ShareParams(text: 'Xem bức ảnh tuyệt đẹp này!', files: [XFile(savePath)]));
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể chia sẻ ảnh');
    }
  }

  Future<void> _downloadImage() async {
    final url = widget.images[currentIndex];
    if (!url.startsWith('http')) {
      Get.snackbar('Thông báo', 'Ảnh này đã có sẵn trong máy của bạn.');
      return;
    }

    setState(() => _isDownloading = true);
    
    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/chiabill_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await Dio().download(url, savePath);
      
      // Kiểm tra quyền (Tuỳ chọn với gal)
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      await Gal.putImage(savePath);
      
      Get.snackbar(
        'Thành công', 
        'Đã lưu ảnh vào thư viện của bạn',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi tải xuống', 
        'Không thể lưu ảnh. Vui lòng cấp quyền lưu trữ.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text('${currentIndex + 1} / ${widget.images.length}', style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareImage,
          ),
          IconButton(
            icon: _isDownloading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.download),
            onPressed: _isDownloading ? null : _downloadImage,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          final url = widget.images[index];
          return PhotoViewGalleryPageOptions(
            imageProvider: url.startsWith('http') 
              ? CachedNetworkImageProvider(url) as ImageProvider
              : FileImage(File(url)),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            heroAttributes: PhotoViewHeroAttributes(tag: url),
          );
        },
        itemCount: widget.images.length,
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(),
        ),
        backgroundDecoration: const BoxDecoration(
          color: Colors.black,
        ),
        pageController: pageController,
        onPageChanged: onPageChanged,
      ),
    );
  }
}
