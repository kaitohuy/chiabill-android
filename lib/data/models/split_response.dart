class SplitResponse {
  final int userId;
  final String? userName;
  final double amount; // Dùng double cho BigDecimal của Java
  final double? splitValue;

  SplitResponse({
    required this.userId,
    this.userName,
    required this.amount,
    this.splitValue,
  });

  factory SplitResponse.fromJson(Map<String, dynamic> json) {
    return SplitResponse(
      userId: json['userId'] as int,
      userName: json['userName'] as String?,
      amount: (json['amount'] as num).toDouble(),
      splitValue: json['splitValue'] != null ? (json['splitValue'] as num).toDouble() : null,
    );
  }
}
