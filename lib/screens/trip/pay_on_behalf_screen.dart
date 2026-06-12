import 'package:chiabill/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../controllers/pay_on_behalf_controller.dart';
import '../../data/models/settlement_response.dart';
import '../../utils/currency_util.dart';

class PayOnBehalfScreen extends StatelessWidget {
  final int tripId;
  final List<SettlementResponse> settlements;

  const PayOnBehalfScreen({super.key, required this.tripId, required this.settlements});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PayOnBehalfController(tripId, settlements));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Thanh toán hộ", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        return Column(
          children: [
            // STEP 1: Chọn chủ nợ (người nhận tiền)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.person_pin_circle_outlined, color: AppColors.primaryDark, size: 20),
                    const SizedBox(width: 8),
                    const Text("Bước 1: Chọn chủ nợ (người nhận tiền)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ]),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showCreditorPicker(context, controller),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: controller.selectedCreditorId.value != null ? AppColors.primaryBackgroundLight : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: controller.selectedCreditorId.value != null ? AppColors.primaryLight : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.account_circle_outlined,
                            color: controller.selectedCreditorId.value != null ? AppColors.primaryDark : Colors.grey.shade400),
                          const SizedBox(width: 12),
                          Expanded(child: Text(
                            controller.selectedCreditorId.value != null
                                ? controller.selectedCreditorName
                                : "Chọn người nhận tiền...",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: controller.selectedCreditorId.value != null ? FontWeight.bold : FontWeight.normal,
                              color: controller.selectedCreditorId.value != null ? Colors.black87 : Colors.grey.shade500,
                            ),
                          )),
                          Icon(Icons.unfold_more_rounded, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // STEP 2: Chọn những người muốn trả hộ
            if (controller.selectedCreditorId.value != null) ...[
              const SizedBox(height: 8),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Icon(Icons.group_outlined, color: AppColors.primaryDark, size: 20),
                      const SizedBox(width: 8),
                      const Text("Bước 2: Chọn người cần trả hộ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ]),
                    TextButton(
                      onPressed: () {
                        bool allSelected = controller.settlementsForCreditor
                            .every((s) => s.fromUserId != null && controller.selectedFromUserIds.contains(s.fromUserId!));
                        allSelected ? controller.deselectAll() : controller.selectAll();
                      },
                      child: Text(
                        controller.settlementsForCreditor.every((s) => s.fromUserId != null && controller.selectedFromUserIds.contains(s.fromUserId!))
                            ? "Bỏ chọn tất cả" : "Chọn tất cả",
                        style: TextStyle(color: AppColors.primaryDark),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: controller.settlementsForCreditor.length,
                        itemBuilder: (context, index) {
                          final s = controller.settlementsForCreditor[index];
                          if (s.fromUserId == null) return const SizedBox.shrink();
                          final isSelected = controller.selectedFromUserIds.contains(s.fromUserId!);
                          final amountCtrl = controller.customAmounts[s.fromUserId!];

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected ? AppColors.primaryLight : Colors.grey.shade200,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => controller.toggleDebt(s.fromUserId!),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (_) => controller.toggleDebt(s.fromUserId!),
                                      activeColor: AppColors.primaryDark,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    ),
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.red.shade100,
                                      child: Text(
                                        (s.fromUserName?.isNotEmpty == true) ? s.fromUserName![0].toUpperCase() : "?",
                                        style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(s.fromUserName ?? "Ẩn danh", style: TextStyle(fontWeight: FontWeight.bold)),
                                          Text("Còn nợ: ${CurrencyUtils.formatNumber(s.amount)}đ",
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    if (isSelected && amountCtrl != null)
                                      SizedBox(
                                        width: 110,
                                        child: TextField(
                                          controller: amountCtrl,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                                          onChanged: (_) => controller.selectedFromUserIds.refresh(),
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                          decoration: InputDecoration(
                                            suffixText: "đ",
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(color: AppColors.primaryDark),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // STEP 3: QR Code
                      if (controller.selectedFromUserIds.isNotEmpty && controller.totalAmount > 0)
                        _buildQRCodeSection(controller),
                      const SizedBox(height: 100), // padding for bottom bar
                    ],
                  ),
                ),
              ),
            ] else
              Expanded(child: Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.people_alt_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("Chọn chủ nợ ở trên để xem\ndanh sách người cần trả hộ",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
                ]),
              )),
          ],
        );
      }),

      // BOTTOM: Total + Nút thanh toán (chỉ mở BottomSheet)
      bottomNavigationBar: Obx(() {
        if (controller.selectedFromUserIds.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.08), blurRadius: 12, offset: const Offset(0, -4))],
          ),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text("Tổng thanh toán", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  Text("${CurrencyUtils.formatNumber(controller.totalAmount)}đ",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
                ]
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showUploadProofBottomSheet(context, controller),
                child: Text("TÔI ĐÃ CHUYỂN TIỀN", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildQRCodeSection(PayOnBehalfController controller) {
    var toUser = controller.creditorUser;
    String? qrImageUrl;
    bool hasData = false;

    if (toUser != null) {
      int priority = toUser.paymentPriority;
      bool hasVietQr = (toUser.bankId != null && toUser.bankId!.isNotEmpty) && (toUser.accountNo != null && toUser.accountNo!.isNotEmpty);
      bool hasStaticQr = (toUser.bankQrUrl != null && toUser.bankQrUrl!.isNotEmpty);
      String addInfo = "Thanh toan ho ${controller.selectedFromUserIds.length} nguoi".replaceAll(' ', '%20');

      if (priority == 1 && hasVietQr) {
        qrImageUrl = "https://img.vietqr.io/image/${toUser.bankId}-${toUser.accountNo}-compact2.jpg?amount=${controller.totalAmount.toInt()}&addInfo=$addInfo";
        hasData = true;
      }
      else if (priority == 2 && hasStaticQr) { qrImageUrl = toUser.bankQrUrl; hasData = true; }
      else if (hasVietQr) { qrImageUrl = "https://img.vietqr.io/image/${toUser.bankId}-${toUser.accountNo}-compact2.jpg?amount=${controller.totalAmount.toInt()}&addInfo=$addInfo"; hasData = true; }
      else if (hasStaticQr) { qrImageUrl = toUser.bankQrUrl; hasData = true; }
    }

    if (!hasData || qrImageUrl == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Text("${controller.selectedCreditorName} chưa cài đặt thông tin nhận tiền.", textAlign: TextAlign.center, style: TextStyle(color: Colors.red)),
            const SizedBox(height: 4),
            const Text("Vui lòng liên hệ trực tiếp để lấy số tài khoản!", textAlign: TextAlign.center, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ]
        )
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight, width: 2),
      ),
      child: Column(
        children: [
          Text("QUÉT MÃ ĐỂ THANH TOÁN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: qrImageUrl,
              placeholder: (context, url) => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
              errorWidget: (context, url, error) => const SizedBox(height: 200, child: Center(child: Text("Lỗi tải QR", textAlign: TextAlign.center))),
            )
          ),
        ],
      ),
    );
  }

  void _showUploadProofBottomSheet(BuildContext context, PayOnBehalfController controller) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 24 + MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Obx(() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Tải ảnh minh chứng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: Icon(Icons.close), onPressed: () => Get.back()),
                ],
              ),
              const SizedBox(height: 12),
              const Text("Bạn có thể tải lên ảnh chụp màn hình giao dịch (Không bắt buộc).", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              
              // Upload Box
              GestureDetector(
                onTap: controller.pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: controller.selectedImage.value != null ? AppColors.primaryBackgroundLight : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: controller.selectedImage.value != null ? AppColors.primaryLight : Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                  child: controller.selectedImage.value != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(controller.selectedImage.value!, fit: BoxFit.contain),
                        )
                      : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text("Bấm để tải ảnh lên", style: TextStyle(color: Colors.grey.shade500)),
                        ]),
                ),
              ),
              const SizedBox(height: 24),

              // Xác nhận
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark, 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  onPressed: controller.isLoading.value ? null : () {
                    // Call API submission
                    controller.submit();
                  },
                  child: controller.isLoading.value
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("XÁC NHẬN THANH TOÁN (${CurrencyUtils.formatNumber(controller.totalAmount)}đ)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          );
        }),
      ),
      isScrollControlled: true,
    );
  }

  void _showCreditorPicker(BuildContext context, PayOnBehalfController controller) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(top: 24, bottom: 24 + MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Chọn người nhận tiền", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  InkWell(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                      child: Icon(Icons.close, size: 20, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: controller.uniqueCreditors.length,
                itemBuilder: (context, index) {
                  final s = controller.uniqueCreditors[index];
                  final isSelected = controller.selectedCreditorId.value == s.toUserId;
                  return InkWell(
                    onTap: () {
                      controller.onCreditorSelected(s.toUserId);
                      Get.back();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      color: isSelected ? AppColors.primary.withValues(alpha:0.05) : Colors.transparent,
                      child: Row(children: [
                        CircleAvatar(
                          backgroundColor: isSelected ? AppColors.primaryBackground : AppColors.primaryBackgroundLight,
                          child: Text(
                            (s.toUserName?.isNotEmpty == true) ? s.toUserName![0].toUpperCase() : "?",
                            style: TextStyle(color: isSelected ? AppColors.primaryDark : AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Text(
                          s.toUserName ?? "Ẩn danh",
                          style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500),
                        )),
                        if (isSelected) Icon(Icons.check_circle, color: AppColors.primaryDark),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}