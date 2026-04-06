class SplitRequest {
  final int userId;
  final double amount;

  SplitRequest({required this.userId, required this.amount});

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'amount': amount,
  };
}