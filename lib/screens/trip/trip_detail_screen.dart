import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../controllers/add_expense_controller.dart';
import '../../controllers/create_payment_controller.dart';
import '../../controllers/invite_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/trip_detail_controller.dart';
import '../../controllers/ghost_controller.dart';
import 'add_expense_bottom_sheet.dart';
import 'create_payment_bottom_sheet.dart';
import 'edit_trip_dialog.dart';

class TripDetailScreen extends StatefulWidget {
  final int tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> with SingleTickerProviderStateMixin {
  late TripDetailController controller;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    // 🌟 THÊM ĐÚNG DÒNG NÀY VÀO ĐẦY TIÊN:
    // Ép tải thông tin Profile ngầm để lấy ID người dùng, permanent: true để nó sống mãi
    Get.put(ProfileController(), permanent: true);

    // Bước 1: Dọn dẹp rác nếu có Controller cũ kẹt trong RAM
    Get.delete<TripDetailController>(tag: widget.tripId.toString(), force: true);

    // Bước 2: Tạo Controller mới tinh
    controller = Get.put(TripDetailController(widget.tripId), tag: widget.tripId.toString());

    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        controller.currentTab.value = _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    // QUAN TRỌNG: Xóa sạch Controller này khi người dùng bấm Back ra ngoài
    Get.delete<TripDetailController>(tag: widget.tripId.toString(), force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.lightGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Obx(() => Text(controller.trip.value?.name ?? "Chi tiết")),
        actions: [
          // Hiển thị Mã mời (Active Invite Code)
          Obx(() {
            if (controller.activeInviteCode.value.isNotEmpty) {
              return Center(
                child: GestureDetector(
                  onTap: controller.copyToClipboard,
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.vpn_key, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          controller.activeInviteCode.value,
                          style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Nút 3 chấm (PopupMenu)
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuSelection(value, controller),
            itemBuilder: (context) => [
              if (controller.isOwner) const PopupMenuItem(value: 'edit_trip', child: Text("Sửa tên chuyến đi")),
              if (controller.isOwner) const PopupMenuItem(value: 'delete_trip', child: Text("Xóa chuyến đi", style: TextStyle(color: Colors.red))),
              if (!controller.isOwner) const PopupMenuItem(value: 'leave_trip', child: Text("Rời nhóm", style: TextStyle(color: Colors.orange))),
            ],
          ),
        ],

        // ==========================================
        // NAVBAR ĐẨY LÊN TRÊN (DƯỚI TIÊU ĐỀ)
        // ==========================================
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
            ),
            child: Obx(() => Row(
              children: [
                _buildTabItem(index: 0, icon: Icons.list_alt, controller: controller),
                _buildTabItem(index: 1, icon: Icons.account_balance_wallet, controller: controller),
                _buildTabItem(index: 2, icon: Icons.pie_chart, controller: controller),
                _buildTabItem(index: 3, icon: Icons.history, controller: controller),
                _buildTabItem(index: 4, icon: Icons.people, controller: controller),
              ],
            )),
          ),
        ),
      ),

      // ==========================================
      // BODY: CHUYỂN TAB DỰA TRÊN INDEX
      // ==========================================
      body: Obx(() {
        if (controller.isLoading.value && controller.trip.value == null) {
          return const Center(child: CircularProgressIndicator(color: Colors.lightGreen));
        }

        switch (controller.currentTab.value) {
          case 0: return _buildExpensesTab(controller);
          case 1: return _buildSettlementTab(controller);
          case 2: return _buildStatsTab(controller); // Tab Biểu đồ mới
          case 3: return _buildHistoryTab(controller);
          case 4: return _buildMembersTab(controller);
          default: return const SizedBox.shrink();
        }
      }),

      // FLOATING ACTION BUTTON (Hiển thị tùy theo tab)
      floatingActionButton: Obx(() {
        if (controller.currentTab.value == 0) {
          return FloatingActionButton.extended(
            onPressed: () {
              if (controller.trip.value != null) {
                Get.bottomSheet(AddExpenseBottomSheet(trip: controller.trip.value!), isScrollControlled: true);
              }
            },
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text("Thêm chi phí", style: TextStyle(fontWeight: FontWeight.bold)),
          );
        } else if (controller.currentTab.value == 4) {
          return FloatingActionButton.extended(
            onPressed: () => _showAddMemberOptions(context, controller),
            backgroundColor: Colors.lightBlue,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.person_add),
            label: const Text("Thành viên", style: TextStyle(fontWeight: FontWeight.bold)),
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }

  Widget _buildTabItem({required int index, required IconData icon, required TripDetailController controller}) {
    bool isSelected = controller.currentTab.value == index;
    return Expanded(
      child: InkWell(
        onTap: () => controller.currentTab.value = index,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.orange : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.orange : Colors.grey.shade400,
            size: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsTab(TripDetailController controller) {
    return Obx(() {
      if (controller.categoryStats.isEmpty) {
        return const Center(
          child: Text("Chưa có dữ liệu chi tiêu để thống kê.\nHãy thêm chi phí trước nhé!", textAlign: TextAlign.center),
        );
      }

      double total = controller.categoryStats.fold(0, (sum, item) => sum + item.totalAmount);

      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Tổng quan chi tiêu", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),

            // BIỂU ĐỒ TRÒN
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 45,
                  sections: controller.categoryStats.asMap().entries.map((entry) {
                    final data = entry.value;
                    final List<Color> colors = [Colors.orange, Colors.blue, Colors.green, Colors.purple, Colors.red, Colors.teal];
                    return PieChartSectionData(
                      color: colors[entry.key % colors.length],
                      value: data.totalAmount,
                      title: "${(data.totalAmount / total * 100).toStringAsFixed(0)}%",
                      radius: 55,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // DANH SÁCH CHI TIẾT
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.categoryStats.length,
              itemBuilder: (context, index) {
                final stat = controller.categoryStats[index];
                final List<Color> colors = [Colors.orange, Colors.blue, Colors.green, Colors.purple, Colors.red, Colors.teal];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Text(stat.categoryIcon, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(stat.categoryName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: stat.totalAmount / total,
                              backgroundColor: Colors.grey[100],
                              color: colors[index % colors.length],
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text("${stat.totalAmount.toInt()} đ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
    });
  }

  void _handleMenuSelection(String value, TripDetailController controller) {
    if (value == 'edit_trip') {
      if (controller.trip.value != null) {
        Get.dialog(EditTripDialog(trip: controller.trip.value!, isFromHome: false));
      }
    } else if (value == 'delete_trip') {
      Get.defaultDialog(
        title: "Xóa chuyến đi?",
        middleText: "Hành động này không thể hoàn tác!",
        textConfirm: "XÓA",
        textCancel: "HỦY",
        confirmTextColor: Colors.white,
        buttonColor: Colors.red,
        onConfirm: () => controller.deleteTrip(),
      );
    } else if (value == 'leave_trip') {
      Get.defaultDialog(
        title: "Rời nhóm",
        middleText: "Bạn chắc chắn muốn rời khỏi nhóm này?",
        textConfirm: "XÁC NHẬN",
        textCancel: "HỦY",
        confirmTextColor: Colors.white,
        buttonColor: Colors.orange,
        onConfirm: () => controller.leaveTrip(),
      );
    }
  }

  // ==========================================
  // GIAO DIỆN TAB LỊCH SỬ THANH TOÁN
  // ==========================================
  Widget _buildHistoryTab(TripDetailController controller) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Obx(() {
                bool hasFilter = controller.filterPaymentStatus.value != null || controller.filterPaymentFromUserId.value != null || controller.filterPaymentToUserId.value != null;
                return InkWell(
                  onTap: () => _showPaymentFilterBottomSheet(context, controller),
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
                        Text("Lọc giao dịch", style: TextStyle(color: hasFilter ? Colors.white : Colors.grey.shade800, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        // DANH SÁCH CUỘN VÔ TẬN (CŨ)
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.payments.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            // 2. Trạng thái rỗng
            if (controller.payments.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async => controller.fetchData(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 100),
                    Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history_toggle_off, size: 80, color: Colors.grey), SizedBox(height: 16), Text("Chưa có lịch sử giao dịch nào!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))])),
                  ],
                ),
              );
            }

            // 3. Danh sách có dữ liệu (Cuộn vô tận)
            return RefreshIndicator(
              color: Colors.blue,
              onRefresh: () async => controller.fetchData(),
              // BỌC LISTVIEW BẰNG NOTIFICATION LISTENER ĐỂ BẮT SỰ KIỆN CUỘN
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  // Nếu cuộn xuống cách đáy 200 pixel -> Tải trang tiếp theo
                  if (!controller.isLoadingMorePayments.value && scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                    controller.fetchPayments(isRefresh: false);
                  }
                  return false;
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  // CỘNG THÊM 1 ĐỂ HIỂN THỊ LOADING Ở ĐÁY NẾU CHƯA HẾT TRANG
                  itemCount: controller.payments.length + (controller.isPaymentLastPage.value ? 0 : 1),
                  itemBuilder: (context, index) {

                    // NẾU LÀ ITEM CUỐI CÙNG -> VẼ VÒNG TRÒN LOADING
                    if (index == controller.payments.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(child: CircularProgressIndicator(color: Colors.blue)),
                      );
                    }

                    // KHÔNG CẦN SORT NỮA VÌ BACKEND ĐÃ SORT SẴN
                    final p = controller.payments[index];

                    // Xử lý format ngày tháng đơn giản (Cắt bỏ phần T và giây mili)
                    String dateStr = p.createdAt ?? "";
                    if (dateStr.length > 16) {
                      dateStr = dateStr.substring(0, 16).replaceAll('T', ' '); // VD: 2026-04-04 17:34
                    }

                    // Giao diện màu sắc theo Trạng thái
                    Color statusColor = Colors.orange;
                    IconData statusIcon = Icons.pending;
                    String statusText = "Đang chờ duyệt";

                    if (p.status == 'APPROVED') {
                      statusColor = Colors.green;
                      statusIcon = Icons.check_circle;
                      statusText = "Thành công";
                    } else if (p.status == 'REJECTED') {
                      statusColor = Colors.red;
                      statusIcon = Icons.cancel;
                      statusText = "Bị từ chối";
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: statusColor.withOpacity(0.5))),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(backgroundColor: statusColor.withOpacity(0.1), child: Icon(statusIcon, color: statusColor)),
                        title: Text("${p.fromUserName} ➡️ ${p.toUserName}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(statusText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
                          ],
                        ),
                        trailing: Text("${p.amount.toInt()} đ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: statusColor)),
                        onTap: () => _showHistoryProofDialog(context, controller, p),
                      ),
                    );
                  },
                ),
              ),
            );
          }
        )
        )
      ]
    );
  }


  void _showPaymentFilterBottomSheet(BuildContext context, TripDetailController controller) {
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
                          child: const Text("Xóa lọc", style: TextStyle(color: Colors.red)),
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
                                  selectedColor: Colors.orange, checkmarkColor: Colors.white, backgroundColor: Colors.orange.shade50, side: BorderSide(color: Colors.orange.shade200),
                                  onSelected: (val) => setState(() => tempStatus = val ? 'PENDING' : null),
                                ),
                                FilterChip(
                                  label: Text("Thành công", style: TextStyle(color: tempStatus == 'APPROVED' ? Colors.white : Colors.green)),
                                  selected: tempStatus == 'APPROVED',
                                  selectedColor: Colors.green, checkmarkColor: Colors.white, backgroundColor: Colors.green.shade50, side: BorderSide(color: Colors.green.shade200),
                                  onSelected: (val) => setState(() => tempStatus = val ? 'APPROVED' : null),
                                ),
                                FilterChip(
                                  label: Text("Từ chối", style: TextStyle(color: tempStatus == 'REJECTED' ? Colors.white : Colors.red)),
                                  selected: tempStatus == 'REJECTED',
                                  selectedColor: Colors.red, checkmarkColor: Colors.white, backgroundColor: Colors.red.shade50, side: BorderSide(color: Colors.red.shade200),
                                  onSelected: (val) => setState(() => tempStatus = val ? 'REJECTED' : null),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            const Text("Người chuyển tiền:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: (controller.trip.value?.members ?? []).map((m) {
                                bool isSelected = tempFromId == m.user.id;
                                return FilterChip(
                                  label: Text(m.user.name ?? "Ẩn", style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                                  selected: isSelected, selectedColor: Colors.blue, checkmarkColor: Colors.white, backgroundColor: Colors.grey.shade100,
                                  onSelected: (val) => setState(() => tempFromId = val ? m.user.id : null),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),

                            const Text("Người nhận tiền:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: (controller.trip.value?.members ?? []).map((m) {
                                bool isSelected = tempToId == m.user.id;
                                return FilterChip(
                                  label: Text(m.user.name ?? "Ẩn", style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                                  selected: isSelected, selectedColor: Colors.blue, checkmarkColor: Colors.white, backgroundColor: Colors.grey.shade100,
                                  onSelected: (val) => setState(() => tempToId = val ? m.user.id : null),
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
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                        onPressed: () {
                          Get.back();
                          controller.applyPaymentFilter(status: tempStatus, fromId: tempFromId, toId: tempToId);
                        },
                        child: const Text("ÁP DỤNG", style: TextStyle(fontWeight: FontWeight.bold)),
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

  // ==========================================
  // DIALOG XEM MINH CHỨNG (HỖ TRỢ PREV/NEXT TƯƠNG LAI)
  // ==========================================
  void _showHistoryProofDialog(BuildContext context, TripDetailController controller, var payment) {
    List<String> images = [];
    if (payment.proofUrl != null && payment.proofUrl.isNotEmpty) {
      images.add(payment.proofUrl);
    }

    final PageController pageController = PageController();

    // =====================================
    // LOGIC CHECK QUYỀN HIỂN THỊ NÚT
    // =====================================
    bool isPending = payment.status == 'PENDING';

    // 1. Tìm ID của người dùng hiện tại đang cầm máy
    String? currentUserIdStr;

    // Thử lấy từ ProfileController nếu đã mở
    if (Get.isRegistered<ProfileController>()) {
      currentUserIdStr = Get.find<ProfileController>().user.value?.id?.toString();
    }

    // 2. Nếu vẫn null, ép kiểu an toàn từ GetStorage
    if (currentUserIdStr == null) {
      var storageId = GetStorage().read('userId') ?? GetStorage().read('user_id') ?? GetStorage().read('id');
      if (storageId != null) {
        currentUserIdStr = storageId.toString();
      }
    }

    // 3. Đưa cả 2 về String để so sánh
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
              Text("Giao dịch: ${payment.amount.toInt()}đ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text("${payment.fromUserName} ➡️ ${payment.toUserName}", style: const TextStyle(color: Colors.grey)),
              const Divider(height: 24),

              if (images.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text("Không có ảnh đính kèm", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
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
                              child: Image.network(images[index], fit: BoxFit.contain),
                            ),
                          );
                        },
                      ),
                      if (images.length > 1) ...[
                        Positioned(
                          left: 0,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, shadows: [Shadow(blurRadius: 2, color: Colors.black)]),
                            onPressed: () => pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, shadows: [Shadow(blurRadius: 2, color: Colors.black)]),
                            onPressed: () => pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // =====================================
              // RENDER NÚT BẤM DỰA VÀO QUYỀN
              // =====================================
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
                                controller.rejectPayment(payment.id);
                              }
                          );
                        },
                        child: const Text("TỪ CHỐI", style: TextStyle(color: Colors.red))
                    ),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        onPressed: () {
                          Get.back();
                          controller.approvePayment(payment.id);
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
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMemberOptions(BuildContext context, TripDetailController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Thêm thành viên mới", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.person_off, color: Colors.white)),
              title: const Text("Thêm người không dùng app"),
              subtitle: const Text("Thêm để chia tiền thay họ"),
              onTap: () {
                Get.back();
                _showAddGhostDialog(context, controller.tripId);
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.person_add, color: Colors.white)),
              title: const Text("Thêm qua SĐT / Email"),
              subtitle: const Text("Tìm và thêm trực tiếp vào nhóm"),
              onTap: () {
                Get.back();
                _showAddDirectMemberDialog(context, controller);
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.share, color: Colors.white)),
              title: const Text("Chia sẻ mã mời"),
              subtitle: const Text("Tạo mã code để bạn bè tự tham gia"),
              onTap: () {
                Get.back(); // Đóng menu BottomSheet
                _showCreateInviteDialog(context, controller); // Mở Dialog tạo mã
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDirectMemberDialog(BuildContext context, TripDetailController controller) {
    final TextEditingController inputController = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [Icon(Icons.search, color: Colors.green), SizedBox(width: 8), Text("Thêm thành viên", style: TextStyle(fontWeight: FontWeight.bold))]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Nhập chính xác Email hoặc Số điện thoại của người dùng đã đăng ký app."),
            const SizedBox(height: 16),
            TextField(
              controller: inputController,
              decoration: InputDecoration(
                  hintText: "VD: 0987654321 hoặc a@gmail.com",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.contact_mail)
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("HỦY", style: TextStyle(color: Colors.grey))),
          Obx(() => ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: controller.isAddingMember.value ? null : () => controller.addDirectMember(inputController.text),
            child: controller.isAddingMember.value
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("TÌM & THÊM"),
          )),
        ],
      ),
    );
  }

  void _showAddGhostDialog(BuildContext context, int tripId) {
    final ghostController = Get.put(GhostController(tripId));
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [Icon(Icons.person_add_alt_1, color: Colors.orange), SizedBox(width: 8), Text("Thêm người ảo", style: TextStyle(fontWeight: FontWeight.bold))]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Nhập tên những người không dùng app, cách nhau bằng dấu phẩy."),
            const SizedBox(height: 16),
            TextField(
              controller: ghostController.namesController,
              decoration: InputDecoration(hintText: "VD: Bố, Mẹ, Bé Bo...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("HỦY")),
          Obx(() => ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: ghostController.isLoading.value ? null : () => ghostController.submitGhosts(),
            child: const Text("XÁC NHẬN"),
          )),
        ],
      ),
    );
  }

  Widget _buildExpensesTab(TripDetailController controller) {
    return Column(
      children: [
        // ==========================================
        // THANH TÌM KIẾM & NÚT LỌC
        // ==========================================
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    // Xử lý Search Realtime
                    controller.applyExpenseFilter(keyword: value);
                  },
                  decoration: InputDecoration(
                    hintText: "Tìm chi phí...",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Nút Lọc (Filter)
              Obx(() {
                // Đổi màu nút nếu đang có filter
                bool hasFilter = controller.filterCategoryId.value != null || controller.filterPayerId.value != null;
                return InkWell(
                  onTap: () => _showExpenseFilterBottomSheet(context, controller),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: hasFilter ? Colors.orange : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12)
                    ),
                    child: Icon(Icons.tune, color: hasFilter ? Colors.white : Colors.grey.shade700),
                  ),
                );
              }),
            ],
          ),
        ),

        // ==========================================
        // DANH SÁCH CHI PHÍ (INFINITE SCROLL + NEW UI)
        // ==========================================
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.expenses.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.expenses.isEmpty) {
              return const Center(child: Text("Không tìm thấy khoản chi nào!", textAlign: TextAlign.center));
            }

            return RefreshIndicator(
              color: Colors.orange,
              onRefresh: () async => controller.fetchData(),
              // BỌC LISTVIEW BẰNG NOTIFICATION LISTENER ĐỂ BẮT SỰ KIỆN CUỘN
              child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    // Nếu cuộn xuống cách đáy 200 pixel -> Tải trang tiếp theo
                    if (!controller.isLoadingMoreExpenses.value && scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                      controller.fetchExpenses(isRefresh: false);
                    }
                    return false;
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    // CỘNG THÊM 1 ĐỂ HIỂN THỊ LOADING Ở ĐÁY NẾU CHƯA HẾT TRANG
                    itemCount: controller.expenses.length + (controller.isExpenseLastPage.value ? 0 : 1),
                    itemBuilder: (context, index) {

                      // NẾU LÀ ITEM CUỐI CÙNG -> VẼ VÒNG TRÒN LOADING
                      if (index == controller.expenses.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(child: CircularProgressIndicator(color: Colors.orange)),
                        );
                      }

                      final expense = controller.expenses[index];
                      final payer = expense.payer;
                      String payerInitial = (payer?.name != null && payer!.name!.trim().isNotEmpty) ? payer.name!.trim()[0].toUpperCase() : "?";

                      // Lấy icon danh mục, nếu null thì hiện hộp quà
                      String categoryIcon = expense.categoryIcon ?? "📦";

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Bo tròn nhiều hơn cho hiện đại
                        elevation: 1, // Đổ bóng nhẹ
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              // ===================================
                              // 1. ICON DANH MỤC Ở LỀ TRÁI
                              // ===================================
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.orange.shade200, width: 1.5),
                                ),
                                child: Center(
                                  child: Text(categoryIcon, style: const TextStyle(fontSize: 26)),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // ===================================
                              // 2. TÊN KHOẢN CHI & NGƯỜI TRẢ CÓ AVATAR NHỎ
                              // ===================================
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        expense.description,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.2),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis
                                    ),
                                    const SizedBox(height: 6),

                                    // Dòng Subtitle: "Bởi: [Avatar] Tên người trả"
                                    Row(
                                      children: [
                                        Text("Bởi: ", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                        // Avatar mini
                                        CircleAvatar(
                                          radius: 9,
                                          backgroundColor: payer?.isGhost == true ? Colors.grey[300] : Colors.green[100],
                                          backgroundImage: (payer?.avatarUrl != null && payer!.avatarUrl!.isNotEmpty) ? NetworkImage(payer.avatarUrl!) : null,
                                          child: (payer?.avatarUrl == null || payer!.avatarUrl!.isEmpty)
                                              ? (payer?.isGhost == true ? const Icon(Icons.visibility_off, color: Colors.grey, size: 10) : Text(payerInitial, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 9)))
                                              : null,
                                        ),
                                        const SizedBox(width: 4),
                                        // Tên người trả
                                        Expanded(
                                          child: Text(
                                            payer?.name ?? 'Ẩn danh',
                                            style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.w500),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // ===================================
                              // 3. SỐ TIỀN & MENU 3 CHẤM
                              // ===================================
                              Text(
                                  "${expense.totalAmount.toInt()} đ",
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.redAccent)
                              ),
                              PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.more_vert, color: Colors.grey),
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _showDeleteConfirmDialog(context, controller, expense.id);
                                  } else if (value == 'edit') {
                                    Get.bottomSheet(AddExpenseBottomSheet(trip: controller.trip.value!, expenseToEdit: expense), isScrollControlled: true)
                                        .then((_) => Get.delete<AddExpenseController>(tag: 'edit_${expense.id}'));
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'edit', child: Text("Sửa")),
                                  const PopupMenuItem(value: 'delete', child: Text("Xóa", style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
              ),
            );
          }),
        ),
      ],
    );
  }

  void _showExpenseFilterBottomSheet(BuildContext context, TripDetailController controller) {
    int? tempCatId = controller.filterCategoryId.value;
    int? tempPayerId = controller.filterPayerId.value;

    Get.bottomSheet(
      StatefulBuilder(
          builder: (context, setState) {
            // Bọc SafeArea để tránh bị lẹm vào nút Home dưới đáy màn hình của các máy tràn viền
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 16),
                // Đặt giới hạn max height để nó không bị lố màn hình
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24))
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===============================
                    // 1. HEADER (Cố định ở trên)
                    // ===============================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Lọc chi phí", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              tempCatId = null;
                              tempPayerId = null;
                            });
                          },
                          child: const Text("Xóa lọc", style: TextStyle(color: Colors.red)),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),

                    // ===============================
                    // 2. NỘI DUNG (Cuộn được nếu dài)
                    // ===============================
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(), // Hiệu ứng cuộn nảy mượt mà
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // LỌC THEO DANH MỤC
                            const Text("Theo danh mục:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: controller.categories.map((cat) {
                                bool isSelected = tempCatId == cat.id;
                                return FilterChip(
                                  label: Text("${cat.icon ?? ''} ${cat.name}", style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                                  selected: isSelected,
                                  selectedColor: Colors.orange,
                                  checkmarkColor: Colors.white,
                                  backgroundColor: Colors.grey.shade100,
                                  onSelected: (val) {
                                    setState(() => tempCatId = val ? cat.id : null);
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),

                            // LỌC THEO NGƯỜI TRẢ
                            const Text("Theo người trả tiền:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: (controller.trip.value?.members ?? []).map((m) {
                                bool isSelected = tempPayerId == m.user.id;
                                return FilterChip(
                                  label: Text(m.user.name ?? "Ẩn danh", style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                                  selected: isSelected,
                                  selectedColor: Colors.orange,
                                  checkmarkColor: Colors.white,
                                  backgroundColor: Colors.grey.shade100,
                                  onSelected: (val) {
                                    setState(() => tempPayerId = val ? m.user.id : null);
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                    // ===============================
                    // 3. NÚT XÁC NHẬN (Cố định ở dưới)
                    // ===============================
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                        onPressed: () {
                          Get.back(); // Đóng bottom sheet
                          controller.applyExpenseFilter(catId: tempCatId, payerId: tempPayerId);
                        },
                        child: const Text("ÁP DỤNG", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            );
          }
      ),
      isScrollControlled: true, // QUAN TRỌNG: Cho phép BottomSheet cao hơn 50% màn hình
      backgroundColor: Colors.transparent, // Fix lỗi viền trắng góc bo tròn
    );
  }

  Widget _buildSettlementTab(TripDetailController controller) {
    return Obx(() {
      if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());

      if (controller.settlements.isEmpty) {
        return RefreshIndicator(
          onRefresh: () async => controller.fetchData(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 100),
              Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.handshake, size: 80, color: Colors.grey), SizedBox(height: 16), Text("Mọi người đang hòa tiền nhau,\nhoặc chưa có khoản chi nào!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))])),
            ],
          ),
        );
      }

      // Chỉ hiển thị danh sách Nợ
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
                      Expanded(child: Column(children: [CircleAvatar(backgroundColor: Colors.red[100], child: Text(fromInitial, style: const TextStyle(color: Colors.red))), const SizedBox(height: 8), Text(settle.fromUserName ?? "Ẩn danh", style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)])),
                      Expanded(flex: 2, child: Column(children: [Text("${settle.amount.toInt()} đ", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.orange)), const Icon(Icons.arrow_forward, color: Colors.grey), const Text("Bấm để trả tiền", style: TextStyle(fontSize: 11, color: Colors.blue, decoration: TextDecoration.underline))])),
                      Expanded(child: Column(children: [CircleAvatar(backgroundColor: Colors.green[100], child: Text(toInitial, style: const TextStyle(color: Colors.green))), const SizedBox(height: 8), Text(settle.toUserName ?? "Ẩn danh", style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)])),
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

  // HÀM XỬ LÝ LOGIC HIỂN THỊ QR CHUYỂN KHOẢN (Bạn dán hàm này ngay bên dưới hàm _buildSettlementTab)
  void _showPaymentQR(BuildContext context, TripDetailController controller, var settle) {
    // 1. SỬA LỖI Ở ĐÂY: Tìm m.user.name thay vì m.name
    var matches = controller.trip.value?.members?.where((m) => m.user.name == settle.toUserName);

    // Lấy object user ra khỏi lớp bọc TripMemberResponse
    var toUser = (matches != null && matches.isNotEmpty) ? matches.first.user : null;

    String? qrImageUrl;
    bool hasData = false;

    if (toUser != null) {
      int priority = toUser.paymentPriority ?? 1;
      bool hasVietQr = (toUser.bankId != null && toUser.bankId!.isNotEmpty) && (toUser.accountNo != null && toUser.accountNo!.isNotEmpty);
      bool hasStaticQr = (toUser.bankQrUrl != null && toUser.bankQrUrl!.isNotEmpty);

      // Định dạng nội dung chuyển khoản: Không dấu, thay khoảng trắng bằng %20 cho URL
      String addInfo = "${settle.fromUserName ?? 'Ban'} thanh toan".replaceAll(' ', '%20');

      // Logic quyết định lấy mã nào
      if (priority == 1 && hasVietQr) {
        qrImageUrl = "https://img.vietqr.io/image/${toUser.bankId}-${toUser.accountNo}-compact2.jpg?amount=${settle.amount.toInt()}&addInfo=$addInfo";
        hasData = true;
      } else if (priority == 2 && hasStaticQr) {
        qrImageUrl = toUser.bankQrUrl;
        hasData = true;
      } else if (hasVietQr) { // Fallback nếu chọn nhầm ưu tiên 2 nhưng chỉ có data của 1
        qrImageUrl = "https://img.vietqr.io/image/${toUser.bankId}-${toUser.accountNo}-compact2.jpg?amount=${settle.amount.toInt()}&addInfo=$addInfo";
        hasData = true;
      } else if (hasStaticQr) {
        qrImageUrl = toUser.bankQrUrl;
        hasData = true;
      }
    }

    // 2. Hiện Dialog
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Thanh toán cho ${settle.toUserName}", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Số tiền cần chuyển: ${settle.amount.toInt()} đ", style: const TextStyle(fontSize: 16)),
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
                    errorBuilder: (context, error, stackTrace) => const Padding(padding: EdgeInsets.all(16), child: Text("Lỗi không thể tải mã QR", textAlign: TextAlign.center)),
                  ),
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
                    const Text("Vui lòng liên hệ trực tiếp để lấy số tài khoản!", textAlign: TextAlign.center, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("ĐÓNG", style: TextStyle(color: Colors.grey))),
          // THÊM NÚT NÀY VÀO ĐỂ MỞ FORM XÁC NHẬN
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () {
                // Get.back(); // Nếu muốn đóng Dialog QR thì bỏ comment dòng này
                Get.bottomSheet(
                  CreatePaymentBottomSheet(tripId: controller.tripId, settlement: settle),
                  isScrollControlled: true,
                ).then((_) => Get.delete<CreatePaymentController>(tag: 'payment_${settle.toUserId}'));
              },
              child: const Text("TÔI ĐÃ CHUYỂN TIỀN")
          )
        ],
      ),
    );
  }

  Widget _buildMembersTab(TripDetailController controller) {
    return Obx(() {
      if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
      final trip = controller.trip.value;
      if (trip == null || trip.members == null || trip.members!.isEmpty) return const Center(child: Text("Chưa có thành viên nào."));

      return RefreshIndicator(
          color: Colors.lightGreen,
          onRefresh: () async => controller.fetchData(),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: trip.members!.length,
            itemBuilder: (context, index) {
              // LƯU Ý: memberData bây giờ là TripMemberResponse
              final memberData = trip.members![index];
              final member = memberData.user;

              bool isDisabled = memberData.status == 'DISABLED';
              bool isMemberOwner = trip.ownerId == member.id;

              String memberInitial = (member.name != null && member.name!.trim().isNotEmpty) ? member.name!.trim()[0].toUpperCase() : "U";

              return Opacity(
                opacity: isDisabled ? 0.5 : 1.0, // Bôi xám nếu bị khóa
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0.5,
                  child: ListTile(
                    leading: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        CircleAvatar(
                          backgroundColor: member.isGhost ? Colors.grey[200] : Colors.lightGreen[100],
                          backgroundImage: (member.avatarUrl != null && member.avatarUrl!.isNotEmpty) ? NetworkImage(member.avatarUrl!) : null,
                          child: (member.avatarUrl == null || member.avatarUrl!.isEmpty)
                              ? (member.isGhost ? const Icon(Icons.visibility_off, color: Colors.grey, size: 20) : Text(memberInitial, style: const TextStyle(color: Colors.lightGreen, fontWeight: FontWeight.bold)))
                              : null,
                        ),
                        if (isMemberOwner)
                          const Text("👑", style: TextStyle(fontSize: 16)), // Vương miện cho chủ phòng
                      ],
                    ),
                    title: Row(
                      children: [
                        Expanded(child: Text(member.name ?? "Ẩn danh", style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        if (isDisabled) const Text(" (Tạm ngưng)", style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    subtitle: Text(member.isGhost ? "Người dùng ảo (Ghost)" : "Thành viên app"),
                    trailing: const Icon(Icons.settings, color: Colors.grey, size: 20),

                    // CLICK VÀO MEMBER HIỆN MENU QUẢN TRỊ
                    onTap: () {
                      Get.bottomSheet(
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(member.name ?? "Thành viên", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),

                                // Thông tin cơ bản
                                ListTile(
                                  leading: const Icon(Icons.email, color: Colors.blue),
                                  title: const Text("Email / Tài khoản"),
                                  subtitle: Text(member.email ?? "Không có thông tin"),
                                ),

                                // QUYỀN CỦA OWNER (Chỉ hiện nếu đang dùng app là Chủ phòng VÀ bấm vào người khác)
                                if (controller.isOwner && !isMemberOwner) ...[
                                  const Divider(),
                                  const Text("Quản trị thành viên", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                  const SizedBox(height: 8),

                                  ListTile(
                                    leading: const Icon(Icons.swap_horiz, color: Colors.blue),
                                    title: const Text("Chuyển quyền Chủ phòng"),
                                    onTap: () {
                                      Get.back(); // Đóng BottomSheet
                                      controller.transferOwner(member.id!);
                                    },
                                  ),
                                  ListTile(
                                    leading: Icon(isDisabled ? Icons.play_arrow : Icons.pause, color: Colors.orange),
                                    title: Text(isDisabled ? "Mở khóa thành viên" : "Tạm ngưng hoạt động"),
                                    onTap: () {
                                      Get.back(); // Đóng BottomSheet
                                      if (isDisabled) {
                                        controller.activateMember(member.id!);
                                      } else {
                                        controller.disableMember(member.id!);
                                      }
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.person_remove, color: Colors.red),
                                    title: const Text("Đuổi khỏi nhóm", style: TextStyle(color: Colors.red)),
                                    onTap: () {
                                      Get.back(); // Đóng BottomSheet
                                      // Hỏi xác nhận xem có muốn xóa nợ hay giữ nợ
                                      Get.defaultDialog(
                                          title: "Xác nhận đuổi?",
                                          content: const Text("Bạn muốn xử lý nợ của người này như thế nào?", textAlign: TextAlign.center),
                                          actions: [
                                            TextButton(onPressed: () => Get.back(), child: const Text("HỦY", style: TextStyle(color: Colors.grey))),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                              onPressed: () {
                                                controller.kickMember(member.id!, false); // false = Giữ nợ
                                              },
                                              child: const Text("ĐUỔI (Giữ nợ)"),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                              onPressed: () {
                                                controller.kickMember(member.id!, true); // true = Xóa nợ (Tạo Expense mới chia đều)
                                              },
                                              child: const Text("ĐUỔI (Xóa nợ)", style: TextStyle(color: Colors.white)),
                                            )
                                          ]
                                      );
                                    },
                                  ),
                                ]
                              ],
                            ),
                          )
                      );
                    },
                  ),
                ),
              );
            },
          )
      );
    });
  }

  void _showDeleteConfirmDialog(BuildContext context, TripDetailController controller, int expenseId) {
    Get.dialog(
      AlertDialog(
        title: const Text("Xác nhận xóa?"),
        content: const Text("Khoản chi này sẽ bị xóa vĩnh viễn và số tiền sẽ được tính toán lại."),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("HỦY")),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteExpense(expenseId);
            },
            child: const Text("XÓA", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCreateInviteDialog(BuildContext context, TripDetailController controller) {
    final TextEditingController customCodeController = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.share, color: Colors.blue),
            SizedBox(width: 8),
            Text("Mã mời tham gia", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Obx(() {
          if (controller.activeInviteCode.value.isNotEmpty) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Chạm vào mã bên dưới để Copy và gửi cho bạn bè nhé!", textAlign: TextAlign.center),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: controller.copyToClipboard,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200, width: 2)),
                    child: Row(
                      children: [
                        Expanded(child: Text(controller.activeInviteCode.value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue, letterSpacing: 1.5), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        const Icon(Icons.copy, color: Colors.blue),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Bạn có thể tự tạo mã cho dễ nhớ, hoặc để trống để hệ thống tự sinh mã bảo mật."),
                const SizedBox(height: 16),
                TextField(
                  controller: customCodeController,
                  decoration: InputDecoration(labelText: "Mã tùy chỉnh (Không bắt buộc)", hintText: "VD: dilo, teamhuy...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.edit)),
                ),
              ],
            );
          }
        }),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("ĐÓNG", style: TextStyle(color: Colors.grey))),
          Obx(() {
            if (controller.activeInviteCode.value.isEmpty) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                onPressed: controller.isLoading.value ? null : () => controller.generateInviteCode(customCodeController.text.trim()),
                child: controller.isLoading.value ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("TẠO MÃ"),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }
}