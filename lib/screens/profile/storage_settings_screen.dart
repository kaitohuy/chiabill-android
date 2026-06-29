import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
          "cache_cleaned_title".tr,
          "cache_cleaned_msg".tr,
        );
      } else {
        ToastUtil.showError(
          "clear_failed_title".tr,
          "clear_failed_msg".tr,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("storage_title".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ]
              ),
              child: Column(
                children: [
                  Text(
                    "cache_size_label".tr,
                    style: const TextStyle(
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
                    "cache_size_desc".tr,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                      _isClearing ? "clearing_status".tr : "clear_now_caps".tr,
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
            Text(
              "auto_clean_config".tr,
              style: const TextStyle(
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "auto_clean_period".tr,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentSchedule == 'daily'
                                    ? "clean_daily_rec".tr
                                    : _currentSchedule == 'weekly'
                                        ? "clean_weekly_def".tr
                                        : "clean_off".tr,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _currentSchedule,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down),
                          isDense: true,
                          alignment: Alignment.centerRight,
                          items: [
                            DropdownMenuItem(value: 'daily', child: Text("clean_daily".tr)),
                            DropdownMenuItem(value: 'weekly', child: Text("clean_weekly".tr)),
                            DropdownMenuItem(value: 'off', child: Text("clean_turn_off".tr)),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              StorageUtil.setCleanSchedule(val);
                              setState(() => _currentSchedule = val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // 2. Giới hạn dung lượng cache tối đa
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.pie_chart_outline, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "max_limit_label".tr,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentMaxSize > 0
                                    ? "max_limit_desc".trParams({'size': _currentMaxSize.toString()})
                                    : "no_limit".tr,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: _currentMaxSize,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down),
                          isDense: true,
                          alignment: Alignment.centerRight,
                          items: [
                            const DropdownMenuItem(value: 20, child: Text("20 MB")),
                            const DropdownMenuItem(value: 50, child: Text("50 MB")),
                            const DropdownMenuItem(value: 100, child: Text("100 MB")),
                            DropdownMenuItem(value: 0, child: Text("no_limit_short".tr)),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              StorageUtil.setMaxCacheSize(val);
                              setState(() => _currentMaxSize = val);
                              _loadCacheSize(); // Reload size to check against limit
                            }
                          },
                        ),
                      ],
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "privacy_data_info".tr,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "privacy_data_desc".tr,
                          style: const TextStyle(
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
