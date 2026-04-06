class ExpenseCategoryResponse {
  final int id;
  final String name;
  final String? icon;
  final int? tripId;

  ExpenseCategoryResponse({
    required this.id,
    required this.name,
    this.icon,
    this.tripId,
  });

  factory ExpenseCategoryResponse.fromJson(Map<String, dynamic> json) {
    return ExpenseCategoryResponse(
      id: json['id'] as int,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      tripId: json['tripId'] as int?,
    );
  }
}