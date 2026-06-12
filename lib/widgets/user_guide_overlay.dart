import 'package:chiabill/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GuideTarget {
  final GlobalKey key;
  final String title;
  final String description;
  final bool isCircle;

  GuideTarget({
    required this.key,
    required this.title,
    required this.description,
    this.isCircle = true,
  });
}

class UserGuideOverlay extends StatefulWidget {
  final List<GuideTarget> targets;
  final VoidCallback onCompleted;
  final VoidCallback onDismissed;
  final ValueChanged<int>? onStepChanged;

  const UserGuideOverlay({
    super.key,
    required this.targets,
    required this.onCompleted,
    required this.onDismissed,
    this.onStepChanged,
  });

  static void show(
    BuildContext context, {
    required List<GuideTarget> targets,
    required VoidCallback onCompleted,
    required VoidCallback onDismissed,
    ValueChanged<int>? onStepChanged,
  }) {
    if (targets.isEmpty) {
      onCompleted();
      return;
    }
    
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => UserGuideOverlay(
        targets: targets,
        onCompleted: () {
          overlayEntry.remove();
          onCompleted();
        },
        onDismissed: () {
          overlayEntry.remove();
          onDismissed();
        },
        onStepChanged: onStepChanged,
      ),
    );
    Overlay.of(context).insert(overlayEntry);
  }

  @override
  State<UserGuideOverlay> createState() => _UserGuideOverlayState();
}

class _UserGuideOverlayState extends State<UserGuideOverlay> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= widget.targets.length) {
      return const SizedBox.shrink();
    }

    final target = widget.targets[_currentIndex];
    
    // Tìm RenderBox của widget mục tiêu
    RenderBox? renderBox;
    try {
      if (target.key.currentContext != null) {
        renderBox = target.key.currentContext!.findRenderObject() as RenderBox?;
      }
    } catch (_) {}

    Rect? rect;
    if (renderBox != null && renderBox.hasSize) {
      final offset = renderBox.localToGlobal(Offset.zero);
      rect = offset & renderBox.size;
    }

    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    // Tính toán vị trí Tooltip Box
    double tooltipWidth = screenWidth * 0.82;
    if (tooltipWidth > 320) tooltipWidth = 320;
    
    bool showBelow = true;
    if (rect != null) {
      showBelow = rect.center.dy < screenHeight * 0.5;
    }

    double leftPos = screenWidth * 0.09;
    if (rect != null) {
      leftPos = rect.center.dx - (tooltipWidth / 2);
      leftPos = leftPos.clamp(16.0, screenWidth - tooltipWidth - 16.0);
    } else {
      leftPos = (screenWidth - tooltipWidth) / 2;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Lớp nền tối mờ có đục lỗ
          GestureDetector(
            onTap: () {}, // Tránh tương tác với bên dưới
            child: rect != null
                ? ClipPath(
                    clipper: HoleClipper(rect: rect, isCircle: target.isCircle),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                  )
                : Container(
                    color: Colors.black.withValues(alpha: 0.7),
                  ),
          ),

          // Vòng phát sáng nếu tìm thấy vị trí mục tiêu
          if (rect != null)
            GlowRing(
              rect: rect,
              isCircle: target.isCircle,
            ),

          // Tooltip Card giải thích
          Positioned(
            left: leftPos,
            width: tooltipWidth,
            top: rect != null
                ? (showBelow ? rect.bottom + 16 : null)
                : (screenHeight - 180) / 2,
            bottom: rect != null
                ? (showBelow ? null : (screenHeight - rect.top) + 16)
                : null,
            child: Card(
              elevation: 12,
              shadowColor: Colors.black45,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tiêu đề & Bước hiện tại
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            target.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBackground,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "${_currentIndex + 1}/${widget.targets.length}",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    
                    // Mô tả chi tiết
                    Text(
                      target.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Thanh tiến trình nhỏ ở dưới
                    Row(
                      children: List.generate(widget.targets.length, (index) {
                        final isActive = index == _currentIndex;
                        return Expanded(
                          child: Container(
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.primary : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    // Hàng các nút bấm hành động
                    Row(
                      children: [
                        // Nút bỏ qua
                        TextButton(
                          onPressed: widget.onDismissed,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade500,
                          ),
                          child: const Text(
                            "Bỏ qua",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Spacer(),
                        // Nút quay lại (nếu không phải bước đầu)
                        if (_currentIndex > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _currentIndex--;
                                });
                                if (widget.onStepChanged != null) {
                                  widget.onStepChanged!(_currentIndex);
                                  Future.delayed(const Duration(milliseconds: 350), () {
                                    if (mounted) setState(() {});
                                  });
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                minimumSize: const Size(0, 34),
                              ),
                              child: Text(
                                "Trước",
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        // Nút Tiếp theo / Hoàn thành
                        ElevatedButton(
                          onPressed: () {
                            if (_currentIndex < widget.targets.length - 1) {
                              setState(() {
                                _currentIndex++;
                              });
                              if (widget.onStepChanged != null) {
                                widget.onStepChanged!(_currentIndex);
                                Future.delayed(const Duration(milliseconds: 350), () {
                                  if (mounted) setState(() {});
                                });
                              }
                            } else {
                              widget.onCompleted();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: const Size(0, 34),
                            elevation: 0,
                          ),
                          child: Text(
                            _currentIndex == widget.targets.length - 1 ? "Hoàn thành" : "Tiếp theo",
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate(key: ValueKey(_currentIndex))
                .fadeIn(duration: 250.ms)
                .slideY(
                  begin: showBelow ? 0.12 : -0.12,
                  end: 0.0,
                  duration: 250.ms,
                  curve: Curves.easeOutQuad,
                ),
          ),
        ],
      ),
    );
  }
}

class HoleClipper extends CustomClipper<Path> {
  final Rect rect;
  final bool isCircle;

  HoleClipper({required this.rect, required this.isCircle});

  @override
  Path getClip(Size size) {
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final holePath = Path();
    if (isCircle) {
      final radius = (rect.width > rect.height ? rect.width : rect.height) / 2 + 8;
      holePath.addOval(Rect.fromCircle(center: rect.center, radius: radius));
    } else {
      holePath.addRRect(RRect.fromRectAndRadius(
        rect.inflate(8),
        const Radius.circular(12),
      ));
    }
    
    return Path.combine(PathOperation.difference, path, holePath);
  }

  @override
  bool shouldReclip(covariant HoleClipper oldClipper) {
    return oldClipper.rect != rect || oldClipper.isCircle != isCircle;
  }
}

class GlowRing extends StatefulWidget {
  final Rect rect;
  final bool isCircle;

  const GlowRing({super.key, required this.rect, required this.isCircle});

  @override
  State<GlowRing> createState() => _GlowRingState();
}

class _GlowRingState extends State<GlowRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + _controller.value * 0.22;
        final opacity = 1.0 - _controller.value;
        final paddedRect = widget.rect.inflate(8);

        return Positioned(
          left: paddedRect.left - (paddedRect.width * (scale - 1) / 2),
          top: paddedRect.top - (paddedRect.height * (scale - 1) / 2),
          width: paddedRect.width * scale,
          height: paddedRect.height * scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 3.5),
                shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: widget.isCircle ? null : BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }
}
