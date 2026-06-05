import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/toast_util.dart';
import '../../../../utils/currency_util.dart';
import '../../../../controllers/group_fund_controller.dart';
import '../../../../data/models/trip_member_response.dart';
import '../../../../data/models/fund_response.dart';

class RequiredContributionSheet extends StatefulWidget {
  final FundResponse fundData;
  final List<TripMemberResponse> members;
  final GroupFundController fundController;

  const RequiredContributionSheet({
    super.key,
    required this.fundData,
    required this.members,
    required this.fundController,
  });

  @override
  State<RequiredContributionSheet> createState() => _RequiredContributionSheetState();
}

class _RequiredContributionSheetState extends State<RequiredContributionSheet> {
  late List<int> selectedUserIds;
  late TextEditingController amountController;
  late TextEditingController notesController;

  @override
  void initState() {
    super.initState();
    // Mặc định chọn tất cả mọi người trừ thủ quỹ. Nếu trip chỉ có 1 người (chính là thủ quỹ) thì chọn luôn thủ quỹ.
    selectedUserIds = widget.members.length <= 1
        ? widget.members.map((m) => m.user.id).toList()
        : widget.members
            .where((m) => m.user.id != widget.fundData.treasurer.id)
            .map((m) => m.user.id)
            .toList();

    amountController = TextEditingController();
    notesController = TextEditingController(text: "Nộp quỹ");
  }

  @override
  void dispose() {
    amountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Yêu cầu nộp quỹ bắt buộc",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              const Text("Số tiền mỗi người cần đóng:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                ],
                decoration: InputDecoration(
                  hintText: "VD: 100,000",
                  suffixText: "đ",
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text("Nội dung / Ghi chú:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  hintText: "VD: Đợt thu đầu chuyến đi",
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Ai phải đóng quỹ:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        final nonTreasurerIds = widget.members
                            .where((m) => m.user.id != widget.fundData.treasurer.id)
                            .map((m) => m.user.id)
                            .toList();

                        if (selectedUserIds.length == nonTreasurerIds.length) {
                          selectedUserIds.clear();
                        } else {
                          selectedUserIds.clear();
                          selectedUserIds.addAll(nonTreasurerIds);
                        }
                      });
                    },
                    child: Text(selectedUserIds.length == widget.members.where((m) => m.user.id != widget.fundData.treasurer.id).length
                        ? "Bỏ chọn tất cả"
                        : "Chọn tất cả"),
                  ),
                ],
              ),
              
              // Grid/List các thành viên để tích chọn
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.members.length,
                  itemBuilder: (context, index) {
                    final member = widget.members[index];
                    final isChecked = selectedUserIds.contains(member.user.id);
                    final isTreasurer = member.user.id == widget.fundData.treasurer.id;

                    if (isTreasurer) {
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 12,
                          backgroundImage: member.user.avatarUrl != null
                              ? NetworkImage(member.user.avatarUrl!)
                              : null,
                          child: member.user.avatarUrl == null
                              ? Text(member.user.name?.substring(0, 1).toUpperCase() ?? "U", style: const TextStyle(fontSize: 10))
                              : null,
                        ),
                        title: Row(
                          children: [
                            Expanded(child: Text(member.user.name ?? "Không tên")),
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text("Thủ quỹ", style: TextStyle(fontSize: 8, color: Colors.blue[800], fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        trailing: const Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: Text(
                            "Tự động tham gia",
                            style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }

                    return CheckboxListTile(
                      activeColor: AppColors.primary,
                      title: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundImage: member.user.avatarUrl != null
                                ? NetworkImage(member.user.avatarUrl!)
                                : null,
                            child: member.user.avatarUrl == null
                                ? Text(member.user.name?.substring(0, 1).toUpperCase() ?? "U", style: const TextStyle(fontSize: 10))
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(member.user.name ?? "Không tên")),
                        ],
                      ),
                      value: isChecked,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            if (!selectedUserIds.contains(member.user.id)) {
                              selectedUserIds.add(member.user.id);
                            }
                          } else {
                            selectedUserIds.remove(member.user.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Thủ quỹ (${widget.fundData.treasurer.name}) tự động tham gia đóng góp nên không cần tích chọn.",
                        style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
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
                  onPressed: widget.fundController.isActionLoading.value
                      ? null
                      : () async {
                          if (widget.fundController.isActionLoading.value) return;
                          widget.fundController.isActionLoading.value = true;
                          FocusScope.of(context).unfocus();
                          final double? amount = double.tryParse(amountController.text.replaceAll(',', ''));
                          if (amount == null || amount <= 0) {
                            ToastUtil.showError("Lỗi", "Vui lòng nhập số tiền đóng quỹ hợp lệ!");
                            widget.fundController.isActionLoading.value = false;
                            return;
                          }
                          if (selectedUserIds.isEmpty) {
                            ToastUtil.showError("Lỗi", "Vui lòng chọn ít nhất một người đóng quỹ!");
                            widget.fundController.isActionLoading.value = false;
                            return;
                          }
                          
                          final ok = await widget.fundController.createRequiredContribution(
                            amount: amount,
                            notes: notesController.text,
                            contributorIds: selectedUserIds,
                          );
                          if (ok) {
                            Navigator.of(context).pop();
                          }
                        },
                  child: widget.fundController.isActionLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "YÊU CẦU THU TIỀN",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        ),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
