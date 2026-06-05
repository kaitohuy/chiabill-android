class ItineraryItemResponse {
  final int? id;
  final int dayNumber;
  final String? timeRange;
  final String activity;
  final String? location;
  final String? note;
  final double? estimatedCost;

  ItineraryItemResponse({
    this.id,
    required this.dayNumber,
    this.timeRange,
    required this.activity,
    this.location,
    this.note,
    this.estimatedCost,
  });

  factory ItineraryItemResponse.fromJson(Map<String, dynamic> json) {
    return ItineraryItemResponse(
      id: json['id'] as int?,
      dayNumber: json['dayNumber'] as int? ?? 1,
      timeRange: json['timeRange'] as String?,
      activity: json['activity'] as String? ?? "",
      location: json['location'] as String?,
      note: json['note'] as String?,
      estimatedCost: json['estimatedCost'] != null ? double.tryParse(json['estimatedCost'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayNumber': dayNumber,
      'timeRange': timeRange,
      'activity': activity,
      'location': location,
      'note': note,
      'estimatedCost': estimatedCost,
    };
  }

  ItineraryItemResponse copyWith({
    int? id,
    int? dayNumber,
    String? timeRange,
    String? activity,
    String? location,
    String? note,
    double? estimatedCost,
  }) {
    return ItineraryItemResponse(
      id: id ?? this.id,
      dayNumber: dayNumber ?? this.dayNumber,
      timeRange: timeRange ?? this.timeRange,
      activity: activity ?? this.activity,
      location: location ?? this.location,
      note: note ?? this.note,
      estimatedCost: estimatedCost ?? this.estimatedCost,
    );
  }
}
