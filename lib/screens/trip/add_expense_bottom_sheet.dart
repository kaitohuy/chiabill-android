import 'package:chiabill/theme/app_colors.dart';
import 'package:chiabill/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
// Thêm để dùng BackdropFilter
import '../../controllers/add_expense_controller.dart';
import '../../data/models/trip_response.dart';
import '../../data/models/expense_response.dart';
import '../../utils/currency_util.dart';
import 'widgets/add_category_dialog.dart';
import 'advanced_split_bottom_sheet.dart';

class AddExpenseBottomSheet extends StatefulWidget {
  final TripResponse trip;
  final ExpenseResponse? expenseToEdit;
  final DateTime? initialDate;
  final AddExpenseController controller; // Bổ sung tham số controller

  const AddExpenseBottomSheet({
    super.key, 
    required this.trip, 
    this.expenseToEdit, 
    this.initialDate,
    required this.controller, // Yêu cầu truyền từ ngoài vào
  });

  @override
  State<AddExpenseBottomSheet> createState() => _AddExpenseBottomSheetState();
}

class _AddExpenseBottomSheetState extends State<AddExpenseBottomSheet> {
  TripResponse get trip => widget.trip;
  ExpenseResponse? get expenseToEdit => widget.expenseToEdit;
  DateTime? get initialDate => widget.initialDate;

