import 'package:chiabill/data/models/trip_member_response.dart';
import 'user_response.dart';

class TripResponse {
  final int id;
  final String name;
  final String? description;
  final String? currency;
  final double? totalBudget;
  final UserResponse? createdBy;
  final int? ownerId;
  final List<TripMemberResponse>? members;
  final String? createdAt;
  final String? startDate;
  final int? memberCount;
  final String? categoryName;
  final String? categoryIcon;

  TripResponse({
    required this.id,
    required this.name,
    this.description,
    this.currency,
    this.totalBudget,
    this.createdBy,
    this.ownerId,
    this.members,
    this.createdAt,
    this.startDate,
    this.memberCount,
    this.categoryName,
    this.categoryIcon,
  });

  factory TripResponse.fromJson(Map<String, dynamic> json) {
    return TripResponse(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      currency: json['currency'] as String?,
      totalBudget: json['totalBudget'] != null ? double.parse(json['totalBudget'].toString()) : null,
      createdBy: json['createdBy'] != null ? UserResponse.fromJson(json['createdBy']) : null,
      ownerId: json['ownerId'] as int?,
      members: json['members'] != null
          ? (json['members'] as List).map((i) => TripMemberResponse.fromJson(i)).toList()
          : null,
      createdAt: json['createdAt'] as String?,
      startDate: json['startDate'] as String?,
      memberCount: json['memberCount'] as int?,
      categoryName: json['categoryName'] as String?,
      categoryIcon: json['categoryIcon'] as String?,
    );
  }
}
