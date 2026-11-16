class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final int categoryId;
  final String? categoryName;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.categoryId,
    this.categoryName,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: double.parse(json['price'].toString()),
      imageUrl: _parseImageUrl(json['image_url']),
      categoryId: json['category_id'] as int,
      categoryName: json['category_name'] as String?,
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
