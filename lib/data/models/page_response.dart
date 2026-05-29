class PageResponse<T> {
  final List<T> content;
  final int pageNumber;
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final bool last;

  PageResponse({
    required this.content,
    required this.pageNumber,
    required this.pageSize,
    required this.totalElements,
    required this.totalPages,
    required this.last,
  });

  factory PageResponse.fromJson(Map<String, dynamic> json, T Function(Object?) fromJsonT) {
    return PageResponse<T>(
      content: (json['content'] as List).map((i) => fromJsonT(i)).toList(),
      pageNumber: json['pageNumber'] ?? 0,
      pageSize: json['pageSize'] ?? 20,
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      last: json['last'] ?? true,
    );
  }
}
