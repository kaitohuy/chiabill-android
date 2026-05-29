class TripHistoryResponse {
  final int? id;
  final int? tripId;
  final int? actorId;
  final String? actorName;
  final String? action;
  final String? content;
  final String? createdAt;

  TripHistoryResponse({
    this.id,
    this.tripId,
    this.actorId,
    this.actorName,
    this.action,
    this.content,
    this.createdAt,
  });

  factory TripHistoryResponse.fromJson(Map<String, dynamic> json) {
    return TripHistoryResponse(
      id: json['id'],
      tripId: json['tripId'],
      actorId: json['actorId'],
      actorName: json['actorName'],
      action: json['action'],
      content: json['content'],
      createdAt: json['createdAt'],
    );
  }
}
