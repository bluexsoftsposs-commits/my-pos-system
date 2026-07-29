import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/currency_formatter.dart';
import '../../core/api_client.dart';

class CategoryDashboardSection extends StatefulWidget {
  final String category;
  const CategoryDashboardSection({super.key, required this.category});

  @override
  State<CategoryDashboardSection> createState() => _CategoryDashboardSectionState();
}

class _CategoryDashboardSectionState extends State<CategoryDashboardSection> {
  Map<String, dynamic>? _data;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(CategoryDashboardSection old) {
    super.didUpdateWidget(old);
    if (old.category != widget.category) _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      switch (widget.category) {
        case 'Pharmacy':
          final expiringResp = await ApiClient.get('/products/expiring?days=30');
          final expiringJson = ApiClient.parseResponse(expiringResp);
          final countResp = await ApiClient.get('/products/expiring-count?days=30');
          final countJson = ApiClient.parseResponse(countResp);
          _data = {
            'expiring': expiringJson['success'] ? expiringJson['data'] : [],
            'count': countJson['success'] ? ((countJson['data'] as Map<String, dynamic>?)?['count'] ?? 0) : 0,
          };
          break;
        case 'Electronics':
          final warrantyResp = await ApiClient.get('/products/warranty');
          final warrantyJson = ApiClient.parseResponse(warrantyResp);
          _data = {
            'warranty': warrantyJson['success'] ? warrantyJson['data'] as List<dynamic> : [],
          };
          break;
        case 'Restaurant':
          final menuResp = await ApiClient.get('/products/menu-items');
          final menuJson = ApiClient.parseResponse(menuResp);
          _data = {
            'menuItems': menuJson['success'] ? menuJson['data'] as List<dynamic> : [],
          };
          break;
        case 'Grocery':
          final lowStockResp = await ApiClient.get('/products/unit-low-stock');
          final lowStockJson = ApiClient.parseResponse(lowStockResp);
          _data = {
            'lowStock': lowStockJson['success'] ? lowStockJson['data'] as List<dynamic> : [],
          };
          break;
        case 'Clothing':
          final seasonalResp = await ApiClient.get('/products/seasonal');
          final seasonalJson = ApiClient.parseResponse(seasonalResp);
          _data = {
            'seasonal': seasonalJson['success'] ? seasonalJson['data'] as List<dynamic> : [],
          };
          break;
        default:
          _data = {};
      }
    } catch (_) {
      _data = {};
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_data == null || _data!.isEmpty) return const SizedBox.shrink();

