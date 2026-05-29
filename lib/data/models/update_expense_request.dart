import 'split_request.dart';

class UpdateExpenseRequest {
  final int payerId;
  final double totalAmount;
  final String description;
  final int? categoryId; // ĐÃ ĐỔI TỪ String? category SANG int? categoryId
  final String expenseDate;
  final String? currency;
  final double? exchangeRate;
  final List<SplitRequest> splits;
  final bool? isFromFund;
  final String? clientUuid;
  final String? splitType;

  UpdateExpenseRequest({
    required this.payerId,
    required this.totalAmount,
    required this.description,
    this.categoryId, // CẬP NHẬT CONSTRUCTOR
    required this.expenseDate,
    this.currency,
    this.exchangeRate,
    required this.splits,
    this.isFromFund,
    this.clientUuid,
    this.splitType,
  });

  Map<String, dynamic> toJson() => {
    'payerId': payerId,
    'totalAmount': totalAmount,
    'description': description,
    'categoryId': categoryId, // CẬP NHẬT JSON KEY
    'expenseDate': expenseDate,
    'currency': currency,
    'exchangeRate': exchangeRate,
    'splits': splits.map((e) => e.toJson()).toList(),
    'isFromFund': isFromFund,
    'clientUuid': clientUuid,
    if (splitType != null) 'splitType': splitType,
  };
}
