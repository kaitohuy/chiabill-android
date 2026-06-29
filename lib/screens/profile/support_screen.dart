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
      ToastUtil.showWarning("error_title".tr, "please_enter_report".tr);
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
              children: [
                const Icon(Icons.favorite, color: Colors.red),
                const SizedBox(width: 8),
                Text("thank_you_title".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              "thank_you_desc".tr,
              style: const TextStyle(fontSize: 15),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Get.back(),
                child: Text("agree_btn".tr),
              )
            ],
          ),
        );
      } else {
        ToastUtil.showError("error_title".tr, response.message ?? "cannot_send_feedback".tr);
      }
    }
  }

  void _handleDonate() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("donate_title".tr, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Text(
          "donate_desc".tr,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
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
              child: Text("donate_thanks".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
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
        ToastUtil.showError("error_title".tr, "cannot_open_link".tr);
      }
    } catch (e) {
      ToastUtil.showError("error_title".tr, "cannot_open_link_err".trParams({'error': e.toString()}));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("support_title".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
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
            _buildSectionHeader("report_bug_section".tr),
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
                    Text(
                      "report_bug_desc".tr,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reportController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: "report_hint".tr,
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
                      label: Text(_isSending ? "sending_status".tr : "send_report_caps".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    child: Text("got_it_caps".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    child: Text("donate_btn_caps".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // LIÊN HỆ NHÀ PHÁT TRIỂN
            _buildSectionHeader("contact_dev_section".tr),
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
                    Text(
                      "contact_dev_desc".tr,
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
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
