import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluexsofts_pos/local_db/database.dart';
import 'package:bluexsofts_pos/local_db/local_database_service.dart';
import 'package:bluexsofts_pos/providers/product_provider.dart';
import 'package:bluexsofts_pos/services/product_service.dart';

class _FailingProductService extends ProductService {
  @override
  Future<List<dynamic>?> getProducts() async {
    throw Exception('Network error');
  }
}

void main() {
  late AppDatabase database;
  late LocalDatabaseService localDb;

  setUp(() {
    database = AppDatabase.forTest(NativeDatabase.memory());
    localDb = LocalDatabaseService(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('ProductProvider offline fallback', () {
    test('network failure falls back to local DB', () async {
      await localDb.insertProduct(ProductsTableCompanion(
        id: const Value('local-1'),
        shopId: const Value('shop-A'),
        name: const Value('Offline Product'),
        description: const Value('Seeded locally'),
        price: const Value(9.99),
        stock: const Value(5),
        sku: const Value('OFF-001'),
        category: const Value('General'),
        imageUrl: const Value(''),
        lowStockThreshold: const Value(1),
        isActive: const Value(true),
        createdAt: Value(DateTime(2025, 1, 1)),
        updatedAt: Value(DateTime(2025, 1, 1)),
      ));

      // Replace DatabaseService singleton's internal DB with test one
      // Instead, test the LocalDatabaseService directly via the provider's internal logic
      // by creating the provider with a failing service and manually injecting DB
      // Since the provider uses DatabaseService() singleton, we need to seed that.
      // Simpler: just test _loadFromLocalDb via the provider's loadProducts path.

      // We bypass the singleton by testing the local DB service directly
      // and verify the provider gets data when network fails.
      final provider = ProductProvider(
        productService: _FailingProductService(),
        localDb: localDb,
      );

      // Provider's local DB is the test DB seeded above.
      // When network fails, it should fall back to local DB.
      await provider.loadProducts();

      // Should have loaded from local DB
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(provider.allProducts, isNotEmpty);
      expect(provider.allProducts.first.name, 'Offline Product');
    });

    test('local DB direct seed and read succeeds', () async {
      await localDb.insertProduct(ProductsTableCompanion(
        id: const Value('direct-1'),
        shopId: const Value('shop-A'),
        name: const Value('Direct Product'),
        description: const Value(''),
        price: const Value(5.0),
        stock: const Value(10),
        sku: const Value('DIR-001'),
        category: const Value('General'),
        imageUrl: const Value(''),
        lowStockThreshold: const Value(2),
        isActive: const Value(true),
        createdAt: Value(DateTime(2025, 6, 1)),
        updatedAt: Value(DateTime(2025, 6, 1)),
      ));

      final products = await localDb.getProducts();
      expect(products.length, 1);
      expect(products.first.name, 'Direct Product');
      expect(products.first.price, 5.0);
    });
  });
}