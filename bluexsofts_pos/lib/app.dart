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
import 'screens/splash_screen.dart';
import 'widgets/barcode_keyboard_listener.dart';

class BluexSoftsPOSApp extends StatelessWidget {
  const BluexSoftsPOSApp({super.key});

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
