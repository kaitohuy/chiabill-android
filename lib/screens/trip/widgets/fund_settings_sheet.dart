import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/currency_util.dart';
import '../../../../controllers/group_fund_controller.dart';
import '../../../../data/models/trip_member_response.dart';
import '../../../../data/models/user_response.dart';

class FundSettingsSheet extends StatefulWidget {
  final List<TripMemberResponse> members;
  final UserResponse? initialTreasurer;
  final GroupFundController fundController;

  const FundSettingsSheet({
    super.key,
    required this.members,
    this.initialTreasurer,
    required this.fundController,
  });

  @override
  State<FundSettingsSheet> createState() => _FundSettingsSheetState();
}

class _FundSettingsSheetState extends State<FundSettingsSheet> {
  UserResponse? selectedTreasurer;
  late TextEditingController alertController;

  @override
  void initState() {
    super.initState();
    selectedTreasurer = widget.initialTreasurer;
    alertController = TextEditingController(text: "200,000");
    widget.fundController.isActionLoading.value = false;
  }

  @override
  void dispose() {
    alertController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: 24 + MediaQuery.of(context).padding.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "activate_group_fund".tr,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                
                // Chọn thủ quỹ
                Text("select_treasurer".tr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
                      value: selectedTreasurer?.id,
                      isExpanded: true,
                      items: widget.members.map((member) {
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
                              Text(member.user.name ?? "unnamed".tr),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        FocusScope.of(context).unfocus();
                        if (val != null) {
                          setState(() {
                            selectedTreasurer = widget.members.firstWhere((m) => m.user.id == val).user;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
  
                // Ngưỡng cảnh báo
                Text(
                  "min_balance_threshold_label".tr,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: alertController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    hintText: "min_balance_threshold_hint".tr,
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    suffixText: "currency_symbol".tr,
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
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
                    onPressed: widget.fundController.isActionLoading.value
                        ? null
                        : () async {
                            if (widget.fundController.isActionLoading.value) return;
                            widget.fundController.isActionLoading.value = true;
                            FocusScope.of(context).unfocus();
                            final double? alertVal = double.tryParse(alertController.text.replaceAll(',', ''));
                            final ok = await widget.fundController.activateFund(
                              alertVal,
                              selectedTreasurer?.id,
                            );
                            if (ok) {
                              Navigator.pop(context);
                            }
                          },
                    child: widget.fundController.isActionLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "activate_now_caps".tr,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                          ),
                  )),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
