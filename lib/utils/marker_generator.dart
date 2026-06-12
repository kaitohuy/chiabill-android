import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerGenerator {
  static Future<BitmapDescriptor> createMarkerWithText(String title, Color iconColor, {bool showText = true}) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    const double iconSize = 50.0; // Size of the location icon
    const double padding = 10.0;
    
    double canvasWidth = iconSize;
    double canvasHeight = iconSize;
    
    TextPainter? textPainter;
    
    if (showText) {
      // Create text painter for the title
      textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 2,
      );

      textPainter.text = TextSpan(
        text: title,
        style: const TextStyle(
          fontSize: 14.0, // Đã giảm xuống 14 theo yêu cầu
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      );

      textPainter.layout(maxWidth: 180);

      // Calculate canvas size with text
      canvasWidth = textPainter.width > iconSize ? textPainter.width + padding * 2 : iconSize + padding * 2;
      canvasHeight = iconSize + textPainter.height + padding * 2;
    }

    if (showText && textPainter != null) {
      // Draw the background for text to make it readable like MapTiler
      final Paint bgPaint = Paint()
        ..color = Colors.white.withValues(alpha:0.9)
        ..style = PaintingStyle.fill;

      final RRect bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          (canvasWidth - textPainter.width) / 2 - 10,
          iconSize + 5,
          textPainter.width + 20,
          textPainter.height + 10,
        ),
        const Radius.circular(16.0),
      );
      
      // Draw shadow
      canvas.drawRRect(bgRect.shift(const Offset(0, 2)), Paint()..color = Colors.black.withValues(alpha:0.1));
      // Draw white background
      canvas.drawRRect(bgRect, bgPaint);

      // Draw text
      textPainter.paint(
        canvas,
        Offset((canvasWidth - textPainter.width) / 2, iconSize + 10),
      );
    }

    // Draw Icon (Using material icon font)
    final TextPainter iconPainter = TextPainter(textDirection: TextDirection.rtl);
    iconPainter.text = TextSpan(
      text: String.fromCharCode(Icons.location_on.codePoint),
      style: TextStyle(
        fontSize: iconSize,
        fontFamily: Icons.location_on.fontFamily,
        package: Icons.location_on.fontPackage,
        color: iconColor,
      ),
    );
    iconPainter.layout();
    iconPainter.paint(canvas, Offset((canvasWidth - iconSize) / 2, 0));

    final img = await pictureRecorder.endRecording().toImage(
          canvasWidth.toInt(),
          canvasHeight.toInt(),
        );
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }

  static Future<BitmapDescriptor> createMarkerWithImage(String? imageUrl, String title, Color brandColor) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    const double pinSize = 70.0;
    const double radius = 28.0;
    const Offset center = Offset(pinSize / 2, 28.0);
    const double padding = 10.0;

    // 1. Chuẩn bị text painter cho tiêu đề ở dưới
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
    );
    textPainter.text = TextSpan(
      text: title,
      style: const TextStyle(
        fontSize: 11.0,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
    textPainter.layout(maxWidth: 160);

    // Kích thước canvas động theo text
    final double canvasWidth = textPainter.width > pinSize ? textPainter.width + padding * 2 : pinSize + padding * 2;
    final double canvasHeight = pinSize + textPainter.height + padding * 2;
    final double pinXOffset = (canvasWidth - pinSize) / 2;

    // Di chuyển canvas draw coordinates để ghim ảnh nằm ở giữa theo chiều ngang
    canvas.save();
    canvas.translate(pinXOffset, 0);

    // 2. Vẽ bóng đổ (Shadow) cho ghim định vị
    final Path pinPath = Path();
    pinPath.addOval(Rect.fromCircle(center: center, radius: radius + 2));
    pinPath.moveTo(center.dx - 12, center.dy + radius - 4);
    pinPath.lineTo(center.dx, pinSize - 5);
    pinPath.lineTo(center.dx + 12, center.dy + radius - 4);
    pinPath.close();

    canvas.drawPath(
      pinPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // 3. Vẽ thân ghim màu trắng (Viền ngoài)
    final Paint whitePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawPath(pinPath, whitePaint);

    // 4. Vẽ viền màu thương hiệu bên trong
    final Paint brandPaint = Paint()
      ..color = brandColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius - 1, brandPaint);

    // 5. Tải và vẽ ảnh
    ui.Image? uiImage;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      uiImage = await _loadNetworkImage(imageUrl);
    }

    if (uiImage != null) {
      // Clip canvas thành hình tròn để vẽ ảnh bo tròn
      canvas.save();
      final Path clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius - 2));
      canvas.clipPath(clipPath);

      // Vẽ ảnh fit vào hình tròn
      canvas.drawImageRect(
        uiImage,
        Rect.fromLTWH(0, 0, uiImage.width.toDouble(), uiImage.height.toDouble()),
        Rect.fromCircle(center: center, radius: radius - 2),
        Paint()..filterQuality = ui.FilterQuality.high,
      );
      canvas.restore();
    } else {
      // Fallback: Vẽ icon định vị màu thương hiệu ở giữa
      final TextPainter iconPainter = TextPainter(textDirection: TextDirection.rtl);
      iconPainter.text = TextSpan(
        text: String.fromCharCode(Icons.landscape.codePoint),
        style: TextStyle(
          fontSize: 32.0,
          fontFamily: Icons.landscape.fontFamily,
          package: Icons.landscape.fontPackage,
          color: brandColor,
        ),
      );
      iconPainter.layout();
      iconPainter.paint(canvas, Offset(center.dx - 16, center.dy - 16));
    }
    
    canvas.restore(); // Khôi phục canvas gốc để vẽ text ở vị trí chuẩn xác

    // 6. Vẽ nhãn nền trắng và text ở dưới ghim ảnh
    final double textX = (canvasWidth - textPainter.width) / 2;
    final double textY = pinSize + 3;

    final Paint bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    final RRect bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        textX - 8,
        textY - 4,
        textPainter.width + 16,
        textPainter.height + 8,
      ),
      const Radius.circular(8.0),
    );

    // Đổ bóng cho nhãn text
    canvas.drawRRect(bgRect.shift(const Offset(0, 2)), Paint()..color = Colors.black.withValues(alpha: 0.1));
    canvas.drawRRect(bgRect, bgPaint);

    // Vẽ text
    textPainter.paint(canvas, Offset(textX, textY));

    final img = await pictureRecorder.endRecording().toImage(canvasWidth.toInt(), canvasHeight.toInt() + 5);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }

  static final Map<String, ui.Image> _imageCache = {};

  static void clearCache() {
    for (var img in _imageCache.values) {
      try {
        img.dispose();
      } catch (_) {}
    }
    _imageCache.clear();
  }

  static Future<ui.Image?> _loadNetworkImage(String path) async {
    if (_imageCache.containsKey(path)) {
      return _imageCache[path];
    }
    try {
      if (_imageCache.length >= 50) {
        final firstKey = _imageCache.keys.first;
        final oldImg = _imageCache.remove(firstKey);
        try {
          oldImg?.dispose();
        } catch (_) {}
      }

      final HttpClient httpClient = HttpClient();
      final Uri uri = Uri.base.resolve(path);
      final HttpClientRequest request = await httpClient.getUrl(uri);
      final HttpClientResponse response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        return null;
      }
      final List<int> bytes = await response.fold<List<int>>(<int>[], (a, b) => a..addAll(b));
      final Uint8List uint8list = Uint8List.fromList(bytes);
      final ui.Codec codec = await ui.instantiateImageCodec(
        uint8list,
        targetWidth: 100,
        targetHeight: 100,
      );
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ui.Image image = fi.image;
      _imageCache[path] = image;
      return image;
    } catch (e) {
      debugPrint("Error loading marker image: $e");
      return null;
    }
  }
}
