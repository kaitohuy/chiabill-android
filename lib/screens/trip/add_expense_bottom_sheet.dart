import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/add_expense_controller.dart';
import '../../data/models/trip_response.dart';
import '../../data/models/expense_response.dart';

class AddExpenseBottomSheet extends StatelessWidget {
  final TripResponse trip;
  final ExpenseResponse? expenseToEdit;

  const AddExpenseBottomSheet({super.key, required this.trip, this.expenseToEdit});

  @override
  Widget build(BuildContext context) {
    final tag = expenseToEdit != null ? 'edit_${expenseToEdit!.id}' : 'add';
    final controller = Get.put(AddExpenseController(trip, expenseToEdit: expenseToEdit), tag: tag);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditMode = expenseToEdit != null;

    // XÓA Padding bao ngoài cùng đi, chỉ dùng Container
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        // BÍ QUYẾT LÀ Ở ĐÂY: Nhét bottomInset vào padding của ScrollView
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: bottomInset + 24),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        Text(
        isEditMode ? "Sửa khoản chi" : "Thêm chi phí mới",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)
        ),
        const SizedBox(height: 20),

            TextField(
              controller: controller.amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Số tiền (VNĐ)",
                prefixIcon: const Icon(Icons.attach_money, color: Colors.orange),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
              TextField(
                controller: controller.descController,
                decoration: InputDecoration(
                  labelText: "Nội dung (VD: Tiền ăn trưa)",
                  prefixIcon: const Icon(Icons.description, color: Colors.orange),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // =====================================
              // DANH MỤC CHI PHÍ
              // =====================================
              const Text("Danh mục", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _showCategoryPicker(context, controller),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Obx(() {
                        final selectedCat = controller.categories.firstWhereOrNull((c) => c.id == controller.selectedCategoryId.value);
                        return Text(
                          selectedCat?.icon ?? "📦", // Hiển thị Emoji Icon
                          style: const TextStyle(fontSize: 24),
                        );
                      }),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Obx(() {
                          final selectedCat = controller.categories.firstWhereOrNull((c) => c.id == controller.selectedCategoryId.value);
                          return Text(
                            selectedCat?.name ?? "Chọn danh mục",
                            style: TextStyle(fontSize: 16, color: selectedCat == null ? Colors.grey : Colors.black87),
                          );
                        }),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

            // =====================================
            // 1. CHỌN NGƯỜI TRẢ TIỀN
            // =====================================
            const Text("Ai đã trả tiền?", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Obx(() => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: controller.selectedPayerId.value,
                  isExpanded: true,
                  items: controller.activeMembers.map((m) =>
                      DropdownMenuItem(value: m.user.id, child: Text(m.user.name ?? "Ẩn danh"))
                  ).toList(),
                  onChanged: (val) => controller.selectedPayerId.value = val!,
                ),
              ),
            )),
            const SizedBox(height: 24),

            // =====================================
            // 2. CHỌN NGƯỜI THAM GIA CHIA TIỀN (CHUẨN UX MỚI)
            // =====================================
            const Text("Chia cho những ai?", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _showMultiSelectDialog(context, controller),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.orange.shade50,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.group, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(() {
                        int selectedCount = controller.selectedSplitMemberIds.length;
                        int totalCount = controller.activeMembers.length;

                        if (selectedCount == totalCount) {
                          return const Text("Chia đều cho tất cả mọi người", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold));
                        } else if (selectedCount == 0) {
                          return const Text("Chưa chọn ai (Bấm để chọn)", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold));
                        } else {
                          return Text("Đã chọn: $selectedCount / $totalCount người", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold));
                        }
                      }),
                    ),
                    const Icon(Icons.edit, color: Colors.orange, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // =====================================
            // NÚT XÁC NHẬN
            // =====================================
            Obx(() => SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
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
      ),

    );
  }

  // ==========================================
  // DIALOG DANH SÁCH CHỌN NGƯỜI (ĐÃ FIX LỖI GETX)
  // ==========================================
  void _showMultiSelectDialog(BuildContext context, AddExpenseController controller) {
    Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.only(left: 24, right: 16, top: 16, bottom: 8),
          contentPadding: EdgeInsets.zero,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Chọn người chia", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Obx(() {
                bool isAllSelected = controller.selectedSplitMemberIds.length == controller.activeMembers.length;
                return TextButton(
                  onPressed: () => controller.toggleAllMembers(!isAllSelected),
                  child: Text(isAllSelected ? "Bỏ chọn tất cả" : "Chọn tất cả", style: const TextStyle(fontSize: 13)),
                );
              }),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 350,
            child: Column(
              children: [
                const Divider(height: 1),
                Expanded(
                  // XÓA OBX Ở ĐÂY, CHỈ ĐỂ LISTVIEW BÌNH THƯỜNG
                  child: ListView.builder(
                    itemCount: controller.activeMembers.length,
                    itemBuilder: (context, index) {
                      final member = controller.activeMembers[index];

                      // CHUYỂN OBX VÀO ĐÂY ĐỂ BỌC TỪNG ITEM
                      return Obx(() {
                        bool isSelected = controller.selectedSplitMemberIds.contains(member.user.id);
                        return CheckboxListTile(
                          activeColor: Colors.orange,
                          title: Text(member.user.name ?? "Ẩn danh", style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(member.user.isGhost ? "Người dùng ảo" : "Thành viên app", style: const TextStyle(fontSize: 12)),
                          value: isSelected,
                          onChanged: (bool? value) {
                            controller.toggleMemberSplit(member.user.id!);
                          },
                        );
                      });
                    },
                  ),
                ),
                const Divider(height: 1),
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                onPressed: () => Get.back(),
                child: const Text("XONG", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        )
    );
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
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Colors.orange, size: 28),
                            SizedBox(height: 4),
                            Text("Tạo mới", style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
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
                        color: controller.selectedCategoryId.value == cat.id ? Colors.orange.shade50 : Colors.white,
                        border: Border.all(color: controller.selectedCategoryId.value == cat.id ? Colors.orange : Colors.grey.shade300),
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
                            style: const TextStyle(fontSize: 11, height: 1.2), // height để các dòng sát nhau hơn
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
    final nameCtrl = TextEditingController();
    // Cập nhật list Emoji: Đa dạng hơn cho các khoản chi phí cá nhân / đặc thù
    final List<String> popularEmojis = [
      "🍕", "🍹", "🚩", "📸", "🐶", "🐱", "👶", "💆‍♀️",
      "💇‍♂️", "💍", "📚", "🎨", "🔧", "⚙️", "✨", "🔥",
      "💡", "💳", "📱", "💻", "⚽", "🎫", "🧸", "🧧"
    ];

    // Biến lưu icon đang được chọn (Mặc định chọn cái đầu tiên)
    final RxString selectedEmoji = popularEmojis.first.obs;

    Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Tạo danh mục mới", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: "Tên danh mục (VD: Tiền trạm)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.edit, color: Colors.orange),
                  ),
                ),
                const SizedBox(height: 20),

                const Text("Chọn một biểu tượng:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 12),

                // KHUNG CHỌN EMOJI
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: popularEmojis.map((emoji) {
                    return Obx(() {
                      bool isSelected = selectedEmoji.value == emoji;
                      return GestureDetector(
                        onTap: () => selectedEmoji.value = emoji,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: isSelected ? Colors.orange.shade100 : Colors.grey.shade50,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: isSelected ? Colors.orange : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1
                              )
                          ),
                          child: Text(emoji, style: const TextStyle(fontSize: 24)),
                        ),
                      );
                    });
                  }).toList(),
                )
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Get.back(),
                child: const Text("HỦY", style: TextStyle(color: Colors.grey))
            ),
            Obx(() => ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
              onPressed: controller.isLoading.value ? null : () {
                if (nameCtrl.text.trim().isEmpty) {
                  Get.snackbar("Thiếu thông tin", "Vui lòng nhập tên danh mục", backgroundColor: Colors.redAccent, colorText: Colors.white);
                  return;
                }
                // Gọi API tạo danh mục với tên và emoji đã chọn
                controller.createNewCategory(nameCtrl.text.trim(), selectedEmoji.value);
              },
              child: controller.isLoading.value
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("TẠO MỚI"),
            )),
          ],
        )
    );
  }
}