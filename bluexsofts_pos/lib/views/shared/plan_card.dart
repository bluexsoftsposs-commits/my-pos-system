import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../core/theme.dart';

class PlanCard extends StatelessWidget {
  final Plan plan;
  final VoidCallback onSelect;
  const PlanCard({super.key, required this.plan, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: plan.popular
            ? const BorderSide(color: AppTheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plan.popular)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Most Popular', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            if (plan.popular) const SizedBox(height: 12),
            Text(plan.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(plan.priceLabel, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            ...plan.features.map((f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                  const SizedBox(width: 12),
                  Text(f, style: const TextStyle(fontSize: 14)),
                ],
              ),
            )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSelect,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: plan.popular ? AppTheme.primary : AppTheme.darkCard,
                ),
                child: Text('Select ${plan.name} - ${plan.priceLabel}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
