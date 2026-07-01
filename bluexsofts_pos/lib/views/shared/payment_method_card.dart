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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [AppTheme.accent.withOpacity(0.2), AppTheme.primary.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : AppTheme.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.accent : AppTheme.darkBorder.withOpacity(0.5),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: AppTheme.accent.withOpacity(0.1), blurRadius: 8)]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? AppTheme.accent.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: selected ? AppTheme.accent : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                method == 'JAZZCASH' ? 'JazzCash' : 'EasyPaisa',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: selected ? Colors.white : Colors.grey[300],
                ),
              ),
            ),
            if (selected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}
