import 'package:chiabill/theme/app_colors.dart';
import 'package:chiabill/utils/toast_util.dart';
import 'package:chiabill/utils/currency_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../data/models/itinerary_item_response.dart';
import '../../controllers/itinerary_controller.dart';

class ItineraryDetailDialog extends StatefulWidget {
  final int tripId;
  final ItineraryItemResponse? item; // Null nếu là tạo mới

  const ItineraryDetailDialog({super.key, required this.tripId, this.item});

  @override
  State<ItineraryDetailDialog> createState() => _ItineraryDetailDialogState();
}

class _ItineraryDetailDialogState extends State<ItineraryDetailDialog> {
  late ItineraryController controller;
  bool _isSaving = false;

  late int selectedDay;
  late TextEditingController timeCtrl;
  late TextEditingController activityCtrl;
  late TextEditingController locationCtrl;
  late TextEditingController noteCtrl;
  late TextEditingController costCtrl;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ItineraryController>(tag: widget.tripId.toString());

    selectedDay = widget.item?.dayNumber ?? 1;
    timeCtrl = TextEditingController(text: widget.item?.timeRange ?? "");
    activityCtrl = TextEditingController(text: widget.item?.activity ?? "");
    locationCtrl = TextEditingController(text: widget.item?.location ?? "");
    noteCtrl = TextEditingController(text: widget.item?.note ?? "");

