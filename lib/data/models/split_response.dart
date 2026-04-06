class SplitResponse {
  final int userId;
  final String? userName;
  final double amount; // Dùng double cho BigDecimal của Java

  SplitResponse({
    required this.userId,
    this.userName,
    required this.amount,
  });

  factory SplitResponse.fromJson(Map<String, dynamic> json) {
    return SplitResponse(
      userId: json['userId'] as int,
      userName: json['userName'] as String?,
      amount: (json['amount'] as num).toDouble(),
    );
  }
}