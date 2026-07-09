import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'database_service.dart';
import 'sale_service.dart';
import 'product_service.dart';
import '../local_db/database.dart';
import '../local_db/local_database_service.dart';

class SyncService {
  final SaleService _saleService;
  final ProductService _productService;
  final LocalDatabaseService _localDb;

  SyncService({
    SaleService? saleService,
    ProductService? productService,
    LocalDatabaseService? localDb,
  })  : _saleService = saleService ?? SaleService(),
        _productService = productService ?? ProductService(),
        _localDb = localDb ?? DatabaseService().local;

  /// Syncs all pending changes from the local queue.
  ///
  /// Returns a summary: `{succeeded: int, failed: int}`
  /// One failure does NOT block the remaining entries.
  Future<Map<String, int>> syncPendingChanges() async {
    int succeeded = 0;
    int failed = 0;

    try {
      final pending = await _localDb.getPendingSyncs();
      for (final entry in pending) {
        try {
          await _processSyncEntry(entry);
          succeeded++;
        } catch (e, stack) {
          failed++;
          debugPrint('sync error for entry ${entry.id}: $e\n$stack');
        }
      }
    } catch (e) {
      debugPrint('syncPendingChanges: failed to read queue: $e');
      failed++;
    }

    return {'succeeded': succeeded, 'failed': failed};
  }

  Future<void> _processSyncEntry(SyncQueueTableData entry) async {
    final action = entry.action;
    final entityType = entry.entityType;
    final entityId = entry.entityId;
    final payload = jsonDecode(entry.payload) as Map<String, dynamic>;

    switch (entityType) {
      case 'sale':
        await _syncSale(entityId, action, payload);
      case 'product':
        await _syncProduct(entityId, action, payload);
      default:
        debugPrint('Unknown entityType: $entityType');
    }

    await _localDb.markSyncCompleted(entry.id);
  }

  Future<void> _syncSale(String saleId, String action, Map<String, dynamic> payload) async {
    switch (action) {
      case 'create':
        final result = await _saleService.createSale(payload);
        if (result != null) {
          await _localDb.markSaleSynced(saleId);
        } else {
          throw Exception('Sale service returned null for sale $saleId');
        }
      default:
        throw Exception('Unknown sale action: $action');
    }
  }

  Future<void> _syncProduct(String productId, String action, Map<String, dynamic> payload) async {
    switch (action) {
      case 'create':
        await _productService.createProduct(payload);
      case 'update':
        await _productService.updateProduct(productId, payload);
      case 'delete':
        await _productService.deleteProduct(productId);
      default:
        throw Exception('Unknown product action: $action');
    }
  }
}

/// Singleton that tracks whether the app has observed a network failure
/// and needs to attempt sync on the next successful call.
class SyncFallback {
  SyncFallback._();
  static final SyncFallback instance = SyncFallback._();

  bool _hadFailure = false;

  /// Call from any provider's network-error catch block.
  void markFailure() {
    if (!_hadFailure) {
      _hadFailure = true;
      debugPrint('[SyncFallback] markFailure() — first failure recorded');
    }
  }

  /// Call from a successful network path. If a failure was previously
  /// recorded, runs syncPendingChanges once and resets the flag.
  Future<void> trySync() async {
    if (!_hadFailure) return;
    _hadFailure = false;
    debugPrint('[SyncFallback] trySync() — previous failure detected, attempting sync');
    try {
      final result = await SyncService().syncPendingChanges();
      debugPrint('[SyncFallback] trySync() — result: $result');
    } catch (e, stack) {
      debugPrint('[SyncFallback] trySync() — error: $e\n$stack');
    }
  }
}

/// Local type alias to avoid import conflicts
typedef LocalDatabaseServiceLocal = LocalDatabaseService;