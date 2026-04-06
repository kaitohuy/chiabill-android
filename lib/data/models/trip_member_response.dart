import 'user_response.dart';

class TripMemberResponse {
  final int id;
  final String? name;
  final String? avatarUrl;
  final String? role;
  final String? status; // ACTIVE hoặc DISABLED
  
  // Thêm các trường này để khi un-flatten sang UserResponse không bị mất data
  final bool isGhost;
  final String? bankId;
  final String? accountNo;
  final int? paymentPriority;
  final String? bankQrUrl;
  final String? email;
  final String? phone;

  TripMemberResponse({
    required this.id,
    this.name,
    this.avatarUrl,
    this.role,
    this.status,
    this.isGhost = false,
    this.bankId,
    this.accountNo,
    this.paymentPriority,
    this.bankQrUrl,
    this.email,
    this.phone,
  });

  // GETTER "CỨU CÁNH": Giúp code UI cũ gọi member.user.name vẫn chạy ngon
  UserResponse get user => UserResponse(
    id: id,
    name: name,
    avatarUrl: avatarUrl,
    isGhost: isGhost,
    bankId: bankId,
    accountNo: accountNo,
    paymentPriority: paymentPriority ?? 1, // Default 1 nếu BE chưa trả về
    bankQrUrl: bankQrUrl,
    email: email,
    phone: phone,
    allowAutoAdd: true,
    allowAutoApprovePayment: true,
  );

  factory TripMemberResponse.fromJson(Map<String, dynamic> json) {
    // Nếu BE vẫn gửi kiểu cũ (lồng trong 'user') hoặc giai đoạn quá độ:
    if (json.containsKey('user') && json['user'] != null) {
      final u = json['user'];
      return TripMemberResponse(
        id: u['id'] as int,
        name: u['name'] as String?,
        avatarUrl: u['avatarUrl'] as String?,
        isGhost: u['isGhost'] as bool? ?? false,
        role: json['role'] as String?,
        status: json['status'] as String?,
        bankId: u['bankId'] as String?,
        accountNo: u['accountNo'] as String?,
        paymentPriority: u['paymentPriority'] as int?,
        bankQrUrl: u['bankQrUrl'] as String?,
        email: u['email'] as String?,
        phone: u['phone'] as String?,
      );
    }
    
    // Nếu BE đã "Làm phẳng" (Flatten):
    return TripMemberResponse(
      id: json['id'] as int,
      name: json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isGhost: json['isGhost'] as bool? ?? false,
      role: json['role'] as String?,
      status: json['status'] as String?,
      bankId: json['bankId'] as String?,
      accountNo: json['accountNo'] as String?,
      paymentPriority: json['paymentPriority'] as int?,
      bankQrUrl: json['bankQrUrl'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }
}