    final costVal = widget.item?.estimatedCost;
    costCtrl = TextEditingController(
      text: costVal != null ? CurrencyUtils.formatNumber(costVal.toInt()) : "",
    );
  }

  @override
  void dispose() {
    timeCtrl.dispose();
    activityCtrl.dispose();
    locationCtrl.dispose();
    noteCtrl.dispose();
    costCtrl.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTimeOfDay(String str) {
    try {
      final clean = str.trim().replaceAll(RegExp(r'[^0-9:]'), '');
      final p = clean.split(':');
      if (p.isNotEmpty) {
        final hour = int.parse(p[0]);
        final minute = p.length > 1 ? int.parse(p[1]) : 0;
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (_) {}
    return null;
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    return "${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _selectTimeRange(BuildContext context) async {
    TimeOfDay? tempStart;
    TimeOfDay? tempEnd;

    if (timeCtrl.text.isNotEmpty) {
      final parts = timeCtrl.text.split('-');
      if (parts.isNotEmpty) {
        tempStart = _parseTimeOfDay(parts[0].trim());
      }
      if (parts.length > 1) {
        tempEnd = _parseTimeOfDay(parts[1].trim());
      }
    }

    final result = await Get.bottomSheet<String?>(
      StatefulBuilder(
        builder: (context, setStateSheet) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Chọn thời gian hoạt động",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: tempStart ?? const TimeOfDay(hour: 8, minute: 0),
                            helpText: "Chọn giờ bắt đầu",
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: AppColors.primary,
                                  onPrimary: Colors.white,
                                  onSurface: Colors.black87,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setStateSheet(() {
                              tempStart = picked;
                            });
                            // Tự động mở tiếp hộp thoại chọn giờ kết thúc
                            if (!context.mounted) return;
                            final pickedEnd = await showTimePicker(
                              context: context,
                              initialTime: tempEnd ?? TimeOfDay(hour: picked.hour + 1, minute: picked.minute),
                              helpText: "Chọn giờ kết thúc",
                              builder: (context, child) => Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: AppColors.primary,
                                    onPrimary: Colors.white,
                                    onSurface: Colors.black87,
                                  ),
                                ),
                                child: child!,
                              ),
                            );
                            if (pickedEnd != null) {
                              setStateSheet(() {
                                tempEnd = pickedEnd;
                              });
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Giờ bắt đầu", style: TextStyle(fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(
                                tempStart != null ? _formatTimeOfDay(tempStart!) : "Chọn giờ",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: tempStart != null ? AppColors.primary : Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          if (tempStart == null) {
                            ToastUtil.showWarning("Thông báo", "Vui lòng chọn giờ bắt đầu trước");
                            return;
                          }
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: tempEnd ?? TimeOfDay(hour: tempStart!.hour + 1, minute: tempStart!.minute),
                            helpText: "Chọn giờ kết thúc",
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: AppColors.primary,
                                  onPrimary: Colors.white,
                                  onSurface: Colors.black87,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setStateSheet(() {
                              tempEnd = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Giờ kết thúc", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Text(
                                    tempEnd != null ? _formatTimeOfDay(tempEnd!) : "Không bắt buộc",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: tempEnd != null ? FontWeight.bold : FontWeight.normal,
                                      color: tempEnd != null ? Colors.black87 : Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                              if (tempEnd != null)
                                GestureDetector(
                                  onTap: () {
                                    setStateSheet(() {
                                      tempEnd = null;
                                    });
                                  },
                                  child: const Icon(Icons.cancel, size: 20, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("HỦY", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: tempStart == null
                            ? null
                            : () {
                                String val = _formatTimeOfDay(tempStart!);
                                if (tempEnd != null) {
                                  val += " - ${_formatTimeOfDay(tempEnd!)}";
                                }
                                Get.back(result: val);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("ĐỒNG Ý", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    if (result != null) {
      setState(() {
        timeCtrl.text = result;
      });
    }
  }

  void _submit() async {
    if (_isSaving) return;
    final activity = activityCtrl.text.trim();
    if (activity.isEmpty) {
      ToastUtil.showWarning("Lỗi", "Vui lòng nhập tên hoạt động");
      return;
    }

    final double? cost = double.tryParse(costCtrl.text.replaceAll(RegExp(r'[^0-9.]'), ""));

    final item = ItineraryItemResponse(
      id: widget.item?.id,
      dayNumber: selectedDay,
      timeRange: timeCtrl.text.trim().isEmpty ? null : timeCtrl.text.trim(),
      activity: activity,
      location: locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim(),
      note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      estimatedCost: cost,
    );

    setState(() {
      _isSaving = true;
    });

    final success = await controller.saveItineraryItem(item, showLoading: false, showToast: false);
    
    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }

    if (success) {
      Get.back(result: true);
      ToastUtil.showSuccess("Thành công", "Đã lưu hoạt động");
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = controller.tripDays.length;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.item == null ? "Thêm hoạt động mới" : "Chỉnh sửa hoạt động",
        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ngày hoạt động (ChoiceChips)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    "Chọn ngày hoạt động",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 42,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: totalDays,
                  itemBuilder: (context, index) {
                    final dayNum = index + 1;
                    final isSelected = selectedDay == dayNum;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        showCheckmark: false,
                        label: Text("Ngày $dayNum"),
                        selected: isSelected,
                        selectedColor: AppColors.primary.withValues(alpha: 0.15),
                        backgroundColor: Colors.grey.shade50,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primary : Colors.grey.shade700,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : Colors.grey.shade300,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => selectedDay = dayNum);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Khung giờ
              TextField(
                controller: timeCtrl,
                readOnly: true,
                onTap: () => _selectTimeRange(context),
                decoration: InputDecoration(
                  labelText: "Khung giờ hoạt động",
                  hintText: "Chạm để chọn giờ",
                  prefixIcon: Icon(Icons.access_time, color: AppColors.primary),
                  suffixIcon: timeCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              timeCtrl.clear();
                            });
                          },
                        )
                      : IconButton(
                          icon: Icon(Icons.edit_calendar, color: AppColors.primary),
                          onPressed: () => _selectTimeRange(context),
                        ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // Hoạt động
              TextField(
                controller: activityCtrl,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: "Hoạt động * (VD: Ăn sáng Phở Vũ)",
                  prefixIcon: Icon(Icons.explore, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  counterText: "",
                ),
              ),
              const SizedBox(height: 16),

              // Địa điểm
              TextField(
                controller: locationCtrl,
                maxLength: 150,
                decoration: InputDecoration(
                  labelText: "Địa điểm (VD: 15 Trần Hưng Đạo)",
                  prefixIcon: Icon(Icons.pin_drop, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  counterText: "",
                ),
              ),
              const SizedBox(height: 16),

              // Chi phí dự toán
              TextField(
                controller: costCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: "Chi phí dự kiến (đ)",
                  prefixIcon: Icon(Icons.attach_money, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // Ghi chú
              TextField(
                controller: noteCtrl,
                maxLength: 200,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Ghi chú",
                  prefixIcon: Icon(Icons.note, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  counterText: "",
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Get.back(),
          child: const Text("HỦY", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text("LƯU", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
