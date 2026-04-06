class NotificationResponse {
  final int id;
  final String title;
  final String message;
  final String type;
  final int? referenceId;
  bool isRead; // Bỏ final để có thể update UI khi người dùng click vào
  final String createdAt;

  NotificationResponse({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      id: json['id'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      referenceId: json['referenceId'],
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] ?? '',
    );
  }
}