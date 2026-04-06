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
    );
  }
}