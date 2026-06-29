import 'package:chiabill/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/auth_controller.dart';
import 'package:cached_network_image/cached_network_image.dart' as org_cached;
import 'theme_settings_screen.dart';
import 'about_screen.dart';
import 'support_screen.dart';
import 'storage_settings_screen.dart';
import 'user_guide_settings_screen.dart';
import 'package:get_storage/get_storage.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  AuthController get authController => Get.put(AuthController());

  // Hàm hiển thị ảnh phóng to toàn màn hình
  void _showFullScreenImage(String imageUrl) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 3,
              child: org_cached.CachedNetworkImage(
                  imageUrl: imageUrl, fit: BoxFit.contain, width: double.infinity, height: double.infinity,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
            ),
            Positioned(
              top: 40, right: 20,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Get.back(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hàm hiển thị dialog xác nhận xóa tài khoản nguy hiểm
  void _showDeleteAccountDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                  const SizedBox(width: 8),
                  Text("confirm_delete_account".tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "confirm_delete_account_msg".tr,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text("cancel_alt".tr, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Get.back();
                      controller.deleteAccount();
                    },
                    child: Text("delete_account_caps".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Chuyển đổi ngôn ngữ trực tiếp không cần dialog
  void _toggleLanguage(String lang) {
    if (Get.locale?.languageCode == lang) return;
    if (lang == 'vi') {
      Get.updateLocale(const Locale('vi', 'VN'));
      GetStorage().write('language', 'vi');
    } else {
      Get.updateLocale(const Locale('en', 'US'));
      GetStorage().write('language', 'en');
    }
    controller.saveProfile(silent: true);
  }

  // Widget toggle pill VI | EN
  Widget _buildLanguageToggle() {
    return Obx(() {
      final isEn = Get.locale?.languageCode == 'en';
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPillOption(label: 'VI', selected: !isEn, onTap: () => _toggleLanguage('vi')),
            _buildPillOption(label: 'EN', selected: isEn, onTap: () => _toggleLanguage('en')),
          ],
        ),
      );
    });
  }

  Widget _buildPillOption({required String label, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      // SỬA LỖI FLUTTER 3.22 Ở ĐÂY
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          controller.saveProfile(silent: true);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text("profile_title".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primaryDark,
          elevation: 0,
          centerTitle: true,
        ),
        body: Obx(() {
          if (controller.isLoading.value && controller.user.value == null) {
            return Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final user = controller.user.value;
          final avatarUrl = controller.currentAvatarUrl.value;
          final qrUrl = controller.currentQrUrl.value;

          // THÊM REFRESH INDICATOR Ở ĐÂY
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await controller.fetchProfile(); // Kéo xuống để tải lại data từ Server
            },
            child: SingleChildScrollView(
              // BẮT BUỘC PHẢI CÓ DÒNG NÀY ĐỂ KÉO ĐƯỢC KHI MÀN HÌNH NGẮN
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ==========================================
                  // 1. AVATAR (CÓ NÚT XÓA + PHÓNG TO)
                  // ==========================================
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      GestureDetector(
                        onTap: avatarUrl != null ? () => _showFullScreenImage(avatarUrl) : null,
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: AppColors.primaryBackground,
                          backgroundImage: avatarUrl != null ? org_cached.CachedNetworkImageProvider(avatarUrl, maxWidth: 300, maxHeight: 300) : null,
                          child: avatarUrl == null ? Icon(Icons.person, size: 60, color: AppColors.primary) : null,
                        ),
                      ),
                      GestureDetector(
                        onTap: controller.isUploading.value ? null : () => controller.pickAndUploadImage('avatar'),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                          child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                      if (avatarUrl != null)
                        Positioned(
                          top: 0, right: 0,
                          child: GestureDetector(
                            onTap: () => controller.removeImage('avatar'),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      if (controller.isUploading.value)
                        Positioned.fill(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 4)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 32),

                  // ==========================================
                  // 2. THÔNG TIN CƠ BẢN
                  // ==========================================
                  TextField(
                    controller: controller.nameController,
                    decoration: InputDecoration(
                      labelText: "display_name_label".tr,
                      prefixIcon: Icon(Icons.badge, color: AppColors.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true, fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ô nhập SĐT
                  Obx(() => TextField(
                    controller: controller.phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "phone_label".tr,
                      errorText: controller.phoneError.value,
                      prefixIcon: Icon(Icons.phone, color: AppColors.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true, fillColor: Colors.white,
                    ),
                  )),
                  const SizedBox(height: 16),
                  
                  // Ô hiển thị Email (Read-only vì liên kết Google)
                  TextField(
                    controller: TextEditingController(text: "not_linked_email".tr),
                    readOnly: true,
                    style: TextStyle(color: Colors.grey),
                    decoration: InputDecoration(
                      labelText: "email_linked_label".tr,
                      prefixIcon: Icon(Icons.email, color: Colors.grey),
                      suffixIcon: Tooltip(
                        message: "email_lock_tooltip".tr,
                        child: const Icon(Icons.lock, color: Colors.grey, size: 20),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true, fillColor: Colors.grey.shade100,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // CARD GIAO DIỆN
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade300)),
                    color: Colors.white,
                    child: ListTile(
                      leading: Icon(Icons.color_lens, color: AppColors.primary),
                      title: Text("theme_and_font".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("theme_and_font_sub".tr, style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Get.to(() => const ThemeSettingsScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CARD BỘ NHỚ & DỮ LIỆU
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade300)),
                    color: Colors.white,
                    child: ListTile(
                      leading: Icon(Icons.storage, color: AppColors.primary),
                      title: Text("storage_and_data".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("storage_and_data_sub".tr, style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Get.to(() => const StorageSettingsScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CARD HƯỚNG DẪN SỬ DỤNG
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade300)),
                    color: Colors.white,
                    child: ListTile(
                      leading: Icon(Icons.help_outline, color: AppColors.primary),
                      title: Text("user_guide".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("user_guide_sub".tr, style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Get.to(() => const UserGuideSettingsScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CARD THÙNG RÁC
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade300)),
                    color: Colors.white,
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: AppColors.primary),
                      title: Text("trash".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("trash_sub".tr, style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Get.toNamed('/trash'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CARD VỀ ỨNG DỤNG
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade300)),
                    color: Colors.white,
                    child: ListTile(
                      leading: Icon(Icons.info_outline, color: AppColors.primary),
                      title: Text("about_app".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("about_app_sub".tr, style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Get.to(() => const AboutScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CARD HỖ TRỢ
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade300)),
                    color: Colors.white,
                    child: ListTile(
                      leading: Icon(Icons.contact_support_outlined, color: AppColors.primary),
                      title: Text("support_and_feedback".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("support_and_feedback_sub".tr, style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Get.to(() => const SupportScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CARD NGÔN NGỮ
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade300)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.language, color: AppColors.primary),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("language".tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text("language_sub".tr, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          _buildLanguageToggle(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // CARD QUYỀN RIÊNG TƯ (THÊM TỰ ĐỘNG)
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade300)),
                    color: Colors.white,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(Icons.privacy_tip, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text("privacy".tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Obx(() => SwitchListTile(
                          activeThumbColor: AppColors.primary,
                          title: Text("allow_auto_add".tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text("allow_auto_add_sub".tr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          value: controller.allowAutoAdd.value,
                          onChanged: (val) => controller.toggleAutoAdd(val),
                        )),
                        const Divider(height: 1),
                        Obx(() => SwitchListTile(
                          activeThumbColor: AppColors.primary,
                          title: Text("auto_approve_payment".tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text("auto_approve_payment_sub".tr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          value: controller.allowAutoApprovePayment.value,
                          onChanged: (val) => controller.toggleAutoApprovePayment(val),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ==========================================
                  // 3. CÀI ĐẶT NHẬN TIỀN
                  // ==========================================
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade300)),
                    color: Colors.white,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(Icons.account_balance_wallet, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text("payment_settings".tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // TAB 1: VIETQR
                        Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            initiallyExpanded: controller.isVietQrExpanded.value,
                            title: Text("vietqr_tab_title".tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text("vietqr_tab_sub".tr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: Column(
                                  children: [
                                    // BỘ TÌM KIẾM NGÂN HÀNG AUTOCOMPLETE
                                    Autocomplete<String>(
                                      optionsBuilder: (TextEditingValue textEditingValue) {
                                        if (textEditingValue.text.isEmpty) {
                                          return const Iterable<String>.empty();
                                        }
                                        final List<String> vietQrBanks = ['MB', 'VCB', 'TCB', 'VPB', 'BIDV', 'CTG', 'ACB', 'TPB', 'VIB', 'HDB', 'STB', 'SHB', 'OCB'];
                                        return vietQrBanks.where((String bank) => bank.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                                      },
                                      onSelected: (String selection) {
                                        controller.bankIdController.text = selection;
                                      },
                                      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                                        if (textEditingController.text.isEmpty && controller.bankIdController.text.isNotEmpty) {
                                          textEditingController.text = controller.bankIdController.text;
                                        }
                                        textEditingController.addListener(() {
                                          controller.bankIdController.text = textEditingController.text;
                                        });

                                        return TextField(
                                          controller: textEditingController,
                                          focusNode: focusNode,
                                          decoration: InputDecoration(
                                            labelText: "bank_id_hint".tr,
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            isDense: true,
                                            suffixIcon: const Icon(Icons.search, size: 14),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(controller: controller.accountNoController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "account_no_label".tr, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true)),
                                    const SizedBox(height: 12),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        TextButton.icon(
                                            onPressed: () {
                                              controller.bankIdController.clear();
                                              controller.accountNoController.clear();
                                            },
                                            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                            label: Text("clear_data".tr, style: const TextStyle(color: Colors.red))
                                        ),
                                        Obx(() => controller.paymentPriority.value == 1
                                            ? Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(color: AppColors.primaryBackgroundLight, borderRadius: BorderRadius.circular(8)),
                                          child: Text("is_default".tr, style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                                        )
                                            : OutlinedButton(
                                          onPressed: () => controller.setAsDefault(1),
                                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: BorderSide(color: AppColors.primary)),
                                          child: Text("set_as_default".tr),
                                        )
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // TAB 2: ẢNH QR TĨNH
                        Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            initiallyExpanded: controller.isStaticQrExpanded.value,
                            title: Text("static_qr_tab_title".tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text("static_qr_tab_sub".tr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    if (qrUrl != null && qrUrl.isNotEmpty)
                                      Stack(
                                        alignment: Alignment.topRight,
                                        children: [
                                          GestureDetector(
                                            onTap: () => _showFullScreenImage(qrUrl),
                                            child: Container(
                                              width: 140, height: 140,
                                              margin: const EdgeInsets.only(bottom: 12),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: AppColors.primary),
                                                borderRadius: BorderRadius.circular(12),
                                                image: DecorationImage(image: org_cached.CachedNetworkImageProvider(qrUrl, maxWidth: 500, maxHeight: 500), fit: BoxFit.cover),
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => controller.removeImage('bank-qr'),
                                            child: Container(
                                              transform: Matrix4.translationValues(8, -8, 0),
                                              padding: const EdgeInsets.all(6),
                                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                                            ),
                                          ),
                                        ],
                                      ),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: controller.isUploading.value ? null : () => controller.pickAndUploadImage('bank-qr'),
                                          icon: const Icon(Icons.qr_code_scanner),
                                          label: Text((qrUrl == null || qrUrl.isEmpty) ? "upload_from_device".tr : "change_image".tr),
                                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: BorderSide(color: AppColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                        ),
                                        const SizedBox(width: 12),
                                        Obx(() => controller.paymentPriority.value == 2
                                            ? Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(color: AppColors.primaryBackgroundLight, borderRadius: BorderRadius.circular(8)),
                                          child: Text("is_default_alt".tr, style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                                        )
                                            : OutlinedButton(
                                          onPressed: () => controller.setAsDefault(2),
                                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: BorderSide(color: AppColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                          child: Text("set_default_alt".tr),
                                        )
                                        )
                                      ],
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
                  const SizedBox(height: 32),

                  // ==========================================
                  // 4. CÁC NÚT BẤM CHÍNH
                  // ==========================================
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: (controller.isLoading.value || controller.isUploading.value) ? null : () => controller.saveProfile(),
                      child: controller.isLoading.value ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : Text("save_changes_caps".tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Obx(() => OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: Colors.grey.shade400)),
                    icon: authController.isLoading.value ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : org_cached.CachedNetworkImage(imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png', width: 20, errorWidget: (context, url, error) => Icon(Icons.g_mobiledata, color: Colors.blue, size: 28)),
                    label: Text(user?.email != null ? "switch_google_account".tr : "link_google_account".tr, style: const TextStyle(color: Colors.black87)),
                    onPressed: authController.isLoading.value ? null : () => authController.loginWithGoogle(forceSwitch: user?.email != null),
                  )),

                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Colors.redAccent),
                      foregroundColor: Colors.redAccent,
                    ),
                    icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                    label: Text("logout_caps".tr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    onPressed: () => authController.logout(),
                  ),

                  const SizedBox(height: 24),
                  const Divider(height: 1, thickness: 1),
                  const SizedBox(height: 16),

                  // ==========================================
                  // 5. VÙNG NGUY HIỂM (XÓA TÀI KHOẢN)
                  // ==========================================
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _showDeleteAccountDialog(context),
                      icon: const Icon(Icons.delete_forever, color: Colors.grey, size: 18),
                      label: Text(
                        "delete_account".tr,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}