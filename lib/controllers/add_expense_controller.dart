import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/models/create_expense_request.dart';
import '../data/models/expense_category_respone.dart';
import '../data/models/split_request.dart';
import '../data/models/trip_response.dart';
import '../data/models/expense_response.dart';
import '../data/models/update_expense_request.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/expense_repository.dart';
import '../data/models/trip_member_response.dart';
import 'trip_detail_controller.dart';

class AddExpenseController extends GetxController {
  final TripResponse trip;
  final ExpenseResponse? expenseToEdit;

  AddExpenseController(this.trip, {this.expenseToEdit});

  final ExpenseRepository _repository = ExpenseRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();

  final amountController = TextEditingController();
  final descController = TextEditingController();

  var isLoading = false.obs;
  var selectedPayerId = 0.obs;

  // Danh sách toàn bộ thành viên đang Active
  late List<TripMemberResponse> activeMembers;

  // THÊM MỚI: Danh sách ID của những người sẽ cùng gánh khoản chi này
  var selectedSplitMemberIds = <int>[].obs;
  var categories = <ExpenseCategoryResponse>[].obs;
  var selectedCategoryId = RxnInt(); // RxnInt để chứa giá trị null ban đầu
  // THÊM BIẾN NÀY DƯỚI DÒNG categories = <ExpenseCategoryResponse>[].obs;
  var isCategoriesLoading = true.obs;

  @override
  void onInit() {
    super.onInit();

    // 1. LỌC BỎ NHỮNG NGƯỜI ĐÃ BỊ DISABLED
    activeMembers = trip.members?.where((m) => m.status != 'DISABLED').toList() ?? [];

    if (expenseToEdit != null) {
      amountController.text = expenseToEdit!.totalAmount.toInt().toString();
      descController.text = expenseToEdit!.description;
      selectedPayerId.value = expenseToEdit!.payer?.id ?? (trip.createdBy?.id ?? 0);
      selectedCategoryId.value = expenseToEdit!.categoryId;

      bool isPayerInList = activeMembers.any((m) => m.user.id == selectedPayerId.value);
      if (!isPayerInList && expenseToEdit!.payer != null) {
        var oldPayerMatch = trip.members?.where((m) => m.user.id == expenseToEdit!.payer!.id);
        if (oldPayerMatch != null && oldPayerMatch.isNotEmpty) {
          activeMembers.add(oldPayerMatch.first);
        }
      }
    } else {
      selectedPayerId.value = trip.createdBy?.id ?? (activeMembers.isNotEmpty ? activeMembers.first.user.id! : 0);
    }

    // 2. MẶC ĐỊNH LÚC ĐẦU LÀ TÍCH CHỌN TẤT CẢ MỌI NGƯỜI
    selectedSplitMemberIds.addAll(activeMembers.map((m) => m.user.id!));
    fetchCategories();
  }

