class PlaceImageModel {
  final int id;
  final String imageUrl;
  final String album;
  final int? userId;
  final String? createdAt;

  PlaceImageModel({
    required this.id,
    required this.imageUrl,
    required this.album,
    this.userId,
    this.createdAt,
  });

  factory PlaceImageModel.fromJson(Map<String, dynamic> json) {
    return PlaceImageModel(
      id: json['id'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      album: json['album'] ?? 'Khác',
      userId: json['userId'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'album': album,
      'userId': userId,
      'createdAt': createdAt,
    };
  }
}
