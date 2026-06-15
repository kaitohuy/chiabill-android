import 'package:chiabill/theme/app_colors.dart';
import 'package:chiabill/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/trip_detail_controller.dart';
import '../../controllers/trip_history_controller.dart';
import '../../controllers/group_fund_controller.dart';
import '../../utils/currency_util.dart';
import 'tabs/history_tab.dart';

class HistoryScreen extends StatefulWidget {
  final TripDetailController mainController;
  const HistoryScreen({super.key, required this.mainController});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TripHistoryController historyController;
  late GroupFundController fundController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    final tripIdStr = widget.mainController.tripId.toString();
    if (Get.isRegistered<TripHistoryController>(tag: tripIdStr)) {
      historyController = Get.find<TripHistoryController>(tag: tripIdStr);
    } else {
      historyController = Get.put(TripHistoryController(widget.mainController.tripId), tag: tripIdStr);
    }
    
    // Đăng ký hoặc tìm GroupFundController
    if (Get.isRegistered<GroupFundController>(tag: tripIdStr)) {
      fundController = Get.find<GroupFundController>(tag: tripIdStr);
    } else {
      fundController = Get.put(GroupFundController(widget.mainController.tripId), tag: tripIdStr);
    }

    // Tải dữ liệu ban đầu
    fundController.fetchContributions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    final tripIdStr = widget.mainController.tripId.toString();
    if (Get.isRegistered<TripHistoryController>(tag: tripIdStr)) {
      Get.delete<TripHistoryController>(tag: tripIdStr);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text("Lịch sử chuyến đi", style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "GIAO DỊCH"),
            Tab(text: "ĐÓNG QUỸ"),
            Tab(text: "HOẠT ĐỘNG"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Giao dịch
          HistoryTab(mainController: widget.mainController),
          
          // Tab 2: Lịch sử Đóng quỹ
          _buildFundContributionTab(context),
          
          // Tab 3: Nhật ký hoạt động
          _buildActivityTab(context, historyController),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: LỊCH SỬ ĐÓNG QUỸ
  // ==========================================
  Widget _buildFundContributionTab(BuildContext context) {
    return Obx(() {
      if (fundController.isContributionsLoading.value && fundController.contributions.isEmpty) {
        return Center(child: CircularProgressIndicator(color: AppColors.primary));
      }

      final list = fundController.contributions;

      if (list.isEmpty) {
        return RefreshIndicator(
          onRefresh: () => fundController.fetchContributions(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: Get.height * 0.15),
              const EmptyState(text: "Chưa có lịch sử đóng quỹ nào"),
            ],
          ),
        );
      }

      // Sắp xếp các khoản đóng quỹ theo thời gian mới nhất lên trước
      final sortedList = List.from(list);
      sortedList.sort((a, b) => b.contributionDate.compareTo(a.contributionDate));

      return RefreshIndicator(
        onRefresh: () => fundController.fetchContributions(),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
          ),
          itemCount: sortedList.length,
          itemBuilder: (context, index) {
            final item = sortedList[index];
            final isDonate = item.type == "VOLUNTARY";
            final isConfirmed = item.isConfirmed;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Avatar người đóng
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: item.contributor.avatarUrl != null
                          ? NetworkImage(item.contributor.avatarUrl!)
                          : null,
                      child: item.contributor.avatarUrl == null
                          ? Text(item.contributor.name?.substring(0, 1).toUpperCase() ?? "U")
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // Thông tin
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.contributor.name ?? "Thành viên",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDonate ? Colors.orange[50] : Colors.blue[50],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isDonate ? "DONATE" : "THU QUỸ",
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: isDonate ? Colors.orange[800] : Colors.blue[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (item.notes != null && item.notes!.isNotEmpty) ...[
                            Text(
                              item.notes!,
                              style: TextStyle(color: Colors.grey[700], fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(item.contributionDate),
                            style: TextStyle(color: Colors.grey[400], fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Số tiền & Trạng thái
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "+${CurrencyUtils.formatNumber(item.amount)} đ",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isConfirmed ? Colors.green[700] : Colors.orange[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isConfirmed ? Colors.green[50] : Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isConfirmed ? "Đã duyệt" : "Chờ duyệt",
                            style: TextStyle(
                              color: isConfirmed ? Colors.green[800] : Colors.orange[800],
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }

  // ==========================================
  // TAB 3: NHẬT KÝ HOẠT ĐỘNG
  // ==========================================
  Widget _buildActivityTab(BuildContext context, TripHistoryController controller) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Obx(() {
                bool hasFilter = controller.filterHistoryActions.isNotEmpty ||
                    controller.filterHistoryStartDate.value != null ||
                    controller.filterHistoryEndDate.value != null;
                return InkWell(
                  onTap: () => _showHistoryFilterBottomSheet(context, controller),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                        color: hasFilter ? Colors.blue : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12)
                    ),
                    child: Row(
                        children: [
                          Icon(Icons.filter_list, color: hasFilter ? Colors.white : Colors.grey.shade700, size: 16),
                          const SizedBox(width: 8),
                          Text("Lọc hoạt động", style: TextStyle(color: hasFilter ? Colors.white : Colors.grey.shade800, fontWeight: FontWeight.bold))
                        ]
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isHistoryLoading.value && controller.tripHistories.isEmpty) {
              return Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            if (controller.tripHistories.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => controller.fetchTripHistory(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 24,
                    bottom: 16 + MediaQuery.of(context).padding.bottom,
                  ),
                  children: [
                    const SizedBox(height: 100),
                    Center(
                      child: Column(
                        children: [
                          SizedBox(height: Get.height * 0.05),
                          const EmptyState(text: "Chưa có nhật ký hoạt động nào"),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => controller.fetchTripHistory(),
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (!controller.isLoadingMoreHistories.value && scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                    controller.fetchTripHistory(isRefresh: false);
                  }
                  return false;
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 16 + MediaQuery.of(context).padding.bottom,
                  ),
                  itemCount: controller.tripHistories.length + (controller.isHistoryLastPage.value ? 0 : 1),
                  itemBuilder: (context, index) {
                    if (index == controller.tripHistories.length) {
                      return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(child: CircularProgressIndicator(color: AppColors.primary))
                      );
                    }

                    final log = controller.tripHistories[index];
                    
                    IconData actionIcon = Icons.info_outline;
                    Color actionColor = Colors.grey;
                    String actionLabel = "Thông báo";

                    switch (log.action) {
                      case 'ADD_EXPENSE':
                        actionIcon = Icons.add_circle_outline;
                        actionColor = AppColors.primary;
                        actionLabel = "Thêm mới";
                        break;
                      case 'EDIT_EXPENSE':
                        actionIcon = Icons.edit_note;
                        actionColor = Colors.blue;
                        actionLabel = "Chỉnh sửa";
                        break;
                      case 'DELETE_EXPENSE':
                        actionIcon = Icons.delete_forever;
                        actionColor = Colors.red;
                        actionLabel = "Đã xóa";
                        break;
                      case 'ADD_MEMBER':
                        actionIcon = Icons.person_add_alt;
                        actionColor = Colors.purple;
                        actionLabel = "Thêm người";
                        break;
                      case 'REMOVE_MEMBER':
                        actionIcon = Icons.person_remove_alt_1;
                        actionColor = AppColors.primary;
                        actionLabel = "Xóa người";
                        break;
                      case 'PAYMENT_REQUEST':
                      case 'PAYMENT_APPROVE':
                      case 'PAYMENT_REJECT':
                        actionIcon = Icons.payment;
                        actionColor = Colors.teal;
                        actionLabel = "Thanh toán";
                        break;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: actionColor.withValues(alpha: 0.2)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: actionColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(actionIcon, color: actionColor, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        log.actorName ?? "Thành viên",
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Text(
                                        _formatDateTime(log.createdAt),
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: actionColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    actionLabel,
                                    style: TextStyle(color: actionColor, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Text(
                              log.content ?? "",
                              style: const TextStyle(fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }),
        )
      ],
    );
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      if (dateStr.length > 16) {
        return dateStr.substring(0, 16).replaceAll('T', ' ');
      }
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }

  void _showHistoryFilterBottomSheet(BuildContext context, TripHistoryController controller) {
    List<String> tempActions = List.from(controller.filterHistoryActions);
    String? tempStartDate = controller.filterHistoryStartDate.value;
    String? tempEndDate = controller.filterHistoryEndDate.value;

    final Map<String, String> availableActions = {
      'ADD_EXPENSE': 'Thêm chi phí',
      'EDIT_EXPENSE': 'Sửa chi phí',
      'DELETE_EXPENSE': 'Xóa chi phí',
      'ADD_MEMBER': 'Thêm thành viên',
      'REMOVE_MEMBER': 'Xóa thành viên',
      'PAYMENT_REQUEST': 'Yêu cầu thanh toán',
      'PAYMENT_APPROVE': 'Duyệt thanh toán',
      'PAYMENT_REJECT': 'Từ chối thanh toán',
    };

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 16 + MediaQuery.of(context).padding.bottom),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Lọc hoạt động", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                          onPressed: () => setState(() { tempActions.clear(); tempStartDate = null; tempEndDate = null; }),
                          child: const Text("Xóa lọc", style: TextStyle(color: Colors.red))
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Loại hoạt động:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: availableActions.entries.map((entry) {
                              bool isSelected = tempActions.contains(entry.key);
                              return FilterChip(
                                label: Text(entry.value, style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
                                selected: isSelected,
                                selectedColor: Colors.blue,
                                checkmarkColor: Colors.white,
                                backgroundColor: Colors.blue.shade50,
                                onSelected: (val) {
                                  setState(() {
                                    if (val) {
                                      tempActions.add(entry.key);
                                    } else {
                                      tempActions.remove(entry.key);
                                    }
                                  });
                                }
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          const Text("Thời gian:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final DateTimeRange? picked = await showDateRangePicker(
                                context: context,
                                locale: const Locale('vi', 'VN'),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                                initialDateRange: tempStartDate != null && tempEndDate != null
                                    ? DateTimeRange(
                                        start: DateTime.parse(tempStartDate!),
                                        end: DateTime.parse(tempEndDate!),
                                      )
                                    : null,
                                helpText: "Chọn khoảng thời gian",
                                cancelText: "Hủy",
                                confirmText: "Lưu",
                                saveText: "Lưu",
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(primary: Colors.blue, onPrimary: Colors.white, onSurface: Colors.black),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() {
                                  tempStartDate = "${picked.start.toIso8601String().substring(0, 10)}T00:00:00";
                                  tempEndDate = "${picked.end.toIso8601String().substring(0, 10)}T23:59:59";
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    tempStartDate != null && tempEndDate != null
                                        ? "${tempStartDate!.substring(8, 10)}/${tempStartDate!.substring(5, 7)}/${tempStartDate!.substring(0, 4)} - ${tempEndDate!.substring(8, 10)}/${tempEndDate!.substring(5, 7)}/${tempEndDate!.substring(0, 4)}"
                                        : "Chọn khoảng thời gian",
                                    style: TextStyle(color: tempStartDate != null ? Colors.black87 : Colors.grey.shade600),
                                  ),
                                  Icon(Icons.calendar_today, size: 18, color: Colors.blue),
                                ],
                              ),
                            ),
                          ),
                          if (tempStartDate != null)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => setState(() { tempStartDate = null; tempEndDate = null; }),
                                child: const Text("Xóa ngày", style: TextStyle(color: Colors.red, fontSize: 12)),
                              ),
                            ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                        onPressed: () {
                          Get.back();
                          controller.applyHistoryFilter(actions: tempActions, startDate: tempStartDate, endDate: tempEndDate);
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
}