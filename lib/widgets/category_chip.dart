import 'package:flutter/material.dart';
import '../models/category.dart';

class CategoryChip extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        // Se conserva la imagen al seleccionar (sin sustituirla por el check).
        showCheckmark: false,
        avatar: _CategoryImage(imageUrl: category.imageUrl),
        label: Text(category.name),
        selected: isSelected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

/// Avatar circular con carga, error y placeholder para la imagen de categoría.
class _CategoryImage extends StatelessWidget {
  final String? imageUrl;

  const _CategoryImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return CircleAvatar(
      radius: 12,
      backgroundColor: Colors.grey[200],
      child: hasImage
          ? ClipOval(
              child: Image.network(
                imageUrl!,
                width: 24,
                height: 24,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey[500],
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.category_outlined,
                  size: 14,
                  color: Colors.grey[600],
                ),
              ),
            )
          : Icon(
              Icons.category_outlined,
              size: 14,
              color: Colors.grey[600],
            ),
    );
  }
}
