class CreateGhostRequest {
  final List<String> names;

  CreateGhostRequest({required this.names});

  Map<String, dynamic> toJson() => {'names': names};
}
