class SearchResult {
  final String type;
  final String id;
  final String title;
  final String subtitle;
  final Map<String, dynamic> data;

  const SearchResult({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.data,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      type: json['type'] as String? ?? '',
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }
}
