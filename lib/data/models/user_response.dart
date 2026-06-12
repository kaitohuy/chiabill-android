class UserResponse {
  final int id;
  final String? name;
  final String? email;
  final String? avatarUrl;
  final String? bankQrUrl;
  final bool isGhost;
  final String? bankId;    // THÊM MỚI
  final String? accountNo; // THÊM MỚI
  final int paymentPriority;
  final String? phone;         // THÊM MỚI
  final bool allowAutoAdd;
  final bool allowAutoApprovePayment;
  final String? language;

  UserResponse({
    required this.id,
    this.name,
    this.email,
    this.avatarUrl,
    this.bankQrUrl,
    this.isGhost = false,
    this.bankId,
    this.accountNo,
    this.phone,
    this.allowAutoAdd = true,
    this.allowAutoApprovePayment = true,
    required this.paymentPriority,
    this.language,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'] as int,
      name: json['name'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bankQrUrl: json['bankQrUrl'] as String?,
      isGhost: json['isGhost'] as bool? ?? false,
      bankId: json['bankId'] as String?,
      accountNo: json['accountNo'] as String?,
      phone: json['phone'] as String?,
      allowAutoAdd: json['allowAutoAdd'] as bool? ?? true,
      allowAutoApprovePayment: json['allowAutoApprovePayment'] as bool? ?? true,
      paymentPriority: json['paymentPriority'] as int? ?? 1,
      language: json['language'] as String?,
    );
  }
}
