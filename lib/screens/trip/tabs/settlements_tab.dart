import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/empty_state.dart';
import '../../../controllers/create_payment_controller.dart';
import '../../../controllers/trip_detail_controller.dart';
import '../../../controllers/trip_settlement_controller.dart';
import '../../../utils/currency_util.dart';
import '../../../theme/app_colors.dart';
import '../create_payment_bottom_sheet.dart';
import '../pay_on_behalf_screen.dart';
import '../balance_detail_bottom_sheet.dart';

class SettlementsTab extends StatefulWidget {
  final TripDetailController mainController;
  const SettlementsTab({super.key, required this.mainController});

  @override
  State<SettlementsTab> createState() => _SettlementsTabState();
}

class _SettlementsTabState extends State<SettlementsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final controller = Get.find<TripSettlementController>(tag: widget.mainController.tripId.toString());
    return Obx(() {
      if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());

      if (controller.settlements.isEmpty) {
        return RefreshIndicator(
          onRefresh: () async => widget.mainController.fetchData(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: Get.height * 0.25),
              const EmptyState(text: "Mọi người đang hòa tiền nhau,\nhoặc chưa có khoản chi nào!"),
            ],
          ),
        );
      }

      return Column(
        children: [
          // KHU VỰC TÌM KIẾM
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (val) => controller.searchQuery.value = val,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: "Tìm theo tên thành viên...",
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 12, right: 8),
                  child: Icon(Icons.search, size: 20),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 24,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: AppColors.primary)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),
          // KHU VỰC LỌC VÀ SẮP XẾP
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    FilterChip(
                      label: const Text("Tất cả", style: TextStyle(fontSize: 11)),
                      selected: !controller.filterOnlyMe.value,
                      onSelected: (val) => controller.filterOnlyMe.value = false,
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text("Chỉ mình tôi", style: TextStyle(fontSize: 11)),
                      selected: controller.filterOnlyMe.value,
                      onSelected: (val) => controller.filterOnlyMe.value = true,
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sort, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        controller.sortOrder.value == "highest"
                            ? "Nợ nhiều nhất"
                            : controller.sortOrder.value == "lowest"
                                ? "Nợ thấp nhất"
                                : controller.sortOrder.value == "az"
                                    ? "Người nợ A-Z"
                                    : "Người nợ Z-A",
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                  onSelected: (val) => controller.sortOrder.value = val,
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: "highest", child: Text("Nợ nhiều nhất")),
                    const PopupMenuItem(value: "lowest", child: Text("Nợ thấp nhất")),
                    const PopupMenuItem(value: "az", child: Text("Người nợ A-Z")),
                    const PopupMenuItem(value: "za", child: Text("Người nợ Z-A")),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 4, height: 16, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    const Text("QUYẾT TOÁN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Get.to(() => PayOnBehalfScreen(
                      tripId: widget.mainController.tripId, 
                      settlements: controller.settlements
                    ));
                  },
                  child: Row(
                    children: [
                      Icon(Icons.people_outline, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text("Thanh toán hộ", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: Colors.orange,
              onRefresh: () async => widget.mainController.fetchData(),
              child: controller.filteredSettlements.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.search_off, size: 60, color: Colors.grey),
                              SizedBox(height: 12),
                              Text("Không tìm thấy kết quả phù hợp", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.filteredSettlements.length,
                      itemBuilder: (context, index) {
                        final settle = controller.filteredSettlements[index];
                        String fromInitial = (settle.fromUserName != null && settle.fromUserName!.trim().isNotEmpty) ? settle.fromUserName!.trim()[0].toUpperCase() : "?";
                        String toInitial = (settle.toUserName != null && settle.toUserName!.trim().isNotEmpty) ? settle.toUserName!.trim()[0].toUpperCase() : "?";

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              if (Get.isBottomSheetOpen == true) return;
                              Get.bottomSheet(
                                BalanceDetailBottomSheet(
                                  tripId: widget.mainController.tripId,
                                  settlement: settle,
                                  onPayPressed: () => _showPaymentQR(context, controller, widget.mainController, settle),
                                ),
                                isScrollControlled: true,
                              );
                            },
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
                                            Image.asset(
                                              'assets/images/payment.png',
                                              width: 32, 
                                              height: 32,
                                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.arrow_forward, color: Colors.grey),
                                            ),
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
            ),
          )
        ],
      );
    });
  }

  void _showPaymentQR(BuildContext context, TripSettlementController controller, TripDetailController mainController, var settle) {
    var matches = mainController.trip.value?.members?.where((m) => m.user.name == settle.toUserName);
    var toUser = (matches != null && matches.isNotEmpty) ? matches.first.user : null;
    String? qrImageUrl;
    bool hasData = false;

    if (toUser != null) {
      int priority = toUser.paymentPriority;
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
                if (Get.isBottomSheetOpen == true) return;
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