import 'user_response.dart';

class PlaceCommentModel {
  final int id;
  final int placeId;
  final UserResponse user;
  final String content;
  final int? parentId;
  final int likeCount;
  final bool isLikedByCurrentUser;
  final String createdAt;
  final String updatedAt;
  final List<PlaceCommentModel> replies;

  PlaceCommentModel({
    required this.id,
    required this.placeId,
    required this.user,
    required this.content,
    this.parentId,
    required this.likeCount,
    required this.isLikedByCurrentUser,
    required this.createdAt,
    required this.updatedAt,
    required this.replies,
  });

  factory PlaceCommentModel.fromJson(Map<String, dynamic> json) {
    return PlaceCommentModel(
      id: json['id'] ?? 0,
      placeId: json['placeId'] ?? 0,
      user: UserResponse.fromJson(json['user'] ?? {}),
      content: json['content'] ?? '',
      parentId: json['parentId'],
      likeCount: json['likeCount'] ?? 0,
      isLikedByCurrentUser: json['isLikedByCurrentUser'] ?? false,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      replies: json['replies'] != null
          ? List<PlaceCommentModel>.from(json['replies'].map((x) => PlaceCommentModel.fromJson(x)))
          : [],
    );
  }
}
