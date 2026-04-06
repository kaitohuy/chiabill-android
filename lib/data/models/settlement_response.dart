class SettlementResponse {
  final int? fromUserId;
  final String? fromUserName;
  final int? toUserId;
  final String? toUserName;
  final double amount; // Đây là số nợ CÒN LẠI
  final double originalAmount; // THÊM MỚI: Nợ gốc
  final double paidAmount; // THÊM MỚI: Đã trả

  SettlementResponse({
    this.fromUserId,
    this.fromUserName,
    this.toUserId,
    this.toUserName,
    required this.amount,
    required this.originalAmount,
    required this.paidAmount,
  });

  factory SettlementResponse.fromJson(Map<String, dynamic> json) {
    return SettlementResponse(
      fromUserId: json['fromUserId'] as int?,
      fromUserName: json['fromUserName'] as String?,
      toUserId: json['toUserId'] as int?,
      toUserName: json['toUserName'] as String?,
      amount: (json['amount'] as num).toDouble(),
      originalAmount: (json['originalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}