import 'package:flutter/foundation.dart';
import '../service_locator.dart';
import '../models/user.dart';

    
class UserProvider extends ChangeNotifier {
    User? _currentUser;
    bool? _isLoggedIn;

    User? get currentUser => _currentUser;
    bool? get isLoggedIn => _isLoggedIn;

    Future<void> init() async {
        _currentUser = await serviceLocator.hiveService.getCurrentUser();
        if (_currentUser != null) {
            _isLoggedIn = true;
        }
        notifyListeners();
    }

    Future<void> updateUser() async {
        _currentUser = await serviceLocator.apiService.getCurrentUser();
        await serviceLocator.hiveService.saveCurrentUser(_currentUser!);
        notifyListeners();
    }
}