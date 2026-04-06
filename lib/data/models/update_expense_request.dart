import 'split_request.dart';

class UpdateExpenseRequest {
  final int payerId;
  final double totalAmount;
  final String description;
  final int? categoryId; // ĐÃ ĐỔI TỪ String? category SANG int? categoryId
  final String expenseDate;
  final List<SplitRequest> splits;

  UpdateExpenseRequest({
    required this.payerId,
    required this.totalAmount,
    required this.description,
    this.categoryId, // CẬP NHẬT CONSTRUCTOR
    required this.expenseDate,
    required this.splits,
  });

  Map<String, dynamic> toJson() => {
    'payerId': payerId,
    'totalAmount': totalAmount,
    'description': description,
    'categoryId': categoryId, // CẬP NHẬT JSON KEY
    'expenseDate': expenseDate,
    'splits': splits.map((e) => e.toJson()).toList(),
  };
}