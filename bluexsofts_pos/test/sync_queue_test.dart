import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluexsofts_pos/local_db/database.dart';
import 'package:bluexsofts_pos/local_db/local_database_service.dart';
import 'package:bluexsofts_pos/services/sync_service.dart';
import 'package:bluexsofts_pos/services/sale_service.dart';

class _MockSaleService extends SaleService {
  bool shouldFail = true;
  int callCount = 0;
  int failUntilCall = 0;

  @override
  Future<Map<String, dynamic>?> createSale(Map<String, dynamic> payload) async {
    callCount++;
    if (shouldFail || callCount <= failUntilCall) {
      throw Exception('Simulated network error');
    }
    return {
      'id': payload['id'],
      'shopId': payload['shopId'],
      'userId': payload['userId'],
      'total': payload['total'],
      'subtotal': payload['subtotal'],
      'tax': payload['tax'],
      'discount': payload['discount'],
      'paymentMethod': payload['paymentMethod'],
      'status': 'COMPLETED',
      'notes': payload['notes'] ?? '',
      'createdAt': payload['createdAt'],
      'saleItems': (payload['items'] as List?)?.cast<Map<String, dynamic>>() ?? [],
    };
  }
}

void main() {
  late AppDatabase database;
  late LocalDatabaseService localDb;
  late _MockSaleService mockSaleService;
  late SyncService syncService;

  setUp(() {
    database = AppDatabase.forTest(NativeDatabase.memory());
    localDb = LocalDatabaseService(database);
    mockSaleService = _MockSaleService();
    syncService = SyncService(
      saleService: mockSaleService,
      localDb: localDb,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('Sync queue round-trip', () {
    test('sale saved offline with synced=false and appears in pending queue', () async {
      final saleId = 'test-sale-1';

      await localDb.insertSale(SalesTableCompanion(
        id: Value(saleId),
        shopId: const Value('shop-1'),
        userId: const Value('user-1'),
        total: const Value(20.0),
        subtotal: const Value(20.0),
        tax: const Value(0),
        discount: const Value(0),
        paymentMethod: const Value('CASH'),
        status: const Value('COMPLETED'),
        notes: const Value('Test offline sale'),
        itemsJson: const Value('[]'),
        createdAt: Value(DateTime.now()),
        synced: const Value(false),
      ));

      await localDb.queueSaleSync(saleId, 'create', {'id': saleId});

      final localSales = await localDb.getSales(synced: false);
      expect(localSales.length, 1);
      expect(localSales.first.id, saleId);
      expect(localSales.first.synced, false);

      final pending = await localDb.getPendingSyncs();
      expect(pending.length, 1);
      expect(pending.first.entityId, saleId);
      expect(pending.first.entityType, 'sale');
      expect(pending.first.action, 'create');
      expect(pending.first.synced, false);
    });

    test('syncPendingChanges marks entries as synced on success', () async {
      final saleId = 'test-sale-2';

      await localDb.insertSale(SalesTableCompanion(
        id: Value(saleId),
        shopId: const Value('shop-1'),
        userId: const Value('user-1'),
        total: const Value(15.0),
        subtotal: const Value(15.0),
        tax: const Value(0),
        discount: const Value(0),
        paymentMethod: const Value('CASH'),
        status: const Value('COMPLETED'),
        notes: const Value(''),
        itemsJson: const Value('[]'),
        createdAt: Value(DateTime.now()),
        synced: const Value(false),
      ));

      await localDb.queueSaleSync(saleId, 'create', {
        'id': saleId,
        'shopId': 'shop-1',
        'userId': 'user-1',
        'items': [],
        'paymentMethod': 'CASH',
        'total': 15.0,
        'subtotal': 15.0,
        'tax': 0,
        'discount': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });

      mockSaleService.shouldFail = false;
      final result = await syncService.syncPendingChanges();

      expect(result['succeeded'], 1);
      expect(result['failed'], 0);

      final syncedSales = await localDb.getSales(synced: true);
      expect(syncedSales.length, 1);
      expect(syncedSales.first.id, saleId);
      expect(syncedSales.first.synced, true);

      final pending = await localDb.getPendingSyncs();
      expect(pending, isEmpty);
    });

    test('one failure does not block other entries from syncing', () async {
      final saleId1 = 'fail-sale';
      final saleId2 = 'ok-sale';

      await localDb.queueSaleSync(saleId1, 'create', {'id': saleId1});
      await localDb.queueSaleSync(saleId2, 'create', {
        'id': saleId2,
        'shopId': 'shop-1',
        'userId': 'user-1',
        'items': [],
        'paymentMethod': 'CASH',
        'total': 5.0,
        'subtotal': 5.0,
        'tax': 0,
        'discount': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // First call fails, second succeeds
      mockSaleService.failUntilCall = 1;
      mockSaleService.shouldFail = false;
      mockSaleService.callCount = 0;

      final result = await syncService.syncPendingChanges();

      expect(result['succeeded'], 1);
      expect(result['failed'], 1);
    });
  });
}