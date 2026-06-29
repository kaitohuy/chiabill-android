import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/calculator_controller.dart';
import '../../theme/app_colors.dart';
import 'widgets/calculator_history_sheet.dart';

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  CalculatorController get controller => Get.find<CalculatorController>();

  static const List<String> basicButtons = [
    'C', '⌫', '𝑓x', '÷',
    '7', '8', '9', '×',
    '4', '5', '6', '-',
    '1', '2', '3', '+',
    '000', '0', '.', '='
  ];

  static const List<String> advancedButtons = [
    'C', '⌫', '123', '÷',
    '(', ')', '%', '×',
    'π', 'e', '^', '-',
    'sin', 'cos', 'tan', '+',
    '000', '0', '.', '='
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("calculator_title".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Get.bottomSheet(
                CalculatorHistorySheet(),
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Màn hình hiển thị
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              color: Colors.grey.shade50,
              alignment: Alignment.bottomRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Obx(() {
                    String input = controller.formattedInput;
                    if (input.isEmpty) input = '0';
                    return RichText(
                      textAlign: TextAlign.right,
                      text: TextSpan(
                        children: input.split(' ').map((part) {
                          bool isOp = ['+', '-', '×', '÷', '^', '%', '(', ')'].contains(part) || 
                                      ['sin', 'cos', 'tan', 'π', 'e'].contains(part);
                          return TextSpan(
                            text: part,
                            style: TextStyle(
                              fontSize: 32,
                              color: isOp ? AppColors.primary : Colors.grey.shade700,
                              fontWeight: isOp ? FontWeight.bold : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    );
                  }),
                  const SizedBox(height: 8),
                  Obx(() => Text(
                    "=${controller.result.value}",
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )),
                ],
              ),
            ),
          ),
          
          const Divider(height: 1, color: Colors.black12),
          
          // Bàn phím
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 16), // Chừa bottom 4px
            child: Obx(() {
              List<String> buttons = controller.isAdvanced.value ? advancedButtons : basicButtons;
              return GridView.builder(
                shrinkWrap: true, // Fix bottom empty space
                physics: const NeverScrollableScrollPhysics(),
                itemCount: buttons.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.0, 
                  crossAxisSpacing: 16, // Tăng margin, giảm size nút
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  return _buildButton(buttons[index]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text) {
    bool isOperator = ['+', '-', '×', '÷', '='].contains(text);
    bool isAction = ['C', '⌫', '𝑓x', '123'].contains(text);
    
    Color textColor = Colors.black87;
    Color bgColor = Colors.grey.shade100;
    
    if (isOperator) {
      textColor = Colors.white;
      bgColor = AppColors.primary;
    } else if (isAction) {
      textColor = AppColors.primaryDark;
      bgColor = AppColors.primaryBackgroundLight;
    }

    if (text == '=') {
      bgColor = Colors.orange;
    }

    Widget content;
    if (text == '⌫') {
      content = Icon(Icons.backspace_outlined, color: textColor, size: 24);
    } else {
      content = Text(
        text,
        style: TextStyle(
          fontSize: text.length > 2 ? 20 : 28, // Chữ nhỏ lại nếu text dài (sin, cos)
          fontWeight: isOperator || isAction ? FontWeight.bold : FontWeight.normal,
          color: textColor,
        ),
      );
    }

    return Material(
      color: bgColor,
      shape: const CircleBorder(),
      elevation: 1, 
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: InkWell(
        onTap: () {
          controller.onKeyPress(text);
        },
        customBorder: const CircleBorder(),
        child: Center(
          child: content,
        ),
      ),
    );
  }
}
