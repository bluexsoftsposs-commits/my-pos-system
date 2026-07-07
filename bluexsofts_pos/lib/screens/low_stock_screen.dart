import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../core/theme.dart';
import '../views/shared/product_form.dart';

class LowStockScreen extends StatefulWidget {
  const LowStockScreen({super.key});

  @override
  State<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends State<LowStockScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadLowStock();
    });
  }

  Future<void> _editThreshold(Product product) async {
    final ctrl = TextEditingController(text: product.lowStockThreshold.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Threshold: ${product.name}', style: const TextStyle(fontSize: 16)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Low stock threshold'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim());
              if (v != null && v >= 0) Navigator.of(ctx).pop(v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      await context.read<ProductProvider>().updateProduct(product.id, {'lowStockThreshold': result});
      if (mounted) {
        context.read<ProductProvider>().loadLowStock();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Threshold updated to $result'), backgroundColor: AppTheme.success),
        );
      }
    }
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProductProvider>();
    final items = prov.lowStockProducts;

    return Scaffold(
      appBar: AppBar(
        title: Text('Low Stock (${prov.lowStockCount})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => prov.loadLowStock(),
          ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: AppTheme.success.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  Text('All products are well stocked', style: TextStyle(color: Colors.grey[400])),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => prov.loadLowStock(),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final p = items[i];
                  final ratio = p.lowStockThreshold > 0 ? p.stock / p.lowStockThreshold : 1.0;
                  final urgency = ratio <= 0.3 ? AppTheme.error : (ratio <= 0.7 ? AppTheme.warning : AppTheme.info);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: urgency.withOpacity(0.3)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _editThreshold(p),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: urgency.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.inventory_2, color: urgency, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  if (p.sku.isNotEmpty)
                                    Text('SKU: ${p.sku}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${p.stock} / ${p.lowStockThreshold}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: urgency,
                                  ),
                                ),
                                Text(
                                  'threshold',
                                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.edit, size: 16, color: Colors.grey[600]),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
