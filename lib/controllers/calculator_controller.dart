import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:math_expressions/math_expressions.dart';
import '../utils/toast_util.dart';

class CalculatorController extends GetxController {
  var input = ''.obs;
  var result = '0'.obs;
  var history = <String>[].obs;
  var isAdvanced = false.obs; // Trạng thái bàn phím
  final box = GetStorage();
  
  final String HISTORY_KEY = 'calculator_history';

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  void loadHistory() {
    List<dynamic>? saved = box.read<List<dynamic>>(HISTORY_KEY);
    if (saved != null) {
      history.value = saved.map((e) => e.toString()).toList();
    }
  }

  void saveHistory() {
    box.write(HISTORY_KEY, history.toList());
  }

  void toggleAdvanced() {
    isAdvanced.value = !isAdvanced.value;
  }

  void onKeyPress(String key) {
    if (key == 'C') {
      input.value = '';
      result.value = '0';
    } else if (key == '⌫') {
      if (input.value.isNotEmpty) {
        input.value = input.value.substring(0, input.value.length - 1);
        _calculateLive();
      }
    } else if (key == '𝑓x' || key == '123') {
      toggleAdvanced();
    } else if (key == '=') {
      _calculateFinal();
    } else {
      // Logic gõ số và toán tử
      if (key == '.') {
        final parts = input.value.split(RegExp(r'[+\-×÷^()]'));
        if (parts.isNotEmpty && parts.last.contains('.')) {
          return;
        }
      }
      
      if (['sin', 'cos', 'tan'].contains(key)) {
        input.value += '$key(';
      } else {
        input.value += key;
      }
      _calculateLive();
    }
  }

  String get formattedInput {
    if (input.value.isEmpty) return '';
    // Hỗ trợ hiển thị thêm các toán tử mới
    final parts = input.value.split(RegExp(r'([+\-×÷^()%])'));
    final operators = RegExp(r'[+\-×÷^()%]').allMatches(input.value).map((m) => m.group(0)!).toList();
    
    String res = '';
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        // Chỉ thêm dấu phẩy nếu part là số hợp lệ
        if (RegExp(r'^[0-9.]+$').hasMatch(parts[i])) {
          res += _formatNumber(parts[i]);
        } else {
          res += parts[i];
        }
      }
      if (i < operators.length) {
        res += ' ${operators[i]} ';
      }
    }
    return res.replaceAll('  ', ' ');
  }

  String _formatNumber(String numStr) {
    if (numStr.isEmpty) return '';
    if (numStr == '.') return '.';
    
    List<String> splitDot = numStr.split('.');
    String integerPart = splitDot[0];
    String decimalPart = splitDot.length > 1 ? splitDot[1] : '';

    String formattedInt = '';
    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0 && integerPart[i] != '-') {
        formattedInt = ',$formattedInt';
      }
      formattedInt = integerPart[i] + formattedInt;
      count++;
    }

    if (splitDot.length > 1) {
      return '$formattedInt.$decimalPart';
    }
    return formattedInt;
  }

  String _formatResult(double val) {
    if (val.isInfinite || val.isNaN) return 'Lỗi';
    
    String s;
    if (val == val.toInt()) {
      s = val.toInt().toString();
    } else {
      s = val.toStringAsFixed(4);
      while (s.contains('.') && (s.endsWith('0') || s.endsWith('.'))) {
        s = s.substring(0, s.length - 1);
      }
    }
    return _formatNumber(s);
  }

  void _calculateLive() {
    if (input.value.isEmpty) {
      result.value = '0';
      return;
    }
    
    try {
      double evalResult = _evaluateExpression(input.value);
      result.value = _formatResult(evalResult);
    } catch (e) {
      // Bỏ qua lỗi tạm thời khi đang gõ dở
    }
  }

  void _calculateFinal() {
    if (input.value.isEmpty) return;

    try {
      double evalResult = _evaluateExpression(input.value);
      String finalRes = _formatResult(evalResult);
      
      String equation = "${formattedInput.replaceAll(' ', '')} = $finalRes";
      history.insert(0, equation);
      if (history.length > 50) history.removeLast();
      saveHistory();

      input.value = finalRes.replaceAll(',', '');
      result.value = finalRes;
    } catch (e) {
      ToastUtil.showError("Lỗi", "Phép tính không hợp lệ");
    }
  }

  void clearHistory() {
    history.clear();
    saveHistory();
    ToastUtil.showSuccess("Thành công", "Đã xóa lịch sử");
  }

  void applyHistoryItem(String equation) {
    try {
      String res = equation.split('=').last.trim();
      input.value = res.replaceAll(',', '');
      result.value = res;
      Get.back();
    } catch (e) {}
  }

  double _evaluateExpression(String expr) {
    expr = expr.replaceAll('×', '*').replaceAll('÷', '/');
    expr = expr.replaceAll('π', '3.141592653589793').replaceAll('e', '2.718281828459045');
    expr = expr.replaceAll('%', '/100');
    
    // Tự động đóng ngoặc nếu thiếu
    int openBrackets = '\('.allMatches(expr).length;
    int closeBrackets = '\)'.allMatches(expr).length;
    for (int i = 0; i < openBrackets - closeBrackets; i++) {
      expr += ')';
    }

    try {
      Parser p = Parser();
      Expression exp = p.parse(expr);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);
      return eval;
    } catch (e) {
      throw Exception("Invalid expr");
    }
  }
}
