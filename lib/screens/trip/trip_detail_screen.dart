import 'package:chiabill/screens/trip/tabs/expense_tab.dart';
import 'package:chiabill/screens/trip/tabs/member_tabs.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/trip_detail_controller.dart';
import '../../controllers/ghost_controller.dart';
import 'add_expense_bottom_sheet.dart';
import 'tabs/settlements_tab.dart';
import 'tabs/stats_tab.dart';
import 'tabs/history_tab.dart';

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
    Get.put(ProfileController(), permanent: true);
    Get.delete<TripDetailController>(tag: widget.tripId.toString(), force: true);
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
          Obx(() {
            if (controller.activeInviteCode.value.isNotEmpty) {
              return Center(
                child: GestureDetector(
                  onTap: () => _showCreateInviteDialog(context, controller),
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.qr_code, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(controller.activeInviteCode.value, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              return Center(
                child: GestureDetector(
                  onTap: () => _showCreateInviteDialog(context, controller),
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_link, size: 14, color: Colors.lightGreen[800]),
                        const SizedBox(width: 4),
                        Text("Tạo mã", style: TextStyle(fontSize: 12, color: Colors.lightGreen[800], fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              );
            }
          }),
          
          // NÚT XUẤT FILE (BÊN CẠNH MÃ MỜI)
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: "Xuất báo cáo",
            onSelected: (value) => controller.exportTrip(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'excel',
                child: Row(children: [Icon(Icons.table_chart, color: Colors.green, size: 20), SizedBox(width: 12), Text("Xuất Excel (.xlsx)")]),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Row(children: [Icon(Icons.picture_as_pdf, color: Colors.red, size: 20), SizedBox(width: 12), Text("Xuất PDF (.pdf)")]),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1))),
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

      body: Obx(() {
        if (controller.isLoading.value && controller.trip.value == null) {
          return const Center(child: CircularProgressIndicator(color: Colors.lightGreen));
        }

        switch (controller.currentTab.value) {
          case 0: return ExpensesTab(controller: controller);
          case 1: return SettlementsTab(controller: controller);
          case 2: return StatsTab(controller: controller);
          case 3: return HistoryTab(controller: controller);
          case 4: return MembersTab(
              controller: controller,
              onAddMemberTap: () => _showAddMemberOptions(context, controller) // Truyền hàm xuống
          );
          default: return const SizedBox.shrink();
        }
      }),

      floatingActionButton: Obx(() {
        if (controller.currentTab.value == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: FloatingActionButton.extended(
              onPressed: () {
                if (controller.trip.value != null) {
                  Get.bottomSheet(AddExpenseBottomSheet(trip: controller.trip.value!), isScrollControlled: true);
                }
              },
              backgroundColor: Colors.orange, foregroundColor: Colors.white,
              icon: const Icon(Icons.add), label: const Text("Thêm chi phí", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          );
        } else if (controller.currentTab.value == 4) {
          // 🌟 ĐẨY NÚT LÊN CAO ĐỂ TRÁNH NÚT RỜI NHÓM NẰM DƯỚI CÙNG
          return Padding(
            padding: const EdgeInsets.only(bottom: 60.0),
            child: FloatingActionButton.extended(
              onPressed: () => _showAddMemberOptions(context, controller),
              backgroundColor: Colors.lightBlue, foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add), label: const Text("Thành viên", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
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
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isSelected ? Colors.orange : Colors.transparent, width: 3))),
          child: Icon(icon, color: isSelected ? Colors.orange : Colors.grey.shade400, size: 26),
        ),
      ),
    );
  }

  // ==========================================
  // FULL CÁC HÀM DIALOG THÊM THÀNH VIÊN
  // ==========================================
  void _showAddMemberOptions(BuildContext context, TripDetailController controller) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(top: 20, left: 0, right: 0, bottom: 20 + MediaQuery.of(context).padding.bottom),
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
              subtitle: const Text("Tạo mã QR và link chia sẻ cho bạn bè"),
              onTap: () {
                Get.back();
                _showCreateInviteDialog(context, controller);
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
            TextField(controller: inputController, decoration: InputDecoration(hintText: "VD: 0987654321 hoặc a@gmail.com", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.contact_mail))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("HỦY", style: TextStyle(color: Colors.grey))),
          Obx(() => ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: controller.isAddingMember.value ? null : () => controller.addDirectMember(inputController.text),
            child: controller.isAddingMember.value ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("TÌM & THÊM"),
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
            TextField(controller: ghostController.namesController, decoration: InputDecoration(hintText: "VD: Bố, Mẹ, Bé Bo...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("HỦY")),
          Obx(() => ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white), onPressed: ghostController.isLoading.value ? null : () => ghostController.submitGhosts(), child: const Text("XÁC NHẬN"))),
        ],
      ),
    );
  }

  // ==========================================
  // HỘP THOẠI TẠO MÃ MỜI - GIAO DIỆN VIP TICKET
  // ==========================================
  void _showCreateInviteDialog(BuildContext context, TripDetailController controller) {
    final TextEditingController customCodeController = TextEditingController();

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent, // Nền trong suốt để tự vẽ khung
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24), // Bo góc sâu cho hiện đại
          ),
          child: Obx(() {
            // =====================================
            // TRẠNG THÁI 1: ĐÃ CÓ MÃ -> HIỆN QR & TICKET
            // =====================================
            if (controller.activeInviteCode.value.isNotEmpty) {
              String inviteCode = controller.activeInviteCode.value;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. HEADER (Màu xanh thương hiệu)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: const BoxDecoration(
                      color: Colors.lightGreen,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.airplane_ticket, color: Colors.white, size: 32),
                        SizedBox(height: 8),
                        Text(
                          "THẺ MỜI THAM GIA",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Text("Đưa mã QR này cho bạn bè quét nhé!", style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 20),

                        // 2. MÃ QR BO TRÒN HIỆN ĐẠI
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(color: Colors.lightGreen.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))
                            ],
                          ),
                          child: QrImageView(
                            data: inviteCode,
                            version: QrVersions.auto,
                            size: 180.0,
                            backgroundColor: Colors.white,
                            // Bo tròn các chấm đen bên trong QR
                            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Colors.black87),
                            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: Colors.black87),
                          ),
                        ),

                        const SizedBox(height: 32),
                        const Text("HOẶC COPY MÃ THỦ CÔNG", style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        const SizedBox(height: 12),

                        // 3. KHU VỰC TEXT COPY (Dạng Voucher)
                        InkWell(
                          onTap: controller.copyToClipboard,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                            decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade300, width: 1.5)
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  inviteCode,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: 2.0),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
                                  ),
                                  child: const Icon(Icons.copy, color: Colors.lightGreen, size: 18),
                                )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 4. NÚT SHARE TO & NỔI BẬT
                        // 4. NÚT SHARE TO & NỔI BẬT
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.lightGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                            ),
                            icon: const Icon(Icons.send_rounded),
                            label: const Text("GỬI QUA ZALO / MESSENGER", style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              // Bọc chuỗi String vào trong ShareParams(text: ...)
                              SharePlus.instance.share(
                                ShareParams(
                                  text: 'Tham gia nhóm chia tiền trên ChiaBill cùng mình nhé!\n\nMã mời: $inviteCode\n\nHoặc mở app ChiaBill quét mã QR để vào nhóm ngay.',
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 8),
                        TextButton(
                            onPressed: () => Get.back(),
                            child: const Text("Đóng", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
                        )
                      ],
                    ),
                  ),
                ],
              );
            } else {
              // =====================================
              // TRẠNG THÁI 2: CHƯA CÓ MÃ -> HIỆN FORM TẠO
              // =====================================
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, size: 48, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text("Tạo mã mời", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text("Bạn có thể tự tạo mã cho dễ nhớ, hoặc để trống để hệ thống tự sinh mã bảo mật ngẫu nhiên.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, height: 1.4)),
                    const SizedBox(height: 24),

                    TextField(
                      controller: customCodeController,
                      decoration: InputDecoration(
                          labelText: "Mã tùy chỉnh (VD: teamhuy...)",
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.edit_note, color: Colors.grey)
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                            child: TextButton(
                                onPressed: () => Get.back(),
                                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                                child: const Text("HỦY", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
                            )
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.lightGreen,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                              ),
                              onPressed: controller.isLoading.value ? null : () => controller.generateInviteCode(customCodeController.text.trim()),
                              child: controller.isLoading.value
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text("TẠO MÃ", style: TextStyle(fontWeight: FontWeight.bold)),
                            )
                        ),
                      ],
                    )
                  ],
                ),
              );
            }
          }),
        ),
      ),
    );
  }
}