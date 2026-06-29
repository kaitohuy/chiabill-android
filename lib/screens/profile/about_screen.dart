import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chiabill/theme/app_colors.dart';
import 'package:chiabill/utils/toast_util.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../data/network/api_service.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("about_app_title".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      final version = snapshot.hasData
                          ? "${snapshot.data!.version} (Build ${snapshot.data!.buildNumber})"
                          : "1.0.0";
                      return Text(
                        "version_label".trParams({'version': version}),
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // BẢO MẬT & QUYỀN RIÊNG TƯ
            _buildSectionHeader("security_privacy_section".tr),
            _buildInfoCard([
              _buildBulletItem(Icons.security, "data_encryption_title".tr, "data_encryption_desc".tr),
              _buildBulletItem(Icons.visibility_off, "privacy_commitment_title".tr, "privacy_commitment_desc".tr),
              const Divider(height: 20, thickness: 1),
              InkWell(
                onTap: () async {
                  final String baseUrl = ApiService().dio.options.baseUrl;
                  final Uri url = Uri.parse("$baseUrl/privacy-policy");
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    ToastUtil.showError("error_title".tr, "cannot_open_policy".tr);
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
                            Text("read_privacy_policy".tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue)),
                            const SizedBox(height: 2),
                            Text("privacy_policy_desc".tr, style: const TextStyle(fontSize: 12, color: Colors.black54)),
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
            _buildSectionHeader("key_features_section".tr),
            _buildInfoCard([
              _buildBulletItem(Icons.bolt, "smart_split_title".tr, "smart_split_desc".tr),
              _buildBulletItem(Icons.cloud_off, "offline_sync_title".tr, "offline_sync_desc".tr),
              _buildBulletItem(Icons.qr_code, "quick_qr_title".tr, "quick_qr_desc".tr),
              _buildBulletItem(Icons.group, "flexible_group_title".tr, "flexible_group_desc".tr),
              _buildBulletItem(Icons.analytics, "visual_stats_title".tr, "visual_stats_desc".tr),
              _buildBulletItem(Icons.notifications_active, "realtime_notif_title".tr, "realtime_notif_desc".tr),
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
                child: Text("got_it_caps".tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
