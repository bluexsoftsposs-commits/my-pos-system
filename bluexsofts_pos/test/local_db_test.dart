import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluexsofts_pos/local_db/database.dart';
import 'package:bluexsofts_pos/local_db/local_database_service.dart';

void main() {
  late AppDatabase database;
  late LocalDatabaseService service;

  setUp(() {
    database = AppDatabase.forTest(NativeDatabase.memory());
    service = LocalDatabaseService(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('Local DB round-trip', () {
    test('insert a product and read it back', () async {
      await service.insertProduct(ProductsTableCompanion(
        id: const Value('prod-001'),
        shopId: const Value('shop-001'),
        name: const Value('Test Product'),
        description: const Value('A test product'),
        price: const Value(19.99),
        stock: const Value(10),
        sku: const Value('TST-001'),
        category: const Value('General'),
        imageUrl: const Value(''),
        lowStockThreshold: const Value(5),
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final product = await service.getProduct('prod-001');

      expect(product, isNotNull);
      expect(product!.id, 'prod-001');
      expect(product.name, 'Test Product');
      expect(product.price, 19.99);
      expect(product.stock, 10);
      expect(product.sku, 'TST-001');
    });

    test('update stock and verify', () async {
      await service.insertProduct(ProductsTableCompanion(
        id: const Value('prod-002'),
        shopId: const Value('shop-001'),
        name: const Value('Stock Test'),
        description: const Value(''),
        price: const Value(5.00),
        stock: const Value(50),
        sku: const Value('STK-001'),
        category: const Value('General'),
        imageUrl: const Value(''),
        lowStockThreshold: const Value(5),
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      await service.updateStock('prod-002', 25);

      final product = await service.getProduct('prod-002');
      expect(product, isNotNull);
      expect(product!.stock, 25);
    });

    test('get all products for a shop', () async {
      await service.insertProduct(ProductsTableCompanion(
        id: const Value('prod-a'),
        shopId: const Value('shop-A'),
        name: const Value('Product A'),
        description: const Value(''),
        price: const Value(1.0),
        stock: const Value(1),
        sku: const Value('A'),
        category: const Value('General'),
        imageUrl: const Value(''),
        lowStockThreshold: const Value(5),
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
      await service.insertProduct(ProductsTableCompanion(
        id: const Value('prod-b'),
        shopId: const Value('shop-B'),
        name: const Value('Product B'),
        description: const Value(''),
        price: const Value(2.0),
        stock: const Value(2),
        sku: const Value('B'),
        category: const Value('General'),
        imageUrl: const Value(''),
        lowStockThreshold: const Value(1),
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final products = await service.getProducts(shopId: 'shop-A');
      expect(products.length, 1);
      expect(products.first.id, 'prod-a');
    });
  });
}