    switch (widget.category) {
      case 'Pharmacy': return _buildPharmacySection();
      case 'Electronics': return _buildElectronicsSection();
      case 'Restaurant': return _buildRestaurantSection();
      case 'Grocery': return _buildGrocerySection();
      case 'Clothing': return _buildClothingSection();
      default: return const SizedBox.shrink();
    }
  }

  // ── Pharmacy ──────────────────────────────────────────────────────

  Widget _buildPharmacySection() {
    final expiring = (_data!['expiring'] as List<dynamic>?) ?? [];
    final count = (_data!['count'] as num?)?.toInt() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.medication, size: 20, color: AppTheme.error),
            const SizedBox(width: 8),
            Text('Pharmacy Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.error)),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$count expiring', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.error)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (expiring.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.success, size: 18),
                SizedBox(width: 8),
                Text('No products expiring in the next 30 days', style: TextStyle(color: AppTheme.success, fontSize: 13)),
              ],
            ),
          )
        else
          ...expiring.take(5).map((p) => _buildExpiringTile(p)),
      ],
    );
  }

  Widget _buildExpiringTile(dynamic p) {
    final expiry = p['expiryDate'] != null ? DateTime.tryParse(p['expiryDate'] as String) : null;
    final daysLeft = expiry != null ? expiry.difference(DateTime.now()).inDays : 999;
    final isExpired = daysLeft <= 0;
    final isSoon = daysLeft <= 7 && daysLeft > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isExpired ? AppTheme.error.withValues(alpha: 0.1) : isSoon ? AppTheme.warning.withValues(alpha: 0.1) : AppTheme.darkCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isExpired ? AppTheme.error.withValues(alpha: 0.3) : isSoon ? AppTheme.warning.withValues(alpha: 0.3) : AppTheme.darkBorder.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isExpired ? Icons.gpp_bad : Icons.medication,
            size: 18,
            color: isExpired ? AppTheme.error : isSoon ? AppTheme.warning : AppTheme.info,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${p['name']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                if (p['batchNumber'] != null)
                  Text('Batch: ${p['batchNumber']}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          Text(
            isExpired ? 'EXPIRED' : '$daysLeft days',
            style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 12,
              color: isExpired ? AppTheme.error : isSoon ? AppTheme.warning : AppTheme.info,
            ),
          ),
        ],
      ),
    );
  }

  // ── Electronics ───────────────────────────────────────────────────

  Widget _buildElectronicsSection() {
    final warranty = (_data!['warranty'] as List<dynamic>?) ?? [];
    final active = warranty.where((p) => p['isExpired'] == false).toList();
    final expired = warranty.where((p) => p['isExpired'] == true).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.handyman, size: 20, color: AppTheme.info),
            const SizedBox(width: 8),
            Text('Warranty Tracking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.info)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${active.length} active', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.success)),
            ),
            if (expired.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${expired.length} expired', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.error)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (warranty.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[500], size: 18),
                const SizedBox(width: 8),
                Text('No warranty-tracked products', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ],
            ),
          )
        else
          ...warranty.take(5).map((p) => _buildWarrantyTile(p)),
      ],
    );
  }

  Widget _buildWarrantyTile(dynamic p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p['isExpired'] == true ? AppTheme.error.withValues(alpha: 0.1) : AppTheme.darkCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: p['isExpired'] == true ? AppTheme.error.withValues(alpha: 0.3) : AppTheme.darkBorder.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            p['isExpired'] == true ? Icons.warning_amber : Icons.verified,
            size: 18,
            color: p['isExpired'] == true ? AppTheme.error : AppTheme.success,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${p['name']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                if (p['brand'] != null || p['model'] != null)
                  Text('${p['brand'] ?? ''} ${p['model'] ?? ''}'.trim(),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          Text(
            p['isExpired'] == true ? 'Expired' : '${p['monthsLeft']}mo left',
            style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 12,
              color: p['isExpired'] == true ? AppTheme.error : AppTheme.success,
            ),
          ),
        ],
      ),
    );
  }

  // ── Restaurant ────────────────────────────────────────────────────

  Widget _buildRestaurantSection() {
    final menuItems = (_data!['menuItems'] as List<dynamic>?) ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.restaurant_menu, size: 20, color: AppTheme.warning),
            const SizedBox(width: 8),
            Text('Menu Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.warning)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${menuItems.length} items', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.warning)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (menuItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[500], size: 18),
                const SizedBox(width: 8),
                Text('No menu items configured', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ],
            ),
          )
        else
          ...menuItems.take(5).map((p) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text('${p['name']}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                const Spacer(),
                Text(CurrencyFormatter.format((p['price'] as num?)?.toDouble() ?? 0),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.primary)),
              ],
            ),
          )),
      ],
    );
  }

  // ── Grocery ───────────────────────────────────────────────────────

  Widget _buildGrocerySection() {
    final lowStock = (_data!['lowStock'] as List<dynamic>?) ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.shopping_basket, size: 20, color: AppTheme.success),
            const SizedBox(width: 8),
            Text('Unit Stock Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.success)),
            if (lowStock.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${lowStock.length} low', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.error)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (lowStock.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.success, size: 18),
                SizedBox(width: 8),
                Text('All stock levels are healthy', style: TextStyle(color: AppTheme.success, fontSize: 13)),
              ],
            ),
          )
        else
          ...lowStock.take(5).map((p) {
            final unit = p['unitType'] ?? 'units';
            final value = p['unitValue'] != null ? '${p['unitValue']}' : '';
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory, size: 16, color: AppTheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${p['name']}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  ),
                  Text('$value $unit',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.error)),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ── Clothing ──────────────────────────────────────────────────────

  Widget _buildClothingSection() {
    final seasonal = (_data!['seasonal'] as List<dynamic>?) ?? [];
    final sizes = <String, int>{};
    final colors = <String, int>{};
    for (final p in seasonal) {
      final s = p['size'] as String? ?? 'N/A';
      final c = p['color'] as String? ?? 'N/A';
      sizes[s] = (sizes[s] ?? 0) + 1;
      colors[c] = (colors[c] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.checkroom, size: 20, color: AppTheme.accent),
            const SizedBox(width: 8),
            Text('Inventory Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.accent)),
          ],
        ),
        const SizedBox(height: 12),
        if (seasonal.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[500], size: 18),
                const SizedBox(width: 8),
                Text('No clothing items with size/color data', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ],
            ),
          )
        else ...[
          if (sizes.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sizes.entries.map((e) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Size ${e.key}: ${e.value}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
              )).toList(),
            ),
          if (colors.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: colors.entries.map((e) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${e.key}: ${e.value}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.success)),
              )).toList(),
            ),
          ],
        ],
      ],
    );
  }
}
