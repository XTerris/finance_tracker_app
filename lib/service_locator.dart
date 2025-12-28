import 'services/database_service.dart';

// Локатор сервисов - предоставляет доступ к общим сервисам приложения
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();

  factory ServiceLocator() => _instance;

  ServiceLocator._internal();

  late DatabaseService _databaseService;

  // Инициализация всех сервисов при запуске приложения
  static Future<void> init() async {
    await DatabaseService.init();
    _instance._databaseService = DatabaseService();
  }

  DatabaseService get databaseService => _databaseService;

  // Освобождение ресурсов при закрытии приложения
  Future<void> dispose() async {
    await _databaseService.dispose();
  }
}

final serviceLocator = ServiceLocator();
