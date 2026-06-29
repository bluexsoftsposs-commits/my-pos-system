import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import '../core/constants.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _filteredProducts;
  List<Product> get allProducts => _products;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final _productService = ProductService();

  List<String> get categories {
    final cats = _products.map((p) => p.category).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  Future<void> loadProducts({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _productService.getProducts();
      if (data != null) {
        _products = data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
        final box = Hive.box(AppConstants.productsBox);
        await box.put('products', jsonEncode(data));
      } else {
        _loadFromCache();
      }
    } catch (_) {
      _loadFromCache();
    }

    _applyFilters();
    _isLoading = false;
    notifyListeners();
  }

  void _loadFromCache() {
    try {
      final box = Hive.box(AppConstants.productsBox);
      final cached = box.get('products');
      if (cached != null) {
        final data = jsonDecode(cached as String) as List;
        _products = data.map((e) => Product.fromJson(e)).toList();
      }
    } catch (_) {}
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    var filtered = _products.where((p) => p.isActive);

    if (_selectedCategory != 'All') {
      filtered = filtered.where((p) => p.category == _selectedCategory);
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) =>
          p.name.toLowerCase().contains(_searchQuery) ||
          p.sku.toLowerCase().contains(_searchQuery) ||
          p.category.toLowerCase().contains(_searchQuery));
    }

    _filteredProducts = filtered.toList();
  }

  Future<bool> createProduct(Map<String, dynamic> data) async {
    try {
      final result = await _productService.createProduct(data);
      if (result != null) {
        await loadProducts(forceRefresh: true);
        return true;
      }
      _error = 'Failed to create product';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to create product';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      final result = await _productService.updateProduct(id, data);
      if (result != null) {
        await loadProducts(forceRefresh: true);
        return true;
      }
      _error = 'Failed to update product';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to update product';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      if (await _productService.deleteProduct(id)) {
        _products.removeWhere((p) => p.id == id);
        _applyFilters();
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // Decrement stock locally after sale (optimistic update)
  void decrementStock(String productId, int quantity) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index >= 0) {
      _products[index].stock = (_products[index].stock - quantity).clamp(0, 99999);
      _applyFilters();
      notifyListeners();
    }
  }
}
