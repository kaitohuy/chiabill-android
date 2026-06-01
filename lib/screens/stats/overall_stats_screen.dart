import 'package:chiabill/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/overall_stats_controller.dart';
import '../../utils/currency_util.dart';
import '../../utils/trip_category_util.dart';
import '../../widgets/empty_state.dart';
import '../trip/trip_detail_screen.dart';

class OverallStatsScreen extends StatefulWidget {
  const OverallStatsScreen({super.key});

  @override
  State<OverallStatsScreen> createState() => _OverallStatsScreenState();
}

class _OverallStatsScreenState extends State<OverallStatsScreen> {
  final OverallStatsController controller = Get.find<OverallStatsController>();
  late ScrollController _monthScrollController;
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _monthScrollController = ScrollController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrent(jump: true);
    });
  }

  void _scrollToCurrent({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_monthScrollController.hasClients) return;
      double screenWidth = Get.width;
      double itemWidth = 100.0;
      
      int monthIndex = controller.selectedMonth.value; // 0 là Tất cả
      double offset = (monthIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
      if (offset < 0) offset = 0;
      if (offset > _monthScrollController.position.maxScrollExtent) {
        offset = _monthScrollController.position.maxScrollExtent;
      }
      if (jump) {
        _monthScrollController.jumpTo(offset);
      } else {
        _monthScrollController.animateTo(offset, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    });
  }

  @override
  void dispose() {
    _monthScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Obx(() => Text("Thống kê (${controller.selectedYear.value})", style: TextStyle(fontWeight: FontWeight.bold))),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // 0. Dashboard Tổng
          _buildDashboard(),
          const SizedBox(height: 10),

          // 1. Month Filter
          _buildMonthHeader(),

          // 2. Main Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                controller.fetchSummary();
                controller.fetchAllTimeStats();
                controller.fetchOverallStats();
              },
              color: AppColors.primary,
              child: Obx(() {
                if (controller.isLoading.value) {
                  return Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (controller.tripStats.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: Get.height * 0.2),
                      _buildEmptyState()
                    ]
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(20),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    _buildPieChart(),
                    const SizedBox(height: 30),
                    _buildStatList(),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Expanded(
            child: Obx(() => GestureDetector(
              onTap: () {
                if (controller.isAllTimeMode.value) {
                  controller.isAllTimeMode.value = false;
                  controller.fetchOverallStats();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: controller.isAllTimeMode.value ? Colors.grey[100] : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() => Text("Tổng (năm ${controller.selectedYear.value})", style: TextStyle(color: controller.isAllTimeMode.value ? Colors.grey : AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 8),
                  Obx(() => Text(
                    "${CurrencyUtils.formatNumber(controller.yearlyTotalExpense.value)} đ",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  )),
                ],
              ),
            ),
          )),
        ),
          const SizedBox(width: 15),
          Expanded(
            child: Obx(() => GestureDetector(
              onTap: () => controller.toggleAllTimeMode(),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: controller.isAllTimeMode.value ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Tổng tất cả", style: TextStyle(color: controller.isAllTimeMode.value ? AppColors.primary : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Obx(() => Text(
                    "${CurrencyUtils.formatNumber(controller.allTimeTotalExpense.value)} đ",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  )),
                ],
              ),
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Obx(() {
      if (controller.isAllTimeMode.value) {
        return const SizedBox.shrink();
      }
      return Container(
        height: 45,
        margin: const EdgeInsets.only(bottom: 10),
        child: ListView.builder(
        controller: _monthScrollController,
        scrollDirection: Axis.horizontal,
        itemExtent: 100.0,
        itemCount: 14, // 1 Tất cả + 12 tháng + 1 icon lịch
        itemBuilder: (context, index) {
          if (index == 1) {
            return GestureDetector(
              onTap: () => _showYearPicker(context),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBackgroundLight,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: AppColors.primaryLighter),
                ),
                child: Center(
                  child: FittedBox(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_month_outlined, color: AppColors.primaryDark, size: 18),
                        const SizedBox(width: 4),
                        Text("Đổi năm", style: TextStyle(color: AppColors.primaryDark, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          int month = index == 0 ? 0 : index - 1; // 0 là Tất cả, 1-12 là các tháng
          return Obx(() {
            bool isSelected = controller.selectedMonth.value == month;
            return GestureDetector(
              onTap: () {
                controller.onDateChanged(month, controller.selectedYear.value);
                _scrollToCurrent();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    month == 0 ? "Tất cả" : "Tháng $month",
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13
                    ),
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
    });
  }

  void _showYearPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Chọn năm"),
          content: SizedBox(
            width: 300,
            height: 300,
            child: Obx(() => YearPicker(
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
              selectedDate: DateTime(controller.selectedYear.value),
              onChanged: (DateTime dateTime) {
                controller.onDateChanged(controller.selectedMonth.value, dateTime.year);
                Navigator.pop(context);
              },
            )),
          ),
        );
      },
    );
  }

  Widget _buildPieChart() {
    return Column(
      children: [
        // Nút toggle gom nhóm
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text("Gom theo danh mục", style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
            Obx(() => Switch(
              value: controller.isGroupByCategory.value,
              onChanged: (val) {
                controller.isGroupByCategory.value = val;
              },
              activeThumbColor: AppColors.primary,
            )),
          ],
        ),
        Stack(
          alignment: Alignment.center,
          children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
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
              sections: _generatePieSections(),
              sectionsSpace: 3,
              centerSpaceRadius: 60,
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("TỔNG CHI", style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
            Obx(() => Text(
              CurrencyUtils.formatNumber(controller.monthlyTotalExpense.value),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            )),
            const Text("đ", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
    )],
        ),
      ],
    );
  }

  List<PieChartSectionData> _generatePieSections() {
    double total = controller.monthlyTotalExpense.value;
    if (total == 0) return [];

    List<PieChartSectionData> sections = [];
    int maxItems = 4; // Show top 3, rest is 'Khác'
    
    final stats = controller.displayStats;

    if (stats.length <= maxItems) {
      for (int i = 0; i < stats.length; i++) {
        final stat = stats[i];
        final color = TripCategoryUtil.getColor(stat.categoryIcon);
        IconData icon = TripCategoryUtil.getIconData(stat.categoryIcon);
        final isTouched = i == touchedIndex;
        sections.add(_createSection(stat.totalAmount.toDouble(), total, color, icon, title: controller.isGroupByCategory.value ? TripCategoryUtil.getName(stat.categoryIcon) : stat.tripName, isTouched: isTouched));
      }
    } else {
      // Top 3
      for (int i = 0; i < 3; i++) {
        final stat = stats[i];
        final color = TripCategoryUtil.getColor(stat.categoryIcon);
        IconData icon = TripCategoryUtil.getIconData(stat.categoryIcon);
        final isTouched = i == touchedIndex;
        sections.add(_createSection(stat.totalAmount.toDouble(), total, color, icon, title: controller.isGroupByCategory.value ? TripCategoryUtil.getName(stat.categoryIcon) : stat.tripName, isTouched: isTouched));
      }
      // Khác (Others)
      double otherAmount = 0;
      for (int i = 3; i < stats.length; i++) {
        otherAmount += stats[i].totalAmount;
      }
      sections.add(_createSection(otherAmount, total, Colors.grey, Icons.more_horiz, title: "Khác", isTouched: 3 == touchedIndex));
    }
    return sections;
  }

  PieChartSectionData _createSection(double value, double total, Color color, IconData icon, {String? title, bool isTouched = false}) {
    double percentage = total > 0 ? (value / total * 100) : 0;
    // Ẩn số % nếu quá bé (< 5%) để tránh chữ đè lên viền
    String percentageText = percentage >= 5 ? "${percentage.toStringAsFixed(0)}%" : "";
    
    return PieChartSectionData(
      color: color,
      value: value,
      title: percentageText,
      radius: isTouched ? 60 : 50,
      titleStyle: TextStyle(fontSize: isTouched ? 16 : 12, fontWeight: FontWeight.bold, color: Colors.white),
      badgeWidget: isTouched ? _Badge(icon, size: 45, borderColor: color, bgColor: color, text: title) : _Badge(icon, size: 30, borderColor: color, bgColor: color),
      badgePositionPercentageOffset: 1.15,
    );
  }

  Widget _buildStatList() {
    final stats = controller.displayStats;
    double total = stats.fold(0, (sum, item) => sum + item.totalAmount);
    
    return Column(
      children: stats.asMap().entries.map((entry) {
        final stat = entry.value;
        final color = TripCategoryUtil.getColor(stat.categoryIcon);
        IconData icon = TripCategoryUtil.getIconData(stat.categoryIcon);
        double percentage = total > 0 ? (stat.totalAmount / total) * 100 : 0;
        
        String displayName = controller.isGroupByCategory.value 
            ? TripCategoryUtil.getName(stat.categoryIcon) 
            : stat.tripName;

        return InkWell(
          onTap: () {
            if (!controller.isGroupByCategory.value) {
              Get.to(() => TripDetailScreen(tripId: stat.tripId));
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Icon(icon, color: Colors.white, size: 20)),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName, style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("${percentage.toStringAsFixed(1)}%", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
                Text("${CurrencyUtils.formatNumber(stat.totalAmount)} đ", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyState(text: "Chưa có chi tiêu nào trong khoảng thời gian này");
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color borderColor;
  final Color bgColor;
  final String? text;

  const _Badge(this.icon, {required this.size, required this.borderColor, required this.bgColor, this.text});

  @override
  Widget build(BuildContext context) {
    Widget badge = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size, height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Center(child: Icon(icon, size: size * 0.45, color: Colors.white)),
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
