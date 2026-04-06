class CreateTripRequest {
  final String name;
  final String description;

  CreateTripRequest({required this.name, required this.description});

  // Convert sang JSON để gửi qua API
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
    };
  }
}