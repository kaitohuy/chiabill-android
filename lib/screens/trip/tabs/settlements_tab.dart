import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/create_payment_controller.dart';
import '../../../controllers/trip_detail_controller.dart';
import '../../../utils/currency_util.dart';
import '../create_payment_bottom_sheet.dart';

class SettlementsTab extends StatelessWidget {
  final TripDetailController controller;
  const SettlementsTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());

      if (controller.settlements.isEmpty) {
        return RefreshIndicator(
          onRefresh: () async => controller.fetchData(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 100),
              Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.handshake, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("Mọi người đang hòa tiền nhau,\nhoặc chưa có khoản chi nào!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))
                      ]
                  )
              )
            ],
          ),
        );
      }

      return RefreshIndicator(
        color: Colors.orange,
        onRefresh: () async => controller.fetchData(),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: controller.settlements.length,
          itemBuilder: (context, index) {
            final settle = controller.settlements[index];
            String fromInitial = (settle.fromUserName != null && settle.fromUserName!.trim().isNotEmpty) ? settle.fromUserName!.trim()[0].toUpperCase() : "?";
            String toInitial = (settle.toUserName != null && settle.toUserName!.trim().isNotEmpty) ? settle.toUserName!.trim()[0].toUpperCase() : "?";

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showPaymentQR(context, controller, settle),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                          child: Column(
                              children: [
                                CircleAvatar(backgroundColor: Colors.red[100], child: Text(fromInitial, style: const TextStyle(color: Colors.red))),
                                const SizedBox(height: 8),
                                Text(settle.fromUserName ?? "Ẩn danh", style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)
                              ]
                          )
                      ),
                      Expanded(
                          flex: 2,
                          child: Column(
                              children: [
                                Text("${CurrencyUtils.formatNumber(settle.amount)} đ", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.orange)),
                                const Icon(Icons.arrow_forward, color: Colors.grey),
                                const Text("Bấm để trả tiền", style: TextStyle(fontSize: 11, color: Colors.blue, decoration: TextDecoration.underline))
                              ]
                          )
                      ),
                      Expanded(
                          child: Column(
                              children: [
                                CircleAvatar(backgroundColor: Colors.green[100], child: Text(toInitial, style: const TextStyle(color: Colors.green))),
                                const SizedBox(height: 8),
                                Text(settle.toUserName ?? "Ẩn danh", style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)
                              ]
                          )
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  void _showPaymentQR(BuildContext context, TripDetailController controller, var settle) {
    var matches = controller.trip.value?.members?.where((m) => m.user.name == settle.toUserName);
    var toUser = (matches != null && matches.isNotEmpty) ? matches.first.user : null;
    String? qrImageUrl;
    bool hasData = false;

    if (toUser != null) {
      int priority = toUser.paymentPriority ?? 1;
      bool hasVietQr = (toUser.bankId != null && toUser.bankId!.isNotEmpty) && (toUser.accountNo != null && toUser.accountNo!.isNotEmpty);
      bool hasStaticQr = (toUser.bankQrUrl != null && toUser.bankQrUrl!.isNotEmpty);
      String addInfo = "${settle.fromUserName ?? 'Ban'} thanh toan".replaceAll(' ', '%20');

      if (priority == 1 && hasVietQr) {
        qrImageUrl = "https://img.vietqr.io/image/${toUser.bankId}-${toUser.accountNo}-compact2.jpg?amount=${settle.amount.toInt()}&addInfo=$addInfo";
        hasData = true;
      }
      else if (priority == 2 && hasStaticQr) { qrImageUrl = toUser.bankQrUrl; hasData = true; }
      else if (hasVietQr) { qrImageUrl = "https://img.vietqr.io/image/${toUser.bankId}-${toUser.accountNo}-compact2.jpg?amount=${settle.amount.toInt()}&addInfo=$addInfo"; hasData = true; }
      else if (hasStaticQr) { qrImageUrl = toUser.bankQrUrl; hasData = true; }
    }

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Thanh toán cho ${settle.toUserName}", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Số tiền cần chuyển: ${CurrencyUtils.formatNumber(settle.amount)} đ", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            if (hasData && qrImageUrl != null)
              Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.orange, width: 2), borderRadius: BorderRadius.circular(12)),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                        qrImageUrl,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                        },
                        errorBuilder: (context, error, stackTrace) => const Padding(padding: EdgeInsets.all(16), child: Text("Lỗi không thể tải mã QR", textAlign: TextAlign.center))
                    )
                ),
              )
            else
              Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
                  child: Column(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
                        const SizedBox(height: 8),
                        Text("${settle.toUserName} chưa cài đặt thông tin nhận tiền trên ứng dụng.", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 4),
                        const Text("Vui lòng liên hệ trực tiếp để lấy số tài khoản!", textAlign: TextAlign.center, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                      ]
                  )
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("ĐÓNG", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () {
                Get.bottomSheet(
                    CreatePaymentBottomSheet(tripId: controller.tripId, settlement: settle),
                    isScrollControlled: true
                ).then((_) => Get.delete<CreatePaymentController>(tag: 'payment_${settle.toUserId}'));
              },
              child: const Text("TÔI ĐÃ CHUYỂN TIỀN")
          )
        ],
      ),
    );
  }
}