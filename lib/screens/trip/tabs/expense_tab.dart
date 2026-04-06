import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/add_expense_controller.dart';
import '../../../controllers/trip_detail_controller.dart';
import '../../../utils/currency_util.dart';
import '../add_expense_bottom_sheet.dart';

class ExpensesTab extends StatelessWidget {
  final TripDetailController controller;
  const ExpensesTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12), color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => controller.applyExpenseFilter(keyword: value),
                  decoration: InputDecoration(
                      hintText: "Tìm chi phí...",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Obx(() {
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
                      child: Icon(Icons.tune, color: hasFilter ? Colors.white : Colors.grey.shade700)
                  ),
                );
              }),
            ],
          ),
        ),

        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (controller.trip.value != null) {
                Get.bottomSheet(AddExpenseBottomSheet(trip: controller.trip.value!), isScrollControlled: true);
              }
            },
            child: Obx(() {
              if (controller.isLoading.value && controller.expenses.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.expenses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 80, color: Colors.orange.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text("Chưa có khoản chi nào.\nChạm vào bất cứ đâu để thêm mới!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: Colors.orange,
                onRefresh: () async => controller.fetchData(),
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
                          return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Center(child: CircularProgressIndicator(color: Colors.orange))
                          );
                        }

                        final expense = controller.expenses[index];
                        final payer = expense.payer;
                        String payerInitial = (payer?.name != null && payer!.name!.trim().isNotEmpty) ? payer.name!.trim()[0].toUpperCase() : "?";
                        String categoryIcon = expense.categoryIcon ?? "📦";

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 50, height: 50,
                                  decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: Colors.orange.shade200, width: 1.5)
                                  ),
                                  child: Center(child: Text(categoryIcon, style: const TextStyle(fontSize: 26))),
                                ),
                                const SizedBox(width: 14),
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
                                      Row(
                                        children: [
                                          Text("Bởi: ", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                          CircleAvatar(
                                            radius: 9,
                                            backgroundColor: payer?.isGhost == true ? Colors.grey[300] : Colors.green[100],
                                            backgroundImage: (payer?.avatarUrl != null && payer!.avatarUrl!.isNotEmpty) ? NetworkImage(payer.avatarUrl!) : null,
                                            child: (payer?.avatarUrl == null || payer!.avatarUrl!.isEmpty)
                                                ? (payer?.isGhost == true ? const Icon(Icons.visibility_off, color: Colors.grey, size: 10) : Text(payerInitial, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 9)))
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
                                Text(
                                    "${CurrencyUtils.formatNumber(expense.totalAmount)} đ",
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.redAccent)
                                ),
                                PopupMenuButton<String>(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                                  onSelected: (value) {
                                    if (value == 'delete') {
                                      _showDeleteConfirmDialog(context, controller, expense.id);
                                    } else if (value == 'edit') {
                                      Get.bottomSheet(
                                          AddExpenseBottomSheet(trip: controller.trip.value!, expenseToEdit: expense),
                                          isScrollControlled: true
                                      ).then((_) => Get.delete<AddExpenseController>(tag: 'edit_${expense.id}'));
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'edit', child: Text("Sửa")),
                                    const PopupMenuItem(value: 'delete', child: Text("Xóa", style: TextStyle(color: Colors.red)))
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
                        const Text("Lọc chi phí", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton(
                            onPressed: () { setState(() { tempCatId = null; tempPayerId = null; }); },
                            child: const Text("Xóa lọc", style: TextStyle(color: Colors.red))
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Theo danh mục:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: controller.categories.map((cat) {
                                bool isSelected = tempCatId == cat.id;
                                return FilterChip(
                                    label: Text("${cat.icon ?? ''} ${cat.name}", style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                                    selected: isSelected,
                                    selectedColor: Colors.orange,
                                    checkmarkColor: Colors.white,
                                    backgroundColor: Colors.grey.shade100,
                                    onSelected: (val) { setState(() => tempCatId = val ? cat.id : null); }
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),

                            const Text("Theo người trả tiền:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: (controller.trip.value?.members ?? []).map((m) {
                                bool isSelected = tempPayerId == m.user.id;
                                return FilterChip(
                                    label: Text(m.user.name ?? "Ẩn danh", style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                                    selected: isSelected,
                                    selectedColor: Colors.orange,
                                    checkmarkColor: Colors.white,
                                    backgroundColor: Colors.grey.shade100,
                                    onSelected: (val) { setState(() => tempPayerId = val ? m.user.id : null); }
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
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                          onPressed: () {
                            Get.back();
                            controller.applyExpenseFilter(catId: tempCatId, payerId: tempPayerId);
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

  void _showDeleteConfirmDialog(BuildContext context, TripDetailController controller, int expenseId) {
    Get.dialog(
      AlertDialog(
        title: const Text("Xác nhận xóa?"),
        content: const Text("Khoản chi này sẽ bị xóa vĩnh viễn và số tiền sẽ được tính toán lại."),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("HỦY")),
          TextButton(
              onPressed: () { Get.back(); controller.deleteExpense(expenseId); },
              child: const Text("XÓA", style: TextStyle(color: Colors.red))
          )
        ],
      ),
    );
  }
}