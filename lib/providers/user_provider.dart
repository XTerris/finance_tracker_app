import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../service_locator.dart';

class UserProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isReady = false;

  User? get currentUser => _currentUser;
  bool get isReady => _isReady;

  Future<void> init() async {
    // Get default user from database (created on first launch)
    _currentUser = await serviceLocator.databaseService.getDefaultUser();

    _isReady = true;
    notifyListeners();
  }
}
