import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/dio_client.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/sale_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/ledger_provider.dart';
import 'providers/online_order_provider.dart';
import 'providers/report_provider.dart';
import 'providers/branch_provider.dart';
import 'providers/connectivity_provider.dart';
import 'services/connectivity_service.dart';
import 'services/sync_service.dart';
import 'screens/splash_screen.dart';
import 'widgets/barcode_keyboard_listener.dart';

class BluexSoftsPOSApp extends StatefulWidget {
  const BluexSoftsPOSApp({super.key});

  @override
  State<BluexSoftsPOSApp> createState() => _BluexSoftsPOSAppState();
}

class _BluexSoftsPOSAppState extends State<BluexSoftsPOSApp> {
  final SyncService _syncService = SyncService();

  Future<void> _onOnline() async {
    debugPrint('[app.dart] _onOnline FIRED');
    final ctx = DioClient.navigatorKey.currentContext;
    if (ctx == null) {
      debugPrint('[app.dart] _onOnline: navigatorKey.currentContext is null, skipping');
      return;
    }
    final saleProv = ctx.read<SaleProvider>();
    debugPrint('[app.dart] _onOnline: calling setSyncing(true)');
    saleProv.setSyncing(true);
    debugPrint('[app.dart] _onOnline: calling syncPendingChanges()');
    final result = await _syncService.syncPendingChanges();
    debugPrint('[app.dart] _onOnline: syncPendingChanges returned: $result');
    if (DioClient.navigatorKey.currentContext == null) {
      debugPrint('[app.dart] _onOnline: navigatorKey.currentContext lost after sync, skipping setSyncing(false)');
      return;
    }
    DioClient.navigatorKey.currentContext!.read<SaleProvider>().setSyncing(false);
    debugPrint('[app.dart] _onOnline: setSyncing(false) done');
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => SaleProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
        ChangeNotifierProvider(create: (_) => LedgerProvider()),
        ChangeNotifierProvider(create: (_) => OnlineOrderProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => BranchProvider()),
        ChangeNotifierProvider(
          create: (_) => ConnectivityProvider(
            ConnectivityService(),
            onOnline: () => _onOnline(),
          ),
        ),
      ],
      child: BarcodeKeyboardListener(
        child: MaterialApp(
          navigatorKey: DioClient.navigatorKey,
          title: 'BluexSofts POS',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
