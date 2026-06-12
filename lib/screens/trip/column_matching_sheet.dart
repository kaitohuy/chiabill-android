import 'package:chiabill/theme/app_colors.dart';
import 'package:chiabill/utils/excel_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'excel_preview_dialog.dart';

class ColumnMatchingSheet extends StatefulWidget {
  final int tripId;
  final ExcelParseResult result;

  const ColumnMatchingSheet({super.key, required this.tripId, required this.result});

  @override
  State<ColumnMatchingSheet> createState() => _ColumnMatchingSheetState();
}

class _ColumnMatchingSheetState extends State<ColumnMatchingSheet> {
  // Bản đồ các trường đích
  final Map<String, String> targetFields = {
    "activity": "Hoạt động * (Bắt buộc)",
    "dayNumber": "Ngày chi tiết (VD: Ngày 1, Day 2)",
    "timeRange": "Khung giờ (VD: 8h-9h)",
    "location": "Địa điểm",
    "note": "Ghi chú",
    "estimatedCost": "Chi phí dự kiến",
  };

  // Ánh xạ đã được chọn (Trường đích -> Index của cột trong Excel)
  late Map<String, int?> matching;

  @override
  void initState() {
    super.initState();
    // Bước 1: Gọi Auto-match từ ExcelHelper để tự động điền thông minh
    final autoMatched = ExcelHelper.autoMatchColumns(widget.result.headers);
    matching = {};
    for (var key in targetFields.keys) {
      matching[key] = autoMatched[key];
    }
  }

  void _onContinue() {
    // Hoạt động là trường bắt buộc phải được map
    if (matching["activity"] == null) {
      Get.snackbar(
        "Lỗi ánh xạ",
        "Vui lòng chọn cột chứa 'Hoạt động' trong file Excel",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Convert sang Map<String, int> không null
    Map<String, int> finalMapping = {};
    matching.forEach((key, val) {
      if (val != null) {
        finalMapping[key] = val;
      }
    });

    final items = ExcelHelper.parseRows(
      allRows: widget.result.allRows,
      mapping: finalMapping,
      startRowIndex: widget.result.headerRowIndex + 1,
    );

    if (items.isEmpty) {
      Get.snackbar(
        "Lỗi đọc file",
        "Không thể tìm thấy hàng dữ liệu hợp lệ nào dựa trên cấu hình khớp cột hiện tại.",
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Đóng Bottom Sheet khớp cột
    Get.back();

    // Mở màn hình xem trước dữ liệu Excel cực đẹp!
    Get.dialog(
      ExcelPreviewDialog(
        tripId: widget.tripId,
        parsedItems: items,
      ),
      useSafeArea: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: 24 + MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.compare_arrows, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Khớp cột thông minh",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.result.fileName,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Hệ thống đã tự động so khớp các cột tương thích. Bạn vui lòng kiểm tra lại bên dưới để khớp dữ liệu chính xác nhất:",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
          ),
          const SizedBox(height: 16),
          // Tiêu đề giải thích cột Trái & Phải
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    "Thông tin hệ thống",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: Text(
                    "Cột trong file Excel",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // List Fields mapping
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: targetFields.entries.map((entry) {
                  final fieldKey = entry.key;
                  final fieldName = entry.value;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(
                            fieldName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: fieldKey == 'activity' ? FontWeight.bold : FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 5,
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int?>(
                                value: matching[fieldKey],
                                hint: const Text("Bỏ qua", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                items: [
                                  const DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text("-- Bỏ qua --", style: TextStyle(fontSize: 13, color: Colors.grey)),
                                  ),
                                  ...List.generate(widget.result.headers.length, (idx) {
                                    final colHeader = widget.result.headers[idx];
                                    final colLabel = colHeader.isEmpty ? "(Cột trống ${idx + 1})" : colHeader;
                                    return DropdownMenuItem<int?>(
                                      value: idx,
                                      child: Text(
                                        colLabel,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    matching[fieldKey] = val;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Button tiếp tục
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: _onContinue,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("XEM TRƯỚC LỊCH TRÌNH", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
