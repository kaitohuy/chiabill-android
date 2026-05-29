import 'dart:ui' as ui;
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
}
