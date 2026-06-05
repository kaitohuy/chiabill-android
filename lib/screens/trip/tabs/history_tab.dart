import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../controllers/profile_controller.dart';
import '../../../controllers/trip_detail_controller.dart';
import '../../../controllers/trip_history_controller.dart';
import '../../../controllers/trip_settlement_controller.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/currency_util.dart';
import '../../../widgets/empty_state.dart';

class HistoryTab extends StatelessWidget {
  final TripDetailController mainController;
  const HistoryTab({super.key, required this.mainController});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TripHistoryController>(tag: mainController.tripId.toString());
    return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Obx(() {
                  bool hasFilter = controller.filterPaymentStatus.value != null ||
                      controller.filterPaymentFromUserId.value != null ||
                      controller.filterPaymentToUserId.value != null;
                  return InkWell(
                    onTap: () => _showPaymentFilterBottomSheet(context, controller, mainController),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                          color: hasFilter ? Colors.blue : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12)
                      ),
                      child: Row(
                          children: [
                            Icon(Icons.filter_list, color: hasFilter ? Colors.white : Colors.grey.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text("Lọc giao dịch", style: TextStyle(color: hasFilter ? Colors.white : Colors.grey.shade800, fontWeight: FontWeight.bold))
                          ]
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.payments.isEmpty && controller.currentPaymentPage.value == 0) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.payments.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async => mainController.fetchData(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 100),
                      Center(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: Get.height * 0.05),
                                const EmptyState(text: "Chưa có lịch sử giao dịch nào!"),
                              ]
                          )
                      )
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                color: Colors.blue,
                onRefresh: () async => mainController.fetchData(),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (!controller.isLoadingMorePayments.value && scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                      controller.fetchPayments(isRefresh: false);
                    }
                    return false;
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.payments.length + (controller.isPaymentLastPage.value ? 0 : 1),
                    itemBuilder: (context, index) {
                      if (index == controller.payments.length) {
                        return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(child: CircularProgressIndicator(color: Colors.blue))
                        );
                      }

                      final p = controller.payments[index];
                      String dateStr = p.createdAt;
                      if (dateStr.length > 16) dateStr = dateStr.substring(0, 16).replaceAll('T', ' ');

                      Color statusColor = Colors.orange;
                      IconData statusIcon = Icons.pending;
                      String statusText = "Đang chờ duyệt";

                      if (p.status == 'APPROVED') {
                        statusColor = AppColors.primary;
                        statusIcon = Icons.check_circle;
                        statusText = "Thành công";
                      } else if (p.status == 'REJECTED') {
                        statusColor = Colors.red;
                        statusIcon = Icons.cancel;
                        statusText = "Bị từ chối";
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: statusColor.withValues(alpha:0.5))),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(backgroundColor: statusColor.withValues(alpha:0.1), child: Icon(statusIcon, color: statusColor)),
                          title: Text("${p.fromUserName} ➡️ ${p.toUserName}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text(statusText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor))
                              ]
                          ),
                          trailing: Text("${CurrencyUtils.formatNumber(p.amount)} đ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: statusColor)),
                          onTap: () => _showHistoryProofDialog(context, controller, p),
                        ),
                      );
                    },
                  ),
                ),
              );
            }),
          )
        ]
    );
  }

  void _showPaymentFilterBottomSheet(BuildContext context, TripHistoryController controller, TripDetailController mainController) {
    String? tempStatus = controller.filterPaymentStatus.value;
    int? tempFromId = controller.filterPaymentFromUserId.value;
    int? tempToId = controller.filterPaymentToUserId.value;

    Get.bottomSheet(
      StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 16),
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Lọc lịch sử", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton(
                            onPressed: () => setState(() { tempStatus = null; tempFromId = null; tempToId = null; }),
                            child: const Text("Xóa lọc", style: TextStyle(color: Colors.red))
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Trạng thái:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                FilterChip(
                                    label: Text("Chờ duyệt", style: TextStyle(color: tempStatus == 'PENDING' ? Colors.white : Colors.orange)),
                                    selected: tempStatus == 'PENDING',
                                    selectedColor: Colors.orange,
                                    checkmarkColor: Colors.white,
                                    backgroundColor: Colors.orange.shade50,
                                    side: BorderSide(color: Colors.orange.shade200),
                                    onSelected: (val) => setState(() => tempStatus = val ? 'PENDING' : null)
                                ),
                                FilterChip(
                                    label: Text("Thành công", style: TextStyle(color: tempStatus == 'APPROVED' ? Colors.white : AppColors.primary)),
                                    selected: tempStatus == 'APPROVED',
                                    selectedColor: AppColors.primary,
                                    checkmarkColor: Colors.white,
                                    backgroundColor: AppColors.primaryBackgroundLight,
                                    side: BorderSide(color: AppColors.primaryLight),
                                    onSelected: (val) => setState(() => tempStatus = val ? 'APPROVED' : null)
                                ),
                                FilterChip(
                                    label: Text("Từ chối", style: TextStyle(color: tempStatus == 'REJECTED' ? Colors.white : Colors.red)),
                                    selected: tempStatus == 'REJECTED',
                                    selectedColor: Colors.red,
                                    checkmarkColor: Colors.white,
                                    backgroundColor: Colors.red.shade50,
                                    side: BorderSide(color: Colors.red.shade200),
                                    onSelected: (val) => setState(() => tempStatus = val ? 'REJECTED' : null)
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            const Text("Người chuyển tiền:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: (mainController.trip.value?.members ?? []).map((m) {
                                bool isSelected = tempFromId == m.user.id;
                                return FilterChip(
                                    label: Text(m.user.name ?? "Ẩn", style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                                    selected: isSelected,
                                    selectedColor: Colors.blue,
                                    checkmarkColor: Colors.white,
                                    backgroundColor: Colors.grey.shade100,
                                    onSelected: (val) => setState(() => tempFromId = val ? m.user.id : null)
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),

                            const Text("Người nhận tiền:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: (mainController.trip.value?.members ?? []).map((m) {
                                bool isSelected = tempToId == m.user.id;
                                return FilterChip(
                                    label: Text(m.user.name ?? "Ẩn", style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                                    selected: isSelected,
                                    selectedColor: Colors.blue,
                                    checkmarkColor: Colors.white,
                                    backgroundColor: Colors.grey.shade100,
                                    onSelected: (val) => setState(() => tempToId = val ? m.user.id : null)
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                          onPressed: () {
                            Get.back();
                            controller.applyPaymentFilter(status: tempStatus, fromId: tempFromId, toId: tempToId);
                          },
                          child: const Text("ÁP DỤNG", style: TextStyle(fontWeight: FontWeight.bold))
                      ),
                    )
                  ],
                ),
              ),
            );
          }
      ),
      isScrollControlled: true, backgroundColor: Colors.transparent,
    );
  }

  void _showHistoryProofDialog(BuildContext context, TripHistoryController controller, var payment) {
    List<String> images = [];
    if (payment.proofUrl != null && payment.proofUrl.isNotEmpty) images.add(payment.proofUrl);

    final PageController pageController = PageController();
    bool isPending = payment.status == 'PENDING';

    String? currentUserIdStr;
    if (Get.isRegistered<ProfileController>()) {
      currentUserIdStr = Get.find<ProfileController>().user.value?.id.toString();
    }

    if (currentUserIdStr == null) {
      var storageId = GetStorage().read('userId') ?? GetStorage().read('user_id') ?? GetStorage().read('id');
      if (storageId != null) currentUserIdStr = storageId.toString();
    }

    String toUserIdStr = payment.toUserId?.toString() ?? "";
    bool isReceiver = (currentUserIdStr != null) && (toUserIdStr == currentUserIdStr);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Giao dịch: ${CurrencyUtils.formatNumber(payment.amount)}đ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text("${payment.fromUserName} ➡️ ${payment.toUserName}", style: const TextStyle(color: Colors.grey)),
              const Divider(height: 24),

              if (images.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text("Không có ảnh đính kèm", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
                )
              else
                SizedBox(
                  height: 350,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PageView.builder(
                        controller: pageController,
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return InteractiveViewer(
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(images[index], fit: BoxFit.contain)
                              )
                          );
                        },
                      ),
                      if (images.length > 1) ...[
                        Positioned(
                            left: 0,
                            child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, shadows: [Shadow(blurRadius: 2, color: Colors.black)]),
                                onPressed: () => pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)
                            )
                        ),
                        Positioned(
                            right: 0,
                            child: IconButton(
                                icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, shadows: [Shadow(blurRadius: 2, color: Colors.black)]),
                                onPressed: () => pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)
                            )
                        ),
                      ]
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              if (isPending && isReceiver)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                        onPressed: () {
                          Get.back();
                          Get.defaultDialog(
                              title: "Từ chối giao dịch?",
                              middleText: "Bạn chắc chắn chưa nhận được tiền và muốn từ chối khoản này?",
                              textConfirm: "TỪ CHỐI",
                              textCancel: "HỦY",
                              confirmTextColor: Colors.white,
                              buttonColor: Colors.red,
                              onConfirm: () {
                                Get.back();
                                Get.find<TripSettlementController>(tag: mainController.tripId.toString()).rejectPayment(payment.id);
                                  controller.fetchData();
                              }
                          );
                        },
                        child: const Text("TỪ CHỐI", style: TextStyle(color: Colors.red))
                    ),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                        onPressed: () {
                          Get.back();
                          Get.find<TripSettlementController>(tag: mainController.tripId.toString()).approvePayment(payment.id);
                                  controller.fetchData();
                        },
                        child: const Text("ĐÃ NHẬN TIỀN")
                    ),
                  ],
                )
              else
                SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                        onPressed: () => Get.back(),
                        child: const Text("ĐÓNG")
                    )
                )
            ],
          ),
        ),
      ),
    );
  }
}