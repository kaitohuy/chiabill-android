import 'package:intl/intl.dart';

class AnnouncementResponse {
  final int id;
  final String type;
  final String title;
  final String? content;
  final String? imageUrl;
  final String? actionType;
  final String? actionUrl;
  final String? actionLabel;

  // Cho UPDATE
  final int? minVersion;
  final int? latestVersion;
  final bool? isForceUpdate;

  // Cho PAYMENT / DONATE
  final String? qrImageUrl;
  final String? bankInfo;
  final double? suggestedAmount;

  // Hiển thị
  final String platform;
  final int priority;
  final bool isDismissible;
  final String displayMode;

  // Thời gian
  final bool isActive;
  final String? startAt;
  final String? endAt;
  final String? createdAt;

  AnnouncementResponse({
    required this.id,
    required this.type,
    required this.title,
    this.content,
    this.imageUrl,
    this.actionType,
    this.actionUrl,
    this.actionLabel,
    this.minVersion,
    this.latestVersion,
    this.isForceUpdate,
    this.qrImageUrl,
    this.bankInfo,
    this.suggestedAmount,
    required this.platform,
    required this.priority,
    required this.isDismissible,
    required this.displayMode,
    required this.isActive,
    this.startAt,
    this.endAt,
    this.createdAt,
  });

  factory AnnouncementResponse.fromJson(Map<String, dynamic> json) {
    return AnnouncementResponse(
      id: json['id'],
      type: json['type'] ?? 'ANNOUNCEMENT',
      title: json['title'] ?? '',
      content: json['content'],
      imageUrl: json['imageUrl'],
      actionType: json['actionType'],
      actionUrl: json['actionUrl'],
      actionLabel: json['actionLabel'],
      minVersion: json['minVersion'],
      latestVersion: json['latestVersion'],
      isForceUpdate: json['isForceUpdate'],
      qrImageUrl: json['qrImageUrl'],
      bankInfo: json['bankInfo'],
      suggestedAmount: (json['suggestedAmount'] as num?)?.toDouble(),
      platform: json['platform'] ?? 'ALL',
      priority: json['priority'] ?? 0,
      isDismissible: json['isDismissible'] ?? true,
      displayMode: json['displayMode'] ?? 'ONCE',
      isActive: json['isActive'] ?? true,
      startAt: json['startAt'],
      endAt: json['endAt'],
      createdAt: json['createdAt'],
    );
  }

  // Helpers
  bool get isUpdate => type == 'UPDATE';
  bool get isDonate => type == 'DONATE';
  bool get isPayment => type == 'PAYMENT';
  bool get isMaintenance => type == 'MAINTENANCE';

  String get formattedAmount {
    if (suggestedAmount == null) return '';
    return NumberFormat('#,###', 'vi_VN').format(suggestedAmount) + 'đ';
  }
}
