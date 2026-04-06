class PaymentResponse {
  final int id;
  final int tripId;
  final int fromUserId;
  final String fromUserName;
  final int toUserId;
  final String toUserName;
  final double amount;
  final String proofUrl;
  final String status;
  final String createdAt;

  PaymentResponse({
    required this.id, required this.tripId, required this.fromUserId, required this.fromUserName,
    required this.toUserId, required this.toUserName, required this.amount,
    required this.proofUrl, required this.status, required this.createdAt,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      id: json['id'],
      tripId: json['tripId'],
      fromUserId: json['fromUserId'],
      fromUserName: json['fromUserName'],
      toUserId: json['toUserId'],
      toUserName: json['toUserName'],
      amount: (json['amount'] as num).toDouble(),
      proofUrl: json['proofUrl'] ?? "",
      status: json['status'] ?? "PENDING",
      createdAt: json['createdAt'] ?? "",
    );
  }
}