import 'package:chiabill/theme/app_colors.dart';
import 'package:chiabill/utils/toast_util.dart';
import 'package:chiabill/utils/export_helper.dart';
import 'package:chiabill/utils/loading_util.dart';
import 'package:chiabill/utils/excel_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import '../../controllers/itinerary_controller.dart';
import '../../controllers/trip_detail_controller.dart';
import '../../data/models/itinerary_item_response.dart';
import '../../data/models/trip_response.dart';
import '../../utils/currency_util.dart';
import '../../utils/time_util.dart';
import 'itinerary_detail_dialog.dart';
import 'column_matching_sheet.dart';
import 'itinerary_settings_screen.dart';

class ItineraryScreen extends StatelessWidget {
  final int tripId;

  const ItineraryScreen({super.key, required this.tripId});

  ItineraryController get controller => Get.find<ItineraryController>(tag: tripId.toString());

  bool get _isCurrentUserDisabled {
    if (Get.isRegistered<TripDetailController>(tag: tripId.toString())) {
      return Get.find<TripDetailController>(tag: tripId.toString()).isCurrentUserDisabled;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Đảm bảo controller được đăng ký và tìm đúng tag
    if (!Get.isRegistered<ItineraryController>(tag: tripId.toString())) {
      Get.put(ItineraryController(tripId), tag: tripId.toString());
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Obx(() {
          // Ép đăng ký Rx variable để tránh lỗi "improper use of GetX"
          controller.isLoading.value;
          controller.itineraryList.length;
          
          String rangeStr = "";
          if (controller.startDate != null) {
            final start = DateTime.tryParse(controller.startDate!);
            if (start != null) {
              final end = controller.endDate != null ? DateTime.tryParse(controller.endDate!) : null;
              if (end != null) {
                rangeStr = " (${start.day}/${start.month} - ${end.day}/${end.month})";
              } else {
                rangeStr = " (${start.day}/${start.month})";
              }
            }
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.tripName,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                "${'itinerary_title'.tr}$rangeStr",
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          );
        }),
        actions: [
          Obx(() {
            final isAsc = controller.isAscending.value;
            return IconButton(
              icon: Icon(
                isAsc ? Icons.arrow_downward : Icons.arrow_upward,
                color: Colors.white,
              ),
              tooltip: isAsc ? "sort_time_asc".tr : "sort_time_desc".tr,
              onPressed: () {
                controller.isAscending.value = !controller.isAscending.value;
              },
            );
          }),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: "alarm_settings".tr,
            onPressed: () => Get.to(() => ItinerarySettingsScreen(tripId: tripId)),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'export') {
                _handleExportExcel();
                return;
              }
              if (_isCurrentUserDisabled) {
                Get.snackbar(
                  "notification".tr,
                  "user_suspended_error".tr,
                  backgroundColor: Colors.redAccent,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
              if (value == 'import') {
                _handleImportExcel(context);
              } else if (value == 'clone') {
                _handleCloneFromOtherTrip(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    const Icon(Icons.file_upload, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text("import_excel".tr),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    const Icon(Icons.file_download, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text("export_excel".tr),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clone',
                child: Row(
                  children: [
                    const Icon(Icons.copy_all, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text("clone_from_other".tr),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final days = controller.tripDays;
        final grouped = controller.groupedItinerary;

        return Column(
          children: [
            // Thanh chuyển đổi ngày ngang cực đẹp (Day Tabs)
            _buildDayTabBar(days),

            // Tóm tắt ngày hiện tại (hoạt động và tổng chi phí dự kiến)
            _buildDaySummaryBar(controller.selectedDayIndex.value + 1),

            // Phần Timeline hoạt động
            Expanded(
              child: _buildTimelineContent(days, grouped),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          if (_isCurrentUserDisabled) {
            Get.snackbar(
              "notification".tr,
              "user_suspended_error".tr,
              backgroundColor: Colors.redAccent,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
            );
            return;
          }
          _openDetailDialog(
            context,
            item: ItineraryItemResponse(
              dayNumber: controller.selectedDayIndex.value + 1,
              activity: "",
            ),
          );
        },
      ),
    );
  }

  /// Vẽ dòng tóm tắt thông tin hoạt động và dự toán chi phí của ngày
  Widget _buildDaySummaryBar(int dayNumber) {
    return Obx(() {
      final dayItems = controller.itineraryList.where((e) => e.dayNumber == dayNumber).toList();
      if (dayItems.isEmpty) return const SizedBox.shrink();

      final totalCost = dayItems.map((e) => e.estimatedCost ?? 0.0).fold(0.0, (a, b) => a + b);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade100),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              "day_summary_text".trParams({'day': dayNumber.toString(), 'count': dayItems.length.toString()}),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const Spacer(),
            if (totalCost > 0)
              Text(
                "${'day_budget'.tr}: ${CurrencyUtils.formatNumber(totalCost.toInt())} đ",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
      );
    });
  }

  /// Vẽ TabBar chuyển đổi ngày
  Widget _buildDayTabBar(List<DateTime> days) {
    return Container(
      height: 70,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final date = days[index];
          return Obx(() {
            final isSelected = controller.selectedDayIndex.value == index;
            return GestureDetector(
              onTap: () => controller.selectedDayIndex.value = index,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.grey.shade200,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${'day'.tr} ${index + 1}",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}",
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected ? Colors.white70 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  /// Vẽ nội dung Timeline
  Widget _buildTimelineContent(List<DateTime> days, Map<int, List<ItineraryItemResponse>> grouped) {
    final activeDayNum = controller.selectedDayIndex.value + 1;
    final dayActivities = grouped[activeDayNum] ?? [];

    if (dayActivities.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_outlined, size: 70, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                "no_activities_day".tr,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Text(
                "add_activity_hint".tr,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final nodes = buildNodes(dayActivities, isAscending: controller.isAscending.value);

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(top: 20, bottom: 80, left: 16, right: 16),
      itemCount: nodes.length,
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        final node = nodes[index];
        if (node is ActivityNode) {
          final item = node.item;
          return ReorderableDelayedDragStartListener(
            key: ValueKey("act_${item.id}"),
            index: index,
            child: _buildActivityCard(context, item, index, nodes.length),
          );
        } else if (node is GapNode) {
          return _buildGapCard(context, node, index, nodes.length);
        }
        return SizedBox(key: ValueKey("none_$index"));
      },
      onReorder: (oldIndex, newIndex) async {
        if (_isCurrentUserDisabled) {
          Get.snackbar(
            "notification".tr,
            "user_suspended_error".tr,
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        if (oldIndex == newIndex) return;

        final dragNode = nodes[oldIndex];
        if (dragNode is! ActivityNode) return;

        final targetNode = nodes[newIndex];
        
        try {
          if (targetNode is GapNode) {
            // Cập nhật khung giờ của Activity thành khung giờ của Gap
            final updatedItem = dragNode.item.copyWith(
              timeRange: targetNode.timeRange,
            );
            final success = await controller.saveItineraryItem(updatedItem, showLoading: false, showToast: false);
            if (success) {
              ToastUtil.showSuccess("updated".tr, "activity_moved_to".trParams({'time': targetNode.timeRange}));
            }
          } else if (targetNode is ActivityNode) {
            // Hoán đổi khung giờ giữa 2 hoạt động
            final tempTime = dragNode.item.timeRange;
            final updatedDrag = dragNode.item.copyWith(timeRange: targetNode.item.timeRange);
            final updatedTarget = targetNode.item.copyWith(timeRange: tempTime);
            
            final results = await Future.wait([
              controller.saveItineraryItem(updatedDrag, showLoading: false, showToast: false),
              controller.saveItineraryItem(updatedTarget, showLoading: false, showToast: false),
            ]);
            
            if (results.every((r) => r)) {
              ToastUtil.showSuccess("swapped".tr, "swap_success".tr);
            }
          }
        } catch (e) {
          ToastUtil.showError("error".tr, e.toString());
        }
      },
    );
  }

  Widget _buildActivityCard(BuildContext context, ItineraryItemResponse item, int index, int totalCount) {
    final isFirst = index == 0;
    final isLast = index == totalCount - 1;

    return Stack(
      key: ValueKey("act_${item.id}"),
      children: [
        // Timeline line & dot (vẽ bằng Stack + Positioned để tối ưu hiệu năng)
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  width: 2,
                  color: isFirst ? Colors.transparent : Colors.grey.shade300,
                ),
              ),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary,
                    width: 3.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    )
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast ? Colors.transparent : Colors.grey.shade300,
                ),
              ),
            ],
          ),
        ),

        // Card content
        Padding(
          padding: const EdgeInsets.only(left: 36, top: 8, bottom: 8),
          child: Slidable(
            key: ValueKey(item.id),
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (context) => _openDetailDialog(context, item: item),
                  backgroundColor: Colors.amber.shade600,
                  foregroundColor: Colors.white,
                  icon: Icons.edit,
                  label: 'edit'.tr,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                ),
                SlidableAction(
                  onPressed: (context) => _handleDeleteItem(item.id),
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: 'delete'.tr,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left primary bar
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _openDetailDialog(context, item: item),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Time
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 14, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Text(
                                        item.timeRange ?? "all_day".tr,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const Spacer(),
                                      // Drag indicator
                                      Icon(Icons.drag_indicator, size: 18, color: Colors.grey.shade400),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Activity name
                                  Text(
                                    item.activity,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),

                                  // Location
                                  if (item.location != null && item.location!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.pin_drop_outlined, size: 14, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            item.location!,
                                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],

                                  // Estimated Cost
                                  if (item.estimatedCost != null && item.estimatedCost! > 0) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.payment_outlined, size: 14, color: Colors.amber.shade700),
                                        const SizedBox(width: 6),
                                        Text(
                                          "${'estimated_cost_label'.tr}: ${CurrencyUtils.formatNumber(item.estimatedCost!)} đ",
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.amber.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],

                                  // Notes
                                  if (item.note != null && item.note!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        "💡 ${item.note}",
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: Colors.blueGrey,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGapCard(BuildContext context, GapNode node, int index, int totalCount) {
    return Stack(
      key: ValueKey("gap_${node.timeRange}"),
      children: [
        // Timeline line & dot (vẽ bằng Stack + Positioned để tối ưu hiệu năng)
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: CustomPaint(
                  size: const Size(24, double.infinity),
                  painter: LineDashedPainter(color: Colors.grey.shade300),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: CustomPaint(
                  size: const Size(24, double.infinity),
                  painter: LineDashedPainter(color: Colors.grey.shade300),
                ),
              ),
            ],
          ),
        ),

        // Gap Card
        Padding(
          padding: const EdgeInsets.only(left: 36, top: 8, bottom: 8),
          child: CustomPaint(
            painter: DashedRectPainter(
              color: Colors.grey.shade300,
              borderRadius: 12.0,
              dashLength: 5,
              gap: 3,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  Get.dialog(ItineraryDetailDialog(
                    tripId: tripId,
                    item: ItineraryItemResponse(
                      dayNumber: node.dayNumber,
                      timeRange: node.timeRange,
                      activity: "",
                    ),
                  ));
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.hourglass_empty, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${'free_time'.tr} (${node.timeRange})",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "tap_to_add_activity".tr,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.add_circle_outline, size: 20, color: AppColors.primary.withValues(alpha: 0.6)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Mở form điền thông tin lẻ
  void _openDetailDialog(BuildContext context, {ItineraryItemResponse? item}) {
    Get.dialog(
      ItineraryDetailDialog(tripId: tripId, item: item),
    );
  }

  /// Xóa hoạt động
  void _handleDeleteItem(int? itemId) {
    if (itemId == null) return;
    if (_isCurrentUserDisabled) {
      Get.snackbar(
        "notification".tr,
        "user_suspended_error".tr,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("confirm_delete".tr),
        content: Text("delete_activity_confirm_desc".tr),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("cancel_caps".tr, style: const TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Get.back();
              await controller.deleteItineraryItem(itemId);
            },
            child: Text("delete_caps".tr, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleImportExcel(BuildContext context) async {
    try {
      final preParsed = await ExcelHelper.pickAndPreParseExcel();
      if (preParsed == null) return;

      // Mở Bottom Sheet khớp cột
      if (Get.isBottomSheetOpen == true) return;
      Get.bottomSheet(
        ColumnMatchingSheet(tripId: tripId, result: preParsed),
        isScrollControlled: true,
      );
    } catch (e) {
      ToastUtil.showError("system_error".tr, "${'excel_create_failed'.tr}: $e");
    }
  }

  /// Xuất lịch trình du lịch ra file Excel
  void _handleExportExcel() async {
    if (controller.itineraryList.isEmpty) {
      ToastUtil.showWarning("error".tr, "itinerary_empty_export".tr);
      return;
    }

    try {
      LoadingUtil.show();
      final bytes = await controller.exportItineraryToExcel();
      LoadingUtil.hide();

      if (bytes == null) {
        ToastUtil.showError("error".tr, "excel_create_failed".tr);
        return;
      }

      final safeName = controller.tripName.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
      final fileName = "LichTrinh_${safeName}_$tripId.xlsx";

      ExportHelper.showExportActionSheet(
        bytes: bytes,
        fileName: fileName,
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        shareText: '${'itinerary_share_prefix'.tr}: ${controller.tripName}',
      );
    } catch (e) {
      LoadingUtil.hide();
      ToastUtil.showError("system_error".tr, "$e");
    }
  }

  /// Xử lý chọn và sao chép lịch trình từ chuyến đi khác
  void _handleCloneFromOtherTrip(BuildContext context) async {
    try {
      LoadingUtil.show();
      final trips = await controller.fetchAllMyTrips();
      LoadingUtil.hide();

      final otherTrips = trips.where((t) => t.id != tripId).toList();
      if (otherTrips.isEmpty) {
        ToastUtil.showInfo("notification".tr, "no_other_trips_to_clone".tr);
        return;
      }

      if (Get.isBottomSheetOpen == true) return;
      if (!context.mounted) return;
      Get.bottomSheet(
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16 + MediaQuery.of(context).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "clone_itinerary_title".tr,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "clone_itinerary_desc".tr,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: otherTrips.length,
                  itemBuilder: (context, index) {
                    final t = otherTrips[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.orangeAccent,
                          child: Icon(Icons.flight_takeoff, color: Colors.white),
                        ),
                        title: Text(
                          t.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          (t.startDate != null && t.endDate != null)
                              ? "${t.startDate} - ${t.endDate}"
                              : "no_specific_date".tr,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Get.back(); // Đóng bottom sheet
                          _confirmCloneTrip(context, t);
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        isScrollControlled: true,
      );
    } catch (e) {
      LoadingUtil.hide();
      ToastUtil.showError("system_error".tr, "$e");
    }
  }

  void _confirmCloneTrip(BuildContext context, TripResponse selectedTrip) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("confirm_clone".tr),
        content: Text(
          "clone_confirm_desc".trParams({'name': selectedTrip.name}),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("cancel_caps".tr, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Get.back(); // Đóng dialog
              await controller.cloneItineraryFromTrip(selectedTrip.id);
            },
            child: Text(
              "clone_caps".tr,
              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

abstract class TimelineNode {}

class ActivityNode extends TimelineNode {
  final ItineraryItemResponse item;
  ActivityNode(this.item);
}

class GapNode extends TimelineNode {
  final String timeRange;
  final int dayNumber;
  final String startTime;
  final String endTime;
  GapNode({required this.timeRange, required this.dayNumber, required this.startTime, required this.endTime});
}

List<TimelineNode> buildNodes(List<ItineraryItemResponse> activities, {bool isAscending = true}) {
  List<TimelineNode> nodes = [];
  if (activities.isEmpty) return nodes;

  List<ItineraryItemResponse> sorted = List.from(activities)..sort((a, b) {
    final cmp = compareTimeRanges(a.timeRange, b.timeRange);
    return isAscending ? cmp : -cmp;
  });

  for (int i = 0; i < sorted.length; i++) {
    final current = sorted[i];
    nodes.add(ActivityNode(current));

    if (i < sorted.length - 1) {
      final next = sorted[i + 1];
      final curRange = parseTimeRange(current.timeRange);
      final nextRange = parseTimeRange(next.timeRange);
      if (curRange != null && nextRange != null) {
        if (isAscending) {
          final curEnd = curRange[1];
          final nextStart = nextRange[0];
          if (compareTimeStrings(curEnd, nextStart) < 0) {
            nodes.add(GapNode(
              timeRange: "$curEnd - $nextStart",
              dayNumber: current.dayNumber,
              startTime: curEnd,
              endTime: nextStart,
            ));
          }
        } else {
          final curStart = curRange[0];
          final nextEnd = nextRange[1];
          if (compareTimeStrings(nextEnd, curStart) < 0) {
            nodes.add(GapNode(
              timeRange: "$nextEnd - $curStart",
              dayNumber: current.dayNumber,
              startTime: nextEnd,
              endTime: curStart,
            ));
          }
        }
      }
    }
  }
  return nodes;
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double borderRadius;

  DashedRectPainter({
    this.color = Colors.grey,
    this.strokeWidth = 1.0,
    this.gap = 4.0,
    this.dashLength = 6.0,
    this.borderRadius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    final dashPath = Path();
    double distance = 0.0;
    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + gap;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.borderRadius != borderRadius;
  }
}

class LineDashedPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashHeight;
  final double dashGap;

  LineDashedPainter({
    this.color = Colors.grey,
    this.strokeWidth = 2.0,
    this.dashHeight = 4.0,
    this.dashGap = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    double y = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(size.width / 2, y), Offset(size.width / 2, y + dashHeight), paint);
      y += dashHeight + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant LineDashedPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashHeight != dashHeight ||
        oldDelegate.dashGap != dashGap;
  }
}
