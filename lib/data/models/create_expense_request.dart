import 'split_request.dart';

class CreateExpenseRequest {
  final int tripId;
  final int payerId;
  final double totalAmount;
  final String description;
  final int? categoryId; // ĐÃ ĐỔI TỪ String? category SANG int? categoryId
  final List<SplitRequest> splits;
  final String? currency;
  final double? exchangeRate;
  final bool? isFromFund;
  final String? clientUuid;
  final String? splitType;

  final String? receiptUrl;

  CreateExpenseRequest({
    required this.tripId,
    required this.payerId,
    required this.totalAmount,
    required this.description,
    this.categoryId, // CẬP NHẬT CONSTRUCTOR
    required this.splits,
    this.expenseDate,
    this.currency,
    this.exchangeRate,
    this.isFromFund,
    this.clientUuid,
    this.splitType,
    this.receiptUrl,
  });

  final String? expenseDate;

  Map<String, dynamic> toJson() => {
    'tripId': tripId,
    'payerId': payerId,
    'totalAmount': totalAmount,
    'description': description,
    'categoryId': categoryId, // CẬP NHẬT JSON KEY CHO KHỚP BACKEND
    'expenseDate': expenseDate ?? DateTime.now().toIso8601String().split('.')[0], // Cắt chuỗi cho chuẩn ISO của Spring Boot (nếu cần)
    'currency': currency,
    'exchangeRate': exchangeRate,
    'isFromFund': isFromFund,
    'clientUuid': clientUuid,
    if (splitType != null) 'splitType': splitType,
    'receiptUrl': receiptUrl,
    'splits': splits.map((e) => e.toJson()).toList(),
  };
}
