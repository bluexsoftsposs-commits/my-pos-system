import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/subscription_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../views/shared/payment_method_card.dart';
import '../views/shared/row_widget.dart';
import 'dashboard_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Plan plan;
  const PaymentScreen({super.key, required this.plan});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'JAZZCASH';
  bool _paymentInitiated = false;
  bool _paymentVerified = false;
  String? _paymentId;
  String? _paymentUrl;
  String? _statusMessage;
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionProvider>();

    return Scaffold(
      appBar: AppBar(title: Text('Pay for ${widget.plan.name}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('Order Summary', style: Theme.of(context).textTheme.titleLarge),
                    const Divider(),
                    RowWidget(label: 'Plan', value: widget.plan.name),
                    RowWidget(label: 'Price', value: widget.plan.priceLabel),
                    const Divider(),
                    RowWidget(
                      label: 'Total',
                      value: widget.plan.priceLabel,
                      valueStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary),
                    ),
                  ],
                ),
              ),
            ),
            if (!_paymentInitiated) ...[
              const SizedBox(height: 24),
              Text('Select Payment Method', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              PaymentMethodCard(
                method: 'JAZZCASH',
                icon: Icons.account_balance_wallet,
                selected: _selectedMethod == 'JAZZCASH',
                onTap: () => setState(() => _selectedMethod = 'JAZZCASH'),
              ),
              const SizedBox(height: 8),
              PaymentMethodCard(
                method: 'EASIPAISA',
                icon: Icons.mobile_friendly,
                selected: _selectedMethod == 'EASIPAISA',
                onTap: () => setState(() => _selectedMethod = 'EASIPAISA'),
              ),
            ],
            const SizedBox(height: 24),
            if (_paymentVerified) ...[
              Card(
                color: AppTheme.success.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppTheme.success),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Payment Successful!', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(_statusMessage ?? 'Plan activated'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  context.read<AuthProvider>().refreshSubscription();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.success,
                ),
                child: const Text('Start Using POS'),
              ),
            ] else if (_paymentInitiated && !_paymentVerified) ...[
              Card(
                color: AppTheme.info.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Awaiting Payment', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            const Text('Complete payment in the browser.'),
                            TextButton.icon(
                              onPressed: _openPaymentTab,
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: const Text('Open payment page', style: TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: sub.isLoading ? null : _pay,
                  icon: sub.isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.lock),
                  label: Text(sub.isLoading ? 'Processing...' : 'Pay ${widget.plan.priceLabel}'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primary,
                  ),
                ),
              ),
              if (sub.error != null) ...[
                const SizedBox(height: 12),
                Text(sub.error!, style: const TextStyle(color: AppTheme.error), textAlign: TextAlign.center),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pay() async {
    final sub = context.read<SubscriptionProvider>();
    final result = await sub.initiatePayment(
      plan: widget.plan.id,
      paymentMethod: _selectedMethod,
    );

    if (result == null || !mounted) return;

    if (result['simulated'] == true) {
      setState(() {
        _paymentInitiated = true;
        _paymentVerified = true;
        _statusMessage = result['message'];
      });
      return;
    }

    final redirectUrl = result['redirectUrl'] as String?;
    final paymentId = result['paymentId'] as String?;

    if (redirectUrl != null && paymentId != null) {
      setState(() {
        _paymentInitiated = true;
        _paymentId = paymentId;
        _paymentUrl = redirectUrl;
      });

      await launchUrl(Uri.parse(redirectUrl), mode: LaunchMode.externalApplication);
      _startPolling(paymentId);
    }
  }

  Future<void> _openPaymentTab() async {
    if (_paymentUrl != null) {
      await launchUrl(Uri.parse(_paymentUrl!), mode: LaunchMode.externalApplication);
      if (_paymentId != null) _startPolling(_paymentId!);
    } else if (_paymentId != null) {
      _startPolling(_paymentId!);
    }
  }

  void _startPolling(String paymentId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final response = await ApiClient.get('/payment/status/$paymentId');
        final result = ApiClient.parseResponse(response);
        if (result['success'] && result['data']['completed'] == true) {
          timer.cancel();
          if (mounted) {
            setState(() {
              _paymentVerified = true;
              _statusMessage = '${result['data']['plan']} plan activated!';
            });
          }
        }
      } catch (_) {}
    });
  }
}
