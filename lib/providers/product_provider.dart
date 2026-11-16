import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Category> _categories = [];
  List<Product> _products = [];
  Product? _selectedProduct;
  int? _selectedCategoryId;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;

  List<Category> get categories => _categories;
  List<Product> get products => _products;
  Product? get selectedProduct => _selectedProduct;
  int? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Productos visibles: lista de API (ya filtrada por categoría) + búsqueda local.
  List<Product> get visibleProducts => filterBySearch(_products, _searchQuery);

  /// Filtro local por nombre/descripción (sin HTTP).
  static List<Product> filterBySearch(List<Product> products, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return products;

    return products.where((product) {
      final name = product.name.toLowerCase();
      final description = (product.description ?? '').toLowerCase();
      return name.contains(q) || description.contains(q);
    }).toList();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    if (_searchQuery.isEmpty) return;
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _api.getCategories();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProducts({int? categoryId}) async {
    _isLoading = true;
    _error = null;
    _selectedCategoryId = categoryId;
    // Conserva _searchQuery al cambiar de categoría o refrescar.
    notifyListeners();

    try {
      if (categoryId == null) {
        _products = await _api.getProducts();
      } else {
        _products = await _api.getProductsByCategory(categoryId);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProductDetail(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedProduct = await _api.getProductById(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSelectedProduct() {
    _selectedProduct = null;
    notifyListeners();
  }
}
