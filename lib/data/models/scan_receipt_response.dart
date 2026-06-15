class ScanReceiptResponse {
  final double totalAmount;
  final String description;
  final int? categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final String? expenseDate;

  ScanReceiptResponse({
    required this.totalAmount,
    required this.description,
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.expenseDate,
  });

  factory ScanReceiptResponse.fromJson(Map<String, dynamic> json) {
    return ScanReceiptResponse(
      totalAmount: json['totalAmount'] != null ? (json['totalAmount'] as num).toDouble() : 0.0,
      description: json['description'] as String? ?? '',
      categoryId: json['categoryId'] as int?,
      categoryName: json['categoryName'] as String?,
      categoryIcon: json['categoryIcon'] as String?,
      expenseDate: json['expenseDate'] as String?,
    );
  }
}
