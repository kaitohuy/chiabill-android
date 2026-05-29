class TripStatResponse {
  final int tripId;
  final String tripName;
  final double totalAmount;
  final String? categoryIcon;

  TripStatResponse({
    required this.tripId,
    required this.tripName,
    required this.totalAmount,
    this.categoryIcon,
  });

  factory TripStatResponse.fromJson(Map<String, dynamic> json) {
    return TripStatResponse(
      tripId: json['tripId'] ?? -1,
      tripName: json['tripName'] ?? '',
      totalAmount: (json['totalAmount'] as num).toDouble(),
      categoryIcon: json['categoryIcon'],
    );
  }
}
