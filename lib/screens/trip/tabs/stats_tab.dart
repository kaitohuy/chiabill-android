import 'package:chiabill/theme/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/trip_detail_controller.dart';
import '../../../controllers/trip_expense_controller.dart';
import '../../../utils/currency_util.dart';

class StatsTab extends StatefulWidget {
  final TripDetailController mainController;
  const StatsTab({super.key, required this.mainController});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TripExpenseController>(tag: widget.mainController.tripId.toString());
    return Obx(() {
      if (controller.categoryStats.isEmpty && controller.expenses.isEmpty) {
        return const Center(
            child: Text(
                "Chưa có dữ liệu chi tiêu để thống kê.\nHãy thêm chi phí trước nhé!",
                textAlign: TextAlign.center
            )
        );
      }

      double totalSpent = controller.categoryStats.fold(0, (sum, item) => sum + item.totalAmount);
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  if (budget != null && budget > 0) ...[
                    const SizedBox(height: 20),
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
                        minHeight: 10,
                      ),
                    ),
                    if (percent > 1.0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text("⚠️ Bạn đã chi tiêu lố ngân sách ${CurrencyUtils.formatNumber(totalSpent - budget)} đ", style: const TextStyle(color: Colors.red, fontSize: 12, fontStyle: FontStyle.italic)),
                      )
                  ]
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Text("Phân bổ chi tiêu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            if (controller.categoryStats.isNotEmpty) ...[
              AspectRatio(
                aspectRatio: 1.3,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 75,
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
                        sections: controller.categoryStats.asMap().entries.map((entry) {
                          final isTouched = entry.key == touchedIndex;
                          final data = entry.value;
                          final List<Color> colors = [Colors.orange, Colors.blue, AppColors.primary, Colors.purple, Colors.red, Colors.teal];
                          final double radius = isTouched ? 60.0 : 50.0;
                          final double fontSize = isTouched ? 16.0 : 12.0;

                          return PieChartSectionData(
                            color: colors[entry.key % colors.length],
                            value: data.totalAmount,
                            title: "${(data.totalAmount / totalSpent * 100).toStringAsFixed(0)}%",
                            radius: radius,
                            titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white),
                            badgeWidget: isTouched ? _Badge(data.categoryIcon, size: 45, borderColor: colors[entry.key % colors.length], text: data.categoryName) : _Badge(data.categoryIcon, size: 35, borderColor: colors[entry.key % colors.length]),
                            badgePositionPercentageOffset: 1.1,
                          );
                        }).toList(),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("TỔNG CỘNG", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(CurrencyUtils.formatNumber(totalSpent), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                        const Text("VNĐ", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.categoryStats.length,
                itemBuilder: (context, index) {
                  final stat = controller.categoryStats[index];
                  final List<Color> colors = [Colors.orange, Colors.blue, AppColors.primary, Colors.purple, Colors.red, Colors.teal];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        controller.searchKeyword.value = "";
                        controller.filterPayerId.value = null;
                        controller.applyExpenseFilter(catId: stat.categoryId);
                        widget.mainController.currentTab.value = 0;
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                    "${CurrencyUtils.formatNumber(stat.totalAmount)} đ",
                                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black87)
                                ),
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
            child: Text(text!, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          badge,
        ],
      );
    }
    return badge;
  }
}
