import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/storage_util.dart';
import '../../utils/toast_util.dart';

class StorageSettingsScreen extends StatefulWidget {
  const StorageSettingsScreen({super.key});

  @override
  State<StorageSettingsScreen> createState() => _StorageSettingsScreenState();
}

class _StorageSettingsScreenState extends State<StorageSettingsScreen> {
  double _cacheSize = 0.0;
  bool _isLoadingSize = true;
  bool _isClearing = false;

  late String _currentSchedule;
  late int _currentMaxSize;

  @override
  void initState() {
    super.initState();
    _currentSchedule = StorageUtil.getCleanSchedule();
    _currentMaxSize = StorageUtil.getMaxCacheSize();
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    setState(() => _isLoadingSize = true);
    final size = await StorageUtil.getCacheSize();
    if (mounted) {
      setState(() {
        _cacheSize = size;
        _isLoadingSize = false;
      });
    }
  }

  Future<void> _clearCache() async {
    setState(() => _isClearing = true);
    
    // Tạo micro-animation chờ 1 giây cho mượt mà chuyên nghiệp
    await Future.delayed(const Duration(milliseconds: 1000));
    
    final success = await StorageUtil.clearCache();
    final newSize = await StorageUtil.getCacheSize();
    
    if (mounted) {
      setState(() {
        _cacheSize = newSize;
        _isClearing = false;
      });
      
      if (success) {
        ToastUtil.showSuccess(
          "Đã dọn dẹp",
          "Bộ nhớ tạm đã được dọn sạch hoàn toàn!",
        );
      } else {
        ToastUtil.showError(
          "Thất bại",
          "Không thể dọn dẹp toàn bộ tệp tin tạm thời.",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Bộ nhớ & Dữ liệu", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // CARD 1: HIỂN THỊ DUNG LƯỢNG CACHE HIỆN TẠI
            // ==========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ]
              ),
              child: Column(
                children: [
                  const Text(
                    "DUNG LƯỢNG BỘ NHỚ ĐỆM",
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _isLoadingSize
                      ? const SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        )
                      : Text(
                          "${_cacheSize.toStringAsFixed(1)} MB",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  const SizedBox(height: 16),
                  Text(
                    "Bao gồm ảnh thu nhỏ, file lưu tạm và bản đồ ngoại tuyến.",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _isClearing || _isLoadingSize ? null : _clearCache,
                    icon: _isClearing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.black54, strokeWidth: 2),
                          )
                        : const Icon(Icons.cleaning_services, size: 18),
                    label: Text(
                      _isClearing ? "ĐANG DỌN DẸP..." : "DỌN DẸP NGAY",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ==========================================
            // CARD 2: THIẾT LẬP TỰ ĐỘNG DỌN DẸP
            // ==========================================
            const Text(
              "CẤU HÌNH TỰ ĐỘNG DỌN DẸP",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              color: Colors.white,
              child: Column(
                children: [
                  // 1. Tự động dọn dẹp theo thời gian
                  ListTile(
                    leading: Icon(Icons.schedule, color: AppColors.primary),
                    title: const Text("Tự động dọn dẹp định kỳ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(
                      _currentSchedule == 'daily'
                          ? "Hàng ngày (Khuyên dùng)"
                          : _currentSchedule == 'weekly'
                              ? "Hàng tuần (Mặc định)"
                              : "Đang tắt tự động dọn dẹp",
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: SizedBox(
                      width: 110,
                      child: DropdownButton<String>(
                        value: _currentSchedule,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down),
                        isDense: true,
                        alignment: Alignment.centerRight,
                        items: const [
                          DropdownMenuItem(value: 'daily', child: Text("Hàng ngày")),
                          DropdownMenuItem(value: 'weekly', child: Text("Hàng tuần")),
                          DropdownMenuItem(value: 'off', child: Text("Tắt")),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            StorageUtil.setCleanSchedule(val);
                            setState(() => _currentSchedule = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  // 2. Giới hạn dung lượng cache tối đa
                  ListTile(
                    leading: Icon(Icons.pie_chart_outline, color: AppColors.primary),
                    title: const Text("Giới hạn dung lượng tối đa", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(
                      _currentMaxSize > 0
                          ? "Tự dọn dẹp khi vượt quá $_currentMaxSize MB"
                          : "Không giới hạn dung lượng",
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: SizedBox(
                      width: 110,
                      child: DropdownButton<int>(
                        value: _currentMaxSize,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down),
                        isDense: true,
                        alignment: Alignment.centerRight,
                        items: const [
                          DropdownMenuItem(value: 20, child: Text("20 MB")),
                          DropdownMenuItem(value: 50, child: Text("50 MB")),
                          DropdownMenuItem(value: 100, child: Text("100 MB")),
                          DropdownMenuItem(value: 0, child: Text("Không giới hạn")),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            StorageUtil.setMaxCacheSize(val);
                            setState(() => _currentMaxSize = val);
                            _loadCacheSize(); // Reload size to check against limit
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ==========================================
            // HỘP GIẢI THÍCH / LỜI KHUYÊN CHO NGƯỜI DÙNG
            // ==========================================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200, width: 0.8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700, size: 22),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Thông tin quyền riêng tư & Dữ liệu",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Bộ nhớ đệm chỉ lưu trữ các tệp tạm thời như ảnh đại diện thu nhỏ và dữ liệu bản đồ để tăng tốc độ hiển thị và tiết kiệm mạng 3G/4G cho bạn.\n\nViệc dọn dẹp bộ nhớ đệm hoàn toàn KHÔNG làm mất thông tin tài khoản đăng nhập hay các dữ liệu chia hóa đơn/chuyến đi chơi của bạn.",
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
