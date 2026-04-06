import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/trip_detail_controller.dart';
import '../../../utils/currency_util.dart';

class StatsTab extends StatelessWidget {
  final TripDetailController controller;
  const StatsTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.categoryStats.isEmpty && controller.expenses.isEmpty) {
        return const Center(
            child: Text(
                "Chưa có dữ liệu chi tiêu để thống kê.\nHãy thêm chi phí trước nhé!",
                textAlign: TextAlign.center
            )
        );
      }

      // Tính toán tổng đã chi và ngân sách
      double totalSpent = controller.categoryStats.fold(0, (sum, item) => sum + item.totalAmount);
      double? budget = controller.trip.value?.totalBudget;

      // Tính toán % để vẽ thanh màu
      double percent = 0.0;
      Color progressColor = Colors.green; // Mặc định xanh an toàn

      if (budget != null && budget > 0) {
        percent = totalSpent / budget;
        if (percent > 1.0) {
          progressColor = Colors.red; // Lố ngân sách -> Đỏ
        } else if (percent > 0.8) {
          progressColor = Colors.orange; // Sắp hết -> Cam
        }
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // THẺ THỐNG KÊ NGÂN SÁCH (BUDGET CARD)
            // ==========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TỔNG CHI TIÊU", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  Text(
                      "${CurrencyUtils.formatNumber(totalSpent)} đ",
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: progressColor == Colors.red ? Colors.red : Colors.black87)
                  ),
                  const SizedBox(height: 20),

                  // Chỉ vẽ thanh tiến trình nếu có set Ngân sách
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
                        value: percent > 1.0 ? 1.0 : percent, // Nếu lố 100% thì full cọc
                        backgroundColor: Colors.grey.shade200,
                        color: progressColor,
                        minHeight: 10,
                      ),
                    ),
                    if (percent > 1.0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text("⚠️ Bạn đã chi tiêu lố ngân sách ${CurrencyUtils.formatNumber(totalSpent - budget)} đ", style: const TextStyle(color: Colors.red, fontSize: 12, fontStyle: FontStyle.italic)),
                      )
                  ] else ...[
                    // Nếu không có ngân sách
                    Text("💡 Thêm ngân sách trong phần Sửa chuyến đi để theo dõi tốt hơn.", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontStyle: FontStyle.italic)),
                  ]
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Text("Phân bổ chi tiêu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // ==========================================
            // BIỂU ĐỒ TRÒN & DANH SÁCH DANH MỤC
            // ==========================================
            if (controller.categoryStats.isNotEmpty) ...[
              SizedBox(
                height: 180,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 45,
                    sections: controller.categoryStats.asMap().entries.map((entry) {
                      final data = entry.value;
                      final List<Color> colors = [Colors.orange, Colors.blue, Colors.green, Colors.purple, Colors.red, Colors.teal];
                      return PieChartSectionData(
                        color: colors[entry.key % colors.length],
                        value: data.totalAmount,
                        title: "${(data.totalAmount / totalSpent * 100).toStringAsFixed(0)}%",
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.categoryStats.length,
                itemBuilder: (context, index) {
                  final stat = controller.categoryStats[index];
                  final List<Color> colors = [Colors.orange, Colors.blue, Colors.green, Colors.purple, Colors.red, Colors.teal];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Text(stat.categoryIcon, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(stat.categoryName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                  value: totalSpent > 0 ? (stat.totalAmount / totalSpent) : 0,
                                  backgroundColor: Colors.grey[100],
                                  color: colors[index % colors.length],
                                  minHeight: 6,
                                  borderRadius: BorderRadius.circular(10)
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                            "${CurrencyUtils.formatNumber(stat.totalAmount)} đ",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)
                        ),
                      ],
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