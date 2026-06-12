import 'package:chiabill/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/empty_state.dart';
import '../../../controllers/add_expense_controller.dart';
import '../../../controllers/trip_detail_controller.dart';
import '../../../controllers/trip_expense_controller.dart';
import '../../../controllers/itinerary_controller.dart';
import '../../../data/models/itinerary_item_response.dart';
import '../../trip/itinerary_screen.dart';
import '../../../utils/currency_util.dart';
import '../add_expense_bottom_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart' as org_cached;
import '../../../utils/ui_util.dart';

class ExpensesTab extends StatefulWidget {
  final TripDetailController mainController;
  const ExpensesTab({super.key, required this.mainController});

  @override
  State<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<ExpensesTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  TripExpenseController get controller => Get.find<TripExpenseController>(tag: widget.mainController.tripId.toString());

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Column(
      children: [
        // Thanh tìm kiếm và Lọc nâng cao
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => controller.applyExpenseFilter(keyword: value),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                      hintText: "Tìm chi phí...",
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 12, right: 8),
                        child: Icon(Icons.search, color: Colors.grey, size: 20),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 24,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Obx(() {
                bool hasFilter = controller.filterCategoryId.value != null || controller.filterPayerId.value != null;
                return InkWell(
                  onTap: () => _showExpenseFilterBottomSheet(context, controller, widget.mainController),
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: hasFilter ? Colors.orange : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(15)
                      ),
                      child: Icon(Icons.tune, size: 20, color: hasFilter ? Colors.white : Colors.grey.shade700)
                  ),
                );
              }),
              const SizedBox(width: 10),
              Obx(() {
                bool hasDateFilter = controller.selectedExpenseDate.value != null;
                return InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: controller.selectedExpenseDate.value ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      controller.onExpenseDateChanged(picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: hasDateFilter ? AppColors.primary : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(15)
                      ),
                      child: Icon(Icons.calendar_month_outlined, size: 20, color: hasDateFilter ? Colors.white : Colors.grey.shade700)
                  ),
                );
              }),
            ],
          ),
        ),

        // Thanh chọn ngày ngang
        _buildDateFilter(),

        // Banner lịch trình hôm nay
        _buildQuickItineraryBanner(),

        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => UIUtil.smartTap(context, () {
              if (widget.mainController.isCurrentUserDisabled) {
                Get.snackbar(
                  "Thông báo",
                  "Bạn đã bị tạm ngưng hoạt động trong chuyến đi này, không thể thực hiện thao tác này.",
                  backgroundColor: Colors.redAccent,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
              if (widget.mainController.trip.value != null && controller.expenses.isEmpty) {
                const tag = 'add_bg';
                final addController = Get.put(
                    AddExpenseController(widget.mainController.trip.value!),
                    tag: tag
                );

                Get.bottomSheet(
                  AddExpenseBottomSheet(
                    trip: widget.mainController.trip.value!,
                    controller: addController,
                  ), 
                  isScrollControlled: true
                );
              }
            }),
            child: Obx(() {
              if (widget.mainController.isLoading.value && controller.expenses.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.expenses.isEmpty) {
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => widget.mainController.fetchData(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: Get.height * 0.15),
                      const EmptyState(text: "Chưa có khoản chi nào.\nChạm vào bất cứ đâu để thêm mới!"),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => widget.mainController.fetchData(),
                child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (!controller.isLoadingMoreExpenses.value && scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                        controller.fetchExpenses(isRefresh: false);
                      }
                      return false;
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.expenses.length + (controller.isExpenseLastPage.value ? 0 : 1),
                      itemBuilder: (context, index) {
                        if (index == controller.expenses.length) {
                          return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Center(child: CircularProgressIndicator(color: AppColors.primary))
                          );
                        }

                        final expense = controller.expenses[index];
                        final payer = expense.payer;
                        String payerInitial = (payer?.name != null && payer!.name!.trim().isNotEmpty) ? payer.name!.trim()[0].toUpperCase() : "?";
                        String categoryIcon = expense.categoryIcon ?? "📦";

                        return Card(
                          key: ValueKey(expense.id), // Thêm key đềEđịnh danh chính xác widget
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade100),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              if (Get.isBottomSheetOpen == true || Get.isDialogOpen == true) return;
                              if (widget.mainController.isCurrentUserDisabled) {
                                Get.snackbar(
                                  "Thông báo",
                                  "Bạn đã bị tạm ngưng hoạt động trong chuyến đi này, không thể thực hiện thao tác này.",
                                  backgroundColor: Colors.redAccent,
                                  colorText: Colors.white,
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                                return;
                              }
                              final tag = 'edit_${expense.id}';
                              // Khởi tạo controller đềEđây thay vì bên trong build của BottomSheet
                              final addController = Get.put(
                                  AddExpenseController(widget.mainController.trip.value!, expenseToEdit: expense),
                                  tag: tag
                              );

                              Get.bottomSheet(
                                  AddExpenseBottomSheet(
                                    trip: widget.mainController.trip.value!,
                                    expenseToEdit: expense,
                                    controller: addController,
                                  ),
                                  isScrollControlled: true
                              );
                            },
                            onLongPress: () {
                              if (widget.mainController.isCurrentUserDisabled) {
                                Get.snackbar(
                                  "Thông báo",
                                  "Bạn đã bị tạm ngưng hoạt động trong chuyến đi này, không thể thực hiện thao tác này.",
                                  backgroundColor: Colors.redAccent,
                                  colorText: Colors.white,
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                                return;
                              }
                              _showDeleteConfirmDialog(context, controller, expense.id);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50, height: 50,
                                    decoration: BoxDecoration(
                                        color: AppColors.primaryBackgroundLight,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: AppColors.primaryLight, width: 1.5)
                                    ),
                                    child: Center(child: Text(categoryIcon, style: TextStyle(fontSize: 26))),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                  expense.description,
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.2),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis
                                              ),
                                            ),
                                            if (expense.id == -1) ...[
                                              const SizedBox(width: 4),
                                              Icon(Icons.schedule, size: 14, color: Colors.orange),
                                            ]
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Text("Bởi: ", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                            CircleAvatar(
                                              radius: 9,
                                              backgroundColor: payer?.isGhost == true ? Colors.grey[300] : AppColors.primaryBackground,
                                              backgroundImage: (payer?.avatarUrl != null && payer!.avatarUrl!.isNotEmpty) ? org_cached.CachedNetworkImageProvider(payer.avatarUrl!, maxWidth: 100, maxHeight: 100) : null,
                                              child: (payer?.avatarUrl == null || payer!.avatarUrl!.isEmpty)
                                                  ? (payer?.isGhost == true ? Icon(Icons.visibility_off, color: Colors.grey, size: 10) : Text(payerInitial, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 9)))
                                                  : null,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                                child: Text(
                                                    payer?.name ?? 'Ẩn danh',
                                                    style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.w500),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis
                                                )
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (expense.currency != null && expense.currency != 'VND' && expense.exchangeRate != null && expense.exchangeRate! > 0) ...[
                                        Text(
                                            "${CurrencyUtils.formatNumber(expense.totalAmount / expense.exchangeRate!)} ${expense.currency}",
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[600])
                                        ),
                                        const SizedBox(height: 2),
                                      ],
                                      Text(
                                          "${CurrencyUtils.formatNumber(expense.totalAmount)} đ",
                                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.redAccent)
                                      ),
                                    ]
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    )
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildDateFilter() {
    return Obx(() {
      final month = controller.selectedExpenseMonth.value;
      final year = controller.selectedExpenseYear.value;
      
      // Lấy danh sách ngày trong tháng/năm đang được chọn
      final lastDay = DateTime(year, month + 1, 0).day;
      final List<DateTime> daysInMonth = List.generate(
        lastDay,
        (index) => DateTime(year, month, index + 1),
      );

      // // Tìm index của ngày chọn để scroll tới (nếu cần xử lý logic thêm)
      // final selectedDate = controller.selectedExpenseDate.value;

      return Container(
        height: 70,
        margin: const EdgeInsets.only(bottom: 8),
        child: ListView.builder(
          controller: controller.dateScrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: daysInMonth.length + 2, // +1 "Tất cả", +1 "Đổi tháng/năm"
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildDateChip(null, "Tất cả");
            }
            if (index == 1) {
              // Nút Đổi tháng/năm Premium
              return GestureDetector(
                onTap: () => _showMonthYearPicker(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  margin: const EdgeInsets.only(right: 8, top: 12, bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBackgroundLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primaryLight, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month_outlined, color: AppColors.primaryDark, size: 18),
                      const SizedBox(width: 6),
                      Text("T$month/$year", style: TextStyle(color: AppColors.primaryDark, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            }
            final date = daysInMonth[index - 2];
            return _buildDayCard(date);
          },
        ),
      );
    });
  }

  void _showMonthYearPicker(BuildContext context) {
    int tempMonth = controller.selectedExpenseMonth.value;
    int tempYear = controller.selectedExpenseYear.value;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Chọn thời gian", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () => Get.back(), icon: Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text("Tháng", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    int m = index + 1;
                    bool isSelected = tempMonth == m;
                    return InkWell(
                      onTap: () => setDialogState(() => tempMonth = m),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.primaryBackgroundLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? AppColors.primary : AppColors.primaryBackground),
                        ),
                        child: Center(
                          child: Text(
                            "Tháng $m",
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.primaryDark,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text("Năm", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 45,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 16, // Ví dụ: từ 2020 đến 2035
                    itemBuilder: (context, index) {
                      int y = 2020 + index;
                      bool isSelected = tempYear == y;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ChoiceChip(
                          label: Text("$y", style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.primaryBackgroundLight,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? AppColors.primary : AppColors.primaryBackground)),
                          onSelected: (val) => setDialogState(() => tempYear = y),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      controller.onExpenseMonthYearChanged(tempMonth, tempYear);
                      Get.back();
                    },
                    child: const Text("XÁC NHẬN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          }
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildDayCard(DateTime date) {
    return Obx(() {
      bool isSelected = controller.selectedExpenseDate.value != null &&
          controller.selectedExpenseDate.value!.day == date.day &&
          controller.selectedExpenseDate.value!.month == date.month &&
          controller.selectedExpenseDate.value!.year == date.year;

      final isToday = _isToday(date);
      final weekday = _getWeekdayName(date.weekday);
      final Color textColor = isSelected ? Colors.white : Colors.black87;

      return GestureDetector(
        onTap: () => controller.onExpenseDateChanged(date),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.only(right: 8, top: 12, bottom: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : (isToday ? AppColors.primary.withValues(alpha: 0.1) : AppColors.primaryBackgroundLight),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : (isToday ? AppColors.primary.withValues(alpha: 0.3) : AppColors.primaryBackground),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              "$weekday, ${date.day}/${date.month}",
              style: TextStyle(
                fontSize: 13,
                color: textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    });
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1: return "Th 2";
      case 2: return "Th 3";
      case 3: return "Th 4";
      case 4: return "Th 5";
      case 5: return "Th 6";
      case 6: return "Th 7";
      case 7: return "CN";
      default: return "";
    }
  }

  Widget _buildDateChip(DateTime? date, String label) {
    return Obx(() {
      bool isSelected = false;
      if (date == null) {
        isSelected = controller.selectedExpenseDate.value == null;
      } else {
        isSelected = controller.selectedExpenseDate.value != null &&
            controller.selectedExpenseDate.value!.day == date.day &&
            controller.selectedExpenseDate.value!.month == date.month &&
            controller.selectedExpenseDate.value!.year == date.year;
      }

      return GestureDetector(
        onTap: () => controller.onExpenseDateChanged(date),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.only(right: 8, top: 12, bottom: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange : AppColors.primaryBackgroundLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.orange : AppColors.primaryBackground,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.primaryDark,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    });
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.day == now.day && date.month == now.month && date.year == now.year;
  }


  void _showExpenseFilterBottomSheet(BuildContext context, TripExpenseController controller, TripDetailController mainController) {
    int? tempCatId = controller.filterCategoryId.value;
    int? tempPayerId = controller.filterPayerId.value;
    bool showAllCategories = false;

    Get.bottomSheet(
      StatefulBuilder(
          builder: (context, setState) {
            final categoriesToDisplay = showAllCategories 
                ? controller.categories 
                : controller.categories.take(6).toList();

            return Container(
              padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 20 + MediaQuery.of(context).padding.bottom),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("BềElọc nâng cao", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(onPressed: () => Get.back(), icon: Icon(Icons.close))
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text("Theo danh mục:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        ...categoriesToDisplay.map((cat) {
                          bool isSelected = tempCatId == cat.id;
                          return ChoiceChip(
                              label: Text("${cat.icon ?? ''} ${cat.name}"),
                              selected: isSelected,
                              selectedColor: Colors.orange.withValues(alpha: 0.2),
                              labelStyle: TextStyle(color: isSelected ? Colors.orange[800] : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                              onSelected: (val) { setState(() => tempCatId = val ? cat.id : null); }
                          );
                        }),
                        if (!showAllCategories && controller.categories.length > 6)
                          ActionChip(
                            label: const Text("Hiện thêm...", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                            onPressed: () => setState(() => showAllCategories = true),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text("Theo người trả tiền:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: (mainController.trip.value?.members ?? []).map((m) {
                        bool isSelected = tempPayerId == m.user.id;
                        return ChoiceChip(
                            label: Text(m.user.name ?? "Ẩn danh"),
                            selected: isSelected,
                            selectedColor: Colors.orange.withValues(alpha: 0.2),
                            labelStyle: TextStyle(color: isSelected ? Colors.orange[800] : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                            onSelected: (val) { setState(() => tempPayerId = val ? m.user.id : null); }
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () { setState(() { tempCatId = null; tempPayerId = null; }); },
                            child: const Text("Xóa lọc", style: TextStyle(color: Colors.red)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              controller.applyExpenseFilter(catId: tempCatId, payerId: tempPayerId);
                              Get.back();
                            },
                            child: const Text("ÁP DỤNG", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          }
      ),
      isScrollControlled: true,
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, TripExpenseController controller, int expenseId) {
    // Tìm expense cần xóa để kiểm tra có phải đợt thu quỹ chung không
    final expense = controller.expenses.firstWhereOrNull((e) => e.id == expenseId);
    final isFundCollectionExpense = expense != null &&
        (expense.isFromFund ||
         expense.description.startsWith("Yêu cầu đóng quỹ") ||
         expense.categoryName?.contains("Quỹ") == true);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 10,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon header nổi bật
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFundCollectionExpense ? Icons.account_balance_wallet_outlined : Icons.delete_sweep_outlined,
                  color: Colors.red.shade700,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                isFundCollectionExpense ? "Hủy đợt thu quỹ chung?" : "Xác nhận xóa chi phí?",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                isFundCollectionExpense
                    ? "Đợt thu này sẽ bị hủy bỏ hoàn toàn. Hệ thống sẽ tự động thực hiện các thao tác sau:"
                    : "Khoản chi này sẽ bị xóa vĩnh viễn và số tiền sẽ được tính toán lại trong chuyến đi.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              if (isFundCollectionExpense) ...[
                const SizedBox(height: 16),
                // Cascade items container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50.withAlpha(76),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade100.withAlpha(127)),
                  ),
                  child: Column(
                    children: [
                      _buildCascadeItem(Icons.remove_circle_outline_rounded, "Hủy yêu cầu đóng góp của các thành viên"),
                      const Divider(height: 12, thickness: 0.5),
                      _buildCascadeItem(Icons.account_balance_outlined, "Hoàn lại tiền vào số dư Quỹ chung"),
                      const Divider(height: 12, thickness: 0.5),
                      _buildCascadeItem(Icons.receipt_long_outlined, "Xóa toàn bộ thanh toán nộp quỹ liên quan"),
                      const Divider(height: 12, thickness: 0.5),
                      _buildCascadeItem(Icons.balance_rounded, "Tự động cập nhật công nợ quyết toán"),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      onPressed: () => Get.back(),
                      child: Text(
                        "HỦY",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Get.back();
                        controller.deleteExpense(expenseId);
                      },
                      child: Text(
                        isFundCollectionExpense ? "XÓA & HỦY" : "XÓA",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCascadeItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.red.shade700),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildQuickItineraryBanner() {
    final itineraryCtrl = Get.find<ItineraryController>(
      tag: widget.mainController.tripId.toString(),
    );

    return Obx(() {
      if (itineraryCtrl.itineraryList.isEmpty) {
        return const SizedBox.shrink();
      }

      // Xác định ngày mục tiêu dựa vào filter ngày (nếu có)
      final targetDate = controller.selectedExpenseDate.value ?? DateTime.now();
      final days = itineraryCtrl.tripDays;

      // Tìm chỉ số ngày của targetDate trong danh sách các ngày của chuyến đi
      int targetDayIdx = -1;
      for (int i = 0; i < days.length; i++) {
        final d = days[i];
        if (d.year == targetDate.year && d.month == targetDate.month && d.day == targetDate.day) {
          targetDayIdx = i;
          break;
        }
      }

      // Nếu có filter ngày và ngày được chọn không nằm trong chuyến đi -> Ẩn banner
      if (controller.selectedExpenseDate.value != null && targetDayIdx == -1) {
        return const SizedBox.shrink();
      }

      int todayIdx = 0;
      if (targetDayIdx != -1) {
        todayIdx = targetDayIdx;
      } else {
        // Mặc định tính theo ngày hôm nay nếu không filter hoặc hôm nay không phải ngày đi
        if (itineraryCtrl.startDate != null) {
          final start = DateTime.tryParse(itineraryCtrl.startDate!);
          if (start != null) {
            final today = DateTime.now();
            final diff = today.difference(start).inDays;
            if (diff >= 0 && diff < days.length) {
              todayIdx = diff;
            }
          }
        }
      }

      final dayNum = todayIdx + 1;
      final dayActivities = itineraryCtrl.groupedItinerary[dayNum] ?? [];

      if (dayActivities.isEmpty) {
        // Nếu đang filter ngày và ngày đó không có hoạt động nào -> Ẩn banner
        if (controller.selectedExpenseDate.value != null) {
          return const SizedBox.shrink();
        }
        // Ngược lại, nếu là xem tất cả/hôm nay không có hoạt động, hiện hoạt động đầu tiên của ngày 1
        final firstDayAct = itineraryCtrl.groupedItinerary[1] ?? [];
        if (firstDayAct.isEmpty) return const SizedBox.shrink();
        
        final nextItem = firstDayAct.first;
        return _buildActiveBannerCard(dayNum, nextItem, isUpcoming: true);
      }

      // Tìm hoạt động sắp tới tiếp theo (chỉ check giờ nếu targetDate là hôm nay)
      final now = DateTime.now();
      bool isToday = targetDate.year == now.year && targetDate.month == now.month && targetDate.day == now.day;
      ItineraryItemResponse? nextItem;

      if (isToday) {
        for (var act in dayActivities) {
          if (act.timeRange != null) {
            try {
              final parts = act.timeRange!.split('-');
              final startPart = parts.first.trim().toLowerCase();
              int? hour;
              int? min;
              if (startPart.contains(':')) {
                final hourMin = startPart.split(':');
                hour = int.parse(hourMin.first);
                min = int.parse(hourMin.last.replaceAll(RegExp(r'[^0-9]'), ''));
              } else if (startPart.contains('h')) {
                final hourMin = startPart.split('h');
                hour = int.parse(hourMin.first);
                final minStr = hourMin.last.replaceAll(RegExp(r'[^0-9]'), '');
                min = minStr.isEmpty ? 0 : int.parse(minStr);
              } else {
                hour = int.parse(startPart);
                min = 0;
              }
              
              final actTime = DateTime(now.year, now.month, now.day, hour, min);
              if (actTime.isAfter(now)) {
                nextItem = act;
                break;
              }
            } catch (_) {}
          }
        }
      }
      
      nextItem ??= dayActivities.first;

      return _buildActiveBannerCard(dayNum, nextItem, isUpcoming: !isToday);
    });
  }

  Widget _buildActiveBannerCard(int dayNum, ItineraryItemResponse item, {required bool isUpcoming}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Get.to(() => ItineraryScreen(tripId: widget.mainController.tripId)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.explore, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isUpcoming ? "Lịch trình sắp tới (Ngày $dayNum)" : "Lịch trình hôm nay (Ngày $dayNum)",
                              style: TextStyle(
                                fontSize: 11, 
                                fontWeight: FontWeight.bold, 
                                color: AppColors.primary,
                              ),
                            ),
                            if (item.timeRange != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.timeRange!,
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.activity,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.location != null && item.location!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.pin_drop, size: 12, color: Colors.grey.shade400),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.location!,
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
