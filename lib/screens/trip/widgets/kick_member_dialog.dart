import 'package:flutter/material.dart';
import 'package:get/get.dart';

class KickMemberDialog extends StatelessWidget {
  final String userName;
  final Function(bool forgiveDebt) onConfirm;

  const KickMemberDialog({
    super.key,
    required this.userName,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header với Icon nổi bật
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_remove_rounded, color: Colors.red.shade400, size: 32),
            ),
            const SizedBox(height: 20),
            
            // Tiêu đề & Nội dung
            Text(
              "Xóa $userName?",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Bạn muốn xử lý các khoản nợ liên quan đến thành viên này như thế nào?",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // LỰA CHỌN 1: GIỮ NỢ
            _buildOptionTile(
              title: "Trục xuất & Giữ nợ",
              subtitle: "Lịch sử nợ vẫn được lưu lại trong danh sách quyết toán.",
              icon: Icons.shield_outlined,
              color: Colors.amber,
              onTap: () {
                Get.back();
                onConfirm(false);
              },
            ),
            const SizedBox(height: 12),

            // LỰA CHỌN 2: XÓA NỢ
            _buildOptionTile(
              title: "Trục xuất & Xóa sạch nợ",
              subtitle: "Tất cả nợ của người này sẽ được xóa trắng (về 0).",
              icon: Icons.auto_fix_high_outlined,
              color: Colors.red,
              onTap: () {
                Get.back();
                onConfirm(true);
              },
            ),
            
            const SizedBox(height: 16),
            
            // Nút Hủy
            TextButton(
              onPressed: () => Get.back(),
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text("QUAY LẠI", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.shade100, width: 1.5),
          borderRadius: BorderRadius.circular(20),
          color: color.shade50.withOpacity(0.3),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.shade100.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color.shade700, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color.shade900)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: color.shade700, height: 1.3)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.shade300),
          ],
        ),
      ),
    );
  }
}
