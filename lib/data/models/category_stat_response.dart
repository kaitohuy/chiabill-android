class CategoryStatResponse {
  final int categoryId;
  final String categoryName;
  final String categoryIcon;
  final double totalAmount;

  CategoryStatResponse({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.totalAmount,
  });

  factory CategoryStatResponse.fromJson(Map<String, dynamic> json) {
    return CategoryStatResponse(
      categoryId: json['categoryId'] as int,
      categoryName: json['categoryName'] as String,
      categoryIcon: json['categoryIcon'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
    );
  }
}
