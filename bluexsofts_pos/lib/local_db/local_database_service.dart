import 'dart:convert';

import 'package:drift/drift.dart';

import 'database.dart';

class LocalDatabaseService {
  final AppDatabase _db;

  LocalDatabaseService(this._db);

  // ── Products ─────────────────────────────────────────────────────────

  Future<void> insertProduct(ProductsTableCompanion product) async {
    await _db.into(_db.productsTable).insertOnConflictUpdate(product);
  }

  Future<void> insertProducts(List<ProductsTableCompanion> products) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.productsTable, products);
    });
  }

  Future<List<ProductsTableData>> getProducts({String? shopId}) async {
    if (shopId != null) {
      return (_db.select(_db.productsTable)
            ..where((tbl) => tbl.shopId.equals(shopId)))
          .get();
    }
    return _db.select(_db.productsTable).get();
  }

  Future<ProductsTableData?> getProduct(String id) async {
    final result = await (_db.select(_db.productsTable)
          ..where((t) => t.id.equals(id)))
        .get();
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> updateStock(String id, int newStock) async {
    await (_db.update(_db.productsTable)
          ..where((t) => t.id.equals(id)))
        .write(ProductsTableCompanion(
          stock: Value(newStock),
          updatedAt: Value(DateTime.now()),
        ));
  }

  Future<void> updateProduct(ProductsTableCompanion product) async {
    await _db.update(_db.productsTable).replace(product);
  }

  Future<void> deleteProduct(String id) async {
    await (_db.delete(_db.productsTable)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  // ── Sales ────────────────────────────────────────────────────────────

  Future<void> insertSale(SalesTableCompanion sale) async {
    await _db.into(_db.salesTable).insertOnConflictUpdate(sale);
  }

  Future<List<SalesTableData>> getSales({String? shopId, bool? synced}) async {
    final query = _db.select(_db.salesTable);
    if (shopId != null) {
      query.where((t) => t.shopId.equals(shopId));
    }
    if (synced != null) {
      query.where((t) => t.synced.equals(synced));
    }
    query.orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    return query.get();
  }

  Future<void> markSaleSynced(String id) async {
    await (_db.update(_db.salesTable)
          ..where((t) => t.id.equals(id)))
        .write(SalesTableCompanion(synced: Value(true)));
  }

  Future<void> deleteSale(String id) async {
    await (_db.delete(_db.salesTable)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  // ── Sync Queue ───────────────────────────────────────────────────────

  Future<void> enqueueSync(SyncQueueTableCompanion entry) async {
    await _db.into(_db.syncQueueTable).insert(entry);
  }

  Future<List<SyncQueueTableData>> getPendingSyncs() async {
    return (_db.select(_db.syncQueueTable)
          ..where((t) => t.synced.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc)]))
        .get();
  }

  Future<void> markSyncCompleted(int id) async {
    await (_db.update(_db.syncQueueTable)
          ..where((t) => t.id.equals(id)))
        .write(SyncQueueTableCompanion(synced: Value(true)));
  }

  Future<void> clearSyncedEntries() async {
    await (_db.delete(_db.syncQueueTable)
          ..where((t) => t.synced.equals(true)))
        .go();
  }

  /// Convenience: add a product change to the sync queue
  Future<void> queueProductSync(
    String entityId,
    String action, // 'create' | 'update' | 'delete'
    Map<String, dynamic> payload,
  ) async {
    await _addQueueEntry('product', entityId, action, payload);
  }

  /// Convenience: add a sale to the sync queue
  Future<void> queueSaleSync(
    String saleId,
    String action,
    Map<String, dynamic> payload,
  ) async {
    await _addQueueEntry('sale', saleId, action, payload);
  }

  Future<void> _addQueueEntry(
    String entityType,
    String entityId,
    String action,
    Map<String, dynamic> payload,
  ) async {
    await enqueueSync(SyncQueueTableCompanion(
      entityType: Value(entityType),
      entityId: Value(entityId),
      action: Value(action),
      payload: Value(jsonEncode(payload)),
      createdAt: Value(DateTime.now()),
    ));
  }

  // ── Utilities ────────────────────────────────────────────────────────

  Future<int> getProductCount({String? shopId}) async {
    final query = _db.select(_db.productsTable);
    if (shopId != null) {
      query.where((t) => t.shopId.equals(shopId));
    }
    return query.get().then((r) => r.length);
  }

  Future<void> clearAll() async {
    await _db.delete(_db.syncQueueTable).go();
    await _db.delete(_db.salesTable).go();
    await _db.delete(_db.productsTable).go();
  }
}