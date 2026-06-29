import 'package:flutter/material.dart';
import '../../core/theme.dart';

class PaymentBadge extends StatelessWidget {
  final String method;
  const PaymentBadge({super.key, required this.method});

  @override
  Widget build(BuildContext context) {
    final color = switch (method) {
      'CARD' => AppTheme.info,
      'MOBILE' => AppTheme.accent,
      _ => AppTheme.success,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(method, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
