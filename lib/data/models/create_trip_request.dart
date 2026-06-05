class CreateTripRequest {
  final String name;
  final String description;
  final String? coverUrl;
  final double? totalBudget;
  final String? startDate;
  final String? endDate;
  final String? categoryName;
  final String? categoryIcon;

  CreateTripRequest({
    required this.name,
    required this.description,
    this.coverUrl,
    this.totalBudget,
    this.startDate,
    this.endDate,
    this.categoryName,
    this.categoryIcon,
  });

  // Convert sang JSON để gửi qua API
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      if (coverUrl != null) 'coverUrl': coverUrl,
      if (totalBudget != null) 'totalBudget': totalBudget,
      'startDate': startDate,
      'endDate': endDate,
      if (categoryName != null) 'categoryName': categoryName,
      if (categoryIcon != null) 'categoryIcon': categoryIcon,
    };
  }
}
