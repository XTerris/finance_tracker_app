import 'services/database_service.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();

  factory ServiceLocator() => _instance;

  ServiceLocator._internal();

  late DatabaseService _databaseService;

  static Future<void> init() async {
    await DatabaseService.init();
    _instance._databaseService = DatabaseService();
  }

  DatabaseService get databaseService => _databaseService;

  Future<void> dispose() async {
    await _databaseService.dispose();
  }
}

final serviceLocator = ServiceLocator();
