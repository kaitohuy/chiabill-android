class InviteInfoResponse {
  final String tripName;
  final String? description;
  final int memberCount;
  final String createdByName;

  InviteInfoResponse({
    required this.tripName,
    this.description,
    required this.memberCount,
    required this.createdByName,
  });

  factory InviteInfoResponse.fromJson(Map<String, dynamic> json) {
    return InviteInfoResponse(
      tripName: json['tripName'],
      description: json['description'],
      memberCount: json['memberCount'] as int,
      createdByName: json['createdByName'],
    );
  }
}