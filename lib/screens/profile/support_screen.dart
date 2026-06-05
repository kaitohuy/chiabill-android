import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../utils/toast_util.dart';
import '../../data/repositories/feedback_repository.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _reportController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
  }

  void _sendReport() async {
    String text = _reportController.text.trim();
    if (text.isEmpty) {
      ToastUtil.showWarning("Lỗi", "Vui lòng nhập nội dung báo cáo!");
      return;
    }

    setState(() => _isSending = true);
    
    final response = await FeedbackRepository().sendFeedback(text);

    if (mounted) {
      setState(() => _isSending = false);
      if (response.success) {
        _reportController.clear();
        
        // Show thank you dialog
        Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.favorite, color: Colors.red),
                SizedBox(width: 8),
                Text("Cảm ơn bạn!", style: TextStyle(fontWeight: FontWeight.bold)),
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
      } else {
        ToastUtil.showError("Lỗi", response.message ?? "Không thể gửi phản hồi lúc này.");
      }
    }
  }

  void _handleDonate() {
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

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      final success = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!success) {
        ToastUtil.showError("Lỗi", "Không thể mở liên kết (Vui lòng cài đặt ứng dụng phù hợp)");
      }
    } catch (e) {
      ToastUtil.showError("Lỗi", "Không thể mở liên kết: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Hỗ trợ & Góp ý", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // BÁO CÁO LỖI & GÓP Ý CARD
            _buildSectionHeader("Báo cáo lỗi & Góp ý"),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), 
                side: BorderSide(color: Colors.grey.shade200)
              ),
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
            const SizedBox(height: 24),

            // NÚT CHỨC NĂNG CHÍNH
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
            const SizedBox(height: 40),

            // LIÊN HỆ NHÀ PHÁT TRIỂN
            _buildSectionHeader("Liên hệ nhà phát triển"),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), 
                side: BorderSide(color: Colors.grey.shade200)
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                child: Column(
                  children: [
                    const Text(
                      "Mọi đóng góp, hợp tác hoặc hỗ trợ khẩn cấp, vui lòng liên hệ trực tiếp với chúng tôi qua các kênh dưới đây:",
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildContactIcon(
                          icon: Icons.mail_outline, 
                          color: Colors.red, 
                          label: "Mail",
                          onTap: () => _launchURL("mailto:huynguyendoan0305@gmail.com")
                        ),
                        _buildContactIcon(
                          icon: Icons.phone_android, 
                          color: Colors.green, 
                          label: "SĐT",
                          onTap: () => _launchURL("tel:0975796204")
                        ),
                        _buildContactIcon(
                          icon: Icons.facebook, 
                          color: Colors.blue.shade800, 
                          label: "Facebook",
                          onTap: () => _launchURL("https://www.facebook.com/doanhuy0305")
                        ),
                        _buildContactIcon(
                          icon: Icons.chat_bubble_outline, 
                          color: Colors.lightBlue, 
                          label: "Zalo",
                          onTap: () => _launchURL("https://zalo.me/0975796204")
                        ),
                      ],
                    )
                  ],
                ),
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

  Widget _buildContactIcon({
    required IconData icon, 
    required Color color, 
    required String label, 
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
