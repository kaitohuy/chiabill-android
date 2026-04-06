import 'split_request.dart';

class CreateExpenseRequest {
  final int tripId;
  final int payerId;
  final double totalAmount;
  final String description;
  final int? categoryId; // ĐÃ ĐỔI TỪ String? category SANG int? categoryId
  final List<SplitRequest> splits;

  CreateExpenseRequest({
    required this.tripId,
    required this.payerId,
    required this.totalAmount,
    required this.description,
    this.categoryId, // CẬP NHẬT CONSTRUCTOR
    required this.splits,
  });

  Map<String, dynamic> toJson() => {
    'tripId': tripId,
    'payerId': payerId,
    'totalAmount': totalAmount,
    'description': description,
    'categoryId': categoryId, // CẬP NHẬT JSON KEY CHO KHỚP BACKEND
    'expenseDate': DateTime.now().toIso8601String().split('.')[0], // Cắt chuỗi cho chuẩn ISO của Spring Boot (nếu cần)
    'splits': splits.map((e) => e.toJson()).toList(),
  };
}