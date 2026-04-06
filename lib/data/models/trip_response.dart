import 'package:chiabill/data/models/trip_member_response.dart';

import 'user_response.dart';

class TripResponse {
  final int id;
  final String name;
  final String? description;
  final String? currency;
  final UserResponse? createdBy;
  final int? ownerId;
  final List<TripMemberResponse>? members;
  final String? createdAt; // THÊM DÒNG NÀY

  TripResponse({
    required this.id,
    required this.name,
    this.description,
    this.currency,
    this.createdBy,
    this.ownerId,
    this.members,
    this.createdAt, // THÊM VÀO CONSTRUCTOR
  });

  factory TripResponse.fromJson(Map<String, dynamic> json) {
    return TripResponse(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      currency: json['currency'] as String?,
      createdBy: json['createdBy'] != null ? UserResponse.fromJson(json['createdBy']) : null,
      ownerId: json['ownerId'] as int?,
      members: json['members'] != null
          ? (json['members'] as List).map((i) => TripMemberResponse.fromJson(i)).toList()
          : null,
      createdAt: json['createdAt'] as String?, // THÊM VÀO HÀM PARSE JSON
    );
  }
}