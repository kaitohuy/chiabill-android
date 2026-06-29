import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../data/models/announcement_response.dart';
import '../controllers/announcement_controller.dart';
import '../theme/app_colors.dart';

// =====================================================
// WIDGET: AnnouncementDialog (entry point)
// =====================================================
class AnnouncementDialog extends StatelessWidget {
  final AnnouncementResponse announcement;

  const AnnouncementDialog({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: _AnnouncementDialogContent(announcement: announcement),
    );
  }
}

// =====================================================
// WIDGET: _AnnouncementDialogContent (nội dung chính)
// =====================================================
class _AnnouncementDialogContent extends StatelessWidget {
  final AnnouncementResponse announcement;

  const _AnnouncementDialogContent({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final config = _AnnouncementTypeConfig.from(announcement.type);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        maxWidth: 500, // Đảm bảo giao diện cân đối trên màn hình lớn/tablet
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: config.primaryColor.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(config),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (announcement.imageUrl != null) _buildBannerImage(),
                    _buildBody(),
                    if (announcement.isDonate || announcement.isPayment)
                      _buildPaymentSection(context, config),
                    _buildActions(context, config),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== HEADER với màu nền nhạt phù hợp từng loại =====
  Widget _buildHeader(_AnnouncementTypeConfig config) {
    return Container(
      width: double.infinity,
      color: config.backgroundColor,
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: config.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: config.primaryColor.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Icon(config.icon, color: config.primaryColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: config.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    config.label,
                    style: TextStyle(
                      color: config.primaryColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  announcement.title,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          if (announcement.isDismissible)
            IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.close_rounded, color: Colors.black54, size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              splashRadius: 20,
            ),
        ],
      ),
    );
  }

  // ===== BANNER IMAGE dạng thẻ cao cấp =====
  Widget _buildBannerImage() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              announcement.imageUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[100],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  // ===== BODY CHỮ CHÍNH =====
  Widget _buildBody() {
    if (announcement.content == null || announcement.content!.isEmpty) {
      return const SizedBox(height: 12);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Text(
        announcement.content!,
        style: const TextStyle(
          fontSize: 14.5,
          color: Color(0xFF374151), // màu sẫm sang trọng hơn xám nhạt
          height: 1.6,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  // ===== PAYMENT / DONATE SECTION =====
  Widget _buildPaymentSection(BuildContext context, _AnnouncementTypeConfig config) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.primaryColor.withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        children: [
          if (announcement.qrImageUrl != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: config.primaryColor.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: config.primaryColor.withValues(alpha: 0.1), width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  announcement.qrImageUrl!,
                  width: 170,
                  height: 170,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      width: 170,
                      height: 170,
                      color: Colors.grey[50],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.qr_code_2_rounded,
                    size: 140,
                    color: config.primaryColor.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_scanner_rounded, size: 14, color: config.primaryColor),
                const SizedBox(width: 4),
                Text(
                  'scan_qr_transfer'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: config.primaryColor.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: config.primaryColor.withValues(alpha: 0.1), height: 1, thickness: 1),
          ],
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (announcement.suggestedAmount != null)
                  _buildInfoRow(
                    icon: Icons.savings_rounded,
                    label: 'suggested_amount'.tr,
                    value: announcement.formattedAmount,
                    highlight: true,
                    config: config,
                    context: context,
                  ),
                if (announcement.bankInfo != null) ...[
                  if (announcement.suggestedAmount != null) const SizedBox(height: 12),
                  _buildBankInfoRows(announcement.bankInfo!, config, context),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankInfoRows(String bankInfoJson, _AnnouncementTypeConfig config, BuildContext context) {
    try {
      final Map<String, dynamic> info = Map<String, dynamic>.from(jsonDecode(bankInfoJson) as Map);
      return Column(
        children: [
          if (info['bank'] != null)
            _buildInfoRow(
              icon: Icons.account_balance_rounded,
              label: 'bank_label'.tr,
              value: info['bank'].toString(),
              config: config,
              context: context,
            ),
          if (info['account'] != null) ...[
            const SizedBox(height: 10),
            _buildInfoRow(
              icon: Icons.credit_card_rounded,
              label: 'account_number_label'.tr,
              value: info['account'].toString(),
              copyable: true,
              config: config,
              context: context,
            ),
          ],
          if (info['name'] != null) ...[
            const SizedBox(height: 10),
            _buildInfoRow(
              icon: Icons.person_rounded,
              label: 'account_owner_label'.tr,
              value: info['name'].toString().toUpperCase(),
              config: config,
              context: context,
            ),
          ],
        ],
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
    bool copyable = false,
    required _AnnouncementTypeConfig config,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? config.primaryColor.withValues(alpha: 0.25) : Colors.grey.withValues(alpha: 0.1),
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (highlight ? config.primaryColor : Colors.grey[400]!).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: highlight ? config.primaryColor : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: highlight ? 15 : 13.5,
                    fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                    color: highlight ? config.primaryColor : const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
          if (copyable)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  Get.closeAllSnackbars();
                  Get.snackbar(
                    'success'.tr,
                    'copied_account_success'.tr,
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: config.primaryColor,
                    colorText: Colors.white,
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                    margin: const EdgeInsets.all(15),
                    duration: const Duration(seconds: 2),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: config.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded, size: 13, color: config.primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'btn_copy'.tr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: config.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===== ACTION BUTTONS với màu cân xứng hoàn hảo =====
  Widget _buildActions(BuildContext context, _AnnouncementTypeConfig config) {
    final controller = Get.find<AnnouncementController>();
    final hasAction = announcement.actionType != null &&
        announcement.actionType != 'NONE' &&
        announcement.actionType != 'DISMISS';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Row(
        children: [
          if (announcement.isDismissible && hasAction) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey[300]!, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'btn_skip'.tr,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: hasAction ? 2 : 1,
            child: ElevatedButton(
              onPressed: () => controller.handleAction(announcement),
              style: ElevatedButton.styleFrom(
                backgroundColor: config.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                announcement.actionLabel ?? _defaultActionLabel(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _defaultActionLabel() {
    if (announcement.isUpdate) return 'btn_update_now'.tr;
    if (announcement.isDonate) return 'btn_supported'.tr;
    if (announcement.isPayment) return 'btn_paid'.tr;
    if (announcement.isMaintenance) return 'btn_understood'.tr;
    return 'btn_close'.tr;
  }
}

// =====================================================
// CONFIG: Màu + icon theo từng loại thông báo (Premium Gradient)
// =====================================================
class _AnnouncementTypeConfig {
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final IconData icon;
  final String label;

  const _AnnouncementTypeConfig({
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.icon,
    required this.label,
  });

  Gradient get gradient => LinearGradient(
        colors: [primaryColor, secondaryColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  factory _AnnouncementTypeConfig.from(String type) {
    switch (type) {
      case 'UPDATE':
        return _AnnouncementTypeConfig(
          primaryColor: AppColors.primary,
          secondaryColor: AppColors.primaryLight,
          backgroundColor: AppColors.primary.withValues(alpha: 0.06),
          icon: Icons.system_update_rounded,
          label: 'type_update'.tr,
        );
      case 'PAYMENT':
        return _AnnouncementTypeConfig(
          primaryColor: const Color(0xFFF2994A), // Orange/Gold
          secondaryColor: const Color(0xFFF2C94C), // Light Gold
          backgroundColor: const Color(0xFFF2994A).withValues(alpha: 0.06),
          icon: Icons.payment_rounded,
          label: 'type_payment'.tr,
        );
      case 'DONATE':
        return _AnnouncementTypeConfig(
          primaryColor: const Color(0xFFEC407A), // Rose/Pink
          secondaryColor: const Color(0xFFF06292), // Light Pink
          backgroundColor: const Color(0xFFEC407A).withValues(alpha: 0.06),
          icon: Icons.favorite_rounded,
          label: 'type_donate'.tr,
        );
      case 'PROMOTION':
        return _AnnouncementTypeConfig(
          primaryColor: const Color(0xFF9B59B6), // Amethyst Purple
          secondaryColor: const Color(0xFFBB8FCE), // Light Purple
          backgroundColor: const Color(0xFF9B59B6).withValues(alpha: 0.06),
          icon: Icons.celebration_rounded,
          label: 'type_promotion'.tr,
        );
      case 'MAINTENANCE':
        return _AnnouncementTypeConfig(
          primaryColor: const Color(0xFF78909C), // Slate Grey
          secondaryColor: const Color(0xFFB0BEC5), // Light Slate
          backgroundColor: const Color(0xFF78909C).withValues(alpha: 0.06),
          icon: Icons.build_rounded,
          label: 'type_maintenance'.tr,
        );
      case 'ANNOUNCEMENT':
      default:
        return _AnnouncementTypeConfig(
          primaryColor: const Color(0xFF2F80ED), // Blue
          secondaryColor: const Color(0xFF56CCF2), // Light Blue
          backgroundColor: const Color(0xFF2F80ED).withValues(alpha: 0.06),
          icon: Icons.campaign_rounded,
          label: 'type_announcement'.tr,
        );
    }
  }
}
