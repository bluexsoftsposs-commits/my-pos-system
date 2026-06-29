import 'package:flutter/material.dart';
import '../../core/theme.dart';

class PaymentMethodCard extends StatelessWidget {
  final String method;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const PaymentMethodCard({
    super.key,
    required this.method,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.15) : AppTheme.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.grey.withOpacity(0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppTheme.primary : Colors.grey, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                method == 'JAZZCASH' ? 'JazzCash' : 'EasyPaisa',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: selected ? AppTheme.primary : null),
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}