  // CẬP NHẬT HÀM NÀY
  Future<void> fetchCategories() async {
    isCategoriesLoading.value = true; // Bắt đầu xoay

    final result = await _categoryRepo.getCategories(trip.id!);

    isCategoriesLoading.value = false; // Tắt xoay

    if (result.success && result.data != null) {
      categories.value = result.data!;
      if (expenseToEdit == null && categories.isNotEmpty) {
        selectedCategoryId.value = categories.first.id;
      }
    } else {
      Get.snackbar("Lỗi tải danh mục", result.message ?? "Có lỗi xảy ra", backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> createNewCategory(String name, String emojiIcon) async {
    isLoading.value = true;
    final result = await _categoryRepo.createCustomCategory(trip.id!, name, emojiIcon);
    isLoading.value = false;

    if (result.success && result.data != null) {
      Get.back(); // Đóng sub-dialog tạo mới
      categories.add(result.data!); // Thêm vào list hiện tại
      selectedCategoryId.value = result.data!.id; // Tự động chọn luôn cái vừa tạo
      Get.snackbar("Thành công", "Đã thêm danh mục mới", backgroundColor: Colors.green, colorText: Colors.white);
    } else {
      Get.snackbar("Lỗi", result.message ?? "Không thể tạo danh mục", backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  // THÊM MỚI: Logic ấn vào 1 người để chọn/bỏ chọn
  void toggleMemberSplit(int memberId) {
    if (selectedSplitMemberIds.contains(memberId)) {
      selectedSplitMemberIds.remove(memberId);
    } else {
      selectedSplitMemberIds.add(memberId);
    }
  }

  // THÊM MỚI: Logic nút Chọn tất cả / Bỏ chọn tất cả
  void toggleAllMembers(bool selectAll) {
    selectedSplitMemberIds.clear();
    if (selectAll) {
      selectedSplitMemberIds.addAll(activeMembers.map((m) => m.user.id!));
    }
  }

  Future<void> submitExpense() async {
    double? total = double.tryParse(amountController.text.replaceAll(',', ''));
    if (total == null || total <= 0) {
      Get.snackbar("Lỗi", "Số tiền không hợp lệ", backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    // THÊM CHẶN GIỚI HẠN (Ví dụ: Tối đa 10 tỷ VNĐ)
    if (total > 10000000000) {
      Get.snackbar("Lỗi", "Chi tiêu gì mà tốn kém thế! Vui lòng nhập số tiền nhỏ hơn 10 tỷ.", backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    // Kiểm tra xem user có chọn ai để chia tiền không
    if (selectedSplitMemberIds.isEmpty) {
      Get.snackbar("Lỗi", "Vui lòng chọn ít nhất 1 người để chia tiền", backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    isLoading.value = true;

    // 3. TÍNH TOÁN TIỀN CHIA ĐỀU CHO CÁC THÀNH VIÊN ĐƯỢC CHỌN
    int memberCount = selectedSplitMemberIds.length;
    double splitAmount = total / memberCount;

    // Đẩy danh sách userId được chọn xuống BE
    List<SplitRequest> splits = selectedSplitMemberIds.map((id) =>
        SplitRequest(userId: id, amount: splitAmount)
    ).toList();

    // Validate danh mục
    if (selectedCategoryId.value == null) {
      Get.snackbar("Lỗi", "Vui lòng chọn danh mục chi phí", backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    isLoading.value = true;

    bool isSuccess = false;
    String errorMessage = "";

    if (expenseToEdit != null) {
      final updateRequest = UpdateExpenseRequest(
        payerId: selectedPayerId.value,
        totalAmount: total,
        description: descController.text.trim(),
        categoryId: selectedCategoryId.value, // TRUYỀN CATEGORY VÀO ĐÂY
        expenseDate: DateTime.now().toIso8601String().split('.')[0],
        splits: splits,
      );
      final result = await _repository.updateExpense(expenseToEdit!.id, updateRequest);
      isSuccess = result.success;
      errorMessage = result.message ?? "Lỗi";
    } else {
      final createRequest = CreateExpenseRequest(
        tripId: trip.id,
        payerId: selectedPayerId.value,
        totalAmount: total,
        description: descController.text.trim(),
        categoryId: selectedCategoryId.value, // TRUYỀN CATEGORY VÀO ĐÂY
        splits: splits,
      );
      final result = await _repository.createExpense(createRequest);
      isSuccess = result.success;
      errorMessage = result.message ?? "Lỗi";
    }

    if (isSuccess) {
      Get.back();
      Get.snackbar("Thành công", expenseToEdit != null ? "Đã cập nhật chi phí" : "Đã thêm chi phí", backgroundColor: Colors.green, colorText: Colors.white);
      Get.find<TripDetailController>(tag: trip.id.toString()).fetchData();
    } else {
      Get.snackbar("Lỗi", errorMessage, backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
    isLoading.value = false;
  }

  @override
  void onClose() {
    amountController.dispose();
    descController.dispose();
    super.onClose();
  }
}