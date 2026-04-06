class UpdateProfileRequest {
  final String name;
  final String? bankId;
  final String? accountNo;
  final String? avatarUrl;
  final String? bankQrUrl;
  final String? phone;
  final bool allowAutoAdd;
  final bool allowAutoApprovePayment;
  final int paymentPriority; // THÊM TRƯỜNG NÀY (1 hoặc 2)

  UpdateProfileRequest({
    required this.name,
    this.bankId,
    this.accountNo,
    this.avatarUrl,
    this.bankQrUrl,
    this.phone,
    required this.allowAutoAdd,
    required this.allowAutoApprovePayment,
    required this.paymentPriority,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'bankId': bankId,
    'accountNo': accountNo,
    'avatarUrl': avatarUrl,
    'bankQrUrl': bankQrUrl,
    'phone': phone,
    'allowAutoAdd': allowAutoAdd,
    'allowAutoApprovePayment': allowAutoApprovePayment,
    'paymentPriority': paymentPriority,
  };
}