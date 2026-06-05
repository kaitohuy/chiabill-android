import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class QuoteMarquee extends StatefulWidget {
  const QuoteMarquee({super.key});

  @override
  State<QuoteMarquee> createState() => _QuoteMarqueeState();
}

class _QuoteMarqueeState extends State<QuoteMarquee> {
  final List<String> _quotes = [
    "Chia bill đều, sẽ có chill travel!",
    "Tiền bạc phân minh, nghĩa tình bền vững!",
    "Tình bạn đẹp nhất là không phải đòi tiền nhiều lần",
    "Tiền không tự sinh ra cũng không tự mất đi, nó chỉ chuyển từ ví người này sang ví người khác!",
    "Hạnh phúc là khi đi chơi xa và tất cả các hóa đơn đều được chia đều tự động!",
    "Chia sẻ niềm vui, san sẻ gánh nặng",
    "Less math, more memories",
    "Không cần đại gia, chỉ cần bạn bè chịu chuyển khoản",
    "Chúng ta còn trẻ, còn khỏe và còn nợ nhau vài bữa",
    "Lịch sử sẽ ghi nhớ chúng ta, còn ví tiền sẽ ghi nhớ bao nhiêu",
  ];

  final TextStyle _textStyle = TextStyle(
    fontSize: 12,
    color: Colors.grey[700],
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.normal,
  );

  int _currentIndex = 0;
  late ScrollController _scrollController;
  Timer? _scrollTimer;
  bool _isScrollingActive = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _currentIndex = DateTime.now().millisecond % _quotes.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Trì hoãn 2 giây để nhường tài nguyên vẽ khung hình tĩnh đầu tiên của app mượt mà tuyệt đối
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _startScrolling();
      });
    });
  }

  double _getTextWidth(String text, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.width;
  }

  void _nextQuote() {
    if (!mounted) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _quotes.length;
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    _startScrolling();
  }

  void _startScrolling() {
    _scrollTimer?.cancel();
    if (!mounted || !_scrollController.hasClients) return;

    final textWidth = _getTextWidth(_quotes[_currentIndex], _textStyle);
    final itemWidth = 13 + 4 + textWidth; // Icon(13) + Spacing(4) + Text
    final scrollDistance = itemWidth + 80; // itemWidth + gap

    // Tính toán tốc độ cuộn tối ưu (tầm 28 pixel mỗi giây)
    final duration = Duration(milliseconds: (scrollDistance * 35).toInt());

    // Tránh chồng chéo các hiệu ứng animateTo
    _isScrollingActive = true;
    _scrollController.animateTo(
      scrollDistance,
      duration: duration,
      curve: Curves.linear,
    ).then((_) {
      if (!mounted || !_scrollController.hasClients || !_isScrollingActive) return;
      
      // Nhảy ẩn về 0 ngay lập tức (không ai nhận ra vì 2 item giống nhau hoàn toàn)
      _scrollController.jumpTo(0);
      
      // Tiếp tục cuộn liền mạch
      _startScrolling();
    });
  }

  @override
  void dispose() {
    _isScrollingActive = false;
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildItem() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.tips_and_updates_outlined,
          color: AppColors.primary,
          size: 13,
        ),
        const SizedBox(width: 4),
        Text(
          _quotes[_currentIndex],
          style: _textStyle,
          maxLines: 1,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _isScrollingActive = false;
        _nextQuote();
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 20,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(), // Vô hiệu kéo tay để giữ cuộn tự động
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildItem(),
              const SizedBox(width: 80), // Gap ngăn cách giữa 2 đầu nối
              _buildItem(),
            ],
          ),
        ),
      ),
    );
  }
}
