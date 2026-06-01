import 'package:chiabill/theme/app_colors.dart';
import 'package:chiabill/utils/currency_util.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../widgets/empty_state.dart';
import '../../../controllers/group_fund_controller.dart';
import '../../../controllers/trip_detail_controller.dart';
import '../../../controllers/trip_expense_controller.dart';
import '../../../controllers/profile_controller.dart';
import '../../../data/models/fund_contribution_response.dart';
import '../../../data/models/fund_response.dart';
import '../../../data/models/trip_member_response.dart';
import '../../../data/models/user_response.dart';
import '../widgets/fund_settings_sheet.dart';
import '../widgets/required_contribution_sheet.dart';
import '../widgets/voluntary_contribution_sheet.dart';

class GroupedContribution {
  final UserResponse contributor;
  final double totalAmount;
  final List<int> contributionIds;
  final List<String> allNotes;
  final DateTime latestDate;

  GroupedContribution({
    required this.contributor,
    required this.totalAmount,
    required this.contributionIds,
    required this.allNotes,
    required this.latestDate,
  });
}

class GroupFundTab extends StatefulWidget {
  final TripDetailController mainController;
  const GroupFundTab({super.key, required this.mainController});

  @override
  State<GroupFundTab> createState() => _GroupFundTabState();
}

