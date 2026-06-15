import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/personal_statement_response.dart';
import '../../data/models/settlement_response.dart';
import '../../data/repositories/settlement_repository.dart';
import '../../utils/currency_util.dart';

class BalanceDetailBottomSheet extends StatelessWidget {
  final int tripId;
  final SettlementResponse settlement;
  final VoidCallback onPayPressed;

  const BalanceDetailBottomSheet({
    super.key,
    required this.tripId,
    required this.settlement,
    required this.onPayPressed,
  });

  Future<PersonalStatementResponse?> _fetchStatement() async {
    final repo = SettlementRepository();
    final res = await repo.getPersonalStatement(tripId, settlement.fromUserId!);
    if (res.success) return res.data;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text("Chi tiết số dư", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Header summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(backgroundColor: Colors.red[100], child: Text((settlement.fromUserName ?? "A").trim()[0].toUpperCase(), style: const TextStyle(color: Colors.red))),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.arrow_forward, color: Colors.grey),
                    ),
                    CircleAvatar(backgroundColor: Colors.green[100], child: Text((settlement.toUserName ?? "B").trim()[0].toUpperCase(), style: const TextStyle(color: Colors.green))),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "${settlement.fromUserName} nợ ${settlement.toUserName}",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                "${CurrencyUtils.formatNumber(settlement.amount)} đ",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
              ),
              const SizedBox(height: 24),
              
              // Statement Body
              Expanded(
                child: FutureBuilder<PersonalStatementResponse?>(
                  future: _fetchStatement(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                      return const Center(child: Text("Không thể tải dữ liệu sao kê"));
                    }
                    
                    final data = snapshot.data!;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              border: Border.all(color: Colors.grey[200]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                InkWell(
                                  onTap: () => _showPaidDetail(context, data),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Row(
                                          children: [
                                            Text("Tiền bạn đã trả hộ:", style: TextStyle(color: Colors.grey)),
                                            SizedBox(width: 4),
                                            Icon(Icons.info_outline, size: 14, color: Colors.grey),
                                          ],
                                        ),
                                        Text("+ ${CurrencyUtils.formatNumber(data.totalPaid)} đ", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _showActualCostDetail(context, data),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Row(
                                          children: [
                                            Text("Chi phí thực tế của bạn:", style: TextStyle(color: Colors.grey)),
                                            SizedBox(width: 4),
                                            Icon(Icons.info_outline, size: 14, color: Colors.grey),
                                          ],
                                        ),
                                        Text("- ${CurrencyUtils.formatNumber(data.totalSpent)} đ", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Divider(),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Số dư cuối cùng:", style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text(
                                      data.netBalance < 0 
                                        ? "Âm ${CurrencyUtils.formatNumber(data.netBalance.abs())} đ" 
                                        : "+ ${CurrencyUtils.formatNumber(data.netBalance)} đ",
                                      style: TextStyle(color: data.netBalance < 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    data.netBalance.abs() > settlement.amount
                                      ? "Bạn đang âm tổng cộng ${CurrencyUtils.formatNumber(data.netBalance.abs())} đ. Hệ thống phân bổ bạn trả trước ${CurrencyUtils.formatNumber(settlement.amount)} đ cho ${settlement.toUserName ?? 'người nhận'} để cấn trừ nợ chéo. Hãy thanh toán các khoản còn lại để tất toán nhé!"
                                      : "Bạn đang âm tổng cộng ${CurrencyUtils.formatNumber(data.netBalance.abs())} đ. Hệ thống phân bổ bạn chuyển khoản cho ${settlement.toUserName ?? 'người nhận'} để cấn trừ nợ chéo. Thanh toán khoản này sẽ giúp tất toán toàn bộ số dư của bạn!",
                                    style: const TextStyle(color: Colors.blue, height: 1.3, fontSize: 12, fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              // Footer
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back(); // Đóng BottomSheet này
                      onPayPressed(); // Gọi callback để mở Dialog thanh toán
                    },
                    icon: const Icon(Icons.qr_code),
                    label: const Text("THANH TOÁN NGAY"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActualCostDetail(BuildContext context, PersonalStatementResponse data) {
    final List<SpentItem> spentItems = [];

    // Lọc các khoản chi tiêu mà thành viên tham gia
    for (final expense in data.involvedExpenses) {
      final userSplit = expense.splits?.firstWhereOrNull((s) => s.userId == data.userId);
      if (userSplit != null && userSplit.amount > 0) {
        spentItems.add(SpentItem(
          date: expense.expenseDate ?? "",
          title: expense.description.isNotEmpty ? expense.description : (expense.categoryName ?? "Chi phí"),
          subtitle: "Chia chi phí",
          icon: expense.categoryIcon ?? "📦",
          amount: userSplit.amount,
        ));
      }
    }

    // Các giao dịch nhận tiền (làm tăng totalSpent trong công thức quyết toán)
    for (final payment in data.involvedPayments) {
      if (payment.toUserId == data.userId) {
        spentItems.add(SpentItem(
          date: payment.createdAt,
          title: "Nhận tiền từ ${payment.fromUserName}",
          subtitle: "Nhận thanh toán nợ",
          icon: "💰",
          amount: payment.amount,
        ));
      }
    }

    spentItems.sort((a, b) => b.date.compareTo(a.date));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Chi tiết chi phí thực tế",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                if (spentItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                      child: Text(
                        "Không có chi phí nào",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: spentItems.length,
                      itemBuilder: (context, index) {
                        final item = spentItems[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              item.icon,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          title: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "${item.date.split('T').first} • ${item.subtitle}",
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          trailing: Text(
                            "- ${CurrencyUtils.formatNumber(item.amount)} đ",
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Tổng cộng chi phí thực tế:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      "- ${CurrencyUtils.formatNumber(data.totalSpent)} đ",
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPaidDetail(BuildContext context, PersonalStatementResponse data) {
    final List<PaidItem> paidItems = [];

    // Lọc các khoản chi do thành viên đứng ra trả
    for (final expense in data.involvedExpenses) {
      if (expense.payer?.id == data.userId) {
        paidItems.add(PaidItem(
          date: expense.expenseDate ?? "",
          title: expense.description.isNotEmpty ? expense.description : (expense.categoryName ?? "Chi phí"),
          subtitle: "Thanh toán hóa đơn",
          icon: expense.categoryIcon ?? "📦",
          amount: expense.totalAmount,
        ));
      }
    }

    // Các khoản chuyển tiền trả nợ hoặc nộp quỹ do thành viên thực hiện
    for (final payment in data.involvedPayments) {
      if (payment.fromUserId == data.userId) {
        paidItems.add(PaidItem(
          date: payment.createdAt,
          title: "Chuyển tiền cho ${payment.toUserName}",
          subtitle: payment.status == "APPROVED" ? "Đã xác nhận" : "Đang chờ duyệt",
          icon: "💸",
          amount: payment.amount,
        ));
      }
    }

    paidItems.sort((a, b) => b.date.compareTo(a.date));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Chi tiết tiền bạn đã trả hộ",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                if (paidItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                      child: Text(
                        "Chưa thanh toán khoản nào",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: paidItems.length,
                      itemBuilder: (context, index) {
                        final item = paidItems[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              item.icon,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          title: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "${item.date.split('T').first} • ${item.subtitle}",
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          trailing: Text(
                            "+ ${CurrencyUtils.formatNumber(item.amount)} đ",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Tổng cộng tiền đã trả hộ:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      "+ ${CurrencyUtils.formatNumber(data.totalPaid)} đ",
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SpentItem {
  final String date;
  final String title;
  final String subtitle;
  final String icon;
  final double amount;

  SpentItem({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.amount,
  });
}

class PaidItem {
  final String date;
  final String title;
  final String subtitle;
  final String icon;
  final double amount;

  PaidItem({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.amount,
  });
}
