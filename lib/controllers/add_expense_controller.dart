import 'dart:io';
import 'package:chiabill/utils/loading_util.dart';
import 'package:chiabill/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../data/models/create_expense_request.dart';
import '../data/models/expense_category_respone.dart';
import '../data/models/split_request.dart';
import '../data/models/trip_response.dart';
import '../data/models/expense_response.dart';
import '../data/models/update_expense_request.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/expense_repository.dart';
import '../data/models/trip_member_response.dart';
import '../utils/currency_util.dart';
import 'trip_detail_controller.dart';
import 'dart:math';
import '../services/group_fund_service.dart';

class AddExpenseController extends GetxController {
  final TripResponse trip;
  final ExpenseResponse? expenseToEdit;
  final DateTime? initialDate;

  AddExpenseController(this.trip, {this.expenseToEdit, this.initialDate});

  final ExpenseRepository _repository = ExpenseRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();
  final GroupFundService _fundService = GroupFundService();

  // Receipt Image Selection & Processing
  var selectedReceiptFile = Rxn<File>();
  var receiptUrl = RxnString();
  var isUploadingImage = false.obs;
  var isScanningImage = false.obs;
  final ImagePicker _picker = ImagePicker();

  Future<void> pickReceiptImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 60,
      maxWidth: 1080,
    );
    if (image != null) {
      final file = File(image.path);
      selectedReceiptFile.value = file;
      scanAndUploadReceipt(file);
    }
  }

  void clearReceiptImage() {
    selectedReceiptFile.value = null;
    receiptUrl.value = null;
    isUploadingImage.value = false;
  }

  Future<void> scanAndUploadReceipt(File file) async {
    // 1. Chạy AI OCR (Chặn UI xoay loading)
    isScanningImage.value = true;
    LoadingUtil.show();

    // Chạy song song: upload Cloudinary chạy nền không chặn
    _uploadReceiptToCloudinaryAsync(file);

    try {
      final ocrResult = await _repository.scanReceipt(trip.id, file);
      if (ocrResult.success && ocrResult.data != null) {
        final data = ocrResult.data!;
        
        if (data.totalAmount > 0) {
          amountController.text = CurrencyUtils.formatNumber(data.totalAmount);
          _updateCalculatedVnd();
        }
        
        if (data.description.isNotEmpty) {
          descController.text = data.description;
        }
        
        if (data.categoryId != null) {
          if (categories.any((c) => c.id == data.categoryId)) {
            selectedCategoryId.value = data.categoryId;
          }
        }
        
        ToastUtil.showSuccess("Đã quét hóa đơn", "Tự động điền số tiền và nội dung bằng AI thành công!");
      } else {
        ToastUtil.showWarning("AI bận", ocrResult.message ?? "Không thể tự động quét hóa đơn. Vui lòng tự điền thông tin.");
      }
    } catch (e) {
      ToastUtil.showWarning("AI bận", "Có lỗi xảy ra khi quét hóa đơn. Vui lòng tự điền thông tin.");
    } finally {
      isScanningImage.value = false;
      LoadingUtil.hide();
    }
  }

  Future<void> _uploadReceiptToCloudinaryAsync(File file) async {
    isUploadingImage.value = true;
    try {
      final result = await _repository.uploadImage(file);
      if (result.success && result.data != null) {
        receiptUrl.value = result.data;
      } else {
        ToastUtil.showError("Lỗi tải ảnh", result.message ?? "Không thể lưu trữ ảnh minh chứng lên đám mây.");
      }
    } catch (e) {
      ToastUtil.showError("Lỗi hệ thống", "Không thể kết nối máy chủ để lưu ảnh.");
    } finally {
      isUploadingImage.value = false;
    }
  }
  var isFromFund = false.obs;
  var fundBalance = 0.0.obs;
  var isFundActivated = false.obs;

  final amountController = TextEditingController();
  final descController = TextEditingController();
  final exchangeRateController = TextEditingController(text: "1");

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

  // ADVANCED SPLIT
  var splitType = 'EQUAL'.obs;
  var splitValues = <int, double>{}.obs; // Lưu giá trị theo từng người (ví dụ %, số tiền, tỷ trọng)
  var selectedDate = Rx<DateTime>(DateTime.now());

  var selectedCurrency = "VND".obs;
  var exchangeRate = 1.0.obs;
  var currencies = <String>["VND", "USD", "EUR", "JPY", "THB", "KRW", "SGD", "GBP", "AUD"].obs;
  
  var calculatedVnd = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    
    amountController.addListener(_updateCalculatedVnd);
    exchangeRateController.addListener(_updateCalculatedVnd);
    
    // Nếu có truyền ngày khởi tạo từ filter (và không phải đang edit) thì lấy ngày đó
    if (initialDate != null && expenseToEdit == null) {
      selectedDate.value = initialDate!;
    }

    // 1. LỌC BỎ NHỮNG NGƯỜI ĐÃ BỊ DISABLED
    activeMembers = trip.members?.where((m) => m.status != 'DISABLED').toList() ?? [];

    if (expenseToEdit != null) {
      amountController.text = CurrencyUtils.formatNumber(expenseToEdit!.totalAmount);
      descController.text = expenseToEdit!.description;
      selectedPayerId.value = expenseToEdit!.payer?.id ?? (trip.createdBy?.id ?? 0);
      selectedCategoryId.value = expenseToEdit!.categoryId;
      receiptUrl.value = expenseToEdit!.receiptUrl;
      if (expenseToEdit!.expenseDate != null) {
        try {
          selectedDate.value = DateTime.parse(expenseToEdit!.expenseDate!);
        } catch (_) {}
      }
      // Khôi phục Tỷ giá nếu là ngoại tệ
      String initialCurrency = expenseToEdit!.currency ?? trip.currency ?? "VND";
      if (!currencies.contains(initialCurrency)) {
        currencies.add(initialCurrency);
      }
      selectedCurrency.value = initialCurrency;

      if (expenseToEdit!.exchangeRate != null) {
        exchangeRate.value = expenseToEdit!.exchangeRate!;
        exchangeRateController.text = CurrencyUtils.formatNumber(exchangeRate.value);
      } else {
        exchangeRate.value = 1.0;
        exchangeRateController.text = "1";
      }

      bool isPayerInList = activeMembers.any((m) => m.user.id == selectedPayerId.value);
      if (!isPayerInList && expenseToEdit!.payer != null) {
        var oldPayerMatch = trip.members?.where((m) => m.user.id == expenseToEdit!.payer!.id);
        if (oldPayerMatch != null && oldPayerMatch.isNotEmpty) {
          activeMembers.add(oldPayerMatch.first);
        }
      }
    } else {
      selectedPayerId.value = trip.createdBy?.id ?? (activeMembers.isNotEmpty ? activeMembers.first.user.id : 0);
      String initialCurrency = trip.currency ?? "VND";
      if (!currencies.contains(initialCurrency)) {
        currencies.add(initialCurrency);
      }
      selectedCurrency.value = initialCurrency;
      exchangeRate.value = 1.0;
      exchangeRateController.text = "1";
    }

    // 2. KHỞI TẠO NGƯỜI CÙNG CHIA TIỀN
    if (expenseToEdit != null && expenseToEdit!.splits != null) {
      // NẾU LÀ SỬA: Chỉ check chọn những người ĐÃ NẰM TRONG bill này từ trước
      selectedSplitMemberIds.addAll(expenseToEdit!.splits!.map((s) => s.userId));
      splitType.value = expenseToEdit!.splitType ?? "EQUAL";
      for (var s in expenseToEdit!.splits!) {
        if (s.splitValue != null) {
          splitValues[s.userId] = s.splitValue!;
        } else if (splitType.value == "EXACT") {
          double rate = expenseToEdit!.exchangeRate ?? 1.0;
          splitValues[s.userId] = rate > 0 ? s.amount / rate : s.amount;
        }
      }
    } else {
      // NẾU LÀ TẠO MỚI: Mặc định chọn chia đều cho tất cả mọi người
      selectedSplitMemberIds.addAll(activeMembers.map((m) => m.user.id));
      splitType.value = "EQUAL";
      splitValues.clear();
    }
    fetchFundInfo();
    fetchCategories();
    _updateCalculatedVnd();
  }

  void _updateCalculatedVnd() {
    if (selectedCurrency.value == "VND") {
      calculatedVnd.value = 0.0;
      return;
    }
    try {
      double amt = double.parse(amountController.text.replaceAll(',', ''));
      double rate = double.parse(exchangeRateController.text.replaceAll(',', ''));
      calculatedVnd.value = amt * rate;
    } catch (_) {
      calculatedVnd.value = 0.0;
    }
  }

  Future<void> fetchFundInfo() async {
    final result = await _fundService.getFund(trip.id);
    if (result.success && result.data != null) {
      fundBalance.value = result.data!.balance;
      isFundActivated.value = true;
      if (expenseToEdit != null) {
        isFromFund.value = expenseToEdit!.isFromFund;
      }
    } else {
      isFundActivated.value = false;
      fundBalance.value = 0.0;
    }
  }

  // CẬP NHẬT HÀM NÀY
  Future<void> fetchCategories() async {
    isCategoriesLoading.value = true; // Bắt đầu xoay

    final result = await _categoryRepo.getCategories(trip.id);

    isCategoriesLoading.value = false; // Tắt xoay

    if (result.success && result.data != null) {
      categories.value = result.data!;
      if (expenseToEdit == null && categories.isNotEmpty) {
        selectedCategoryId.value = categories.first.id;
      }
    } else {
      ToastUtil.showError("Lỗi tải danh mục", result.message ?? "Có lỗi xảy ra");
    }
  }

  Future<void> createNewCategory(String name, String emojiIcon) async {
    isLoading.value = true;
    try {
      final result = await _categoryRepo.createCustomCategory(trip.id, name, emojiIcon);
      if (result.success && result.data != null) {
        Get.back(); // Đóng sub-dialog tạo mới
        categories.add(result.data!); // Thêm vào list hiện tại
        selectedCategoryId.value = result.data!.id; // Tự động chọn luôn cái vừa tạo
        ToastUtil.showSuccess("Thành công", "Đã thêm danh mục mới");
      } else {
        ToastUtil.showError("Lỗi", result.message ?? "Không thể tạo danh mục");
      }
    } catch (e) {
      ToastUtil.showError("Lỗi hệ thống", e.toString());
    } finally {
      isLoading.value = false;
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
      selectedSplitMemberIds.addAll(activeMembers.map((m) => m.user.id));
    }
  }

  Future<void> fetchLatestExchangeRate(String currency) async {
    if (currency == "VND") {
      exchangeRate.value = 1.0;
      exchangeRateController.text = "1";
      return;
    }
    final result = await _repository.getLatestExchangeRate(currency);
    if (result.success && result.data != null) {
      exchangeRate.value = result.data!;
      exchangeRateController.text = CurrencyUtils.formatNumber(exchangeRate.value);
    } else {
      // Default fallback
      exchangeRate.value = 1.0;
      exchangeRateController.text = "1";
    }
  }

  Future<void> submitExpense() async {
    if (isUploadingImage.value) {
      ToastUtil.showWarning("Đang xử lý", "Vui lòng đợi ảnh hóa đơn tải lên hoàn thành");
      return;
    }

    double? originalAmount = double.tryParse(amountController.text.replaceAll(',', ''));
    if (originalAmount == null || originalAmount <= 0) {
      ToastUtil.showWarning("Lỗi", "Số tiền không hợp lệ");
      return;
    }

    // Lấy tỷ giá từ ô nhập (nếu chọn VND thì là 1)
    double userExchangeRate = 1.0;
    if (selectedCurrency.value != "VND") {
      double? parsedRate = double.tryParse(exchangeRateController.text.replaceAll(',', ''));
      if (parsedRate != null && parsedRate > 0) {
        userExchangeRate = parsedRate;
      } else {
        ToastUtil.showWarning("Lỗi", "Vui lòng nhập tỷ giá hợp lệ");
        return;
      }
    }

    // Tính ra VND
    double total = originalAmount * userExchangeRate;

    // THÊM CHẶN GIỚI HẠN (Ví dụ: Tối đa 10 tỷ VNĐ)
    if (total > 10000000000) {
      ToastUtil.showWarning("Lỗi", "Chi tiêu gì mà tốn kém thế! Vui lòng nhập số tiền nhỏ hơn 10 tỷ.");
      return;
    }

    // Kiểm tra xem user có chọn ai để chia tiền không
    if (selectedSplitMemberIds.isEmpty) {
      ToastUtil.showWarning("Lỗi", "Vui lòng chọn ít nhất 1 người để chia tiền");
      return;
    }

    // Validate danh mục
    if (selectedCategoryId.value == null) {
      ToastUtil.showWarning("Lỗi", "Vui lòng chọn danh mục chi phí");
      return;
    }

    isLoading.value = true;
    try {
      // 3. TÍNH TOÁN TIỀN CHIA ĐỀU CHO CÁC THÀNH VIÊN ĐƯỢC CHỌN
      int memberCount = selectedSplitMemberIds.length;
      double splitAmount = total / memberCount;

      // Đẩy danh sách userId được chọn xuống BE
      List<SplitRequest> splits = selectedSplitMemberIds.map((id) =>
          SplitRequest(userId: id, amount: splitAmount)
      ).toList();

      bool isSuccess = false;
      String errorMessage = "";

      if (expenseToEdit != null) {
        final updateRequest = UpdateExpenseRequest(
          payerId: selectedPayerId.value,
          totalAmount: total,
          description: descController.text.trim(),
          categoryId: selectedCategoryId.value,
          expenseDate: selectedDate.value.toIso8601String().split('.')[0],
          currency: selectedCurrency.value,
          exchangeRate: userExchangeRate,
          splits: splits,
          isFromFund: isFromFund.value,
          splitType: splitType.value,
          receiptUrl: receiptUrl.value,
        );
        final result = await _repository.updateExpense(expenseToEdit!.id, updateRequest);
        isSuccess = result.success;
        errorMessage = result.message ?? "Lỗi";
      } else {
        if (isFromFund.value && total > fundBalance.value) {
          final double fundPart = fundBalance.value;
          final double restPart = total - fundBalance.value;

          List<SplitRequest> splitsFund = _generateSplits(fundPart, userExchangeRate);
          List<SplitRequest> splitsRest = _generateSplits(restPart, userExchangeRate);

          // Tạo khoản 1 từ quỹ
          final createRequest1 = CreateExpenseRequest(
            tripId: trip.id,
            payerId: selectedPayerId.value,
            totalAmount: fundPart,
            description: "${descController.text.trim()} (Trích từ quỹ chung)",
            categoryId: selectedCategoryId.value,
            expenseDate: selectedDate.value.toIso8601String().split('.')[0],
            currency: selectedCurrency.value,
            exchangeRate: userExchangeRate,
            splits: splitsFund,
            isFromFund: true,
            clientUuid: _generateUuid(),
            splitType: splitType.value,
            receiptUrl: receiptUrl.value,
          );

          final result1 = await _repository.createExpense(createRequest1);

          if (result1.success) {
            // Tạo khoản 2 nợ payer
            final createRequest2 = CreateExpenseRequest(
              tripId: trip.id,
              payerId: selectedPayerId.value,
              totalAmount: restPart,
              description: "${descController.text.trim()} (Phần thiếu hụt nợ người trả)",
              categoryId: selectedCategoryId.value,
              expenseDate: selectedDate.value.toIso8601String().split('.')[0],
              currency: selectedCurrency.value,
              exchangeRate: userExchangeRate,
              splits: splitsRest,
              isFromFund: false,
              clientUuid: _generateUuid(),
              splitType: splitType.value,
              receiptUrl: receiptUrl.value,
            );
            final result2 = await _repository.createExpense(createRequest2);
            isSuccess = result2.success;
            errorMessage = result2.message ?? "Lỗi tạo phần thiếu hụt";
          } else {
            isSuccess = false;
            errorMessage = result1.message ?? "Lỗi trích xuất quỹ";
          }
        } else {
        final createRequest = CreateExpenseRequest(
          tripId: trip.id,
          payerId: selectedPayerId.value,
          totalAmount: total,
          description: descController.text.trim(),
          categoryId: selectedCategoryId.value,
          expenseDate: selectedDate.value.toIso8601String().split('.')[0],
          currency: selectedCurrency.value,
          exchangeRate: userExchangeRate,
          splits: splits,
          isFromFund: isFromFund.value,
          clientUuid: _generateUuid(),
          splitType: splitType.value,
          receiptUrl: receiptUrl.value,
        );
        final result = await _repository.createExpense(createRequest);
        isSuccess = result.success;
        errorMessage = result.message ?? "Lỗi";
        }
      }

      if (isSuccess) {
        // BƯỚC 1: Tắt loading và đóng bàn phím
        isLoading.value = false;
        FocusManager.instance.primaryFocus?.unfocus();

        // BƯỚC 2: Chờ bàn phím thu lại trước
        await Future.delayed(const Duration(milliseconds: 150));

        // BƯỚC 3: Đóng BottomSheet - phải chờ animation đóng xong (~300ms) mới làm gì tiếp
        Get.back();

        // BƯỚC 4: Chờ BottomSheet đóng HOÀN TOÀN rồi mới show Toast (tránh xung đột animation)
        Future.delayed(const Duration(milliseconds: 500), () {
          ToastUtil.showSuccess("Thành công", expenseToEdit != null ? "Đã cập nhật chi phí" : "Đã thêm chi phí");
        });

        // BƯỚC 5: Sau khi Toast xuất hiện xong, sync dữ liệu ngầm
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (!Get.isRegistered<TripDetailController>(tag: trip.id.toString())) return;
          Get.find<TripDetailController>(tag: trip.id.toString()).fetchData(isSilent: true);
        });
      } else {
        ToastUtil.showError("Lỗi", errorMessage);
        isLoading.value = false;
      }
    } catch (e) {
      ToastUtil.showError("Lỗi hệ thống", e.toString());
      isLoading.value = false;
    }
  }

  String _generateUuid() {
    final random = Random();
    return "client-${DateTime.now().microsecondsSinceEpoch}-${random.nextInt(100000)}";
  }

  List<SplitRequest> _generateSplits(double totalAmountInVnd, double exchangeRate) {
    if (splitType.value == 'EQUAL') {
      int count = selectedSplitMemberIds.length;
      if (count == 0) return [];
      double amountPerPerson = (totalAmountInVnd / count).roundToDouble();
      double sum = 0;
      List<SplitRequest> splits = [];
      for (int i = 0; i < count; i++) {
        int id = selectedSplitMemberIds[i];
        double amount = (i == count - 1) ? (totalAmountInVnd - sum) : amountPerPerson;
        sum += amount;
        splits.add(SplitRequest(userId: id, amount: amount));
      }
      return splits;
    }

    if (splitType.value == 'PERCENTAGE') {
      double sum = 0;
      List<SplitRequest> splits = [];
      var keys = splitValues.keys.where((id) => (splitValues[id] ?? 0) > 0).toList();
      if (keys.isEmpty) return [];
      
      double totalPercent = keys.fold(0.0, (s, id) => s + splitValues[id]!);
      if ((totalPercent - 100).abs() > 0.1) return []; // Tổng % phải = 100

      for (int i = 0; i < keys.length; i++) {
        int id = keys[i];
        double percent = splitValues[id]!;
        double amount = (totalAmountInVnd * percent / 100).roundToDouble();
        if (i == keys.length - 1) {
          amount = totalAmountInVnd - sum;
        }
        sum += amount;
        splits.add(SplitRequest(userId: id, amount: amount, splitValue: percent));
      }
      return splits;
    }

    if (splitType.value == 'SHARES') {
      List<int> keys = splitValues.keys.where((id) => (splitValues[id] ?? 0) > 0).toList();
      if (keys.isEmpty) return [];
      double totalShares = keys.fold(0.0, (s, id) => s + splitValues[id]!);
      if (totalShares <= 0) return [];

      double sum = 0;
      List<SplitRequest> splits = [];
      for (int i = 0; i < keys.length; i++) {
        int id = keys[i];
        double share = splitValues[id]!;
        double amount = (totalAmountInVnd * share / totalShares).roundToDouble();
        if (i == keys.length - 1) {
          amount = totalAmountInVnd - sum;
        }
        sum += amount;
        splits.add(SplitRequest(userId: id, amount: amount, splitValue: share));
      }
      return splits;
    }

    if (splitType.value == 'EXACT') {
      List<int> keys = splitValues.keys.where((id) => (splitValues[id] ?? 0) > 0).toList();
      if (keys.isEmpty) return [];
      
      double totalExactOriginal = keys.fold(0.0, (s, id) => s + splitValues[id]!);
      double totalExactVnd = totalExactOriginal * exchangeRate;
      
      // Cho phép lệch 5 đơn vị VND do làm tròn
      if ((totalExactVnd - totalAmountInVnd).abs() > 5.0) return [];

      double sum = 0;
      List<SplitRequest> splits = [];
      for (int i = 0; i < keys.length; i++) {
        int id = keys[i];
        double exactInOriginal = splitValues[id]!;
        double amountInVnd = (exactInOriginal * exchangeRate).roundToDouble();
        if (i == keys.length - 1) {
          amountInVnd = totalAmountInVnd - sum;
        }
        sum += amountInVnd;
        splits.add(SplitRequest(userId: id, amount: amountInVnd, splitValue: exactInOriginal));
      }
      return splits;
    }

    return [];
  }

  @override
  void onClose() {
    amountController.dispose();
    descController.dispose();
    exchangeRateController.dispose();
    super.onClose();
  }
}
