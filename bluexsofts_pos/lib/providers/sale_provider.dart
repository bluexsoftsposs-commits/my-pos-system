import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../services/sale_service.dart';
import '../services/database_service.dart';
import '../models/sale.dart';
import '../local_db/database.dart';
import '../services/sync_service.dart';

class SaleProvider with ChangeNotifier {
  List<Sale> _sales = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _summary;
  bool _isSyncing = false;

  final _saleService = SaleService();
  final _localDb = DatabaseService().local;
  final _uuid = const Uuid();

  List<Sale> get sales => _sales;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get summary => _summary;
  bool get isSyncing => _isSyncing;

  Future<void> loadSales() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _saleService.getSales();
      if (data != null) {
        _sales = data.map((e) => Sale.fromJson(e as Map<String, dynamic>)).toList();
        // Opportunistic sync after successful network call
        await SyncFallback.instance.trySync();
      } else {
        _error = 'Failed to load sales';
      }
    } catch (e) {
      SyncFallback.instance.markFailure();
      _error = 'Failed to load sales';
    }

    _isLoading = false;
    notifyListeners();
  }

  static const _summaryCacheKey = 'sale_summary_cache';

  Future<void> loadSummary({String? from, String? to}) async {
    try {
      final data = await _saleService.getSummary(from: from, to: to);
      if (data != null) {
        _summary = data;
        // Cache to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_summaryCacheKey, jsonEncode(data));
        notifyListeners();
        return;
      }
    } catch (_) {}
    // Fallback: read from cache
    await _loadSummaryFromCache();
  }

  Future<void> _loadSummaryFromCache() async {
    try {
      if (_summary != null) return;
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_summaryCacheKey);
      if (cached != null) {
        _summary = jsonDecode(cached) as Map<String, dynamic>;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<Sale?> createSale(
    Map<String, dynamic> payload, {
    String shopId = '',
    String userId = '',
  }) async {
    final saleId = _uuid.v4();
    final rawItems = (payload['items'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];
    final subtotal = rawItems.fold<double>(
      0.0,
      (sum, item) => sum + ((item['price'] as num).toDouble() * (item['quantity'] as num).toInt()),
    );
    final tax = (payload['tax'] as num?)?.toDouble() ?? 0;
    final discount = (payload['discount'] as num?)?.toDouble() ?? 0;
    final total = subtotal + tax - discount;

    // ── DEBUG: createSale entered ──
    debugPrint('[createSale] ENTERED — saleId=$saleId shopId=$shopId userId=$userId');
    debugPrint('[createSale] payload keys: ${payload.keys}');
    debugPrint('[createSale] items count: ${(payload["items"] as List?)?.length}');
    debugPrint('[createSale] computed subtotal=$subtotal tax=$tax discount=$discount total=$total');

    // Always persist to local DB first
    try {
      await _localDb.insertSale(SalesTableCompanion(
        id: Value(saleId),
        shopId: Value(shopId),
        userId: Value(userId),
        total: Value(total),
        subtotal: Value(subtotal),
        tax: Value(tax),
        discount: Value(discount),
        paymentMethod: Value(payload['paymentMethod'] as String? ?? 'CASH'),
        status: const Value('COMPLETED'),
        notes: Value(payload['notes'] as String? ?? ''),
        itemsJson: Value(jsonEncode(rawItems)),
        createdAt: Value(DateTime.now()),
        synced: const Value(false),
      ));
      debugPrint('[createSale] local DB insert SUCCEEDED');
    } catch (e, stack) {
      debugPrint('[createSale] local DB insert FAILED: $e\n$stack');
      // If even the local DB insert fails, we cannot recover the sale.
      // Re-throw so the caller sees the failure.
      rethrow;
    }

    // Augment payload with generated fields for the backend
    final augmentedPayload = Map<String, dynamic>.from(payload)
      ..['id'] = saleId
      ..['shopId'] = shopId
      ..['userId'] = userId
      ..['subtotal'] = subtotal
      ..['total'] = total
      ..['createdAt'] = DateTime.now().toIso8601String();

    debugPrint('[createSale] augmentedPayload keys: ${augmentedPayload.keys}');
    debugPrint('[createSale] about to call _saleService.createSale');

    try {
      final data = await _saleService.createSale(augmentedPayload);
      if (data != null) {
        debugPrint('[createSale] network SUCCESS — marking synced, parsing response');
        debugPrint('[createSale] response keys: ${data.keys}');
        await _localDb.markSaleSynced(saleId);
        final sale = Sale.fromJson(data);
        _sales.insert(0, sale);
        notifyListeners();
        debugPrint('[createSale] returning sale id=${sale.id}');
        return sale;
      }
      debugPrint('[createSale] createSale returned null — enqueuing for sync');
    } catch (e, stack) {
      debugPrint('[createSale] network exception: $e\n$stack');
      SyncFallback.instance.markFailure();
    }

    // Network failed — enqueue for later sync
    debugPrint('[createSale] enqueuing saleId=$saleId for offline sync');
    await _localDb.queueSaleSync(saleId, 'create', augmentedPayload);
    _error = 'Sale saved offline — will sync when back online';
    notifyListeners();
    debugPrint('[createSale] returning null (offline path)');
    return null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void setSyncing(bool value) {
    _isSyncing = value;
    notifyListeners();
  }
}