class _GroupFundTabState extends State<GroupFundTab> with SingleTickerProviderStateMixin {
  late GroupFundController fundController;
  late TabController _tabController;
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Đăng ký hoặc lấy Controller
    final String tag = widget.mainController.tripId.toString();
    if (Get.isRegistered<GroupFundController>(tag: tag)) {
      fundController = Get.find<GroupFundController>(tag: tag);
      fundController.fetchFundData();
    } else {
      fundController = Get.put(GroupFundController(widget.mainController.tripId), tag: tag);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.mainController.trip.value;
    final currentUserId = widget.mainController.currentUserId;
    final isOwner = trip?.ownerId == currentUserId;

    return Obx(() {
      if (fundController.isLoading.value) {
        return Center(child: CircularProgressIndicator(color: AppColors.primary));
      }

      if (!fundController.isFundActivated.value) {
        // Giao diện Quỹ chưa được kích hoạt
        return _buildUnactivatedView();
      }

      final fundData = fundController.fund.value;
      if (fundData == null) {
        return const Center(child: Text("Đã xảy ra lỗi khi tải Quỹ chung."));
      }

      final isTreasurer = fundData.treasurer.id == currentUserId;
      final showAdminActions = isTreasurer || isOwner;

      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(text: "Quỹ"),
                Tab(text: "Donate"),
                Tab(text: "Thống kê"),
              ],
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildFundTab(fundData, showAdminActions, currentUserId),
            _buildDonateTab(fundData),
            _buildStatsTab(),
          ],
        ),
      );
    });
  }

  // ==========================================
  // UNACTIVATED VIEW (KÍCH HOẠT QUỸ CHUNG)
  // ==========================================
  Widget _buildUnactivatedView() {
    final members = widget.mainController.trip.value?.members ?? [];
    UserResponse? selectedTreasurer;
    if (Get.isRegistered<ProfileController>()) {
      selectedTreasurer = Get.find<ProfileController>().user.value;
    }
    final alertController = TextEditingController(text: "200000");

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wallet, size: 80, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              "Quỹ chung chưa kích hoạt",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Quỹ chung giúp cả nhóm thu tiền bắt buộc định kỳ hoặc nhận đóng góp tự nguyện của mọi người để thanh toán các khoản chi tiêu chung nhanh chóng.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
              icon: const Icon(Icons.flash_on),
              label: const Text("KÍCH HOẠT NGAY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              onPressed: () {
                _showActivateBottomSheet(members, selectedTreasurer, alertController);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showActivateBottomSheet(
    List<TripMemberResponse> members,
    UserResponse? selectedTreasurer,
    TextEditingController alertController,
  ) {
    Get.bottomSheet(
      FundSettingsSheet(
        members: members,
        initialTreasurer: selectedTreasurer,
        fundController: fundController,
      ),
      isScrollControlled: true,
    );
  }

  // ==========================================
  // TAB 1: QUỸ (FUND CORE)
  // ==========================================
  Widget _buildFundTab(FundResponse fundData, bool showAdminActions, int? currentUserId) {
    // Lọc ra các đợt thu bắt buộc chưa đóng (isConfirmed = false)
    final pendingRequired = fundController.contributions
        .where((c) => c.type == "REQUIRED" && !c.isConfirmed)
        .toList();

    // Gom nhóm đóng góp bắt buộc theo contributor.id
    final Map<int, List<FundContributionResponse>> groupedByMember = {};
    for (final c in pendingRequired) {
      groupedByMember.putIfAbsent(c.contributor.id, () => []).add(c);
    }

    final List<GroupedContribution> groupedPending = groupedByMember.entries.map((entry) {
      final list = entry.value;
      final contributor = list.first.contributor;
      final totalAmount = list.fold<double>(0.0, (sum, c) => sum + c.amount);
      final contributionIds = list.map((c) => c.id).toList();
      final allNotes = list.map((c) => c.notes ?? "Nộp quỹ").toSet().toList();
      
      DateTime latest = list.first.contributionDate;
      for (final c in list) {
        if (c.contributionDate.isAfter(latest)) {
          latest = c.contributionDate;
        }
      }

      return GroupedContribution(
        contributor: contributor,
        totalAmount: totalAmount,
        contributionIds: contributionIds,
        allNotes: allNotes,
        latestDate: latest,
      );
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        await fundController.fetchFundData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ Số dư Gradient cực đẹp
            _buildBalanceCard(fundData),
            const SizedBox(height: 16),

            // Thông tin Thủ quỹ
            _buildTreasurerCard(fundData, showAdminActions),
            const SizedBox(height: 24),

            // Hành động Thủ quỹ
            if (showAdminActions) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add_alert),
                      label: const Text("Yêu cầu đóng quỹ", style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => _showCreateRequiredContributionSheet(fundData),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Danh sách các đợt thu bắt buộc đang chờ nộp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Yêu cầu nộp quỹ đang chờ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("${groupedPending.length} người", style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),

            if (groupedPending.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, size: 40, color: AppColors.primary.withValues(alpha: 0.5)),
                    const SizedBox(height: 8),
                    const Text(
                      "Tuyệt vời! Không có đợt thu quỹ nào đang chờ đóng.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groupedPending.length,
                itemBuilder: (context, index) {
                  final item = groupedPending[index];
                  final isMyContribution = item.contributor.id == currentUserId;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isMyContribution ? AppColors.primary.withValues(alpha: 0.3) : Colors.grey[200]!,
                        width: isMyContribution ? 1.5 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isMyContribution ? "Bạn cần đóng" : (item.contributor.name ?? "Thành viên"),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.allNotes.join(", "),
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(item.latestDate),
                                style: TextStyle(color: Colors.grey[400], fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${CurrencyUtils.formatNumber(item.totalAmount)} đ",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: isMyContribution ? Colors.red : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (showAdminActions)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => _showConfirmMultipleContributionsDialog(item),
                                child: const Text("Xác nhận đã nộp", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "Chưa đóng",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(FundResponse fundData) {
    final alertThreshold = fundData.alertThreshold ?? 0.0;
    final isLowBalance = fundData.balance <= alertThreshold;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLowBalance
              ? [const Color(0xFFEF5350), const Color(0xFFE53935)]
              : [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isLowBalance ? Colors.red[300]! : AppColors.primary).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "SỐ DƯ QUỸ CHUNG",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "${CurrencyUtils.formatNumber(fundData.balance)} ${fundData.currency}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (isLowBalance)
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.yellow, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Số dư quỹ đang dưới mức cảnh báo (${CurrencyUtils.formatNumber(alertThreshold)} đ). Hãy kêu gọi mọi người đóng quỹ!",
                    style: const TextStyle(color: Colors.yellow, fontSize: 11, fontWeight: FontWeight.bold, height: 1.3),
                  ),
                ),
              ],
            )
          else
            Text(
              "Mức cảnh báo tối thiểu: ${CurrencyUtils.formatNumber(alertThreshold)} đ",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTreasurerCard(FundResponse fundData, bool canChangeTreasurer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: fundData.treasurer.avatarUrl != null
                ? NetworkImage(fundData.treasurer.avatarUrl!)
                : null,
            child: fundData.treasurer.avatarUrl == null
                ? Text(fundData.treasurer.name?.substring(0, 1).toUpperCase() ?? "T")
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "THỦ QUỸ",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fundData.treasurer.name ?? "Không tên",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                if (fundData.treasurer.accountNo != null && fundData.treasurer.accountNo!.isNotEmpty)
                  Text(
                    "STK: ${fundData.treasurer.accountNo} (${fundData.treasurer.bankId ?? ''})",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  )
                else
                  Text(
                    "Chưa cập nhật tài khoản ngân hàng",
                    style: TextStyle(color: Colors.grey[400], fontSize: 12, fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
          if (canChangeTreasurer)
            IconButton(
              icon: Icon(Icons.settings_outlined, color: AppColors.primary),
              onPressed: () => _showChangeTreasurerSheet(fundData),
            ),
        ],
      ),
    );
  }

  void _showChangeTreasurerSheet(FundResponse fundData) {
    final members = widget.mainController.trip.value?.members ?? [];
    int selectedNewTreasurerId = fundData.treasurer.id;

    Get.bottomSheet(
      StatefulBuilder(builder: (context, setSheetState) {
        return Container(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Thay đổi Thủ quỹ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Lưu ý: Chỉ chủ nhóm mới được thay đổi thủ quỹ của chuyến đi.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              
              // Chọn thủ quỹ mới
              const Text("Chọn Thủ quỹ mới:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedNewTreasurerId,
                    isExpanded: true,
                    items: members.map((member) {
                      return DropdownMenuItem<int>(
                        value: member.user.id,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundImage: member.user.avatarUrl != null
                                  ? NetworkImage(member.user.avatarUrl!)
                                  : null,
                              child: member.user.avatarUrl == null
                                  ? Text(member.user.name?.substring(0, 1).toUpperCase() ?? "U")
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Text(member.user.name ?? "Không tên"),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setSheetState(() {
                          selectedNewTreasurerId = val;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: Obx(() => ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: fundController.isActionLoading.value
                      ? null
                      : () async {
                          if (fundController.isActionLoading.value) return;
                          fundController.isActionLoading.value = true;
                          final ok = await fundController.updateTreasurer(selectedNewTreasurerId);
                          if (ok) {
                            Navigator.of(context).pop();
                          }
                        },
                  child: fundController.isActionLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "XÁC NHẬN THAY ĐỔI",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        ),
                )),
              ),
            ],
          ),
        );
      }),
      isScrollControlled: true,
    );
  }

  void _showCreateRequiredContributionSheet(FundResponse fundData) {
    final members = widget.mainController.trip.value?.members ?? [];
    Get.bottomSheet(
      RequiredContributionSheet(
        fundData: fundData,
        members: members,
        fundController: fundController,
      ),
      isScrollControlled: true,
    );
  }

  void _showConfirmMultipleContributionsDialog(GroupedContribution item) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Xác nhận nộp quỹ", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          "Bạn có chắc chắn muốn xác nhận thành viên ${item.contributor.name} đã đóng số tiền ${CurrencyUtils.formatNumber(item.totalAmount)} đ hay chưa (bao gồm ${item.contributionIds.length} đợt nộp quỹ)?\nKhi xác nhận, số dư quỹ sẽ được cộng và công nợ nộp quỹ sẽ được xoá bỏ.",
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("HỦY", style: TextStyle(color: Colors.grey)),
          ),
          Obx(() => ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: fundController.isActionLoading.value
                ? null
                : () async {
                    if (fundController.isActionLoading.value) return;
                    fundController.isActionLoading.value = true;
                    FocusScope.of(context).unfocus();
                    final ok = await fundController.confirmMultipleContributions(item.contributionIds);
                    if (ok) {
                      Navigator.of(context).pop();
                    }
                  },
            child: fundController.isActionLoading.value
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("XÁC NHẬN"),
          )),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: DONATE & LỊCH SỬ ĐÓNG GÓP (TIMELINE)
  // ==========================================
  Widget _buildDonateTab(FundResponse fundData) {
    final list = fundController.contributions.where((c) => c.type == "VOLUNTARY").toList();

    return RefreshIndicator(
      onRefresh: () async {
        await fundController.fetchContributions();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ kêu gọi Donate màu Cam gradient ấm áp
            _buildCallToDonateCard(),
            const SizedBox(height: 16),

            // Card chứa thông điệp ý nghĩa (phong cách giống màn hình giờ mở cửa / giá vé)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.volunteer_activism, color: AppColors.primary, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Thông điệp ý nghĩa",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "* 1 Việt Nam Đồng hơn không đồng nào",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text("Lịch sử đóng góp quỹ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            if (list.isEmpty)
              const EmptyState(
                text: "Chưa có lịch sử đóng góp quỹ nào.",
                imageHeight: 120.0,
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final item = list[index];
                  final isDonate = item.type == "VOLUNTARY";
                  final isConfirmed = item.isConfirmed;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        // Cột chứa Icon trạng thái / loại đóng góp
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDonate
                                ? Colors.orange[50]
                                : (isConfirmed ? Colors.green[50] : Colors.red[50]),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isDonate ? Icons.volunteer_activism : Icons.payments_outlined,
                            color: isDonate
                                ? Colors.orange[800]
                                : (isConfirmed ? Colors.green[800] : Colors.red[800]),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Thông tin đóng góp
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.contributor.name ?? "Không tên",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDonate ? Colors.orange[100] : Colors.blue[50],
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
                              Text(
                                item.notes ?? "",
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(item.contributionDate),
                                style: TextStyle(color: Colors.grey[400], fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Số tiền & Trạng thái duyệt
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "+${CurrencyUtils.formatNumber(item.amount)} đ",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: isConfirmed ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isConfirmed ? Colors.green[50] : Colors.orange[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isConfirmed ? "Đã xác nhận" : "Chờ duyệt",
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: isConfirmed ? Colors.green[800] : Colors.orange[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallToDonateCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[400]!, Colors.orange[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Đóng góp tự nguyện (Donate)",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "Bạn muốn tài trợ, tặng thêm hoặc đóng góp thêm cho quỹ chung của cả nhóm? Mọi đóng góp tự nguyện sẽ trực tiếp tăng số dư quỹ mà không tạo nợ cho ai khác.",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, height: 1.3),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange[800],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.volunteer_activism),
            label: const Text("Gửi Đóng Góp", style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: _showCreateVoluntaryContributionSheet,
          ),
        ],
      ),
    );
  }

  void _showCreateVoluntaryContributionSheet() {
    Get.bottomSheet(
      VoluntaryContributionSheet(
        fundController: fundController,
      ),
      isScrollControlled: true,
    );
  }

  // ==========================================
  // TAB 3: THỐNG KÊ (STATS TAB TÁI SỬ DỤNG)
  // ==========================================
  Widget _buildStatsTab() {
    final String tag = widget.mainController.tripId.toString();
    
    // Tìm TripExpenseController. Nếu chưa có, chúng ta khởi tạo nó.
    TripExpenseController expenseController;
    if (Get.isRegistered<TripExpenseController>(tag: tag)) {
      expenseController = Get.find<TripExpenseController>(tag: tag);
    } else {
      expenseController = Get.put(TripExpenseController(widget.mainController.tripId), tag: tag);
    }

    return Obx(() {
      if (expenseController.categoryStats.isEmpty && expenseController.expenses.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              "Chưa có dữ liệu chi tiêu để thống kê.\nHãy thêm chi phí trước nhé!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.4),
            ),
          ),
        );
      }

      double totalSpent = expenseController.categoryStats.fold(0, (sum, item) => sum + item.totalAmount);
      double? budget = widget.mainController.trip.value?.totalBudget;

      double percent = 0.0;
      Color progressColor = AppColors.primary;

      if (budget != null && budget > 0) {
        percent = totalSpent / budget;
        if (percent > 1.0) {
          progressColor = Colors.red;
        } else if (percent > 0.8) {
          progressColor = Colors.orange;
        }
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Tổng chi tiêu
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TỔNG CHI TIÊU CHUYẾN ĐI", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  Text(
                    "${CurrencyUtils.formatNumber(totalSpent)} đ",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: progressColor == Colors.red ? Colors.red : Colors.black87)
                  ),
                  const SizedBox(height: 16),

                  if (budget != null && budget > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${(percent * 100).toStringAsFixed(1)}% ngân sách",
                          style: TextStyle(color: progressColor, fontWeight: FontWeight.bold, fontSize: 13)
                        ),
                        Text(
                          "Giới hạn: ${CurrencyUtils.formatNumber(budget)} đ",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: percent > 1.0 ? 1.0 : percent,
                        backgroundColor: Colors.grey.shade200,
                        color: progressColor,
                        minHeight: 8,
                      ),
                    ),
                    if (percent > 1.0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text("⚠️ Bạn đã chi tiêu lố ngân sách ${CurrencyUtils.formatNumber(totalSpent - budget)} đ", style: const TextStyle(color: Colors.red, fontSize: 12, fontStyle: FontStyle.italic)),
                      )
                  ] else ...[
                    Text("💡 Thêm ngân sách trong phần Sửa chuyến đi để theo dõi tốt hơn.", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontStyle: FontStyle.italic)),
                  ]
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text("Phân bổ chi tiêu", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            if (expenseController.categoryStats.isNotEmpty) ...[
              AspectRatio(
                aspectRatio: 1.3,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 70,
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                                touchedIndex = -1;
                                return;
                              }
                              touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        sections: expenseController.categoryStats.asMap().entries.map((entry) {
                          final isTouched = entry.key == touchedIndex;
                          final data = entry.value;
                          final List<Color> colors = [Colors.orange, Colors.blue, AppColors.primary, Colors.purple, Colors.red, Colors.teal];
                          final double radius = isTouched ? 55.0 : 45.0;
                          final double fontSize = isTouched ? 15.0 : 11.0;

                          return PieChartSectionData(
                            color: colors[entry.key % colors.length],
                            value: data.totalAmount,
                            title: "${(data.totalAmount / totalSpent * 100).toStringAsFixed(0)}%",
                            radius: radius,
                            titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white),
                            badgeWidget: isTouched 
                                ? _Badge(data.categoryIcon, size: 42, borderColor: colors[entry.key % colors.length], text: data.categoryName) 
                                : _Badge(data.categoryIcon, size: 32, borderColor: colors[entry.key % colors.length]),
                            badgePositionPercentageOffset: 1.1,
                          );
                        }).toList(),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("TỔNG CỘNG", style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(CurrencyUtils.formatNumber(totalSpent), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                        const Text("VNĐ", style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: expenseController.categoryStats.length,
                itemBuilder: (context, index) {
                  final stat = expenseController.categoryStats[index];
                  final List<Color> colors = [Colors.orange, Colors.blue, AppColors.primary, Colors.purple, Colors.red, Colors.teal];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        expenseController.searchKeyword.value = "";
                        expenseController.filterPayerId.value = null;
                        expenseController.applyExpenseFilter(catId: stat.categoryId);
                        widget.mainController.currentTab.value = 0; // Chuyển về Tab Chi tiêu
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Text(stat.categoryIcon, style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(stat.categoryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 6),
                                  LinearProgressIndicator(
                                    value: totalSpent > 0 ? (stat.totalAmount / totalSpent) : 0,
                                    backgroundColor: Colors.grey[100],
                                    color: colors[index % colors.length],
                                    minHeight: 5,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "${CurrencyUtils.formatNumber(stat.totalAmount)} đ",
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black87)
                                ),
                                const SizedBox(height: 4),
                                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ]
          ],
        ),
      );
    });
  }
}

class _Badge extends StatelessWidget {
  final String icon;
  final double size;
  final Color borderColor;
  final String? text;

  const _Badge(this.icon, {required this.size, required this.borderColor, this.text});

  @override
  Widget build(BuildContext context) {
    Widget badge = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size, height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      padding: EdgeInsets.all(size * 0.15),
      child: Center(child: Text(icon, style: TextStyle(fontSize: size * 0.5))),
    );

    if (text != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
            child: Text(
              text!.length > 10 ? "${text!.substring(0, 8)}..." : text!,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
            ),
          ),
          const SizedBox(height: 4),
          badge,
        ],
      );
    }
    return badge;
  }
}
