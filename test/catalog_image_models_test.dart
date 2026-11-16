import 'package:flutter_test/flutter_test.dart';
import 'package:app_tienda/models/category.dart';
import 'package:app_tienda/models/product.dart';

void main() {
  group('Category.fromJson', () {
    test('mapea image_url correctamente', () {
      final category = Category.fromJson({
        'id': 1,
        'name': 'Electrónica',
        'description': 'Gadgets',
        'image_url':
            'https://images.unsplash.com/photo-1498049794561-7780e7231661?auto=format&fit=crop&w=600&h=600&q=80',
      });

      expect(category.id, 1);
      expect(category.name, 'Electrónica');
      expect(category.description, 'Gadgets');
      expect(category.imageUrl, contains('images.unsplash.com'));
    });

    test('tolera image_url null o ausente', () {
      final withoutField = Category.fromJson({
        'id': 2,
        'name': 'Ropa',
        'description': null,
      });
      final withNull = Category.fromJson({
        'id': 3,
        'name': 'Hogar',
        'description': 'Casa',
        'image_url': null,
      });
      final withEmpty = Category.fromJson({
        'id': 4,
        'name': 'Deportes',
        'description': 'Sport',
        'image_url': '   ',
      });

      expect(withoutField.imageUrl, isNull);
      expect(withNull.imageUrl, isNull);
      expect(withEmpty.imageUrl, isNull);
    });
  });

  group('Product.fromJson', () {
    test('mapea image_url correctamente', () {
      final product = Product.fromJson({
        'id': 1,
        'name': 'Auriculares Bluetooth',
        'description': 'Inalámbricos',
        'price': '49.99',
        'image_url':
            'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=600&h=600&q=80',
        'category_id': 1,
        'category_name': 'Electrónica',
      });

      expect(product.id, 1);
      expect(product.price, 49.99);
      expect(product.categoryId, 1);
      expect(product.imageUrl, contains('images.unsplash.com'));
    });

    test('tolera image_url null o vacío', () {
      final withNull = Product.fromJson({
        'id': 2,
        'name': 'Smartwatch',
        'description': null,
        'price': 89.99,
        'image_url': null,
        'category_id': 1,
        'category_name': 'Electrónica',
      });
      final withEmpty = Product.fromJson({
        'id': 3,
        'name': 'Camiseta Básica',
        'description': 'Algodón',
        'price': 19.99,
        'image_url': '',
        'category_id': 2,
        'category_name': 'Ropa',
      });

      expect(withNull.imageUrl, isNull);
      expect(withEmpty.imageUrl, isNull);
    });
  });
}
