class CreateTripRequest {
  final String name;
  final String description;
  final double? totalBudget; // THÊM DÒNG NÀY

  CreateTripRequest({
    required this.name,
    required this.description,
    this.totalBudget, // THÊM DÒNG NÀY
  });

  // Convert sang JSON để gửi qua API
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      if (totalBudget != null) 'totalBudget': totalBudget, // THÊM DÒNG NÀY (chỉ gửi nếu có nhập)
    };
  }
}