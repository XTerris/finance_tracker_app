import 'services/api_service.dart';
import 'services/hive_service.dart';


class ServiceLocator {
    static final ServiceLocator _instance = ServiceLocator._internal();

    factory ServiceLocator() => _instance;

    ServiceLocator._internal();
    
    ApiService? _apiService;
    HiveService? _hiveService;
    
    ApiService get apiService {
        return _apiService ??= ApiService();
    }
    
    HiveService get hiveService {
        return _hiveService ??= HiveService();
    }
}

final serviceLocator = ServiceLocator();