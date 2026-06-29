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
    "activity": "activity_required".tr,
    "dayNumber": "day_details_hint".tr,
    "timeRange": "time_range_hint".tr,
    "location": "location".tr,
    "note": "notes".tr,
    "estimatedCost": "estimated_cost_label".tr,
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
        "mapping_error".tr,
        "select_activity_column_error".tr,
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
        "file_read_error".tr,
        "no_valid_data_rows_error".tr,
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
                    Text(
                      "smart_column_matching".tr,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
            "column_matching_desc".tr,
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
                    "system_info".tr,
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
                    "excel_column".tr,
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
                                hint: Text("ignore".tr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                items: [
                                  DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text("-- ${'ignore'.tr} --", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                  ),
                                  ...List.generate(widget.result.headers.length, (idx) {
                                    final colHeader = widget.result.headers[idx];
                                    final colLabel = colHeader.isEmpty ? "empty_column_prefix".trParams({'index': (idx + 1).toString()}) : colHeader;
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("preview_itinerary_caps".tr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
