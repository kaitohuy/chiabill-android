import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/create_payment_controller.dart';
import '../../data/models/settlement_response.dart';
import '../../utils/currency_util.dart';

class CreatePaymentBottomSheet extends StatelessWidget {
  final int tripId;
  final SettlementResponse settlement;

  const CreatePaymentBottomSheet({super.key, required this.tripId, required this.settlement});

  @override
  Widget build(BuildContext context) {
    // Dùng tag để tránh trùng lặp nếu mở nhiều BottomSheet
    final tag = 'payment_${settlement.toUserId}';
    final controller = Get.put(CreatePaymentController(tripId, settlement), tag: tag);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85, // Chiếm 85% màn hình
      padding: EdgeInsets.only(
        left: 20, 
        right: 20, 
        top: 24, 
        bottom: 24 + bottomInset + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("pay_to_member".trParams({'name': settlement.toUserName ?? ''}), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Get.back()),
            ],
          ),
          const Divider(),

          // THỐNG KÊ NỢ
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat("original_debt".tr, settlement.originalAmount, Colors.grey[700]!),
                _buildStat("paid".tr, settlement.paidAmount, Colors.green),
                _buildStat("remaining".tr, settlement.amount, Colors.redAccent),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // NHẬP SỐ TIỀN
          Text("payment_amount_this_time".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: controller.amountController, // Tên controller của bạn
            keyboardType: TextInputType.number, // Ép mở bàn phím số

            // THÊM ĐOẠN NÀY ĐỂ FORMAT REALTIME:
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // Chặn nhập chữ
              CurrencyInputFormatter(), // Tự động chèn dấu phẩy
            ],

            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.payments, color: Colors.green),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixText: "VNĐ",
            ),
          ),

          const SizedBox(height: 24),

          // UPLOAD ẢNH
          Text("transfer_proof_image".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() {
              File? image = controller.selectedImage.value;
              return GestureDetector(
                onTap: controller.pickImage,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: image == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text("click_to_upload_image".tr, style: const TextStyle(color: Colors.grey)),
                    ],
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(image, fit: BoxFit.contain), // Dùng contain để hiển thị nguyên ảnh bill dài
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // NÚT XÁC NHẬN
          Obx(() => SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: controller.isLoading.value ? null : () => controller.submitPayment(),
              child: controller.isLoading.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text("send_approval_request_caps".tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStat(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text("${amount.toInt()}đ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}