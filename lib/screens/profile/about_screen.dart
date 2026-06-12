import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chiabill/theme/app_colors.dart';
import 'package:chiabill/utils/toast_util.dart';
import '../../data/network/api_service.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Về DuliVie", style: TextStyle(fontWeight: FontWeight.bold)),
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
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: Image.asset(
                      'assets/images/logo_home.png',
                      width: 64,
                      height: 64,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "DuliVie",
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

            // BẢO MẬT & QUYỀN RIÊNG TƯ
            _buildSectionHeader("Bảo mật & Quyền riêng tư"),
            _buildInfoCard([
              _buildBulletItem(Icons.security, "Mã hóa dữ liệu", "Mọi thông tin tài khoản, ngân hàng được bảo mật chuẩn mã hóa đường truyền SSL."),
              _buildBulletItem(Icons.visibility_off, "Cam kết riêng tư", "DuliVie không thu thập vị trí hoặc bán dữ liệu người dùng cho bên thứ ba."),
              const Divider(height: 20, thickness: 1),
              InkWell(
                onTap: () async {
                  final String baseUrl = ApiService().dio.options.baseUrl;
                  final Uri url = Uri.parse("$baseUrl/privacy-policy");
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    ToastUtil.showError("Lỗi", "Không thể mở trang web chính sách");
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: Row(
                    children: [
                      Icon(Icons.description, color: AppColors.primary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Đọc Chính sách bảo mật", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue)),
                            const SizedBox(height: 2),
                            Text("Xem chi tiết quy định bảo vệ dữ liệu người dùng", style: TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      ),
                      const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // TÍNH NĂNG NỔI BẬT
            _buildSectionHeader("Tính năng nổi bật"),
            _buildInfoCard([
              _buildBulletItem(Icons.bolt, "Chia tiền thông minh", "Tự động phân bổ, quyết toán chính xác đến từng đồng lẻ."),
              _buildBulletItem(Icons.cloud_off, "Đồng bộ ngoại tuyến", "Tạo, sửa chi phí, chuyến đi ngay cả khi mất mạng. Tự động sync khi online."),
              _buildBulletItem(Icons.qr_code, "Mã QR thanh toán nhanh", "Tự động tạo mã QR đi kèm số tiền và nội dung chuyển khoản tiện lợi."),
              _buildBulletItem(Icons.group, "Quản lý nhóm linh hoạt", "Dễ dàng thêm thành viên, phân chia vai trò và quản lý quỹ nhóm tiện lợi."),
              _buildBulletItem(Icons.analytics, "Thống kê trực quan", "Biểu đồ phân tích chi tiêu trực quan giúp kiểm soát ngân sách hiệu quả."),
              _buildBulletItem(Icons.notifications_active, "Thông báo thời gian thực", "Nhận thông báo lập tức khi có hóa đơn mới hoặc thành viên thanh toán."),
            ]),
            const SizedBox(height: 32),

            // NÚT CHỨC NĂNG CUỐI TRANG
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                onPressed: () => Get.back(),
                child: const Text("ĐÃ RÕ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
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
