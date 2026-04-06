import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/auth_controller.dart';
import '../auth/welcome_screen.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final AuthController authController = Get.put(AuthController());
  final ProfileController controller = Get.put(ProfileController());

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
              child: Image.network(imageUrl, fit: BoxFit.contain, width: double.infinity, height: double.infinity),
            ),
            Positioned(
              top: 40, right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Get.back(),
              ),
            ),
          ],
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
          title: const Text("Hồ sơ cá nhân", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.lightGreen[800],
          elevation: 0,
          centerTitle: true,
        ),
        body: Obx(() {
          if (controller.isLoading.value && controller.user.value == null) {
            return const Center(child: CircularProgressIndicator(color: Colors.lightGreen));
          }

          final user = controller.user.value;
          final avatarUrl = controller.currentAvatarUrl.value;
          final qrUrl = controller.currentQrUrl.value;

          // THÊM REFRESH INDICATOR Ở ĐÂY
          return RefreshIndicator(
            color: Colors.orange,
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
                          backgroundColor: Colors.lightGreen[100],
                          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                          child: avatarUrl == null ? const Icon(Icons.person, size: 60, color: Colors.lightGreen) : null,
                        ),
                      ),
                      GestureDetector(
                        onTap: controller.isUploading.value ? null : () => controller.pickAndUploadImage('avatar'),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
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
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      if (controller.isUploading.value)
                        const Positioned.fill(child: CircularProgressIndicator(color: Colors.orange, strokeWidth: 4)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(user?.email ?? "", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 32),

                  // ==========================================
                  // 2. THÔNG TIN CƠ BẢN
                  // ==========================================
                  TextField(
                    controller: controller.nameController,
                    decoration: InputDecoration(
                      labelText: "Tên hiển thị",
                      prefixIcon: const Icon(Icons.badge, color: Colors.lightGreen),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true, fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ô nhập SĐT
                  TextField(
                    controller: controller.phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "Số điện thoại",
                      prefixIcon: const Icon(Icons.phone, color: Colors.lightGreen),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true, fillColor: Colors.white,
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
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(Icons.privacy_tip, color: Colors.orange),
                              SizedBox(width: 8),
                              Text("Quyền riêng tư", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Obx(() => SwitchListTile(
                          activeThumbColor: Colors.green,
                          title: const Text("Cho phép thêm tự động", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: const Text("Người khác có thể thêm bạn trực tiếp vào nhóm qua SĐT/Email mà không cần gửi link.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          value: controller.allowAutoAdd.value,
                          onChanged: (val) => controller.toggleAutoAdd(val),
                        )),
                        const Divider(height: 1),
                        Obx(() => SwitchListTile(
                          activeThumbColor: Colors.green,
                          title: const Text("Tự động duyệt nhận tiền", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: const Text("Tự động đánh dấu Đã nhận (APPROVED) khi có người báo cáo chuyển khoản cho bạn.", style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(Icons.account_balance_wallet, color: Colors.orange),
                              SizedBox(width: 8),
                              Text("Cài đặt nhận tiền", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // TAB 1: VIETQR
                        Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            initiallyExpanded: controller.isVietQrExpanded.value,
                            title: const Text("1. Nhập STK Ngân hàng (VietQR)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: const Text("Tự động điền số tiền khi người khác quét", style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                                            labelText: "Mã ngân hàng (Gõ để tìm...)",
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            isDense: true,
                                            suffixIcon: const Icon(Icons.search, size: 20),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(controller: controller.accountNoController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Số tài khoản", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true)),
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
                                            label: const Text("Xóa data", style: TextStyle(color: Colors.red))
                                        ),
                                        Obx(() => controller.paymentPriority.value == 1
                                            ? Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                                          child: const Text("✓ Đang là mặc định", style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold)),
                                        )
                                            : OutlinedButton(
                                          onPressed: () => controller.setAsDefault(1),
                                          style: OutlinedButton.styleFrom(foregroundColor: Colors.green, side: const BorderSide(color: Colors.green)),
                                          child: const Text("Đặt làm mặc định"),
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
                            title: const Text("2. Tải ảnh QR tĩnh", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: const Text("Dùng nếu bạn không có Số tài khoản chính chủ", style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                                                border: Border.all(color: Colors.lightGreen),
                                                borderRadius: BorderRadius.circular(12),
                                                image: DecorationImage(image: NetworkImage(qrUrl), fit: BoxFit.cover),
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
                                          label: Text((qrUrl == null || qrUrl.isEmpty) ? "Tải ảnh từ máy" : "Đổi ảnh"),
                                          style: OutlinedButton.styleFrom(foregroundColor: Colors.orange, side: const BorderSide(color: Colors.orange), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                        ),
                                        const SizedBox(width: 12),
                                        Obx(() => controller.paymentPriority.value == 2
                                            ? Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                                          child: const Text("✓ Đang mặc định", style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold)),
                                        )
                                            : OutlinedButton(
                                          onPressed: () => controller.setAsDefault(2),
                                          style: OutlinedButton.styleFrom(foregroundColor: Colors.green, side: const BorderSide(color: Colors.green), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                          child: const Text("Đặt mặc định"),
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
                  // 4. CÁC NÚT BẤM
                  // ==========================================
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.lightGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: (controller.isLoading.value || controller.isUploading.value) ? null : () => controller.saveProfile(),
                      child: controller.isLoading.value ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text("LƯU THAY ĐỔI", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Obx(() => OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: Colors.grey)),
                    icon: authController.isLoading.value ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png', width: 20, errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, color: Colors.blue, size: 28)),
                    label: const Text("LIÊN KẾT TÀI KHOẢN GOOGLE", style: TextStyle(color: Colors.black87)),
                    onPressed: authController.isLoading.value ? null : () => authController.loginWithGoogle(),
                  )),

                  const SizedBox(height: 24),
                  const Divider(),

                  // ==========================================
                  // 5. ĐĂNG XUẤT (SỬA LẠI CHỖ NÀY)
                  // ==========================================
                  TextButton.icon(
                    onPressed: () => authController.logout(), // CHỈ CẦN GỌI HÀM NÀY
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text("Đăng xuất", style: TextStyle(color: Colors.red)),
                  )
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}