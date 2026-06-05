import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chiabill/theme/app_colors.dart';
import '../../utils/toast_util.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> with SingleTickerProviderStateMixin {
  late final MobileScannerController _scannerController;
  late final AnimationController _animationController;
  late final Animation<double> _animation;
  double _zoomScale = 0.0;
  double _baseScale = 0.0;
  bool _isTorchOn = false;
  bool _hasDetected = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController)
      ..addListener(() {
        setState(() {});
      });
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasDetected) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _hasDetected = true;
        Get.back(result: barcode.rawValue);
        break;
      }
    }
  }

  Future<void> _scanFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final BarcodeCapture? capture = await _scannerController.analyzeImage(image.path);
      if (capture != null && capture.barcodes.isNotEmpty) {
        final String? code = capture.barcodes.first.rawValue;
        if (code != null && code.isNotEmpty) {
          Get.back(result: code);
        } else {
          ToastUtil.showError("Không tìm thấy mã QR", "Vui lòng chọn ảnh chứa mã QR rõ ràng hơn.");
        }
      } else {
        ToastUtil.showError("Không tìm thấy mã QR", "Vui lòng chọn ảnh chứa mã QR rõ ràng hơn.");
      }
    } catch (e) {
      debugPrint('[QRScanner] Error scanning from gallery: $e');
      ToastUtil.showError("Lỗi quét ảnh", "Đã xảy ra lỗi khi quét mã QR từ ảnh.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double cutoutSize = screenWidth * 0.7;
    final double left = (screenWidth - cutoutSize) / 2;
    final double top = (screenHeight - cutoutSize) / 4;
    final Rect cutoutRect = Rect.fromLTWH(left, top, cutoutSize, cutoutSize);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onScaleStart: (details) {
          _baseScale = _zoomScale;
        },
        onScaleUpdate: (details) {
          double newScale = _baseScale + (details.scale - 1.0) * 0.2;
          newScale = newScale.clamp(0.0, 1.0);
          setState(() {
            _zoomScale = newScale;
          });
          _scannerController.setZoomScale(newScale);
        },
        child: Stack(
          children: [
            // 1. MobileScanner Preview
            Positioned.fill(
              child: MobileScanner(
                controller: _scannerController,
                onDetect: _onDetect,
              ),
            ),

            // 2. Semi-transparent overlay with cutout and corner borders
            Positioned.fill(
              child: CustomPaint(
                painter: ScannerOverlayPainter(cutoutRect: cutoutRect),
              ),
            ),

            // 3. Animated scanning line inside the cutout
            Positioned(
              top: cutoutRect.top + (cutoutRect.height * _animation.value),
              left: cutoutRect.left + 8,
              width: cutoutRect.width - 16,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.0),
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.8),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ],
                ),
              ),
            ),

            // 4. Instructions below cutout
            Positioned(
              top: cutoutRect.bottom + 24,
              left: 32,
              right: 32,
              child: const Text(
                "Đặt mã QR vào trong khung để quét",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 4),
                  ],
                ),
              ),
            ),

            // 5. App Bar (Back Button)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black38,
                      padding: const EdgeInsets.all(10),
                    ),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Quét mã QR",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 6. Zoom Slider Control
            Positioned(
              bottom: 128,
              left: 32,
              right: 32,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.zoom_out, color: Colors.white70, size: 20),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: Colors.white30,
                          thumbColor: Colors.white,
                          overlayColor: AppColors.primary.withValues(alpha: 0.2),
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        ),
                        child: Slider(
                          value: _zoomScale,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (val) {
                            setState(() {
                              _zoomScale = val;
                            });
                            _scannerController.setZoomScale(val);
                          },
                        ),
                      ),
                    ),
                    const Icon(Icons.zoom_in, color: Colors.white70, size: 20),
                  ],
                ),
              ),
            ),

            // 7. Bottom Actions Control Bar (Torch, Gallery, Switch Camera)
            Positioned(
              bottom: 40 + MediaQuery.of(context).padding.bottom,
              left: 40,
              right: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Flashlight
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black38,
                      padding: const EdgeInsets.all(12),
                    ),
                    icon: Icon(
                      _isTorchOn ? Icons.flash_on : Icons.flash_off,
                      color: _isTorchOn ? Colors.yellow : Colors.white,
                      size: 26,
                    ),
                    onPressed: () async {
                      await _scannerController.toggleTorch();
                      setState(() {
                        _isTorchOn = !_isTorchOn;
                      });
                    },
                  ),

                  // Pick Image Gallery
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.all(16),
                    ),
                    icon: const Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: _scanFromGallery,
                  ),

                  // Switch Camera
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black38,
                      padding: const EdgeInsets.all(12),
                    ),
                    icon: const Icon(
                      Icons.flip_camera_ios_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: () async {
                      await _scannerController.switchCamera();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Rect cutoutRect;
  ScannerOverlayPainter({required this.cutoutRect});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()..color = Colors.black.withValues(alpha: 0.5);

    // Draw overlay background with transparent cutout hole
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(RRect.fromRectAndRadius(cutoutRect, const Radius.circular(16))),
      ),
      backgroundPaint,
    );

    // Draw 4 corner borders around the cutout
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final double borderLength = 24.0;
    final double radius = 16.0;

    // Top Left corner
    canvas.drawPath(
      Path()
        ..moveTo(cutoutRect.left, cutoutRect.top + borderLength)
        ..lineTo(cutoutRect.left, cutoutRect.top + radius)
        ..arcToPoint(Offset(cutoutRect.left + radius, cutoutRect.top), radius: Radius.circular(radius))
        ..lineTo(cutoutRect.left + borderLength, cutoutRect.top),
      borderPaint,
    );

    // Top Right corner
    canvas.drawPath(
      Path()
        ..moveTo(cutoutRect.right - borderLength, cutoutRect.top)
        ..lineTo(cutoutRect.right - radius, cutoutRect.top)
        ..arcToPoint(Offset(cutoutRect.right, cutoutRect.top + radius), radius: Radius.circular(radius))
        ..lineTo(cutoutRect.right, cutoutRect.top + borderLength),
      borderPaint,
    );

    // Bottom Left corner
    canvas.drawPath(
      Path()
        ..moveTo(cutoutRect.left, cutoutRect.bottom - borderLength)
        ..lineTo(cutoutRect.left, cutoutRect.bottom - radius)
        ..arcToPoint(Offset(cutoutRect.left + radius, cutoutRect.bottom), radius: Radius.circular(radius))
        ..lineTo(cutoutRect.left + borderLength, cutoutRect.bottom),
      borderPaint,
    );

    // Bottom Right corner
    canvas.drawPath(
      Path()
        ..moveTo(cutoutRect.right - borderLength, cutoutRect.bottom)
        ..lineTo(cutoutRect.right - radius, cutoutRect.bottom)
        ..arcToPoint(Offset(cutoutRect.right, cutoutRect.bottom - radius), radius: Radius.circular(radius))
        ..lineTo(cutoutRect.right, cutoutRect.bottom - borderLength),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
