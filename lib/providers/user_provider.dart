import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../service_locator.dart';

class UserProvider extends ChangeNotifier {
  late User _currentUser;
  late bool _isLoggedIn;
  bool _isReady = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isReady => _isReady;

  Future<void> init() async {
    User? user = await serviceLocator.hiveService.getCurrentUser();

    _isLoggedIn = user != null && serviceLocator.apiService.isAuthenticated;

    if (_isLoggedIn) {
      _currentUser = user!;
      // Verify the token is still valid by making an API call
      try {
        final currentUser = await serviceLocator.apiService.getCurrentUser();
        _currentUser = currentUser;
        await serviceLocator.hiveService.saveCurrentUser(_currentUser);
      } catch (e) {
        debugPrint('Cannot verify session (offline?): $e');
        _isLoggedIn = true;
        _currentUser = user;
      }
    } else if (user != null && !serviceLocator.apiService.isAuthenticated) {
      await serviceLocator.hiveService.clearCurrentUser();
    }

    _isReady = true;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    await serviceLocator.apiService.login(username, password);
    await _updateUser();
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> createUser(
    String username,
    String email,
    String password,
  ) async {
    await serviceLocator.apiService.createUser(username, email, password);
    await login(email, password);
  }

  Future<void> logout() async {
    await serviceLocator.apiService.clearToken();
    await serviceLocator.hiveService.clearCurrentUser();
    await serviceLocator.hiveService.clearAllTransactions();
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<void> _updateUser() async {
    _currentUser = await serviceLocator.apiService.getCurrentUser();
    await serviceLocator.hiveService.saveCurrentUser(_currentUser);
  }
}
