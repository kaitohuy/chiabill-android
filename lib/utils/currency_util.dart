import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyUtils {
  // 1. Hàm format tiền để hiển thị (VD: 1000000 -> 1,000,000)
  static String formatNumber(num amount) {
    // Dùng en_US để ép Flutter dùng dấu phẩy (,) phân cách hàng nghìn
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(amount);
  }
}

// 2. Class Formatter để tự động thêm dấu phẩy khi đang gõ phím
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Bước A: Xóa tất cả các ký tự không phải là số (bao gồm cả dấu phẩy người dùng vừa gõ)
    String cleanedText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanedText.isEmpty) return newValue.copyWith(text: '');

    // Bước B: Format lại thành chuỗi có dấu phẩy
    final int value = int.parse(cleanedText);
    final formatter = NumberFormat('#,###', 'en_US');
    String newText = formatter.format(value);

    // Bước C: Trả về chuỗi mới và đẩy con trỏ chuột (cursor) về cuối dòng
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}