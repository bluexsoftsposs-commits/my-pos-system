import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../models/user.dart';
import '../views/shared/plan_card.dart';
import 'payment_screen.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<SubscriptionProvider>().loadPlans());
  }

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a Plan'),
        automaticallyImplyLeading: false,
      ),
      body: sub.isLoading
          ? const Center(child: CircularProgressIndicator())
          : sub.plans.isEmpty
              ? const Center(child: Text('No plans available'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sub.plans.length,
                  itemBuilder: (context, index) {
                    final plan = sub.plans[index];
                    return PlanCard(plan: plan, onSelect: () => _selectPlan(plan));
                  },
                ),
    );
  }

  void _selectPlan(Plan plan) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PaymentScreen(plan: plan)),
    );
  }
}
