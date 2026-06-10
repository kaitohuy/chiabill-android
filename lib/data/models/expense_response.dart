import 'user_response.dart';
import 'split_response.dart';

class ExpenseResponse {
  final int id;
  final double totalAmount;
  final String description;
  final String? expenseDate;
  final UserResponse? payer;
  final List<SplitResponse>? splits;

  // Cập nhật các trường Category từ BE
  final int? categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final String? currency;
  final double? exchangeRate;
  final bool isFromFund;
  final String? clientUuid;
  final String? splitType;
  final String? receiptUrl;

  ExpenseResponse({
    required this.id,
    required this.totalAmount,
    required this.description,
    this.expenseDate,
    this.payer,
    this.splits,
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.currency,
    this.exchangeRate,
    this.isFromFund = false,
    this.clientUuid,
    this.splitType,
    this.receiptUrl,
  });

  factory ExpenseResponse.fromJson(Map<String, dynamic> json) {
    return ExpenseResponse(
      id: json['id'] as int,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      description: json['description'] as String,
      expenseDate: json['expenseDate'] as String?,
      payer: json['payer'] != null ? UserResponse.fromJson(json['payer']) : null,
      splits: json['splits'] != null
          ? (json['splits'] as List).map((i) => SplitResponse.fromJson(i)).toList()
          : null,
      // Map các trường Category mới
      categoryId: json['categoryId'] as int?,
      categoryName: json['categoryName'] as String?,
      categoryIcon: json['categoryIcon'] as String?,
      currency: json['currency'] as String?,
      exchangeRate: json['exchangeRate'] != null ? (json['exchangeRate'] as num).toDouble() : null,
      isFromFund: json['isFromFund'] as bool? ?? false,
      clientUuid: json['clientUuid'] as String?,
      splitType: json['splitType'] as String?,
      receiptUrl: json['receiptUrl'] as String?,
    );
  }
}
