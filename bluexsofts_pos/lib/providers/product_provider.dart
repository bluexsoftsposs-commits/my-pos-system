import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/product_service.dart';
import '../services/database_service.dart';
import '../models/product.dart';
import '../core/constants.dart';
import '../local_db/database.dart';
import '../local_db/local_database_service.dart';
import '../services/sync_service.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;
  int _lowStockCount = 0;
  List<Product> _lowStockProducts = [];

  List<Product> get products => _filteredProducts;
  List<Product> get allProducts => _products;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get lowStockCount => _lowStockCount;
  List<Product> get lowStockProducts => _lowStockProducts;

  final ProductService _productService;
  final LocalDatabaseService _localDb;

  ProductProvider({ProductService? productService, LocalDatabaseService? localDb})
      : _productService = productService ?? ProductService(),
        _localDb = localDb ?? DatabaseService().local;

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
        // Persist to local database as cache
        await _cacheToLocalDb(data);
        // Also keep Hive cache for backwards compatibility
        final box = Hive.box(AppConstants.productsBox);
        await box.put('products', jsonEncode(data));
        // Opportunistic sync: if we had a prior network failure, try syncing now
        await SyncFallback.instance.trySync();
      } else {
        await _loadFromLocalDb();
      }
    } catch (_) {
      SyncFallback.instance.markFailure();
      await _loadFromLocalDb();
    }

    _applyFilters();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _cacheToLocalDb(List<dynamic> data) async {
    final products = data.map((e) {
      final map = e as Map<String, dynamic>;
      return ProductsTableCompanion(
        id: Value(map['id'] as String),
        shopId: Value(map['shopId'] as String),
        name: Value(map['name'] as String),
        description: Value(map['description'] as String? ?? ''),
        price: Value((map['price'] as num).toDouble()),
        stock: Value(map['stock'] as int? ?? 0),
        sku: Value(map['sku'] as String? ?? ''),
        category: Value(map['category'] as String? ?? 'General'),
        imageUrl: Value(map['imageUrl'] as String? ?? ''),
        barcode: Value(map['barcode'] as String?),
        lowStockThreshold: Value(map['lowStockThreshold'] as int? ?? 5),
        isActive: Value(map['isActive'] as bool? ?? true),
        createdAt: Value(DateTime.parse(map['createdAt'] as String)),
        updatedAt: Value(DateTime.now()),
      );
    }).toList();
    await _localDb.insertProducts(products);
  }

  Future<void> _loadFromLocalDb() async {
    try {
      final localProducts = await _localDb.getProducts();
      if (localProducts.isNotEmpty) {
        _products = localProducts.map((p) => Product(
          id: p.id,
          shopId: p.shopId,
          name: p.name,
          description: p.description,
          price: p.price,
          stock: p.stock,
          sku: p.sku,
          category: p.category,
          imageUrl: p.imageUrl,
          barcode: p.barcode,
          lowStockThreshold: p.lowStockThreshold,
          isActive: p.isActive,
          createdAt: p.createdAt,
        )).toList();
        return;
      }
      // Fallback to Hive cache if local DB is empty
      _loadFromHiveCache();
    } catch (_) {
      _loadFromHiveCache();
    }
  }

  void _loadFromHiveCache() {
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
          p.category.toLowerCase().contains(_searchQuery) ||
          (p.barcode != null &&
              p.barcode!.toLowerCase().contains(_searchQuery)));
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
      _error = e.toString().replaceFirst('Exception: ', '');
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

  Future<Product?> findProductByBarcode(String barcode) async {
    try {
      final result = await _productService.findProductByBarcode(barcode);
      if (result != null) {
        return Product.fromJson(result);
      }
      return null;
    } catch (_) {
      return null;
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

  Future<void> loadLowStock() async {
    try {
      final data = await _productService.getLowStockProducts();
      if (data != null) {
        _lowStockCount = (data['count'] as num).toInt();
        _lowStockProducts = (data['products'] as List)
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('loadLowStock error: $e');
    }
    // Fallback: compute low-stock from local cached products
    await _loadLowStockFromLocal();
  }

  Future<void> _loadLowStockFromLocal() async {
    try {
      final localProducts = await _localDb.getProducts();
      if (localProducts.isNotEmpty) {
        final lowStock = localProducts
            .where((p) => p.stock <= p.lowStockThreshold)
            .toList();
        _lowStockCount = lowStock.length;
        _lowStockProducts = lowStock.map((p) => Product(
          id: p.id,
          shopId: p.shopId,
          name: p.name,
          description: p.description,
          price: p.price,
          stock: p.stock,
          sku: p.sku,
          category: p.category,
          imageUrl: p.imageUrl,
          barcode: p.barcode,
          lowStockThreshold: p.lowStockThreshold,
          isActive: p.isActive,
          createdAt: p.createdAt,
        )).toList();
        notifyListeners();
      }
    } catch (_) {}
  }
}
