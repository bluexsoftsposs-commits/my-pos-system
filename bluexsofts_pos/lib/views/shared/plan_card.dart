import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../core/theme.dart';

class PlanCard extends StatelessWidget {
  final Plan plan;
  final VoidCallback onSelect;
  const PlanCard({super.key, required this.plan, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: plan.popular
            ? Border.all(color: AppTheme.accent, width: 2)
            : Border.all(color: AppTheme.darkBorder.withOpacity(0.5)),
        boxShadow: [
          if (plan.popular)
            BoxShadow(
              color: AppTheme.accent.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          else
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plan.popular)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'Most Popular',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (plan.popular) const SizedBox(height: 16),
            Text(
              plan.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              plan.priceLabel,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: AppTheme.darkBorder),
            const SizedBox(height: 8),
            ...plan.features.map((f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.check, color: AppTheme.success, size: 14),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      f,
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSelect,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: plan.popular ? AppTheme.accent : AppTheme.darkSurface,
                  elevation: plan.popular ? 4 : 0,
                  shadowColor: plan.popular ? AppTheme.accent.withOpacity(0.4) : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: plan.popular
                        ? BorderSide.none
                        : BorderSide(color: AppTheme.darkBorder),
                  ),
                ),
                child: Text(
                  'Select ${plan.name} - ${plan.priceLabel}',
                  style: TextStyle(
                    color: plan.popular ? Colors.white : Colors.grey[300],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
