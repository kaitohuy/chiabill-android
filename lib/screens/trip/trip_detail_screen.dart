import 'package:chiabill/theme/app_colors.dart';
import 'package:chiabill/screens/trip/tabs/expense_tab.dart';
import 'package:chiabill/screens/trip/tabs/member_tabs.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../controllers/add_expense_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/trip_detail_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../controllers/ghost_controller.dart';
import '../../controllers/trip_expense_controller.dart';
import 'add_expense_bottom_sheet.dart';
import 'history_screen.dart';
import 'import_member_screen.dart';
import 'tabs/group_fund_tab.dart';
import 'tabs/settlements_tab.dart';

class TripDetailScreen extends StatefulWidget {
  final int tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  late TripDetailController controller;

  @override
  void initState() {
    super.initState();
    Get.put(ProfileController(), permanent: true);
    Get.delete<TripDetailController>(tag: widget.tripId.toString(), force: true);
    controller = Get.put(TripDetailController(widget.tripId), tag: widget.tripId.toString());
  }

  @override
  void dispose() {
    Get.delete<TripDetailController>(tag: widget.tripId.toString(), force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Obx(() => Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            controller.trip.value?.name ?? "Chi tiết",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
          ),
        )),
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () => _showCreateInviteDialog(context, controller),
          ),
          Obx(() => controller.currentTab.value == 0 
            ? IconButton(
                icon: Icon(Icons.calendar_month_outlined, color: Colors.white),
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: Get.find<TripExpenseController>(tag: controller.tripId.toString()).selectedExpenseDate.value ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    Get.find<TripExpenseController>(tag: controller.tripId.toString()).onExpenseDateChanged(picked);
                  }
                },
              )
            : const SizedBox.shrink()),
          IconButton(
            icon: Icon(Icons.history, color: Colors.white),
            onPressed: () => Get.to(() => HistoryScreen(mainController: controller)),
          ),
          IconButton(
            icon: Icon(Icons.file_download_outlined, color: Colors.white),
            onPressed: () => _showExportDialog(context, controller),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.trip.value == null) {
          return Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        switch (controller.currentTab.value) {
          case 0: return ExpensesTab(mainController: controller);
          case 1: return GroupFundTab(mainController: controller);
          case 2: return SettlementsTab(mainController: controller);
          case 3: return MembersTab(
              controller: controller,
              onAddMemberTap: () => _showAddMemberOptions(context, controller)
          );
          default: return ExpensesTab(mainController: controller);
        }
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Obx(() {
        Get.find<ThemeController>().currentTheme.value;
        return FloatingActionButton(
          onPressed: _handleFabPress,
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          elevation: 4,
          child: Icon(Icons.add, color: Colors.white, size: 32),
        );
      }),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 10,
        notchMargin: 8,
        shape: const CircularNotchedRectangle(),
        child: SizedBox(
          height: 60, // Đồng bộ với MainScreen
          child: Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBottomTab(0, Icons.list_alt_outlined, Icons.list_alt, "Chi tiêu"),
              _buildBottomTab(1, Icons.account_balance_outlined, Icons.account_balance, "Quỹ chung"),
              const SizedBox(width: 48), // Khoảng trống cho FAB
              _buildBottomTab(2, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, "Nợ nần"),
              _buildBottomTab(3, Icons.people_outline, Icons.people, "Thành viên"),
            ],
          )),
        ),
      ),
    );
  }

  Widget _buildBottomTab(int index, IconData icon, IconData activeIcon, String label) {
    bool isSelected = controller.currentTab.value == index;
    Color color = isSelected ? AppColors.primary : Colors.grey[600]!;
    
    return MaterialButton(
      minWidth: 40,
      onPressed: () => controller.currentTab.value = index,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isSelected ? activeIcon : icon, color: color, size: 24),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  void _handleFabPress() {
    if (controller.trip.value == null) return;
    
    // Nếu ở tab thành viên thì hiện menu thêm TV, còn lại là thêm chi phí
    if (controller.currentTab.value == 3) {
      _showAddMemberOptions(context, controller);
    } else {
      const tag = 'add';
      // Khởi tạo controller ở đây
      final addController = Get.put(
          AddExpenseController(controller.trip.value!, initialDate: Get.find<TripExpenseController>(tag: controller.tripId.toString()).selectedExpenseDate.value),
          tag: tag
      );

      Get.bottomSheet(
        AddExpenseBottomSheet(
          trip: controller.trip.value!,
          initialDate: Get.find<TripExpenseController>(tag: controller.tripId.toString()).selectedExpenseDate.value,
          controller: addController, // Truyền controller vào
        ), 
        isScrollControlled: true
      );
    }
  }

  // ==========================================
  // HÀM DIALOGS (Giữ nguyên logic cũ nhưng style mới)
  // ==========================================
  void _showExportDialog(BuildContext context, TripDetailController controller) {
    // State nội bộ của BottomSheet dùng StatefulBuilder (đồng bộ pattern với _showMonthYearPicker)
    bool includeDetails = true;
    bool includeSettlement = true;
    String? selectedFormat; // null = chưa chọn format

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              top: 8,
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),

                const Text("Xuất báo cáo", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("Chọn định dạng và nội dung muốn xuất", style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                const SizedBox(height: 20),

                // ── Chọn định dạng file ──
                const Text("Định dạng", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.5)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildFormatChip(
                      icon: Icons.table_view_outlined,
                      label: "Excel",
                      sublabel: ".xlsx",
                      isSelected: selectedFormat == 'excel',
                      onTap: () => setSheetState(() => selectedFormat = 'excel'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _buildFormatChip(
                      icon: Icons.picture_as_pdf_outlined,
                      label: "PDF",
                      sublabel: ".pdf",
                      isSelected: selectedFormat == 'pdf',
                      onTap: () => setSheetState(() => selectedFormat = 'pdf'),
                    )),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Chọn nội dung muốn export ──
                const Text("Nội dung xuất", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.5)),
                const SizedBox(height: 8),

                _buildExportOptionTile(
                  icon: Icons.list_alt_outlined,
                  title: "Thông tin tổng quan",
                  subtitle: "Thành viên, ngân sách, thống kê danh mục",
                  value: true, // Luôn bật, không thể tắt
                  enabled: false,
                  onChanged: null,
                ),
                _buildExportOptionTile(
                  icon: Icons.receipt_long_outlined,
                  title: "Chi tiết từng khoản chi",
                  subtitle: "Ngày, tên khoản, người trả, số tiền, ghi chú",
                  value: includeDetails,
                  enabled: true,
                  onChanged: (val) => setSheetState(() => includeDetails = val ?? false),
                ),
                _buildExportOptionTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: "Bảng quyết toán nợ",
                  subtitle: "Ai nợ ai bao nhiêu sau khi tính toán",
                  value: includeSettlement,
                  enabled: true,
                  onChanged: (val) => setSheetState(() => includeSettlement = val ?? false),
                ),

                const SizedBox(height: 20),

                // ── Nút Xuất ──
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedFormat == null ? Colors.grey[300] : AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: selectedFormat == null ? 0 : 2,
                    ),
                    onPressed: selectedFormat == null ? null : () {
                      Get.back();
                      controller.exportTrip(
                        selectedFormat!,
                        includeDetails: includeDetails,
                        includeSettlement: includeSettlement,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selectedFormat == 'pdf' ? Icons.picture_as_pdf_outlined : Icons.file_download_outlined,
                          color: selectedFormat == null ? Colors.grey : Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          selectedFormat == null ? "Chọn định dạng trước" : "XUẤT ${selectedFormat!.toUpperCase()}",
                          style: TextStyle(
                            color: selectedFormat == null ? Colors.grey : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  // Chip chọn định dạng file (Excel / PDF)
  Widget _buildFormatChip({
    required IconData icon,
    required String label,
    required String sublabel,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[200]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppColors.primary : Colors.black87, fontSize: 14)),
                Text(sublabel, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ],
            ),
            if (isSelected) ...[
              const Spacer(),
              Icon(Icons.check_circle, color: AppColors.primary, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  // Tile option tick chọn nội dung export
  Widget _buildExportOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required ValueChanged<bool?>? onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: AppColors.primary,
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Row(
          children: [
            Icon(icon, size: 18, color: enabled ? AppColors.primary : Colors.grey[400]),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: enabled ? Colors.black87 : Colors.grey)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 26),
          child: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        ),
      ),
    );
  }



  void _showAddMemberOptions(BuildContext context, TripDetailController controller) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(top: 20, left: 0, right: 0, bottom: MediaQuery.of(context).padding.bottom + 20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Thêm thành viên", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildActionItem(Icons.person_outline, "Người ảo (không dùng app)", "Tạo tài khoản giả để bạn chia tiền thay họ.", () {
              Get.back();
              _showAddGhostDialog(context, controller.tripId);
            }),
            _buildActionItem(Icons.group_add_outlined, "Nhập từ nhóm khác", "Thêm nhanh thành viên từ nhóm bạn đã tham gia.", () {
              Get.back();
              Get.to(() => ImportMemberScreen(currentTripId: controller.tripId));
            }),
            _buildActionItem(Icons.search, "Tìm qua SĐT / Email", "Thêm người dùng đã đăng ký app vào nhóm.", () {
              Get.back();
              _showAddDirectMemberDialog(context, controller);
            }),
            _buildActionItem(Icons.share_outlined, "Chia sẻ mã mời", "Gửi link hoặc mã QR cho bạn bè tự tham gia.", () {
              Get.back();
              _showCreateInviteDialog(context, controller);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppColors.primaryDark),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12)),
      onTap: onTap,
    );
  }

  void _showAddDirectMemberDialog(BuildContext context, TripDetailController controller) {
    final TextEditingController inputController = TextEditingController();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Thêm thành viên", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Nhập Email hoặc SĐT người dùng đã đăng ký app.", style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: inputController,
              decoration: InputDecoration(
                hintText: "VD: 0987654321",
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              )
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("HỦY", style: TextStyle(color: Colors.grey))),
          Obx(() => ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: controller.isAddingMember.value ? null : () => controller.addDirectMember(inputController.text),
            child: controller.isAddingMember.value ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("THÊM"),
          )),
        ],
      ),
    );
  }

  void _showAddGhostDialog(BuildContext context, int tripId) {
    final ghostController = Get.put(GhostController(tripId));
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Thêm người ảo", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Nhập tên những người không dùng app (cách nhau bằng dấu phẩy).", style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: ghostController.namesController,
              decoration: InputDecoration(
                hintText: "VD: Bố, Mẹ, Anh Hai...",
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              )
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("HỦY")),
          Obx(() => ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: ghostController.isLoading.value ? null : () => ghostController.submitGhosts(),
            child: const Text("XÁC NHẬN")
          )),
        ],
      ),
    );
  }

  void _showCreateInviteDialog(BuildContext context, TripDetailController controller) {
    final TextEditingController customCodeController = TextEditingController();
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Obx(() {
          if (controller.activeInviteCode.value.isNotEmpty) {
            String inviteCode = controller.activeInviteCode.value;
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Mã mời tham gia", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  QrImageView(
                    data: inviteCode,
                    version: QrVersions.auto,
                    size: 200.0,
                    dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Colors.black87),
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                    child: Text(inviteCode, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      icon: Icon(Icons.share),
                      label: const Text("CHIA SẺ LINK", style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => controller.shareInviteLink(),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Tạo mã mời", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text("Để trống để hệ thống tự sinh mã bảo mật.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: customCodeController,
                    decoration: InputDecoration(hintText: "Mã tùy chỉnh...", filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: controller.isLoading.value ? null : () => controller.generateInviteCode(customCodeController.text),
                      child: const Text("TẠO MÃ", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          }
        }),
      ),
    );
  }
}