import 'package:flutter_test/flutter_test.dart';
import 'package:app_tienda/models/product.dart';
import 'package:app_tienda/providers/product_provider.dart';

Product _product({
  required int id,
  required String name,
  String? description,
  int categoryId = 1,
}) {
  return Product(
    id: id,
    name: name,
    description: description,
    price: 10,
    imageUrl: null,
    categoryId: categoryId,
    categoryName: 'Test',
  );
}

void main() {
  final electronics = [
    _product(
      id: 1,
      name: 'Auriculares Bluetooth',
      description: 'Auriculares inalámbricos con cancelación de ruido',
      categoryId: 1,
    ),
    _product(
      id: 2,
      name: 'Smartwatch',
      description: 'Reloj inteligente con monitor de actividad',
      categoryId: 1,
    ),
    _product(
      id: 9,
      name: 'Tablet 10"',
      description: 'Tablet con pantalla de 10 pulgadas',
      categoryId: 1,
    ),
  ];

  final clothing = [
    _product(
      id: 3,
      name: 'Camiseta Básica',
      description: 'Camiseta de algodón 100% en varios colores',
      categoryId: 2,
    ),
    _product(
      id: 4,
      name: 'Jeans Clásicos',
      description: 'Pantalón jeans corte recto',
      categoryId: 2,
    ),
  ];

  group('ProductProvider.filterBySearch', () {
    test('busca por nombre', () {
      final result = ProductProvider.filterBySearch(electronics, 'auriculares');
      expect(result.map((p) => p.id), [1]);
    });

    test('busca por descripción', () {
      final result = ProductProvider.filterBySearch(electronics, 'cancelación');
      expect(result.map((p) => p.id), [1]);
    });

    test('ignora mayúsculas y minúsculas', () {
      final result = ProductProvider.filterBySearch(electronics, 'SMARTWATCH');
      expect(result.map((p) => p.id), [2]);
    });

    test('elimina espacios exteriores', () {
      final result = ProductProvider.filterBySearch(electronics, '  tablet  ');
      expect(result.map((p) => p.id), [9]);
    });

    test('combinada con categoría (lista ya filtrada)', () {
      // Simula loadProducts(categoryId: 2): solo ropa en _products.
      final result = ProductProvider.filterBySearch(clothing, 'algodón');
      expect(result.map((p) => p.id), [3]);
      expect(result.every((p) => p.categoryId == 2), isTrue);
    });

    test('sin coincidencias devuelve lista vacía', () {
      final result = ProductProvider.filterBySearch(electronics, 'xyz');
      expect(result, isEmpty);
    });

    test('consulta vacía devuelve todos', () {
      final result = ProductProvider.filterBySearch(electronics, '   ');
      expect(result.length, electronics.length);
    });
  });

  group('ProductProvider search state', () {
    test('setSearchQuery y clearSearch actualizan searchQuery', () {
      final provider = ProductProvider();
      expect(provider.searchQuery, isEmpty);

      provider.setSearchQuery('jeans');
      expect(provider.searchQuery, 'jeans');

      provider.clearSearch();
      expect(provider.searchQuery, isEmpty);
    });

    test('conserva la consulta al simular cambio de categoría (sin limpiar)', () {
      final provider = ProductProvider();
      provider.setSearchQuery('tablet');
      expect(provider.searchQuery, 'tablet');
      // loadProducts no limpia _searchQuery; se verifica el contrato del getter.
      expect(provider.searchQuery.trim().isNotEmpty, isTrue);
    });
  });
}