  @override
  void dispose() {
    // Xóa controller một cách an toàn tuyệt đối sau khi widget đã hoàn toàn bị gỡ khỏi widget tree
    // Xác định tag giống hệt lúc khởi tạo ở trip_detail_screen và expense_tab
    final isEditMode = widget.expenseToEdit != null;
    final tag = isEditMode 
        ? 'edit_${widget.expenseToEdit!.id}' 
        : (widget.initialDate != null ? 'add' : 'add_bg');
    
    if (Get.isRegistered<AddExpenseController>(tag: tag)) {
      Get.delete<AddExpenseController>(tag: tag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = expenseToEdit != null;
    final controller = widget.controller;

    return Obx(() => Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24, 
          right: 24, 
          top: 24, 
          bottom: 24,
        ),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        Text(
        isEditMode ? "Sửa khoản chi" : "Thêm chi phí mới",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)
        ),
        const SizedBox(height: 20),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: controller.amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CurrencyInputFormatter(),
                    ],
                    decoration: InputDecoration(
                      labelText: "Số tiền",
                      prefixIcon: Icon(Icons.attach_money, color: AppColors.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 56, // Khoảng tương đương chiều cao TextField
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Obx(() => DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: controller.selectedCurrency.value,
                        isExpanded: true,
                        menuMaxHeight: 300,
                        borderRadius: BorderRadius.circular(16),
                        dropdownColor: Colors.white,
                        icon: Icon(Icons.keyboard_arrow_down, color: AppColors.primary, size: 24),
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                        items: [
                          ...controller.currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                          DropdownMenuItem(
                            value: "ADD_NEW", 
                            child: Row(
                              children: [
                                Icon(Icons.add, color: AppColors.primary, size: 18),
                                const SizedBox(width: 4),
                                Text("Thêm", style: TextStyle(color: AppColors.primary)),
                              ]
                            )
                          )
                        ],
                        onChanged: (val) {
                          if (val == "ADD_NEW") {
                            _showAddCurrencyDialog(context, controller);
                          } else if (val != null) {
                            controller.selectedCurrency.value = val;
                            controller.fetchLatestExchangeRate(val);
                          }
                        },
                      ),
                    )),
                  ),
                ),
              ],
            ),
            
            // THÊM: Ô nhập tỷ giá nếu không phải VND
            Obx(() {
              if (controller.selectedCurrency.value == "VND") return const SizedBox(height: 16);
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Text("Vui lòng nhập tỷ giá nếu hiện tại đã thay đổi *", style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: controller.exchangeRateController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
                      CurrencyInputFormatter(),
                    ],
                    decoration: InputDecoration(
                      labelText: "Tỷ giá (1 ${controller.selectedCurrency.value} = ... VNĐ)",
                      prefixIcon: const Icon(Icons.currency_exchange, color: Colors.orange),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }),
            
            // Tính toán trước VNĐ (Real-time preview)
            Obx(() {
              if (controller.selectedCurrency.value == "VND" || controller.calculatedVnd.value == 0) return const SizedBox.shrink();
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "≈ ${CurrencyUtils.formatNumber(controller.calculatedVnd.value)} đ",
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                    ),
                  ],
                ),
              );
            }),
              TextField(
                controller: controller.descController,
                decoration: InputDecoration(
                  labelText: "Nội dung (VD: Tiền ăn trưa)",
                  prefixIcon: Icon(Icons.description, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

            // =====================================
            // HÀNG 1: NGÀY CHI TIÊU & DANH MỤC
            // =====================================
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Ngày chi tiêu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: controller.selectedDate.value,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(primary: AppColors.primary),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            controller.selectedDate.value = picked;
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: AppColors.primary, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Obx(() => Text(
                                  "${controller.selectedDate.value.day}/${controller.selectedDate.value.month}/${controller.selectedDate.value.year}",
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                )),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Danh mục", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _showCategoryPicker(context, controller),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              Obx(() {
                                final selectedCat = controller.categories.firstWhereOrNull((c) => c.id == controller.selectedCategoryId.value);
                                return Text(
                                  selectedCat?.icon ?? "📦",
                                  style: const TextStyle(fontSize: 20),
                                );
                              }),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Obx(() {
                                  final selectedCat = controller.categories.firstWhereOrNull((c) => c.id == controller.selectedCategoryId.value);
                                  return Text(
                                    selectedCat?.name ?? "Chọn",
                                    style: TextStyle(fontSize: 14, color: selectedCat == null ? Colors.grey : Colors.black87),
                                    overflow: TextOverflow.ellipsis,
                                  );
                                }),
                              ),
                              const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // =====================================
            // HÀNG 2: NGƯỜI TRẢ TIỀN & NGƯỜI CHIA
            // =====================================
            Obx(() {
              double amt = double.tryParse(
                  controller.amountController.text.replaceAll(',', '')) ?? 0.0;
              double rate = controller.selectedCurrency.value == "VND"
                  ? 1.0
                  : (double.tryParse(controller.exchangeRateController.text
                  .replaceAll(',', '')) ?? 1.0);
              double totalVnd = amt * rate;
              bool isFundSufficient = controller.fundBalance.value >= totalVnd;
              bool showPayer = !controller.isFromFund.value ||
                  !isFundSufficient;

              return Row(
                children: [
                  if (showPayer) ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.isFromFund.value
                                ? "Ai ứng phần thiếu?"
                                : "Ai đã trả tiền?",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha:0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primaryLight),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: controller.selectedPayerId.value,
                                isExpanded: true,
                                menuMaxHeight: 300,
                                borderRadius: BorderRadius.circular(16),
                                dropdownColor: Colors.white,
                                icon: Icon(Icons.keyboard_arrow_down,
                                    color: AppColors.primary, size: 20),
                                style: TextStyle(color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                                items: controller.activeMembers.map((m) =>
                                    DropdownMenuItem(value: m.user.id,
                                        child: Text(m.user.name ?? "Ẩn danh"))
                                ).toList(),
                                onChanged: (val) =>
                                controller.selectedPayerId.value = val!,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Chia cho ai?", style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () =>
                              Get.bottomSheet(AdvancedSplitBottomSheet(controller: controller), isScrollControlled: true, backgroundColor: Colors.transparent),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.primaryLight),
                              borderRadius: BorderRadius.circular(12),
                              color: AppColors.primaryBackgroundLight,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.group, color: AppColors.primary,
                                    size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Obx(() {
                                    int selectedCount = controller.selectedSplitMemberIds.length;
                                    int totalCount = controller.activeMembers.length;

                                    String modeText = "";
                                    if (controller.splitType.value == "PERCENTAGE") {
                                      modeText = " (%)";
                                    } else if (controller.splitType.value == "SHARES") {modeText = " (Tỉ trọng)";}
                                    else if (controller.splitType.value == "EXACT") {modeText = " (Chính xác)";}

                                    if (controller.splitType.value != "EQUAL") {
                                      int selectedKeys = controller.splitValues.keys.where((id) => (controller.splitValues[id] ?? 0) > 0).length;
                                      return Text("Đã chia $selectedKeys/$totalCount$modeText",
                                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                                          overflow: TextOverflow.ellipsis);
                                    }

                                    if (selectedCount == totalCount) {
                                      return Text("Tất cả mọi người",
                                          style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13),
                                          overflow: TextOverflow.ellipsis);
                                    } else if (selectedCount == 0) {
                                      return const Text("Chưa chọn",
                                          style: TextStyle(color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13),
                                          overflow: TextOverflow.ellipsis);
                                    } else {
                                      return Text("Đã chọn: $selectedCount",
                                          style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13),
                                          overflow: TextOverflow.ellipsis);
                                    }
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 20),

            // =====================================
            // SWITCH: THANH TOÁN BẰNG QUỸ CHUNG
            // =====================================
            Obx(() {
              if (!controller.isFundActivated.value) return const SizedBox.shrink();

              double amt = double.tryParse(controller.amountController.text.replaceAll(',', '')) ?? 0.0;
              double rate = controller.selectedCurrency.value == "VND" ? 1.0 : (double.tryParse(controller.exchangeRateController.text.replaceAll(',', '')) ?? 1.0);
              double totalVnd = amt * rate;
              bool isShortage = controller.isFromFund.value && totalVnd > controller.fundBalance.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: controller.isFromFund.value 
                          ? AppColors.primary.withValues(alpha:0.08)
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: controller.isFromFund.value 
                            ? AppColors.primary.withValues(alpha:0.3)
                            : Colors.grey[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance, 
                          color: controller.isFromFund.value ? AppColors.primary : Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Thanh toán bằng Quỹ chung",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Số dư Quỹ: ${CurrencyUtils.formatNumber(controller.fundBalance.value)} đ",
                                style: TextStyle(
                                  color: controller.fundBalance.value <= 200000 ? Colors.red : Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: controller.isFromFund.value,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) {
                            controller.isFromFund.value = val;
                          },
                        ),
                      ],
                    ),
                  ),
                  if (isShortage) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber[800], size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Số dư quỹ chung không đủ. Hệ thống sẽ tự động tách phần thiếu (${CurrencyUtils.formatNumber(totalVnd - controller.fundBalance.value)} đ) làm một hóa đơn riêng do mọi người cùng chia nợ, và chi trả phần còn lại từ quỹ chung.",
                              style: TextStyle(color: Colors.amber[900], fontSize: 11, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              );
            }),

            // =====================================
            // NÚT XÁC NHẬN
            // =====================================
            Obx(() => SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: controller.isLoading.value ? null : () => controller.submitExpense(),
                child: controller.isLoading.value
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                    isEditMode ? "CẬP NHẬT" : "XÁC NHẬN",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                ),
              ),
            )),
        ],
      ),
        ))
    ,
        // OVERLAY LOADING NỘI BỘ (Đã loại bỏ Blur để tránh lỗi BLASTBufferQueue trên Xiaomi)
        if (controller.isLoading.value)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white70,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEditMode ? "Đang cập nhật..." : "Đang lưu...",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ));
  }



  // ==========================================
  // DIALOG CHỌN DANH MỤC
  // ==========================================
  void _showCategoryPicker(BuildContext context, AddExpenseController controller) {
    Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Chọn danh mục", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: Obx(() {
              if (controller.isCategoriesLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              // Xử lý thêm trường hợp nếu rỗng thật (sau khi đã tải xong)
              if (controller.categories.isEmpty) {
                return const Center(child: Text("Chưa có danh mục nào.\nHãy tạo mới nhé!", textAlign: TextAlign.center));
              }

              if (controller.categories.isEmpty) return const Center(child: CircularProgressIndicator());

              return GridView.builder(
                // SỬA: Nới chiều cao ra một chút (từ 1 thành 0.85)
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10
                ),
                itemCount: controller.categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == controller.categories.length) {
                    return InkWell(
                      onTap: () {
                        Get.back();
                        _showCreateCategoryDialog(context, controller);
                      },
                      child: Container(
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: AppColors.primary, size: 28),
                            SizedBox(height: 4),
                            Text("Tạo mới", style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  }

                  final cat = controller.categories[index];
                  return InkWell(
                    onTap: () {
                      controller.selectedCategoryId.value = cat.id;
                      Get.back();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4), // Thêm padding nhỏ
                      decoration: BoxDecoration(
                        color: controller.selectedCategoryId.value == cat.id ? AppColors.primaryBackgroundLight : Colors.white,
                        border: Border.all(color: controller.selectedCategoryId.value == cat.id ? AppColors.primary : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // SỬA: Bọc Flexible để Icon/Emoji không bao giờ tràn
                          Flexible(
                            child: Text(
                              cat.icon ?? "📦",
                              style: const TextStyle(fontSize: 26),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // SỬA: Giới hạn tên danh mục tối đa 2 dòng, quá thì cắt ...
                          Text(
                            cat.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, height: 1.2),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        )
    );
  }

  // ==========================================
  // DIALOG TẠO DANH MỤC MỚI (CÓ BỘ CHỌN EMOJI)
  // ==========================================
  void _showCreateCategoryDialog(BuildContext context, AddExpenseController controller) {
    Get.dialog(AddCategoryDialog(controller: controller, trip: trip));
  }

  void _showAddCurrencyDialog(BuildContext context, AddExpenseController controller) {
    final ctrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Thêm tiền tệ mới", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.characters,
          maxLength: 3,
          decoration: InputDecoration(
            labelText: "Mã tiền tệ (VD: CAD)",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("HỦY", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              final newCurrency = ctrl.text.trim().toUpperCase();
              if (newCurrency.length == 3) {
                if (!controller.currencies.contains(newCurrency)) {
                  controller.currencies.add(newCurrency);
                }
                controller.selectedCurrency.value = newCurrency;
                controller.fetchLatestExchangeRate(newCurrency);
                Get.back();
              } else {
                ToastUtil.showWarning("Lỗi", "Mã tiền tệ phải có đúng 3 ký tự");
              }
            },
            child: const Text("THÊM"),
          )
        ],
      )
    );
  }
}
