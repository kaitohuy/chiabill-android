class InvitationResponse {
  final String inviteCode;
  final String inviteLink;
  final int tripId;
  final String tripName;

  InvitationResponse({
    required this.inviteCode,
    required this.inviteLink,
    required this.tripId,
    required this.tripName,
  });

  factory InvitationResponse.fromJson(Map<String, dynamic> json) {
    return InvitationResponse(
      inviteCode: json['inviteCode'],
      inviteLink: json['inviteLink'],
      tripId: json['tripId'] as int,
      tripName: json['tripName'],
    );
  }
}
