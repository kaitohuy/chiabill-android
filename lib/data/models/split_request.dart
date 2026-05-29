class SplitRequest {
  final int userId;
  final double amount;
  final double? splitValue;

  SplitRequest({required this.userId, required this.amount, this.splitValue});

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'amount': amount,
    if (splitValue != null) 'splitValue': splitValue,
  };
}
