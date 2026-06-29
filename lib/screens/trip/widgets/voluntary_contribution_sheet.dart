import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/toast_util.dart';
import '../../../../utils/currency_util.dart';
import '../../../../controllers/group_fund_controller.dart';

class VoluntaryContributionSheet extends StatefulWidget {
  final GroupFundController fundController;

  const VoluntaryContributionSheet({
    super.key,
    required this.fundController,
  });

  @override
  State<VoluntaryContributionSheet> createState() => _VoluntaryContributionSheetState();
}

class _VoluntaryContributionSheetState extends State<VoluntaryContributionSheet> {
  late TextEditingController amountController;
  late TextEditingController notesController;

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController();
    notesController = TextEditingController(text: "fund_voluntary_default_notes".tr);
    widget.fundController.isActionLoading.value = false;
  }

  @override
  void dispose() {
    amountController.dispose();
    notesController.dispose();
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
                  "fund_voluntary_title".tr,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
  
                Text("fund_voluntary_amount_label".tr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    hintText: "fund_voluntary_amount_hint".tr,
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
                const SizedBox(height: 16),
  
                Text("notes_label".tr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    hintText: "fund_voluntary_notes_hint".tr,
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
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
                            final double? amount = double.tryParse(amountController.text.replaceAll(',', ''));
                            if (amount == null || amount <= 0) {
                              ToastUtil.showError("failed".tr, "invalid_contribution_amount".tr);
                              widget.fundController.isActionLoading.value = false;
                              return;
                            }
                            
                            final ok = await widget.fundController.createVoluntaryContribution(
                              amount: amount,
                              notes: notesController.text,
                            );
                             if (ok) {
                               Navigator.pop(context);
                             }
                          },
                    child: widget.fundController.isActionLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "confirm_contribution_caps".tr,
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
