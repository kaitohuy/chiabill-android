import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/add_expense_controller.dart';
import '../../utils/currency_util.dart';
import '../../theme/app_colors.dart';

class AdvancedSplitBottomSheet extends StatefulWidget {
  final AddExpenseController controller;

  const AdvancedSplitBottomSheet({super.key, required this.controller});

  @override
  State<AdvancedSplitBottomSheet> createState() => _AdvancedSplitBottomSheetState();
}

class _AdvancedSplitBottomSheetState extends State<AdvancedSplitBottomSheet> {
  late String _splitType;
  late List<int> _selectedMemberIds;
  late Map<int, double> _splitValues;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _splitType = widget.controller.splitType.value;
    _selectedMemberIds = List.from(widget.controller.selectedSplitMemberIds);
    _splitValues = Map.from(widget.controller.splitValues);

    // Điền mặc định nếu thiếu
    for (var m in widget.controller.activeMembers) {
      if (!_splitValues.containsKey(m.user.id)) {
        _splitValues[m.user.id] = 0.0;
      }
    }
  }

  void _saveAndClose() {
    widget.controller.splitType.value = _splitType;
    widget.controller.selectedSplitMemberIds.value = _selectedMemberIds;
    widget.controller.splitValues.value = _splitValues;
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: Get.height * (_isFullScreen ? 0.95 : 0.7),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildTabs(),
            _buildInfoCard(),
            if (_splitType == 'EQUAL') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Thành viên tham gia", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedMemberIds.length == widget.controller.activeMembers.length) {
                          _selectedMemberIds.clear();
                        } else {
                          _selectedMemberIds = widget.controller.activeMembers.map((m) => m.user.id).toList();
                        }
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _selectedMemberIds.length == widget.controller.activeMembers.length ? "Bỏ chọn tất cả" : "Chọn tất cả",
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              )
            ] else ...[
              const SizedBox(height: 16),
            ],
            Expanded(child: _buildMemberList()),
          _buildSummaryBar(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveAndClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Xác nhận', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Tùy chọn chia tiền",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
              onPressed: () => setState(() => _isFullScreen = !_isFullScreen),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Get.back(),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTab("EQUAL", "Chia đều", Icons.group),
          const SizedBox(width: 8),
          _buildTab("EXACT", "Chính xác", Icons.attach_money),
          const SizedBox(width: 8),
          _buildTab("PERCENTAGE", "Phần trăm", Icons.percent),
          const SizedBox(width: 8),
          _buildTab("SHARES", "Tỷ trọng", Icons.pie_chart),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    String title = "";
    String desc = "";
    Color bgColor = Colors.orange.shade100;
    Color iconColor = Colors.orange.shade800;
    IconData icon = Icons.info_outline;

    switch (_splitType) {
      case 'EQUAL':
        title = "Chia đều";
        desc = "Chọn những người tham gia, số tiền sẽ được chia đều cho tất cả.";
        bgColor = Colors.blue.shade50;
        iconColor = Colors.blue.shade800;
        icon = Icons.group;
        break;
      case 'EXACT':
        title = "Chia chính xác";
        desc = "Nhập chính xác số tiền mỗi người phải trả. Thích hợp khi có người gọi món riêng đắt tiền.";
        bgColor = Colors.orange.shade100;
        iconColor = Colors.orange.shade800;
        icon = Icons.attach_money;
        break;
      case 'PERCENTAGE':
        title = "Chia theo phần trăm";
        desc = "Nhập phần trăm (%) mỗi người phải trả. Tổng phần trăm phải đúng bằng 100%.";
        bgColor = Colors.purple.shade50;
        iconColor = Colors.purple.shade800;
        icon = Icons.percent;
        break;
      case 'SHARES':
        title = "Chia theo tỷ trọng";
        desc = "Nhập số phần (suất) của mỗi người. Ví dụ: Gia đình đi 3 người thì tính 3 phần.";
        bgColor = Colors.green.shade50;
        iconColor = Colors.green.shade800;
        icon = Icons.pie_chart;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: iconColor, fontSize: 14)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: iconColor.withValues(alpha:0.8), fontSize: 12, height: 1.3)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTab(String type, String label, IconData icon) {
    bool isSelected = _splitType == type;
    return GestureDetector(
      onTap: () {
        if (_splitType == type) return;
        setState(() {
          _splitType = type;
          
          int activeCount = widget.controller.activeMembers.length;
          if (activeCount > 0) {
            if (type == 'EXACT') {
              double expectedTotal = double.tryParse(widget.controller.amountController.text.replaceAll(',', '')) ?? 0.0;
              int totalInt = expectedTotal.round();
              int base = totalInt ~/ activeCount;
              int remainder = totalInt % activeCount;
              for (int i = 0; i < activeCount; i++) {
                var id = widget.controller.activeMembers[i].user.id;
                _splitValues[id] = (base + (i < remainder ? 1 : 0)).toDouble();
              }
            } else if (type == 'PERCENTAGE') {
              int totalInt = 10000; // 100.00%
              int base = totalInt ~/ activeCount;
              int remainder = totalInt % activeCount;
              for (int i = 0; i < activeCount; i++) {
                var id = widget.controller.activeMembers[i].user.id;
                _splitValues[id] = (base + (i < remainder ? 1 : 0)) / 100.0;
              }
            } else if (type == 'SHARES') {
               for (var m in widget.controller.activeMembers) {
                _splitValues[m.user.id] = 1.0;
              }
            } else if (type == 'EQUAL') {
               for (var m in widget.controller.activeMembers) {
                _splitValues[m.user.id] = 0.0;
              }
            }
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha:0.1) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? AppColors.primary : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberList() {
    return ListView.builder(
      itemCount: widget.controller.activeMembers.length,
      itemBuilder: (context, index) {
        final member = widget.controller.activeMembers[index];
        final user = member.user;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                child: user.avatarUrl == null ? Text((user.name ?? "A")[0].toUpperCase()) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name ?? "Ẩn danh",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    if (_splitType == 'SHARES') ...[
                      const SizedBox(height: 2),
                      Builder(builder: (context) {
                        double totalShares = _splitValues.values.fold(0.0, (s, e) => s + e);
                        double myShare = _splitValues[user.id] ?? 0.0;
                        if (totalShares == 0) return const SizedBox();
                        double percent = (myShare / totalShares) * 100;
                        String shareStr = myShare.toStringAsFixed(myShare.truncateToDouble() == myShare ? 0 : 2);
                        String totalStr = totalShares.toStringAsFixed(totalShares.truncateToDouble() == totalShares ? 0 : 2);
                        return Text(
                          "$shareStr/$totalStr phần (${percent.toStringAsFixed(1)}%)",
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        );
                      })
                    ]
                  ],
                ),
              ),
              if (_splitType == 'EQUAL')
                Checkbox(
                  value: _selectedMemberIds.contains(user.id),
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedMemberIds.add(user.id);
                      } else {
                        _selectedMemberIds.remove(user.id);
                      }
                    });
                  },
                )
              else
                SizedBox(
                  width: 140,
                  child: TextFormField(
                    key: ValueKey('$_splitType-${user.id}'),
                    initialValue: _splitValues[user.id] == 0 
                      ? '' 
                      : (_splitType == 'EXACT' ? CurrencyUtils.formatNumber(_splitValues[user.id]!) : _splitValues[user.id].toString().replaceAll(RegExp(r'\.0$'), '')),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: _splitType == 'EXACT' 
                      ? [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()] 
                      : [],
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: '0',
                      suffixText: _getSuffix(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _splitValues[user.id] = double.tryParse(val.replaceAll(',', '')) ?? 0.0;
                      });
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _getSuffix() {
    if (_splitType == 'PERCENTAGE') return '%';
    if (_splitType == 'SHARES') return ' phần';
    return '';
  }

  Widget _buildSummaryBar() {
    if (_splitType == 'EQUAL') {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Text(
          "Đã chọn ${_selectedMemberIds.length} người",
          style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
      );
    }

    double total = _splitValues.values.fold(0.0, (s, e) => s + e);
    String statusText = "";
    Color statusColor = Colors.grey[600]!;

    if (_splitType == 'PERCENTAGE') {
      double diff = 100 - total;
      if (diff.abs() < 0.1) {
         statusText = "Đã chia đủ 100%";
         statusColor = Colors.green;
      } else if (diff > 0) {
         statusText = "Còn thiếu: ${diff.toStringAsFixed(diff.truncateToDouble() == diff ? 0 : 2)}%";
         statusColor = Colors.orange.shade800;
      } else {
         statusText = "Bị vượt mức: ${diff.abs().toStringAsFixed(diff.abs().truncateToDouble() == diff.abs() ? 0 : 2)}%";
         statusColor = Colors.red;
      }
    } else if (_splitType == 'SHARES') {
      statusText = "Tổng: ${total.toStringAsFixed(total.truncateToDouble() == total ? 0 : 2)} phần";
      statusColor = AppColors.primary;
    } else if (_splitType == 'EXACT') {
      double expectedTotal = double.tryParse(widget.controller.amountController.text.replaceAll(',', '')) ?? 0.0;
      double diff = expectedTotal - total;
      if (diff.abs() < 0.1) {
         statusText = "Đã chia đủ tiền";
         statusColor = Colors.green;
      } else if (diff > 0) {
         statusText = "Còn thiếu: ${CurrencyUtils.formatNumber(diff)} ${widget.controller.selectedCurrency.value}";
         statusColor = Colors.orange.shade800;
      } else {
         statusText = "Bị vượt mức: ${CurrencyUtils.formatNumber(diff.abs())} ${widget.controller.selectedCurrency.value}";
         statusColor = Colors.red;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        statusText,
        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
