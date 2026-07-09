import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/constants.dart';
import 'services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.productsBox);
  await Hive.openBox(AppConstants.offlineQueueBox);
  await Hive.openBox(AppConstants.settingsBox);
  // Initialize local database
  DatabaseService();
  runApp(const BluexSoftsPOSApp());
}
