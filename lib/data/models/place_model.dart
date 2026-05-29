import 'place_image_model.dart';

class PlaceModel {
  final int id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final String city;
  final String summary;
  final String ticketPrices;
  final String openingHours;
  final List<PlaceImageModel> images;
  final int? creatorId;
  final bool isUserGenerated;

  PlaceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.summary,
    required this.ticketPrices,
    required this.openingHours,
    required this.images,
    this.creatorId,
    required this.isUserGenerated,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      city: json['city'] ?? '',
      summary: json['summary'] ?? '',
      ticketPrices: json['ticketPrices'] ?? '',
      openingHours: json['openingHours'] ?? '',
      images: json['images'] != null 
          ? List<PlaceImageModel>.from(json['images'].map((x) => PlaceImageModel.fromJson(x)))
          : [],
      creatorId: json['creatorId'],
      isUserGenerated: json['isUserGenerated'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'summary': summary,
      'ticketPrices': ticketPrices,
      'openingHours': openingHours,
      'images': images.map((x) => x.toJson()).toList(),
      'creatorId': creatorId,
      'isUserGenerated': isUserGenerated,
    };
  }
}
