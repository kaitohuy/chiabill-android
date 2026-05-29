class CreateTripRequest {
  final String name;
  final String description;
  final double? totalBudget;
  final String? startDate;
  final String? categoryName;
  final String? categoryIcon;

  CreateTripRequest({
    required this.name,
    required this.description,
    this.totalBudget,
    this.startDate,
    this.categoryName,
    this.categoryIcon,
  });

  // Convert sang JSON để gửi qua API
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      if (totalBudget != null) 'totalBudget': totalBudget,
      'startDate': startDate,
      if (categoryName != null) 'categoryName': categoryName,
      if (categoryIcon != null) 'categoryIcon': categoryIcon,
    };
  }
}
