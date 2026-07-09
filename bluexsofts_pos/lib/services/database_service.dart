import '../local_db/database.dart';
import '../local_db/local_database_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  AppDatabase? _database;
  LocalDatabaseService? _localService;

  AppDatabase get database {
    _database ??= AppDatabase();
    return _database!;
  }

  LocalDatabaseService get local {
    _localService ??= LocalDatabaseService(database);
    return _localService!;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
    _localService = null;
  }
}