import 'package:chiabill/theme/app_colors.dart';
import 'package:chiabill/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final TextEditingController _reportController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
  }

  void _sendReport() {
    String text = _reportController.text.trim();
    if (text.isEmpty) {
      ToastUtil.showWarning("Lỗi", "Vui lòng nhập nội dung báo cáo!");
      return;
    }

    setState(() => _isSending = true);
    
    // Giả lập gửi báo cáo lên server
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isSending = false);
        _reportController.clear();
        
        // Show thank you dialog
        Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.favorite, color: Colors.red),
                const SizedBox(width: 8),
                const Text("Cảm ơn bạn!", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              "Ý kiến đóng góp của bạn đã được gửi tới đội ngũ phát triển. Sự phản hồi của bạn chính là động lực lớn nhất để Chiabill ngày càng hoàn thiện hơn!",
              style: TextStyle(fontSize: 15),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Get.back(),
                child: const Text("Đồng ý"),
              )
            ],
          ),
        );
      }
    });
  }

  void _handleDonate() {
    Get.back(); // Quay lại trang cá nhân
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Donate (Ủng hộ)", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: const Text(
          "Hiện tại số user chưa nhiều, tôi có thể tự mình chi trả chi phí cho các anh chị em, sau này khi cộng đồng lớn mạnh, tôi sẽ mở lại chức năng này hẹ hẹ.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
              onPressed: () => Get.back(),
              child: const Text("Cảm ơn nhé! 💖", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Về Chiabill", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LOGO & VERSION
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 50),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Chiabill",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Phiên bản 1.0.0 (Production Ready)",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // TÍNH NĂNG NỔI BẬT
            _buildSectionHeader("Tính năng nổi bật"),
            _buildInfoCard([
              _buildBulletItem(Icons.bolt, "Chia tiền thông minh", "Tự động phân bổ, quyết toán chính xác đến từng đồng lẻ."),
              _buildBulletItem(Icons.cloud_off, "Đồng bộ ngoại tuyến", "Tạo, sửa chi phí, chuyến đi ngay cả khi mất mạng. Tự động sync khi online."),
              _buildBulletItem(Icons.qr_code, "Mã QR thanh toán nhanh", "Tự động tạo mã QR đi kèm số tiền và nội dung chuyển khoản tiện lợi."),
            ]),
            const SizedBox(height: 20),

            // BẢO MẬT & QUYỀN RIÊNG TƯ
            _buildSectionHeader("Bảo mật & Quyền riêng tư"),
            _buildInfoCard([
              _buildBulletItem(Icons.security, "Mã hóa dữ liệu", "Mọi thông tin tài khoản, ngân hàng được bảo mật chuẩn mã hóa đường truyền SSL."),
              _buildBulletItem(Icons.visibility_off, "Cam kết riêng tư", "Chiabill không thu thập vị trí hoặc bán dữ liệu người dùng cho bên thứ ba."),
            ]),
            const SizedBox(height: 20),

            // THƯ VIỆN & CÔNG NGHỆ
            _buildSectionHeader("Công nghệ & Thư viện sử dụng"),
            _buildInfoCard([
              _buildBulletItem(Icons.code, "Nền tảng Flutter", "Xây dựng trên nền tảng UI đa nền tảng tối tân của Google."),
              _buildBulletItem(Icons.layers, "State Management", "Sử dụng GetX giúp ứng dụng phản hồi mượt mà, quản lý bộ nhớ RAM tối ưu."),
              _buildBulletItem(Icons.swap_horiz, "API & Caching", "Sử dụng Dio & GetStorage đảm bảo tốc độ gọi API tối đa và lưu cache offline mượt mà."),
            ]),
            const SizedBox(height: 24),

            // PHẦN GỬI REPORT
            _buildSectionHeader("Báo cáo lỗi & Góp ý"),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Nếu gặp lỗi hoặc có ý tưởng muốn đóng góp, bạn hãy gửi phản hồi trực tiếp cho nhà phát triển nhé!",
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reportController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: "Mô tả lỗi hoặc đóng góp ý kiến của bạn...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _isSending ? null : _sendReport,
                      icon: _isSending 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send, size: 18),
                      label: Text(_isSending ? "Đang gửi..." : "GỬI REPORT", style: const TextStyle(fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // NÚT CHỨC NĂNG CUỐI TRANG
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Get.back(),
                    child: const Text("ĐÃ RÕ", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    onPressed: _handleDonate,
                    child: const Text("DONATE 💖", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildBulletItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
