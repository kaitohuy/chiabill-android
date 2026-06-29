import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../theme/app_colors.dart';
import '../../../../controllers/trip_detail_controller.dart';

class ExportReportSheet extends StatefulWidget {
  final TripDetailController controller;
  const ExportReportSheet({super.key, required this.controller});

  @override
  State<ExportReportSheet> createState() => _ExportReportSheetState();
}

class _ExportReportSheetState extends State<ExportReportSheet> {
  bool includeDetails = true;
  bool includeSettlement = true;
  String? selectedFormat; // null = chưa chọn format

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 8,
        left: 24,
        right: 24,
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),

          Text("export_report".tr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("select_format_content_desc".tr, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 20),

          // ── Chọn định dạng file ──
          Text("format".tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildFormatChip(
                  icon: Icons.table_view_outlined,
                  label: "Excel",
                  sublabel: ".xlsx",
                  isSelected: selectedFormat == 'excel',
                  onTap: () => setState(() => selectedFormat = 'excel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormatChip(
                  icon: Icons.picture_as_pdf_outlined,
                  label: "PDF",
                  sublabel: ".pdf",
                  isSelected: selectedFormat == 'pdf',
                  onTap: () => setState(() => selectedFormat = 'pdf'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Chọn nội dung muốn export ──
          Text("export_content".tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.5)),
          const SizedBox(height: 8),

          _buildExportOptionTile(
            icon: Icons.list_alt_outlined,
            title: "overview_info".tr,
            subtitle: "overview_info_desc".tr,
            value: true, // Luôn bật, không thể tắt
            enabled: false,
            onChanged: null,
          ),
          _buildExportOptionTile(
            icon: Icons.receipt_long_outlined,
            title: "detailed_expenses".tr,
            subtitle: "detailed_expenses_desc".tr,
            value: includeDetails,
            enabled: true,
            onChanged: (val) => setState(() => includeDetails = val ?? false),
          ),
          _buildExportOptionTile(
            icon: Icons.account_balance_wallet_outlined,
            title: "settlement_sheet".tr,
            subtitle: "settlement_sheet_desc".tr,
            value: includeSettlement,
            enabled: true,
            onChanged: (val) => setState(() => includeSettlement = val ?? false),
          ),

          const SizedBox(height: 20),

          // ── Nút Xuất ──
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedFormat == null ? Colors.grey[300] : AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: selectedFormat == null ? 0 : 2,
              ),
              onPressed: selectedFormat == null
                  ? null
                  : () {
                      Get.back();
                      widget.controller.exportTrip(
                        selectedFormat!,
                        includeDetails: includeDetails,
                        includeSettlement: includeSettlement,
                      );
                    },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selectedFormat == 'pdf' ? Icons.picture_as_pdf_outlined : Icons.file_download_outlined,
                    color: selectedFormat == null ? Colors.grey : Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    selectedFormat == null ? "select_format_first".tr : "export_caps".trParams({"format": selectedFormat!.toUpperCase()}),
                    style: TextStyle(
                      color: selectedFormat == null ? Colors.grey : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Chip chọn định dạng file (Excel / PDF)
  Widget _buildFormatChip({
    required IconData icon,
    required String label,
    required String sublabel,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[200]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppColors.primary : Colors.black87, fontSize: 14)),
                Text(sublabel, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ],
            ),
            if (isSelected) ...[
              const Spacer(),
              Icon(Icons.check_circle, color: AppColors.primary, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  // Tile option tick chọn nội dung export
  Widget _buildExportOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required ValueChanged<bool?>? onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: AppColors.primary,
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Row(
          children: [
            Icon(icon, size: 18, color: enabled ? AppColors.primary : Colors.grey[400]),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: enabled ? Colors.black87 : Colors.grey)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 26),
          child: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        ),
      ),
    );
  }
}
