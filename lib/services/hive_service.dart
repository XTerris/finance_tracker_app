import '../models/user.dart';


class HiveService {
  // TODO: Implement Hive DB methods
  Future<void> save(String box, dynamic data) async {
    // Placeholder for save method
  }

  Future<dynamic> get(String box, String key) async {
    // Placeholder for get method
    return null;
  }

  Future<User> getCurrentUser() async {
    // Wait 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    // Placeholder for getting current user
    return User(id: "1", name: "John Doe", email: "john.doe@example.com"); // Replace with actual user retrieval logic
  }

  Future<void> saveCurrentUser(User user) async {
    // Placeholder for saving current user
    await save('userBox', user);
  }
}
