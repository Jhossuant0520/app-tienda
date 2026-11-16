class Category {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: _parseImageUrl(json['image_url']),
    );
  }

  /// Normaliza image_url: null, ausente o cadena vacía → null.
  static String? _parseImageUrl(dynamic value) {
    if (value == null) return null;
    final url = value.toString().trim();
    if (url.isEmpty) return null;
    return url;
  }
}
